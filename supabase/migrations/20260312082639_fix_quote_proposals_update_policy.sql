/*
  # Fix quote proposals update policy
  
  1. Changes
    - Update the "Producers can update their own proposals" policy to allow updating REJECTED proposals
    - Producers can now re-submit proposals after they've been rejected
    - The USING clause allows updates on PENDING or REJECTED proposals
    - The WITH CHECK clause ensures the new status is PENDING
  
  2. Security
    - Maintains requirement that user must be a producer in the company
    - Ensures updated proposals always return to PENDING status
*/

DROP POLICY IF EXISTS "Producers can update their own proposals" ON quote_proposals;

CREATE POLICY "Producers can update their own proposals"
  ON quote_proposals
  FOR UPDATE
  TO authenticated
  USING (
    (status IN ('PENDING', 'REJECTED'))
    AND
    (EXISTS (
      SELECT 1
      FROM company_users
      WHERE company_users.company_id = quote_proposals.producer_company_id
        AND company_users.user_id = auth.uid()
        AND company_users.is_producteur = true
    ))
  )
  WITH CHECK (
    (status = 'PENDING')
    AND
    (EXISTS (
      SELECT 1
      FROM company_users
      WHERE company_users.company_id = quote_proposals.producer_company_id
        AND company_users.user_id = auth.uid()
        AND company_users.is_producteur = true
    ))
  );