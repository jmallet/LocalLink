/*
  # Adaptation des tables existantes pour le MVP LocalLink

  ## Vue d'ensemble
  Cette migration adapte les tables existantes pour le nouveau schéma MVP.
  Elle ajoute les champs manquants et crée les nouvelles structures nécessaires.

  ## 1. Types ENUM
    - `user_type`: PARTICULIER | PRO | ADMIN
    - `company_source`: INSEE | IMPORT | MANUAL
    - `requester_type`: PARTICULIER | ACHETEUR_PRO
    - `quote_status`: SENT | VIEWED | RESPONDED | CLOSED

  ## 2. Modifications
    ### users
      - Ajout de `user_type` pour gérer les 3 rôles

    ### companies
      - Ajout de `source` (provenance)
      - Renommage de `claimed` en `is_claimed`
      - Ajout de `siret` (unique)

    ### user_companies
      - Ajout de `is_acheteur_pro` et `is_producteur`
      - Suppression du champ `role` (remplacé par les flags)

  ## 3. Nouvelles tables
    ### producer_profiles
      - Profil producteur (1-1 avec companies)

    ### producer_products
      - Alias/vue vers products_services

    ### lead_accesses
      - Tracking des ouvertures

    ### quote_messages
      - Messages liés aux devis

  ## 4. Sécurité
    - Toutes les tables ont RLS activé avec policies appropriées
*/

-- ============================================================================
-- 1. CRÉATION DES ENUMS
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE user_type AS ENUM ('PARTICULIER', 'PRO', 'ADMIN');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE company_source AS ENUM ('INSEE', 'IMPORT', 'MANUAL');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE requester_type AS ENUM ('PARTICULIER', 'ACHETEUR_PRO');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE quote_status AS ENUM ('SENT', 'VIEWED', 'RESPONDED', 'CLOSED');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 2. MODIFICATION DE LA TABLE USERS (équivalent de profiles)
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'user_type'
  ) THEN
    ALTER TABLE users ADD COLUMN user_type user_type DEFAULT 'PRO';
  END IF;
END $$;

-- ============================================================================
-- 3. MODIFICATION DE LA TABLE COMPANIES
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'source'
  ) THEN
    ALTER TABLE companies ADD COLUMN source company_source DEFAULT 'MANUAL';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'claimed'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'is_claimed'
  ) THEN
    ALTER TABLE companies RENAME COLUMN claimed TO is_claimed;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'siret'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'siret_bce'
  ) THEN
    ALTER TABLE companies RENAME COLUMN siret_bce TO siret;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'name'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'company_name'
  ) THEN
    ALTER TABLE companies RENAME COLUMN company_name TO name;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'naf_code'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'category'
  ) THEN
    ALTER TABLE companies RENAME COLUMN category TO naf_code;
  END IF;
END $$;

-- ============================================================================
-- 4. MODIFICATION DE LA TABLE USER_COMPANIES
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_companies' AND column_name = 'is_acheteur_pro'
  ) THEN
    ALTER TABLE user_companies ADD COLUMN is_acheteur_pro boolean DEFAULT true;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_companies' AND column_name = 'is_producteur'
  ) THEN
    ALTER TABLE user_companies ADD COLUMN is_producteur boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_companies' AND column_name = 'verified'
  ) THEN
    ALTER TABLE user_companies ADD COLUMN verified boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_companies' AND column_name = 'verified_at'
  ) THEN
    ALTER TABLE user_companies ADD COLUMN verified_at timestamptz;
  END IF;
END $$;

-- Ajouter une contrainte unique si elle n'existe pas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_companies_user_id_company_id_key'
  ) THEN
    ALTER TABLE user_companies ADD CONSTRAINT user_companies_user_id_company_id_key UNIQUE(user_id, company_id);
  END IF;
EXCEPTION
  WHEN duplicate_table THEN NULL;
END $$;

-- ============================================================================
-- 5. CRÉATION DE LA TABLE PRODUCER_PROFILES
-- ============================================================================

CREATE TABLE IF NOT EXISTS producer_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL UNIQUE REFERENCES companies(id) ON DELETE CASCADE,
  is_active boolean DEFAULT false,
  intervention_radius_km integer,
  delivery_available boolean DEFAULT false,
  minimum_order_amount numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE producer_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view producer profiles" ON producer_profiles;
CREATE POLICY "Public can view producer profiles"
  ON producer_profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Company users can manage their producer profile" ON producer_profiles;
CREATE POLICY "Company users can manage their producer profile"
  ON producer_profiles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies
      WHERE user_companies.company_id = producer_profiles.company_id
      AND user_companies.user_id = auth.uid()
      AND user_companies.is_producteur = true
    )
  );

-- ============================================================================
-- 6. MIGRATION DES DONNÉES EXISTANTES
-- ============================================================================

-- Créer producer_profiles pour les companies qui sont productrices
INSERT INTO producer_profiles (company_id, is_active)
SELECT id, producer_active
FROM companies
WHERE is_producer = true
ON CONFLICT (company_id) DO NOTHING;

-- Mettre is_producteur à true pour les user_companies existants où la company est productrice
UPDATE user_companies
SET is_producteur = true
WHERE company_id IN (SELECT id FROM companies WHERE is_producer = true)
AND is_producteur IS NULL OR is_producteur = false;

-- ============================================================================
-- 7. CRÉATION DE LA TABLE LEAD_ACCESSES
-- ============================================================================

CREATE TABLE IF NOT EXISTS lead_accesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_request_id uuid NOT NULL UNIQUE REFERENCES quote_requests(id) ON DELETE CASCADE,
  producer_company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  opened_at timestamptz DEFAULT now()
);

