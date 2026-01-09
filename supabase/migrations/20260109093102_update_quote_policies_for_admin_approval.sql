/*
  # Mise à jour des policies pour le système de validation admin

  ## Changements
  - Les entreprises ne voient que les devis approuvés par l'admin
  - Les demandeurs voient toujours leurs propres devis
  - Les admins voient tous les devis

  ## Sécurité
  - Validation stricte : seuls les admins peuvent approuver/rejeter
  - Les pros ne peuvent pas contourner l'approbation admin
*/

-- Supprimer l'ancienne policy
DROP POLICY IF EXISTS "View own or received quotes" ON quote_requests;

-- Recréer avec la vérification d'approbation admin
CREATE POLICY "View own or received quotes" ON quote_requests 
FOR SELECT 
TO authenticated 
USING (
  -- Le demandeur voit toujours ses propres devis
  auth.uid() = requester_id 
  -- Les admins voient tous les devis
  OR EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.user_id = auth.uid() 
    AND profiles.user_type = 'ADMIN'
  )
  -- Les entreprises voient uniquement les devis approuvés
  OR (
    admin_approved = true 
    AND EXISTS (
      SELECT 1 
      FROM company_users 
      WHERE company_users.company_id = quote_requests.target_company_id 
      AND company_users.user_id = auth.uid()
    )
  )
);

-- Policy pour permettre aux admins d'approuver/rejeter
CREATE POLICY "Admins can approve/reject quotes" ON quote_requests
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.user_type = 'ADMIN'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.user_type = 'ADMIN'
  )
);
