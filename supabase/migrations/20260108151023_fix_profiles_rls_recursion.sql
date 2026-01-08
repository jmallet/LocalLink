/*
  # Fix Profiles RLS Infinite Recursion

  1. Problem
    - The admin policies on profiles table cause infinite recursion
    - When checking if a user is admin, it queries profiles table which triggers the policy again
  
  2. Solution
    - Create a SECURITY DEFINER function that bypasses RLS to check admin status
    - Update admin policies to use this function instead of direct SELECT
  
  3. Changes
    - Drop existing admin policies
    - Create is_admin() function with SECURITY DEFINER
    - Recreate admin policies using the new function
*/

-- Drop existing admin policies that cause recursion
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;

-- Create a function to check if current user is admin (bypasses RLS)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role user_type;
BEGIN
  SELECT user_type INTO user_role
  FROM profiles
  WHERE user_id = auth.uid();
  
  RETURN user_role = 'ADMIN';
END;
$$;

-- Recreate admin policies using the new function
CREATE POLICY "Admins can view all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (is_admin());

CREATE POLICY "Admins can update any profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (is_admin());
