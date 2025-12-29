/*
  # Support des demandes de devis pour les particuliers

  ## Description
  Cette migration permet aux particuliers de créer des demandes de devis, en plus des entreprises.
  Les demandes peuvent provenir soit d'une entreprise (buyer_company_id) soit d'un particulier (individual_id).

  ## Modifications

  1. Modifications sur quote_requests
    - Ajout de la colonne `individual_id` (nullable)
    - Modification de la contrainte `buyer_company_id` pour la rendre nullable
    - Ajout d'une contrainte CHECK pour s'assurer qu'au moins l'un des deux (buyer_company_id ou individual_id) est renseigné
    - Ajout d'un index sur `individual_id`

  2. Sécurité (RLS)
    - Nouvelle politique pour que les particuliers puissent voir leurs propres demandes
    - Nouvelle politique pour que les particuliers puissent créer des demandes
    - Nouvelle politique pour que les particuliers puissent modifier leurs demandes

  ## Notes importantes
    - Les demandes existantes restent inchangées (buyer_company_id)
    - Les producteurs verront les demandes des particuliers et des entreprises
*/

-- Modifier la table quote_requests pour supporter les particuliers
DO $$
BEGIN
  -- Rendre buyer_company_id nullable
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'buyer_company_id'
  ) THEN
    ALTER TABLE quote_requests ALTER COLUMN buyer_company_id DROP NOT NULL;
  END IF;

  -- Ajouter la colonne individual_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quote_requests' AND column_name = 'individual_id'
  ) THEN
    ALTER TABLE quote_requests ADD COLUMN individual_id uuid REFERENCES individuals(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Ajouter une contrainte pour s'assurer qu'au moins l'un des deux est renseigné
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'quote_requests_requester_check'
  ) THEN
    ALTER TABLE quote_requests ADD CONSTRAINT quote_requests_requester_check
      CHECK (
        (buyer_company_id IS NOT NULL AND individual_id IS NULL) OR
        (buyer_company_id IS NULL AND individual_id IS NOT NULL)
      );
  END IF;
END $$;

-- Créer un index sur individual_id
CREATE INDEX IF NOT EXISTS idx_quote_requests_individual ON quote_requests(individual_id);

-- Nouvelles politiques RLS pour les particuliers

-- Politique pour que les particuliers puissent voir leurs propres demandes
DROP POLICY IF EXISTS "Individuals can view their own quote requests" ON quote_requests;
CREATE POLICY "Individuals can view their own quote requests"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM individuals
      WHERE individuals.id = quote_requests.individual_id
      AND individuals.user_id = auth.uid()
    )
  );

-- Politique pour que les particuliers puissent créer des demandes
DROP POLICY IF EXISTS "Individuals can create quote requests" ON quote_requests;
CREATE POLICY "Individuals can create quote requests"
  ON quote_requests FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM individuals
      WHERE individuals.id = quote_requests.individual_id
      AND individuals.user_id = auth.uid()
    )
  );

-- Politique pour que les particuliers puissent modifier leurs demandes
DROP POLICY IF EXISTS "Individuals can update their own quote requests" ON quote_requests;
CREATE POLICY "Individuals can update their own quote requests"
  ON quote_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM individuals
      WHERE individuals.id = quote_requests.individual_id
      AND individuals.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM individuals
      WHERE individuals.id = quote_requests.individual_id
      AND individuals.user_id = auth.uid()
    )
  );

-- Politique pour que les producteurs puissent voir les demandes qui leur sont destinées (mise à jour)
DROP POLICY IF EXISTS "Producers can view quote requests sent to them" ON quote_requests;
CREATE POLICY "Producers can view quote requests sent to them"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quote_recipients
      JOIN companies ON companies.id = quote_recipients.producer_company_id
      WHERE quote_recipients.quote_request_id = quote_requests.id
      AND companies.user_id = auth.uid()
    )
  );