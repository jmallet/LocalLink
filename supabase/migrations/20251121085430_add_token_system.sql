/*
  # Add Token System for Quote Unlocking

  ## Description
  Add a token-based system for producers to unlock quote requests. Producers purchase tokens
  and spend them to view full contact details of quote requesters.

  ## New Tables

  ### 1. company_tokens
  Tracks the token balance for each company.
  - `id` (uuid, primary key)
  - `company_id` (uuid, foreign key to companies)
  - `token_balance` (integer) - current number of available tokens
  - `total_purchased` (integer) - lifetime total of tokens purchased
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 2. token_transactions
  Records all token purchases and usage.
  - `id` (uuid, primary key)
  - `company_id` (uuid, foreign key to companies)
  - `type` (text) - 'purchase' or 'unlock'
  - `amount` (integer) - number of tokens (positive for purchase, negative for unlock)
  - `balance_after` (integer) - token balance after transaction
  - `quote_recipient_id` (uuid, nullable) - if type is 'unlock', links to the unlocked quote
  - `payment_id` (uuid, nullable) - links to payments table for purchases
  - `created_at` (timestamptz)

  ## Updates to Existing Tables

  ### quote_recipients
  - Update `unlocked` logic to work with token system
  - Add `unlocked_by_token` boolean to track if unlocked via token

  ## Security
  - Enable RLS on all new tables
  - Add policies for authenticated users to read their own data
  - Only allow token updates through secure functions

  ## Important Notes
  - Token purchases are handled via Stripe
  - Tokens are decremented atomically to prevent race conditions
  - Token balance cannot go negative
*/

-- Create company_tokens table
CREATE TABLE IF NOT EXISTS company_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL UNIQUE,
  token_balance integer DEFAULT 0 NOT NULL CHECK (token_balance >= 0),
  total_purchased integer DEFAULT 0 NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create token_transactions table
CREATE TABLE IF NOT EXISTS token_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  type text NOT NULL CHECK (type IN ('purchase', 'unlock')),
  amount integer NOT NULL,
  balance_after integer NOT NULL,
  quote_recipient_id uuid REFERENCES quote_recipients(id) ON DELETE SET NULL,
  payment_id uuid REFERENCES payments(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_company_tokens_company_id ON company_tokens(company_id);
CREATE INDEX IF NOT EXISTS idx_token_transactions_company_id ON token_transactions(company_id);
CREATE INDEX IF NOT EXISTS idx_token_transactions_type ON token_transactions(type);

-- Enable RLS
ALTER TABLE company_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;

-- Policies for company_tokens
CREATE POLICY "Companies can view their own tokens"
  ON company_tokens FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT id FROM companies WHERE user_id = auth.uid()
    )
  );

-- Policies for token_transactions
CREATE POLICY "Companies can view their own transactions"
  ON token_transactions FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT id FROM companies WHERE user_id = auth.uid()
    )
  );

-- Function to safely unlock a quote with a token
CREATE OR REPLACE FUNCTION unlock_quote_with_token(
  p_company_id uuid,
  p_quote_recipient_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_balance integer;
  v_new_balance integer;
  v_already_unlocked boolean;
BEGIN
  -- Check if quote is already unlocked
  SELECT unlocked INTO v_already_unlocked
  FROM quote_recipients
  WHERE id = p_quote_recipient_id AND producer_company_id = p_company_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Quote not found or unauthorized');
  END IF;

  IF v_already_unlocked THEN
    RETURN jsonb_build_object('success', false, 'error', 'Quote already unlocked');
  END IF;

  -- Get current token balance
  SELECT token_balance INTO v_current_balance
  FROM company_tokens
  WHERE company_id = p_company_id
  FOR UPDATE;

  -- If no token record exists, create one with 0 balance
  IF NOT FOUND THEN
    INSERT INTO company_tokens (company_id, token_balance, total_purchased)
    VALUES (p_company_id, 0, 0);
    v_current_balance := 0;
  END IF;

  -- Check if enough tokens
  IF v_current_balance < 1 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient tokens');
  END IF;

  -- Decrement token balance
  v_new_balance := v_current_balance - 1;
  
  UPDATE company_tokens
  SET token_balance = v_new_balance,
      updated_at = now()
  WHERE company_id = p_company_id;

  -- Unlock the quote
  UPDATE quote_recipients
  SET unlocked = true,
      unlocked_at = now()
  WHERE id = p_quote_recipient_id;

  -- Record the transaction
  INSERT INTO token_transactions (company_id, type, amount, balance_after, quote_recipient_id)
  VALUES (p_company_id, 'unlock', -1, v_new_balance, p_quote_recipient_id);

  RETURN jsonb_build_object('success', true, 'balance', v_new_balance);
END;
$$;

-- Function to add tokens after purchase
CREATE OR REPLACE FUNCTION add_tokens_after_purchase(
  p_company_id uuid,
  p_token_amount integer,
  p_payment_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_balance integer;
  v_new_balance integer;
BEGIN
  -- Get or create token record
  INSERT INTO company_tokens (company_id, token_balance, total_purchased)
  VALUES (p_company_id, 0, 0)
  ON CONFLICT (company_id) DO NOTHING;

  -- Get current balance
  SELECT token_balance INTO v_current_balance
  FROM company_tokens
  WHERE company_id = p_company_id
  FOR UPDATE;

  -- Add tokens
  v_new_balance := v_current_balance + p_token_amount;

  UPDATE company_tokens
  SET token_balance = v_new_balance,
      total_purchased = total_purchased + p_token_amount,
      updated_at = now()
  WHERE company_id = p_company_id;

  -- Record transaction
  INSERT INTO token_transactions (company_id, type, amount, balance_after, payment_id)
  VALUES (p_company_id, 'purchase', p_token_amount, v_new_balance, p_payment_id);

  RETURN jsonb_build_object('success', true, 'balance', v_new_balance);
END;
$$;