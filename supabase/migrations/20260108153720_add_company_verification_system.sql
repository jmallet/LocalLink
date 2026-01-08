/*
  # Add Company Verification System

  1. New Columns
    - `companies.verified` (boolean) - Indicates if the company has been verified by an admin
  
  2. New Functions
    - `admin_toggle_company_verification` - Allows admins to verify/unverify companies
    - `get_admin_company_list` - Returns all companies with verification status for admin
  
  3. Changes to RLS Policies
    - Pros can only update their company profile if verified = true
    - Reading is still allowed for unverified companies
  
  4. Security
    - Only admins can change verification status
    - Unverified companies are blocked from updates (except by admins)
*/

-- Add verified column to companies table
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS verified boolean DEFAULT false;

-- Update existing companies to be unverified by default
UPDATE companies SET verified = false WHERE verified IS NULL;

-- Drop existing update policy for companies
DROP POLICY IF EXISTS "Company users can update" ON companies;

-- Recreate update policy with verification check
CREATE POLICY "Company users can update"
  ON companies FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_users
      WHERE company_users.company_id = companies.id
      AND company_users.user_id = auth.uid()
    )
    AND verified = true -- Company must be verified
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_users
      WHERE company_users.company_id = companies.id
      AND company_users.user_id = auth.uid()
    )
    AND verified = true -- Company must be verified
  );

-- Create admin function to toggle company verification
CREATE OR REPLACE FUNCTION admin_toggle_company_verification(
  company_id_param uuid,
  new_verified_status boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the caller is an admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  -- Update the company verification status
  UPDATE companies
  SET verified = new_verified_status
  WHERE id = company_id_param;

  RETURN true;
END;
$$;

-- Grant execute to authenticated users (they must be admin to actually use it)
GRANT EXECUTE ON FUNCTION admin_toggle_company_verification(uuid, boolean) TO authenticated;

-- Create function to get all companies for admin (with verification status)
CREATE OR REPLACE FUNCTION get_admin_company_list()
RETURNS TABLE (
  id uuid,
  name text,
  siret text,
  description text,
  city text,
  postal_code text,
  address text,
  verified boolean,
  is_claimed boolean,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the caller is an admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  -- Return all companies with verification status
  RETURN QUERY
  SELECT 
    c.id,
    c.name,
    c.siret,
    c.description,
    c.city,
    c.postal_code,
    c.address,
    c.verified,
    c.is_claimed,
    c.created_at
  FROM companies c
  ORDER BY c.created_at DESC;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_admin_company_list() TO authenticated;
