# CycleDo - Product Requirements Document

## One-liner
Smart recurring task manager — track life's maintenance cycles with completion-based scheduling.

## Problem
Life is full of recurring tasks that don't follow a fixed calendar:
- You're supposed to change the water filter every month, but you did it 5 days late — the next one should be a month from *when you actually did it*, not from the original date.
- Existing calendar apps (Google Calendar, iOS Reminders, TickTick) support recurring tasks, but they reset based on the *original schedule*, not the *actual completion date*.
- People forget maintenance tasks until something breaks.

## Solution
CycleDo manages "completion-based" recurring tasks. When you mark a task as done, the next due date is automatically calculated from the date you completed it.

## Target Users
- Homeowners (water filters, HVAC, pest control)
- Pet owners (deworming, vaccines, grooming)
- Car owners (oil change, tire rotation, inspection)
- Health-conscious people (dental cleaning, eye exam, physical)
- Anyone with recurring life maintenance tasks

## Core Features (MVP v1.0)

### 1. Task Management
- Create a recurring task: name, cycle (e.g., every 2 months), category
- Task list sorted by "days until due"
- Color-coded urgency: green (>7 days) → yellow (3-7 days) → red (overdue)

### 2. Smart Completion
- Tap "Done" → record actual completion date
- Automatically calculate next due date = completion date + cycle interval
- Keep completion history

### 3. Push Notifications
- Remind X days before due date (user configurable)
- Configurable notification time (e.g., 9:00 AM)
- Overdue reminders daily until completed

### 4. Categories & Templates
- Built-in templates:
  - 🏠 Home: water filter, AC cleaning, pest control
  - 🐕 Pets: deworming, vaccines, grooming
  - 🚗 Car: oil change, tire rotation, inspection
  - 🏥 Health: dental, eye exam, physical
- Custom categories supported

### 5. User Account
- Sign up / Sign in (Google, Apple, Email)
- Data synced across devices

## Features NOT in MVP (Future)
- Family sharing (multiple members)
- Shopping links (e.g., "buy this filter" → Amazon/JD)
- Maintenance cost tracking
- Photo attachments (e.g., photo of filter model)
- Calendar view
- Widgets (iOS/Android home screen)
- Apple Watch support

## Tech Stack

### Current Version (Telegram Mini App)
- **Frontend**: Pure HTML/CSS/JS, deployed on Cloudflare Pages (checkdom.pages.dev)
- **Backend**: Supabase (PostgreSQL + Auth)
- **Notifications**: pg_cron checks every minute → sends via Telegram Bot API
- **Bot**: @CheckDomAppBot

### Future App Version
- **Frontend**: React Native + Expo (one codebase for iOS + Android)
- **Backend**: Supabase (continue using existing project)
- **Notifications**: Expo Push Notifications (native push)

### Database Schema

```sql
-- Households
CREATE TABLE households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT 'My Home',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- User profiles (Telegram ID as primary key)
CREATE TABLE profiles (
  id BIGINT PRIMARY KEY,               -- Telegram user ID
  first_name TEXT,
  username TEXT,
  household_id UUID REFERENCES households(id),
  role TEXT DEFAULT 'member',           -- 'owner' or 'member'
  language TEXT DEFAULT 'ru',           -- 'zh', 'en', 'ru'
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Recurring tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  date TEXT NOT NULL,                   -- next due date (YYYY-MM-DD)
  freq INTEGER NOT NULL DEFAULT 1,     -- cycle value
  unit TEXT NOT NULL,                   -- cycle unit (month, week, year, day)
  history JSONB DEFAULT '[]'::jsonb,   -- completion history
  notify_days_before INTEGER DEFAULT 0,
  notify_time TEXT DEFAULT '09:00',
  notifications_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Notification Flow
1. Supabase pg_cron runs `check_and_notify_telegram()` every minute
2. Check tasks where `due_date - today <= notify_days_before`
3. Match current time with user's `notify_time` (in their timezone)
4. Send notification via Telegram Bot API
5. Error handling: skip failed users/tasks, never crash the whole loop

## Monetization (App Version)
- **Free tier**: up to 5 active tasks
- **Pro ($2.99/month or $24.99/year)**: unlimited tasks, custom categories
- Payment via App Store / Google Play in-app purchases

## Key Files
- `PRD.md` — This document (product requirements)
- `cycledo-schema.sql` — Complete database schema + notification function
- `checkdom-original.html` — Original frontend code (985 lines, Telegram Mini App)

## Supabase Project Info
- Project name: checkdom
- Reference ID: sytlwramamwttvrcxxtt
- Region: West EU (Ireland)
- Scheduled jobs: pg_cron runs notification check every minute

## Development Phases

### Phase 1 — Current (Telegram Mini App)
- [x] Basic task management (CRUD)
- [x] Completion-based auto-rescheduling
- [x] Telegram push notifications
- [x] Multi-language support (zh/en/ru)
- [x] Family/household sharing
- [x] Calendar view

### Phase 2 — App Version
- [ ] React Native + Expo setup
- [ ] Apple/Google sign-in
- [ ] Native push notifications
- [ ] Built-in category templates
- [ ] Submit to App Store + Google Play

### Phase 3 — Growth
- [ ] Home screen widgets
- [ ] Cost tracking
- [ ] Shopping links
- [ ] More languages

## Design Principles
1. **Dead simple** — Creating a task should take < 10 seconds
2. **Glanceable** — Open the app, instantly see what's due
3. **Trustworthy** — Notifications must be reliable, never miss a reminder
4. **Minimal** — No feature bloat, do one thing well
