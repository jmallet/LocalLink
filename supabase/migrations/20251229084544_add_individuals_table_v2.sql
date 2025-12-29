/*
  # Add Individuals Table for Individual Users

  ## Description
  Create a table for individual users (particuliers) who can only submit quote requests
  but cannot receive them. Individuals have a simpler profile than companies.

  ## New Tables

  ### individuals
  Stores profile information for individual users.
  - `id` (uuid, primary key)
  - `user_id` (uuid, foreign key to auth.users) - unique link to auth user
  - `first_name` (text) - individual's first name
  - `last_name` (text) - individual's last name
  - `phone` (text, nullable) - contact phone number
  - `city` (text, nullable) - city location
  - `postal_code` (text, nullable) - postal code
  - `created_at` (timestamptz) - account creation timestamp
  - `updated_at` (timestamptz) - last update timestamp

  ## Updates to Existing Tables

  ### quote_requests
  - Add `individual_id` column to support quote requests from individuals
  - Make `buyer_company_id` nullable since individuals don't have companies
  - Add constraint to ensure either buyer_company_id or individual_id is set

  ## Security
  - Enable RLS on individuals table
  - Individuals can only read and update their own profile
  - Quote request policies updated to support individuals

  ## Important Notes
  - Individuals can ONLY submit quote requests, not receive them
  - Companies continue to receive and respond to quote requests
  - One user can be either an individual OR have a company, not both
*/

-- Create individuals table
CREATE TABLE IF NOT EXISTS individuals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  first_name text NOT NULL DEFAULT '',
  last_name text NOT NULL DEFAULT '',
  phone text,
  city text,
  postal_code text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_individuals_user_id ON individuals(user_id);

-- Enable RLS
ALTER TABLE individuals ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Individuals can view their own profile" ON individuals;
DROP POLICY IF EXISTS "Individuals can update their own profile" ON individuals;
DROP POLICY IF EXISTS "Individuals can insert their own profile" ON individuals;

-- Policies for individuals
CREATE POLICY "Individuals can view their own profile"
  ON individuals FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Individuals can update their own profile"
  ON individuals FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Individuals can insert their own profile"
  ON individuals FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Add individual_id to quote_requests
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'individual_id'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN individual_id uuid REFERENCES individuals(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Make buyer_company_id nullable
ALTER TABLE quote_requests ALTER COLUMN buyer_company_id DROP NOT NULL;

-- Drop existing constraint if it exists
ALTER TABLE quote_requests DROP CONSTRAINT IF EXISTS quote_requests_buyer_check;

-- Add constraint to ensure either company or individual is set
ALTER TABLE quote_requests
ADD CONSTRAINT quote_requests_buyer_check
CHECK (
  (buyer_company_id IS NOT NULL AND individual_id IS NULL) OR
  (buyer_company_id IS NULL AND individual_id IS NOT NULL)
);

-- Create index for individual quote requests
CREATE INDEX IF NOT EXISTS idx_quote_requests_individual_id ON quote_requests(individual_id);

-- Update RLS policies for quote_requests to include individuals
DROP POLICY IF EXISTS "Companies can view quotes they requested" ON quote_requests;
DROP POLICY IF EXISTS "Buyers can view quotes they requested" ON quote_requests;

CREATE POLICY "Buyers can view quotes they requested"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    buyer_company_id IN (
      SELECT id FROM companies WHERE user_id = auth.uid()
    )
    OR
    individual_id IN (
      SELECT id FROM individuals WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Companies can insert their own quote requests" ON quote_requests;
DROP POLICY IF EXISTS "Buyers can insert their own quote requests" ON quote_requests;

CREATE POLICY "Buyers can insert their own quote requests"
  ON quote_requests FOR INSERT
  TO authenticated
  WITH CHECK (
    buyer_company_id IN (
      SELECT id FROM companies WHERE user_id = auth.uid()
    )
    OR
    individual_id IN (
      SELECT id FROM individuals WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Companies can update their own quote requests" ON quote_requests;
DROP POLICY IF EXISTS "Buyers can update their own quote requests" ON quote_requests;

CREATE POLICY "Buyers can update their own quote requests"
  ON quote_requests FOR UPDATE
  TO authenticated
  USING (
    buyer_company_id IN (
      SELECT id FROM companies WHERE user_id = auth.uid()
    )
    OR
    individual_id IN (
      SELECT id FROM individuals WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    buyer_company_id IN (
      SELECT id FROM companies WHERE user_id = auth.uid()
    )
    OR
    individual_id IN (
      SELECT id FROM individuals WHERE user_id = auth.uid()
    )
  );

-- Add policy for producers to view relevant approved quotes
DROP POLICY IF EXISTS "Producers can view relevant approved quotes" ON quote_requests;

CREATE POLICY "Producers can view relevant approved quotes"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    approved_by_admin = true
    AND id IN (
      SELECT quote_request_id FROM quote_recipients
      WHERE producer_company_id IN (
        SELECT id FROM companies WHERE user_id = auth.uid()
      )
    )
  );
