/*
  # Allow Admins to Create Unclaimed Companies

  ## Description
  Ajout d'une policy pour permettre aux administrateurs de créer des entreprises
  non réclamées (sans user_id).

  ## Modifications
  - Nouvelle policy permettant aux admins d'insérer des entreprises sans user_id
  - Ces entreprises peuvent ensuite être réclamées par les utilisateurs
*/

-- Policy : les admins peuvent créer des entreprises non réclamées (sans user_id)
CREATE POLICY "Admins can create unclaimed companies"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin() AND user_id IS NULL AND claimed = false
  );
