/*
  # Simplifier les policies des demandes de devis

  ## Changements
  - Suppression de la vérification `is_producteur = true` dans les policies
  - Permet à tous les utilisateurs liés à une entreprise de voir les devis reçus
  - Simplifie l'accès aux demandes de devis pour une meilleure UX

  ## Sécurité
  - Les utilisateurs peuvent toujours uniquement voir les devis de leurs propres entreprises
  - Les demandeurs peuvent voir leurs propres devis
*/

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "View own or received quotes" ON quote_requests;
DROP POLICY IF EXISTS "Update quote status" ON quote_requests;

-- Recréer les policies simplifiées
CREATE POLICY "View own or received quotes" ON quote_requests 
FOR SELECT 
TO authenticated 
USING (
  auth.uid() = requester_id 
  OR EXISTS (
    SELECT 1 
    FROM company_users 
    WHERE company_users.company_id = quote_requests.target_company_id 
    AND company_users.user_id = auth.uid()
  )
);

CREATE POLICY "Update quote status" ON quote_requests 
FOR UPDATE 
TO authenticated 
USING (
  auth.uid() = requester_id 
  OR EXISTS (
    SELECT 1 
    FROM company_users 
    WHERE company_users.company_id = quote_requests.target_company_id 
    AND company_users.user_id = auth.uid()
  )
);
