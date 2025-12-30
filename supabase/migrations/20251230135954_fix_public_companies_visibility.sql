/*
  # Correction de la visibilité publique des entreprises

  ## Description
  Restaure la politique RLS permettant à tout le monde (authentifié ou non)
  de voir les entreprises avec producer_active = true.

  ## Changements
  - Ajout de la politique "Public can view active producers"
    permettant la visualisation publique des entreprises actives
*/

-- Recréer la politique pour la visibilité publique des entreprises actives
CREATE POLICY "Public can view active producers"
  ON companies FOR SELECT
  USING (producer_active = true AND verified = true);
