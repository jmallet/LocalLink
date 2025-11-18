/*
  # Remove budget field from quote requests

  1. Changes
    - Remove `budget` column from `quote_requests` table
    
  2. Notes
    - This field is no longer needed in the quote request flow
    - Removes financial information from quote requests
*/

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'budget'
  ) THEN
    ALTER TABLE quote_requests DROP COLUMN budget;
  END IF;
END $$;
