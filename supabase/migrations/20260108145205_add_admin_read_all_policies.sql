/*
  # Add Admin Read-All Policies

  1. Security
    - Add policy for ADMIN users to read all companies
    - Add policy for ADMIN users to read all quote_requests
    - Add policy for ADMIN users to read all producer_profiles
    - Add policy for ADMIN users to update/delete companies
    - Add policy for ADMIN users to update/delete quote_requests
    - These policies allow admin dashboard to function properly
*/

-- Allow ADMIN users to view all companies
CREATE POLICY "Admins can view all companies"
  ON companies FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );

-- Allow ADMIN users to update any company
CREATE POLICY "Admins can update any company"
  ON companies FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );

-- Allow ADMIN users to delete any company
CREATE POLICY "Admins can delete any company"
  ON companies FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );

-- Allow ADMIN users to view all quote_requests
CREATE POLICY "Admins can view all quote_requests"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );

-- Allow ADMIN users to update any quote_request
CREATE POLICY "Admins can update any quote_request"
  ON quote_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );

-- Allow ADMIN users to delete any quote_request
CREATE POLICY "Admins can delete any quote_request"
  ON quote_requests FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );

-- Allow ADMIN users to view all producer_profiles
CREATE POLICY "Admins can view all producer_profiles"
  ON producer_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );