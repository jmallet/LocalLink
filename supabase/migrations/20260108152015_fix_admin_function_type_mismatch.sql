/*
  # Fix Admin Function Type Mismatch

  1. Problem
    - The email column from auth.users is varchar(255)
    - The function declares email as text
    - This causes a type mismatch error
  
  2. Solution
    - Cast the email column to text explicitly
  
  3. Changes
    - Update get_admin_user_list to cast u.email::text
*/

-- Drop and recreate function with proper type casting
DROP FUNCTION IF EXISTS get_admin_user_list();

CREATE OR REPLACE FUNCTION get_admin_user_list()
RETURNS TABLE (
  user_id uuid,
  first_name text,
  last_name text,
  phone text,
  user_type user_type,
  created_at timestamptz,
  updated_at timestamptz,
  email text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the caller is an admin using the helper function
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  -- Return the user list with emails (cast email to text)
  RETURN QUERY
  SELECT 
    p.user_id,
    p.first_name,
    p.last_name,
    p.phone,
    p.user_type,
    p.created_at,
    p.updated_at,
    u.email::text
  FROM profiles p
  JOIN auth.users u ON u.id = p.user_id
  ORDER BY p.created_at DESC;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_admin_user_list() TO authenticated;
