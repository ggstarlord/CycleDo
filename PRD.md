# CycleDo - Product Requirements Document

## One-liner
Smart recurring task manager — track life's maintenance cycles with completion-based scheduling.

## Problem
Life is full of recurring tasks that don't follow a fixed calendar:
- You're supposed to change the water filter every month, but you did it 5 days late — the next one should be a month from *when you actually did it*, not from the original date.
- Existing calendar apps (Google Calendar, iOS Reminders, TickTick) support recurring tasks, but they reset based on the *original schedule*, not the *actual completion date*.
- People forget maintenance tasks until something breaks.

## Solution
CycleDo is a mobile app that manages "completion-based" recurring tasks. When you mark a task as done, the next occurrence is automatically calculated from the date you completed it.

## Target Users
- Homeowners (water filters, HVAC, cleaning)
- Pet owners (deworming, vaccines, grooming)
- Car owners (oil change, tire rotation, inspection)
- Health-conscious people (dental cleaning, eye exam, prescriptions)
- Anyone with recurring life maintenance tasks

## Core Features (MVP - v1.0)

### 1. Task Management
- Create a recurring task: name, cycle (e.g., every 2 months), category
- View all tasks as a list sorted by "days until due"
- Color-coded urgency: green (>7 days) → yellow (3-7 days) → red (overdue)

### 2. Smart Completion
- Tap "Done" → record actual completion date
- Automatically calculate next due date = completion date + cycle interval
- Keep completion history (for tracking patterns)

### 3. Push Notifications
- Remind X days before due date (user configurable)
- Configurable notification time (e.g., 9:00 AM)
- Overdue reminders (daily until completed)

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
- Family sharing (multiple members in one household)
- Shopping links (e.g., "buy this filter" → Amazon/JD)
- Maintenance cost tracking
- Photo attachments (e.g., photo of the filter model)
- Calendar view
- Widgets (iOS/Android home screen)
- Apple Watch support

## Tech Stack

### Frontend
- **React Native + Expo** — one codebase for iOS + Android
- **Expo Router** — navigation
- **Expo Notifications** — push notifications

### Backend
- **Supabase** — database (PostgreSQL), auth, real-time sync
- Existing Supabase project can be reused/migrated

### Database Schema (v1.0)

```sql
-- Users (handled by Supabase Auth)
-- profiles table for extended user info
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  timezone TEXT DEFAULT 'UTC',
  language TEXT DEFAULT 'en',
  notification_token TEXT, -- Expo push token
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Task categories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,        -- e.g., "Home", "Pets", "Car"
  icon TEXT,                 -- emoji or icon name
  is_default BOOLEAN DEFAULT false,
  user_id UUID REFERENCES profiles(id), -- NULL = built-in template
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Recurring tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  category_id UUID REFERENCES categories(id),
  name TEXT NOT NULL,
  description TEXT,
  cycle_value INTEGER NOT NULL DEFAULT 1,  -- e.g., 2
  cycle_unit TEXT NOT NULL DEFAULT 'month', -- 'day', 'week', 'month', 'year'
  next_due_date DATE NOT NULL,
  notify_days_before INTEGER DEFAULT 1,
  notify_time TIME DEFAULT '09:00',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Completion history
CREATE TABLE completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  completed_at DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Push Notification Flow
1. Supabase pg_cron runs every minute
2. Check tasks where `next_due_date - today <= notify_days_before`
3. Match current time with user's `notify_time` (in their timezone)
4. Send push via Expo Push Notification Service
5. Error handling: skip failed users, continue to next (never crash the whole loop)

## Monetization
- **Free tier**: up to 5 active tasks
- **Pro ($2.99/month or $24.99/year)**: unlimited tasks, custom categories, priority support
- Payment via Apple App Store / Google Play in-app purchases

## App Store Info
- **App Name**: CycleDo
- **Subtitle**: Smart Recurring Task Manager
- **Keywords**: recurring tasks, maintenance reminder, home upkeep, cycle tracker, habit
- **Primary Category**: Productivity
- **Secondary Category**: Lifestyle

## Development Phases

### Phase 1 — MVP (4-6 weeks)
- [ ] Project setup (Expo + Supabase)
- [ ] Auth (Google + Apple sign-in)
- [ ] Task CRUD (create, read, update, delete)
- [ ] Completion flow (mark done → auto-reschedule)
- [ ] Push notifications
- [ ] Basic UI (task list, sorted by urgency)

### Phase 2 — Polish (2-3 weeks)
- [ ] Built-in category templates
- [ ] Onboarding flow
- [ ] Settings page (timezone, notification preferences)
- [ ] App Store assets (screenshots, description)
- [ ] Submit to App Store + Google Play

### Phase 3 — Growth (post-launch)
- [ ] Family sharing
- [ ] Widgets
- [ ] Cost tracking
- [ ] Localization (Chinese, Russian, etc.)

## Design Principles
1. **Dead simple** — Creating a task should take < 10 seconds
2. **Glanceable** — Open the app, instantly see what's due
3. **Trustworthy** — Notifications must be reliable, never miss a reminder
4. **Minimal** — No feature bloat, do one thing well
