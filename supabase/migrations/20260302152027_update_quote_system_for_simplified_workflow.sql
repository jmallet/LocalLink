/*
  # Mise à jour du système de devis pour un workflow simplifié

  ## Description
  Cette migration adapte le système de devis pour un parcours utilisateur simplifié :
  - Ajout d'un champ d'urgence pour les demandes de devis
  - Support des fourchettes de prix dans les propositions
  - Système de demande de précisions
  - Nouveau statut "EN_ATTENTE_INFOS"

  ## Modifications apportées
  
  ### 1. Table quote_requests
  - Ajout de `urgency` (enum) : URGENT_48H, THIS_WEEK, FLEXIBLE
  - Simplification des champs (volume et fréquence deviennent optionnels)
  - Nouveau statut : WAITING_FOR_INFO

  ### 2. Table quote_proposals
  - Ajout de `proposal_type` : FIXED_PRICE, PRICE_RANGE
  - Ajout de `price_min` et `price_max` pour les fourchettes
  - `proposed_amount` devient optionnel (utilisé uniquement pour FIXED_PRICE)

  ### 3. Nouvelle table quote_clarifications
  - Stocke les demandes de précisions des professionnels
  - Permet les échanges de questions/réponses

  ## Sécurité (RLS)
  - Les professionnels peuvent créer des demandes de clarification
  - Les particuliers peuvent voir et répondre aux clarifications
  - Politiques adaptées pour la lecture/écriture
*/

-- ============================================================================
-- 1. AJOUT DE NOUVEAUX ENUMS
-- ============================================================================

CREATE TYPE urgency_level AS ENUM ('URGENT_48H', 'THIS_WEEK', 'FLEXIBLE');
CREATE TYPE proposal_type AS ENUM ('FIXED_PRICE', 'PRICE_RANGE');

-- Mise à jour de l'enum quote_status pour ajouter WAITING_FOR_INFO
ALTER TYPE quote_status ADD VALUE IF NOT EXISTS 'WAITING_FOR_INFO';

-- ============================================================================
-- 2. MISE À JOUR DE LA TABLE QUOTE_REQUESTS
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quote_requests' AND column_name = 'urgency'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN urgency urgency_level DEFAULT 'FLEXIBLE';
  END IF;
END $$;

-- ============================================================================
-- 3. MISE À JOUR DE LA TABLE QUOTE_PROPOSALS
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quote_proposals' AND column_name = 'proposal_type'
  ) THEN
    ALTER TABLE quote_proposals ADD COLUMN proposal_type proposal_type DEFAULT 'FIXED_PRICE';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quote_proposals' AND column_name = 'price_min'
  ) THEN
    ALTER TABLE quote_proposals ADD COLUMN price_min numeric;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quote_proposals' AND column_name = 'price_max'
  ) THEN
    ALTER TABLE quote_proposals ADD COLUMN price_max numeric;
  END IF;
END $$;

-- Rendre proposed_amount nullable puisqu'il n'est utilisé que pour FIXED_PRICE
ALTER TABLE quote_proposals ALTER COLUMN proposed_amount DROP NOT NULL;

-- ============================================================================
-- 4. CRÉATION DE LA TABLE QUOTE_CLARIFICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS quote_clarifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_request_id uuid NOT NULL REFERENCES quote_requests(id) ON DELETE CASCADE,
  producer_company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  question text NOT NULL,
  answer text,
  answered_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 5. ACTIVATION RLS POUR QUOTE_CLARIFICATIONS
-- ============================================================================

ALTER TABLE quote_clarifications ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. POLICIES RLS POUR QUOTE_CLARIFICATIONS
-- ============================================================================

CREATE POLICY "Producers can create clarifications for their company"
  ON quote_clarifications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_users 
      WHERE company_users.company_id = quote_clarifications.producer_company_id 
      AND company_users.user_id = auth.uid() 
      AND company_users.is_producteur = true
    )
  );

CREATE POLICY "Producers can view their company clarifications"
  ON quote_clarifications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_users 
      WHERE company_users.company_id = quote_clarifications.producer_company_id 
      AND company_users.user_id = auth.uid()
    )
  );

CREATE POLICY "Requesters can view clarifications for their requests"
  ON quote_clarifications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quote_requests 
      WHERE quote_requests.id = quote_clarifications.quote_request_id 
      AND quote_requests.requester_id = auth.uid()
    )
  );

CREATE POLICY "Requesters can answer clarifications for their requests"
  ON quote_clarifications
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quote_requests 
      WHERE quote_requests.id = quote_clarifications.quote_request_id 
      AND quote_requests.requester_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM quote_requests 
      WHERE quote_requests.id = quote_clarifications.quote_request_id 
      AND quote_requests.requester_id = auth.uid()
    )
  );

-- ============================================================================
-- 7. INDEX POUR QUOTE_CLARIFICATIONS
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_quote_clarifications_quote_request_id 
  ON quote_clarifications(quote_request_id);
CREATE INDEX IF NOT EXISTS idx_quote_clarifications_producer_company_id 
  ON quote_clarifications(producer_company_id);

-- ============================================================================
-- 8. FONCTION DE MISE À JOUR AUTOMATIQUE DU TIMESTAMP
-- ============================================================================

CREATE OR REPLACE FUNCTION update_quote_clarifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_quote_clarifications_updated_at_trigger
  BEFORE UPDATE ON quote_clarifications
  FOR EACH ROW
  EXECUTE FUNCTION update_quote_clarifications_updated_at();
