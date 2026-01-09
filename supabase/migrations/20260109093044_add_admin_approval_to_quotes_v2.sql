/*
  # Ajout du système de validation admin pour les demandes de devis

  ## Changements
  - Ajout du champ `admin_approved` (boolean, défaut false)
  - Ajout du champ `admin_approved_at` (timestamp)
  - Ajout du champ `admin_approved_by` (uuid référençant auth.users)
  - Ajout du champ `admin_rejection_reason` (texte optionnel)

  ## Sécurité
  - Les pros ne voient que les devis approuvés par l'admin
  - L'admin voit tous les devis
  - Les demandeurs voient toujours leurs propres devis

  ## Rétrocompatibilité
  - Les devis existants sont automatiquement approuvés
*/

-- Ajouter les colonnes de validation admin
ALTER TABLE quote_requests 
ADD COLUMN IF NOT EXISTS admin_approved boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS admin_approved_at timestamptz,
ADD COLUMN IF NOT EXISTS admin_approved_by uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS admin_rejection_reason text;

-- Mettre à jour les devis existants pour qu'ils soient approuvés (rétrocompatibilité)
UPDATE quote_requests 
SET admin_approved = true
WHERE admin_approved = false;
