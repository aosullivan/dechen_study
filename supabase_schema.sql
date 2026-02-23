-- Study App Database Schema for Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Study Texts Table
CREATE TABLE study_texts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  full_text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Chapters Table
CREATE TABLE chapters (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  study_text_id UUID REFERENCES study_texts(id) ON DELETE CASCADE,
  number INTEGER NOT NULL,
  title TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(study_text_id, number)
);

-- Sections Table
CREATE TABLE sections (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  chapter_id UUID REFERENCES chapters(id) ON DELETE CASCADE,
  chapter_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Daily Sections Table (tracks user progress)
CREATE TABLE daily_sections (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  section_id UUID REFERENCES sections(id) ON DELETE CASCADE,
  date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, date)
);

-- Usage Metrics Event Stream (tracks product usage and dwell time)
CREATE TABLE app_usage_events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  occurred_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  received_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  event_name TEXT NOT NULL,
  session_id TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  anon_id TEXT,
  text_id TEXT,
  mode TEXT,
  section_path TEXT,
  section_title TEXT,
  chapter_number INTEGER,
  verse_ref TEXT,
  duration_ms INTEGER,
  properties JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for better query performance
CREATE INDEX idx_chapters_study_text ON chapters(study_text_id);
CREATE INDEX idx_sections_chapter ON sections(chapter_id);
CREATE INDEX idx_daily_sections_user ON daily_sections(user_id);
CREATE INDEX idx_daily_sections_date ON daily_sections(date);
CREATE INDEX idx_app_usage_events_occurred_at ON app_usage_events(occurred_at);
CREATE INDEX idx_app_usage_events_event_name_occurred_at ON app_usage_events(event_name, occurred_at);
CREATE INDEX idx_app_usage_events_text_mode_occurred_at ON app_usage_events(text_id, mode, occurred_at);
CREATE INDEX idx_app_usage_events_section_path_occurred_at ON app_usage_events(section_path, occurred_at);
CREATE INDEX idx_app_usage_events_user_occurred_at ON app_usage_events(user_id, occurred_at);

-- Enable Row Level Security (RLS)
ALTER TABLE study_texts ENABLE ROW LEVEL SECURITY;
ALTER TABLE chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_usage_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for study_texts (everyone can read)
CREATE POLICY "Public study texts are viewable by everyone"
  ON study_texts FOR SELECT
  USING (true);

-- RLS Policies for chapters (everyone can read)
CREATE POLICY "Public chapters are viewable by everyone"
  ON chapters FOR SELECT
  USING (true);

-- RLS Policies for sections (everyone can read)
CREATE POLICY "Public sections are viewable by everyone"
  ON sections FOR SELECT
  USING (true);

-- RLS Policies for daily_sections (users can only see their own)
CREATE POLICY "Users can view their own daily sections"
  ON daily_sections FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily sections"
  ON daily_sections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily sections"
  ON daily_sections FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Insert usage metrics events"
  ON app_usage_events FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    (auth.uid() IS NOT NULL AND user_id = auth.uid())
    OR
    (auth.uid() IS NULL AND user_id IS NULL)
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for study_texts
CREATE TRIGGER update_study_texts_updated_at
  BEFORE UPDATE ON study_texts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
