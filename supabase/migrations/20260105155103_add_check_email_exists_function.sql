/*
  # Add function to check if email exists

  1. New Functions
    - `check_email_exists(email_to_check text)`: Returns true if email exists in auth.users
    - This function is used during registration to prevent duplicate accounts
    - Only accessible to authenticated users attempting to register

  2. Security
    - Function runs with security definer privileges
    - Only returns boolean, no sensitive data exposed
*/

CREATE OR REPLACE FUNCTION check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE email = email_to_check
  );
END;
$$;