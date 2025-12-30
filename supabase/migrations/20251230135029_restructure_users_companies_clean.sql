/*
  # Restructuration de la relation Users-Companies

  ## Description
  Refonte complète de l'architecture pour séparer les utilisateurs et les entreprises
  avec une relation many-to-many via une table de jointure.

  ## Changements

  ### 1. Nouvelle table `users`
  - `id` (uuid, primary key, référence auth.users)
  - `email` (text, unique)
  - `first_name` (text)
  - `last_name` (text)
  - `phone` (text)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 2. Nouvelle table `user_companies` (table de jointure)
  - `id` (uuid, primary key)
  - `user_id` (uuid, foreign key vers users)
  - `company_id` (uuid, foreign key vers companies)
  - `role` (text: owner, admin, member)
  - `created_at` (timestamptz)
  - Constraint unique sur (user_id, company_id)

  ### 3. Modification de `companies`
  - Suppression de la contrainte NOT NULL sur user_id
  - Ajout de `claimed` (boolean) pour les entreprises non réclamées
  - Ajout de `siren` (text) séparé du SIRET
  - Rendre plusieurs champs optionnels pour les entreprises non réclamées

  ## Nettoyage des données
  - Les entreprises avec des user_id invalides sont marquées comme non réclamées
  - Seuls les vrais users de auth.users sont migrés

  ## Sécurité (RLS)
  - Nouvelles politiques basées sur la table de jointure
  - Un user peut gérer les entreprises où il a un rôle
  - Les admins ont tous les droits sur leurs entreprises
*/

-- 1. Créer la table users
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  first_name text,
  last_name text,
  phone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. Ajouter les nouvelles colonnes à companies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'companies' AND column_name = 'claimed'
  ) THEN
    ALTER TABLE companies ADD COLUMN claimed boolean DEFAULT true;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'companies' AND column_name = 'siren'
  ) THEN
    ALTER TABLE companies ADD COLUMN siren text;
  END IF;
END $$;

-- 3. Nettoyer les données : marquer comme non réclamées les entreprises avec user_id invalide
UPDATE companies
SET claimed = false, user_id = NULL
WHERE user_id IS NOT NULL 
AND NOT EXISTS (SELECT 1 FROM auth.users WHERE id = companies.user_id);

-- 4. Modifier les contraintes de companies pour permettre user_id NULL
ALTER TABLE companies ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE companies ALTER COLUMN email DROP NOT NULL;
ALTER TABLE companies ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE companies ALTER COLUMN contact_first_name DROP NOT NULL;
ALTER TABLE companies ALTER COLUMN contact_last_name DROP NOT NULL;
ALTER TABLE companies ALTER COLUMN contact_email DROP NOT NULL;

-- 5. Créer la table de jointure user_companies
CREATE TABLE IF NOT EXISTS user_companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  role text DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')) NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, company_id)
);

-- 6. Migrer les données existantes (uniquement les vrais users)
-- Créer les users à partir des companies existantes qui ont un user_id valide
INSERT INTO users (id, email, first_name, last_name, phone)
SELECT DISTINCT 
  c.user_id,
  c.email,
  c.contact_first_name,
  c.contact_last_name,
  c.phone
FROM companies c
WHERE c.user_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM auth.users WHERE id = c.user_id)
ON CONFLICT (id) DO NOTHING;

-- Créer les relations dans user_companies pour les companies existantes
INSERT INTO user_companies (user_id, company_id, role)
SELECT 
  c.user_id,
  c.id,
  'owner'
FROM companies c
WHERE c.user_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM auth.users WHERE id = c.user_id)
ON CONFLICT (user_id, company_id) DO NOTHING;

-- 7. Créer les index pour les performances
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_companies_user_id ON user_companies(user_id);
CREATE INDEX IF NOT EXISTS idx_user_companies_company_id ON user_companies(company_id);
CREATE INDEX IF NOT EXISTS idx_companies_claimed ON companies(claimed);

-- 8. Activer RLS sur les nouvelles tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_companies ENABLE ROW LEVEL SECURITY;