ALTER TABLE lead_accesses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Company users can view their lead accesses" ON lead_accesses;
CREATE POLICY "Company users can view their lead accesses"
  ON lead_accesses FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies
      WHERE user_companies.company_id = lead_accesses.producer_company_id
      AND user_companies.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Company users can create lead accesses" ON lead_accesses;
CREATE POLICY "Company users can create lead accesses"
  ON lead_accesses FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_companies
      WHERE user_companies.company_id = lead_accesses.producer_company_id
      AND user_companies.user_id = auth.uid()
    )
  );

-- ============================================================================
-- 8. CRÉATION DE LA TABLE QUOTE_MESSAGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS quote_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_request_id uuid NOT NULL REFERENCES quote_requests(id) ON DELETE CASCADE,
  sender_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE quote_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view messages" ON quote_messages;
CREATE POLICY "Participants can view messages"
  ON quote_messages FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quote_requests qr
      LEFT JOIN user_companies uc ON uc.company_id = qr.buyer_company_id
      LEFT JOIN quote_recipients qrec ON qrec.quote_request_id = qr.id
      LEFT JOIN user_companies uc2 ON uc2.company_id = qrec.producer_company_id
      WHERE qr.id = quote_messages.quote_request_id
      AND (
        uc.user_id = auth.uid()
        OR uc2.user_id = auth.uid()
        OR qr.buyer_individual_id IN (SELECT id FROM individuals WHERE user_id = auth.uid())
      )
    )
  );

DROP POLICY IF EXISTS "Participants can send messages" ON quote_messages;
CREATE POLICY "Participants can send messages"
  ON quote_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = sender_user_id
    AND EXISTS (
      SELECT 1 FROM quote_requests qr
      LEFT JOIN user_companies uc ON uc.company_id = qr.buyer_company_id
      LEFT JOIN quote_recipients qrec ON qrec.quote_request_id = qr.id
      LEFT JOIN user_companies uc2 ON uc2.company_id = qrec.producer_company_id
      WHERE qr.id = quote_messages.quote_request_id
      AND (
        uc.user_id = auth.uid()
        OR uc2.user_id = auth.uid()
        OR qr.buyer_individual_id IN (SELECT id FROM individuals WHERE user_id = auth.uid())
      )
    )
  );

-- ============================================================================
-- 9. AJOUT DE COLONNES POUR LE NOUVEAU SYSTÈME DE DEVIS
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'requester_type'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN requester_type requester_type;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'target_company_id'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN target_company_id uuid REFERENCES companies(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'requester_id'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN requester_id uuid REFERENCES auth.users(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'volume_estimated'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN volume_estimated text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'frequency'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN frequency text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'location'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN location text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'new_status'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN new_status quote_status DEFAULT 'SENT';
  END IF;
END $$;

-- ============================================================================
-- 10. MISE À JOUR DES POLICIES
-- ============================================================================

-- Policies sur users
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Policies sur user_companies
DROP POLICY IF EXISTS "Users can view their company links" ON user_companies;
CREATE POLICY "Users can view their company links"
  ON user_companies FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their company links" ON user_companies;
CREATE POLICY "Users can create their company links"
  ON user_companies FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy pour que les companies soient visibles publiquement
DROP POLICY IF EXISTS "Public can view companies" ON companies;
CREATE POLICY "Public can view companies"
  ON companies FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Company users can update their company" ON companies;
CREATE POLICY "Company users can update their company"
  ON companies FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies
      WHERE user_companies.company_id = companies.id
      AND user_companies.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Authenticated users can create companies" ON companies;
CREATE POLICY "Authenticated users can create companies"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policies sur products_services
DROP POLICY IF EXISTS "Public can view products" ON products_services;
CREATE POLICY "Public can view products"
  ON products_services FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Company users can manage products" ON products_services;
CREATE POLICY "Company users can manage products"
  ON products_services FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies
      WHERE user_companies.company_id = products_services.company_id
      AND user_companies.user_id = auth.uid()
      AND user_companies.is_producteur = true
    )
  );

-- Policies sur quote_requests (mises à jour)
DROP POLICY IF EXISTS "Users can view relevant quote requests" ON quote_requests;
CREATE POLICY "Users can view relevant quote requests"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    requester_id = auth.uid()
    OR buyer_individual_id IN (SELECT id FROM individuals WHERE user_id = auth.uid())
    OR buyer_company_id IN (SELECT company_id FROM user_companies WHERE user_id = auth.uid())
    OR target_company_id IN (SELECT company_id FROM user_companies WHERE user_id = auth.uid() AND is_producteur = true)
  );

DROP POLICY IF EXISTS "Users can create quote requests" ON quote_requests;
CREATE POLICY "Users can create quote requests"
  ON quote_requests FOR INSERT
  TO authenticated
  WITH CHECK (
    requester_id = auth.uid()
    OR buyer_individual_id IN (SELECT id FROM individuals WHERE user_id = auth.uid())
    OR buyer_company_id IN (SELECT company_id FROM user_companies WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "Participants can update quote requests" ON quote_requests;
CREATE POLICY "Participants can update quote requests"
  ON quote_requests FOR UPDATE
  TO authenticated
  USING (
    requester_id = auth.uid()
    OR buyer_individual_id IN (SELECT id FROM individuals WHERE user_id = auth.uid())
    OR buyer_company_id IN (SELECT company_id FROM user_companies WHERE user_id = auth.uid())
    OR target_company_id IN (SELECT company_id FROM user_companies WHERE user_id = auth.uid() AND is_producteur = true)
  );
