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

-- Create indexes for better query performance
CREATE INDEX idx_chapters_study_text ON chapters(study_text_id);
CREATE INDEX idx_sections_chapter ON sections(chapter_id);
CREATE INDEX idx_daily_sections_user ON daily_sections(user_id);
CREATE INDEX idx_daily_sections_date ON daily_sections(date);

-- Enable Row Level Security (RLS)
ALTER TABLE study_texts ENABLE ROW LEVEL SECURITY;
ALTER TABLE chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sections ENABLE ROW LEVEL SECURITY;

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
