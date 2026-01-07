/*
  # Allow anonymous users to read producer profiles

  1. Changes
    - Add policy allowing anonymous users to view producer profiles
    - This enables public browsing of companies on the "Pros Locaux" page
    - Only active producer profiles can be viewed

  2. Security
    - Anonymous users can only read active producer profiles
    - All write operations still require authentication
    - This is necessary for the public company listing page
*/

-- Allow anonymous users to view active producer profiles
CREATE POLICY "Anonymous can view active producer profiles"
  ON producer_profiles
  FOR SELECT
  TO anon
  USING (is_active = true);