-- 9. Politiques RLS pour users
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 10. Politiques RLS pour user_companies
CREATE POLICY "Users can view their own company relationships"
  ON user_companies FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Owners can manage company relationships"
  ON user_companies FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = user_companies.company_id
      AND uc.user_id = auth.uid()
      AND uc.role = 'owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = user_companies.company_id
      AND uc.user_id = auth.uid()
      AND uc.role = 'owner'
    )
  );

-- 11. Supprimer les anciennes politiques RLS de companies et en créer de nouvelles
DROP POLICY IF EXISTS "Users can view their own company" ON companies;
DROP POLICY IF EXISTS "Users can insert their own company" ON companies;
DROP POLICY IF EXISTS "Users can update their own company" ON companies;

-- Nouvelle politique: les utilisateurs peuvent voir les entreprises dont ils sont membres
CREATE POLICY "Users can view their companies"
  ON companies FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = companies.id
      AND uc.user_id = auth.uid()
    )
  );

-- Nouvelle politique: les utilisateurs peuvent créer des entreprises
CREATE POLICY "Authenticated users can create companies"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Nouvelle politique: les owners et admins peuvent modifier leurs entreprises
CREATE POLICY "Users can update their companies"
  ON companies FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = companies.id
      AND uc.user_id = auth.uid()
      AND uc.role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = companies.id
      AND uc.user_id = auth.uid()
      AND uc.role IN ('owner', 'admin')
    )
  );

-- Nouvelle politique: les owners peuvent supprimer leurs entreprises
CREATE POLICY "Owners can delete their companies"
  ON companies FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = companies.id
      AND uc.user_id = auth.uid()
      AND uc.role = 'owner'
    )
  );

-- 12. Mettre à jour les politiques RLS pour products_services
DROP POLICY IF EXISTS "Companies can manage their own products" ON products_services;

CREATE POLICY "Company members can manage products"
  ON products_services FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = products_services.company_id
      AND uc.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = products_services.company_id
      AND uc.user_id = auth.uid()
    )
  );

-- 13. Mettre à jour les politiques RLS pour quote_requests
DROP POLICY IF EXISTS "Users can view their own quote requests" ON quote_requests;
DROP POLICY IF EXISTS "Users can create quote requests" ON quote_requests;
DROP POLICY IF EXISTS "Users can update their own quote requests" ON quote_requests;

CREATE POLICY "Company members can view quote requests"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = quote_requests.buyer_company_id
      AND uc.user_id = auth.uid()
    )
  );

CREATE POLICY "Company members can create quote requests"
  ON quote_requests FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = quote_requests.buyer_company_id
      AND uc.user_id = auth.uid()
    )
  );

CREATE POLICY "Company members can update quote requests"
  ON quote_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = quote_requests.buyer_company_id
      AND uc.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = quote_requests.buyer_company_id
      AND uc.user_id = auth.uid()
    )
  );

-- 14. Mettre à jour les politiques RLS pour quote_recipients
DROP POLICY IF EXISTS "Producers can view their received quotes" ON quote_recipients;
DROP POLICY IF EXISTS "Producers can update their quote recipients" ON quote_recipients;

CREATE POLICY "Company members can view received quotes"
  ON quote_recipients FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = quote_recipients.producer_company_id
      AND uc.user_id = auth.uid()
    )
  );

CREATE POLICY "Company members can update quote recipients"
  ON quote_recipients FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = quote_recipients.producer_company_id
      AND uc.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = quote_recipients.producer_company_id
      AND uc.user_id = auth.uid()
    )
  );

-- 15. Mettre à jour les politiques RLS pour visibility_boosts
DROP POLICY IF EXISTS "Companies can view their own visibility boosts" ON visibility_boosts;

CREATE POLICY "Company members can view visibility boosts"
  ON visibility_boosts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = visibility_boosts.company_id
      AND uc.user_id = auth.uid()
    )
  );

-- 16. Mettre à jour les politiques RLS pour payments
DROP POLICY IF EXISTS "Users can view their own payments" ON payments;

CREATE POLICY "Company members can view payments"
  ON payments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_companies uc
      WHERE uc.company_id = payments.company_id
      AND uc.user_id = auth.uid()
    )
  );
