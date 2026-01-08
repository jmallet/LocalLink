/*
  # Improve is_admin Function

  1. Problem
    - The is_admin() function may return NULL instead of FALSE when user doesn't exist
    - In PostgreSQL, NULL = 'ADMIN' returns NULL, not FALSE
  
  2. Solution
    - Use COALESCE to ensure the function always returns a boolean
    - Return FALSE explicitly when user_type is NULL or not ADMIN
  
  3. Changes
    - Update is_admin() to handle NULL cases properly
*/

-- Recreate is_admin function with better NULL handling
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
  
  -- Return FALSE if user_role is NULL, otherwise check if it's ADMIN
  RETURN COALESCE(user_role = 'ADMIN', FALSE);
END;
$$;
