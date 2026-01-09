/*
  # Add foreign key for quote_requests requester

  1. Changes
    - Add foreign key constraint from quote_requests.requester_id to profiles.user_id
    
  2. Notes
    - This allows PostgREST to properly join quote_requests with profiles
    - The requester_id already references auth.users, and profiles.user_id also references auth.users
    - This creates a logical relationship for queries
*/

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'quote_requests_requester_id_profiles_fkey'
    AND table_name = 'quote_requests'
  ) THEN
    ALTER TABLE quote_requests
    ADD CONSTRAINT quote_requests_requester_id_profiles_fkey
    FOREIGN KEY (requester_id) REFERENCES profiles(user_id) ON DELETE CASCADE;
  END IF;
END $$;
