/*
  # Fix Admin RLS policies for quote clarifications and proposals

  1. Changes
    - Drop existing admin SELECT policies for quote_clarifications and quote_proposals
    - Recreate them using the is_admin() function for consistency
    - Ensure admins can view all clarifications and proposals

  2. Security
    - Maintains strict RLS while ensuring admins have full read access
*/

-- Drop and recreate admin policies for quote_clarifications
DROP POLICY IF EXISTS "Admins can read all quote clarifications" ON quote_clarifications;

CREATE POLICY "Admins can read all quote clarifications"
  ON quote_clarifications
  FOR SELECT
  TO authenticated
  USING (is_admin());

-- Drop and recreate admin policies for quote_proposals  
DROP POLICY IF EXISTS "Admins can read all quote proposals" ON quote_proposals;

CREATE POLICY "Admins can read all quote proposals"
  ON quote_proposals
  FOR SELECT
  TO authenticated
  USING (is_admin());
