-- Enable email auth with confirmation
-- This configures the auth.users table to require email confirmation

-- Create storage bucket for texts
INSERT INTO storage.buckets (id, name, public)
VALUES ('texts', 'texts', false)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for the texts bucket
-- Allow authenticated users to upload their own files
CREATE POLICY "Users can upload their own texts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'texts' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to read their own files
CREATE POLICY "Users can read their own texts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'texts' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to update their own files
CREATE POLICY "Users can update their own texts"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'texts' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own files
CREATE POLICY "Users can delete their own texts"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'texts' AND auth.uid()::text = (storage.foldername(name))[1]);
