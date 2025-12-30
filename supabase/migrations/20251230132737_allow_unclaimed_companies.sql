/*
  # Allow Unclaimed Companies

  ## Description
  Modification de la table companies pour permettre l'ajout d'entreprises sans compte utilisateur.
  Ces entreprises peuvent ensuite être "réclamées" par un utilisateur lors de son inscription.

  ## Modifications

  ### 1. Colonnes modifiées
  - `user_id` : devient nullable (permet les entreprises non réclamées)
  - Ajout de `siren` (distinct du SIRET, 9 chiffres vs 14)
  - Ajout de `claimed` : booléen pour savoir si l'entreprise a été réclamée
  - Ajout de `claimed_at` : date de réclamation
  
  ### 2. Champs obligatoires pour les entreprises non réclamées
  - `company_name` : Nom de l'entreprise
  - `siret_bce` : Numéro SIRET (14 chiffres)
  - `siren` : Numéro SIREN (9 chiffres)
  - `address` : Adresse complète
  - `postal_code` : Code postal
  - `city` : Ville
  - `category` : Secteur d'activité (nécessaire pour filtrer)

  ### 3. Champs optionnels pour les entreprises non réclamées
  - `email`, `phone`, `contact_first_name`, `contact_last_name`, `contact_email`
  - Ces champs deviennent obligatoires uniquement lors de la réclamation

  ## Sécurité
  - Les entreprises non réclamées sont visibles par tous en lecture seule
  - Seuls les admins peuvent créer des entreprises non réclamées
  - Les utilisateurs authentifiés peuvent réclamer une entreprise non réclamée
*/

-- Rendre user_id nullable
ALTER TABLE companies 
  ALTER COLUMN user_id DROP NOT NULL;

-- Ajouter le champ SIREN (9 chiffres, distinct du SIRET qui en fait 14)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'siren'
  ) THEN
    ALTER TABLE companies ADD COLUMN siren text;
  END IF;
END $$;

-- Ajouter les champs pour gérer les réclamations
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'claimed'
  ) THEN
    ALTER TABLE companies ADD COLUMN claimed boolean DEFAULT false;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'claimed_at'
  ) THEN
    ALTER TABLE companies ADD COLUMN claimed_at timestamptz;
  END IF;
END $$;

-- Rendre certains champs optionnels (nullable)
ALTER TABLE companies 
  ALTER COLUMN email DROP NOT NULL,
  ALTER COLUMN phone DROP NOT NULL,
  ALTER COLUMN contact_first_name DROP NOT NULL,
  ALTER COLUMN contact_last_name DROP NOT NULL,
  ALTER COLUMN contact_email DROP NOT NULL;

-- S'assurer que category est NOT NULL (nécessaire pour les filtres)
ALTER TABLE companies 
  ALTER COLUMN category SET NOT NULL;

-- Mettre à jour les entreprises existantes (claimed = true car elles ont un user_id)
UPDATE companies 
SET claimed = true, claimed_at = created_at 
WHERE user_id IS NOT NULL AND claimed IS NULL;

-- Créer un index pour les entreprises non réclamées
CREATE INDEX IF NOT EXISTS idx_companies_claimed ON companies(claimed) WHERE claimed = false;

-- Créer un index pour le SIREN
CREATE INDEX IF NOT EXISTS idx_companies_siren ON companies(siren);

-- Supprimer les anciennes policies pour companies et les recréer
DROP POLICY IF EXISTS "Companies are viewable by everyone when producer_active" ON companies;
DROP POLICY IF EXISTS "Users can view their own company" ON companies;
DROP POLICY IF EXISTS "Users can insert their own company" ON companies;
DROP POLICY IF EXISTS "Users can update their own company" ON companies;

-- Nouvelle policy : tout le monde peut voir les entreprises actives (réclamées ou non)
CREATE POLICY "Everyone can view active companies"
  ON companies FOR SELECT
  USING (producer_active = true OR claimed = false);

-- Policy : les utilisateurs peuvent voir leur propre entreprise
CREATE POLICY "Users can view their own company"
  ON companies FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy : les utilisateurs peuvent créer leur entreprise (avec user_id)
CREATE POLICY "Users can insert their own company"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy : les utilisateurs peuvent mettre à jour leur propre entreprise
CREATE POLICY "Users can update their own company"
  ON companies FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy : permettre la réclamation d'une entreprise non réclamée
CREATE POLICY "Users can claim unclaimed companies"
  ON companies FOR UPDATE
  TO authenticated
  USING (claimed = false AND user_id IS NULL)
  WITH CHECK (auth.uid() = user_id AND claimed = true);
