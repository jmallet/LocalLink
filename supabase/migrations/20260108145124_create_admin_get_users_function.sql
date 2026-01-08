/*
  # Create Admin Get Users Function

  1. New Function
    - `get_admin_user_list` function that returns profiles with emails
    - Only accessible by ADMIN users
    - Uses SECURITY DEFINER to access auth.users
  
  2. Security
    - Function checks that caller is ADMIN before returning data
*/

-- Create a function that returns user list for admins
CREATE OR REPLACE FUNCTION get_admin_user_list()
RETURNS TABLE (
  user_id uuid,
  first_name text,
  last_name text,
  phone text,
  user_type text,
  created_at timestamptz,
  updated_at timestamptz,
  email text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the caller is an admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.user_id = auth.uid()
    AND p.user_type = 'ADMIN'
  ) THEN
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