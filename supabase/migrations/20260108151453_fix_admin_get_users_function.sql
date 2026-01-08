/*
  # Fix Admin Get Users Function

  1. Problem
    - The get_admin_user_list function may have recursion issues similar to the RLS policies
    - The function checks admin status by querying profiles directly
  
  2. Solution
    - Update the function to use the new is_admin() helper function
    - This ensures consistent admin checking without recursion
  
  3. Changes
    - Drop and recreate get_admin_user_list function using is_admin()
*/

-- Drop existing function
DROP FUNCTION IF EXISTS get_admin_user_list();

-- Recreate function using is_admin() helper
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

  -- Return the user list with emails
  RETURN QUERY
  SELECT 
    p.user_id,
    p.first_name,
    p.last_name,
    p.phone,
    p.user_type,
    p.created_at,
    p.updated_at,
    u.email
  FROM profiles p
  JOIN auth.users u ON u.id = p.user_id
  ORDER BY p.created_at DESC;
END;
$$;
