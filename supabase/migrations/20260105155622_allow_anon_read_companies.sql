/*
  # Allow anonymous users to read companies

  1. Changes
    - Add policy allowing anonymous users to view companies
    - This enables SIRET verification during registration before user authentication
    - Only SELECT access is granted, no write permissions

  2. Security
    - Anonymous users can only read company data
    - All other operations still require authentication
    - This is necessary for the registration flow where users check if a SIRET exists
*/

-- Allow anonymous users to view companies (for SIRET verification during registration)
CREATE POLICY "Anonymous can view companies"
  ON companies
  FOR SELECT
  TO anon
  USING (true);