/*
  # Add Admin Policies

  1. Security
    - Add policy for ADMIN users to read all profiles
    - Add policy for ADMIN users to update any profile
    - These policies allow admin dashboard to function properly
*/

-- Allow ADMIN users to view all profiles
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );

-- Allow ADMIN users to update any profile
CREATE POLICY "Admins can update any profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.user_type = 'ADMIN'
    )
  );