/*
  # Add user roles system

  1. Changes
    - Add `role` column to companies table (user, admin)
    - Add admin_users table for admin-specific data
    - Add RLS policies for admin access

  2. Security
    - Only admins can view all companies
    - Only admins can moderate quotes
    - Only admins can manage blog posts
*/

-- Add role column to companies table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'role'
  ) THEN
    ALTER TABLE companies ADD COLUMN role text DEFAULT 'user' CHECK (role IN ('user', 'admin'));
  END IF;
END $$;

-- Create admin_users table for admin-specific data
CREATE TABLE IF NOT EXISTS admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  permissions jsonb DEFAULT '{"manage_companies": true, "manage_quotes": true, "manage_blog": true, "manage_payments": true}'::jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Admin can read their own admin data
CREATE POLICY "Admins can read own admin data"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Create helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM companies
    WHERE user_id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update companies policies to allow admin access
CREATE POLICY "Admins can view all companies"
  ON companies
  FOR SELECT
  TO authenticated
  USING (is_admin());

-- Allow admins to update any company (for verification)
CREATE POLICY "Admins can update any company"
  ON companies
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Allow admins to view all quote requests
CREATE POLICY "Admins can view all quote requests"
  ON quote_requests
  FOR SELECT
  TO authenticated
  USING (is_admin());

-- Allow admins to update quote requests (moderation)
CREATE POLICY "Admins can update quote requests"
  ON quote_requests
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Allow admins to view all quote recipients
CREATE POLICY "Admins can view all quote recipients"
  ON quote_recipients
  FOR SELECT
  TO authenticated
  USING (is_admin());

-- Allow admins to manage blog posts
CREATE POLICY "Admins can insert blog posts"
  ON blog_posts
  FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Admins can update blog posts"
  ON blog_posts
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Admins can delete blog posts"
  ON blog_posts
  FOR DELETE
  TO authenticated
  USING (is_admin());
