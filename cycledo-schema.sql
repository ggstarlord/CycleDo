-- CycleDo Database Schema
-- Supabase project: sytlwramamwttvrcxxtt
-- Last updated: 2026-04-02

-- ============================================
-- Tables
-- ============================================

CREATE TABLE households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '我的别墅',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE profiles (
  id BIGINT PRIMARY KEY,               -- Telegram user ID
  first_name TEXT,
  username TEXT,
  household_id UUID REFERENCES households(id),
  role TEXT DEFAULT 'member',
  language TEXT DEFAULT 'ru',           -- 'zh', 'en', 'ru'
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  date TEXT NOT NULL,                   -- next due date (YYYY-MM-DD)
  freq INTEGER NOT NULL DEFAULT 1,     -- cycle value
  unit TEXT NOT NULL,                   -- cycle unit (月, etc.)
  history JSONB DEFAULT '[]'::jsonb,   -- completion dates array
  notify_days_before INTEGER DEFAULT 0,
  notify_time TEXT DEFAULT '09:00',
  notifications_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- Notification Function
-- ============================================

CREATE OR REPLACE FUNCTION check_and_notify_telegram()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  bot_token text := current_setting('app.settings.tg_bot_token', true);
  user_record record;
  task_record record;
  message_text text;
  user_local_now timestamp;
  user_today date;
  user_current_time text;
  days_left integer;
  user_tz text;

  lang_code text;
  txt_header text;
  txt_task text;
  txt_time text;
  txt_link text;
BEGIN
  -- fallback: if env var not set, use hardcoded token
  IF bot_token IS NULL OR bot_token = '' THEN
    bot_token := '7936452208:AAFzPACB4OCUCwmq2BLwxxxqQJ-plXqnsiA';
  END IF;

  FOR user_record IN SELECT * FROM profiles LOOP
    BEGIN  -- per-user error handling

      user_tz := coalesce(user_record.timezone, 'UTC');
      BEGIN
        user_local_now := now() AT TIME ZONE user_tz;
      EXCEPTION WHEN OTHERS THEN
        user_local_now := now() AT TIME ZONE 'UTC';
      END;

      user_today := user_local_now::date;
      user_current_time := to_char(user_local_now, 'HH24:MI');

      FOR task_record IN
        SELECT * FROM tasks
        WHERE household_id = user_record.household_id
          AND notifications_enabled = true
          AND notify_time = user_current_time
          AND (date::date - user_today) <= notify_days_before
          AND (date::date - user_today) >= 0
      LOOP
        BEGIN  -- per-task error handling
          days_left := task_record.date::date - user_today;
          lang_code := coalesce(user_record.language, 'ru');

          IF lang_code = 'zh' THEN
              txt_task := '📋 事项：';
              txt_time := '📅 时间：';
              txt_link := '👇 点击去处理：';
              IF days_left = 0 THEN txt_header := '🚨 <b>今日到期！请立即执行</b>';
              ELSIF days_left = 1 THEN txt_header := '⚠️ <b>明天到期！别忘了</b>';
              ELSE txt_header := '⏳ <b>倒计时 ' || days_left || ' 天 (请提前准备)</b>';
              END IF;
          ELSIF lang_code = 'en' THEN
              txt_task := '📋 Task: ';
              txt_time := '📅 Date: ';
              txt_link := '👇 Check details:';
              IF days_left = 0 THEN txt_header := '🚨 <b>DUE TODAY! Action required</b>';
              ELSIF days_left = 1 THEN txt_header := '⚠️ <b>DUE TOMORROW!</b>';
              ELSE txt_header := '⏳ <b>Countdown: ' || days_left || ' days left</b>';
              END IF;
          ELSE
              txt_task := '📋 Задача: ';
              txt_time := '📅 Дата: ';
              txt_link := '👇 Нажмите для деталей:';
              IF days_left = 0 THEN txt_header := '🚨 <b>СЕГОДНЯ! Срок выполнения</b>';
              ELSIF days_left = 1 THEN txt_header := '⚠️ <b>ЗАВТРА! Не забудьте</b>';
              ELSE txt_header := '⏳ <b>Осталось дней: ' || days_left || ' (Подготовьтесь)</b>';
              END IF;
          END IF;

          message_text := txt_header || E'\n\n' ||
                          txt_task || task_record.name || E'\n' ||
                          txt_time || task_record.date || E'\n\n' ||
                          txt_link || E'\n' ||
                          'https://t.me/CheckDomAppBot/checkdom';

          PERFORM net.http_post(
            url := 'https://api.telegram.org/bot' || bot_token || '/sendMessage',
            headers := '{"Content-Type": "application/json"}'::jsonb,
            body := jsonb_build_object(
              'chat_id', user_record.id,
              'text', message_text,
              'parse_mode', 'HTML'
            )
          );
        EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'Error sending task % to user %: %', task_record.id, user_record.id, SQLERRM;
        END;
      END LOOP;

    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Error processing user %: %', user_record.id, SQLERRM;
    END;
  END LOOP;
END;
$$;

-- ============================================
-- Cron Job (pg_cron)
-- ============================================
-- Runs every minute to check and send notifications
-- SELECT cron.schedule('check_and_notify', '* * * * *', 'SELECT check_and_notify_telegram();');
