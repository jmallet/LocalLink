/*
  # Ajout du statut PENDING

  ## Description
  Ajoute le statut PENDING pour les demandes de devis en attente.

  ## Modifications
  - Ajout de PENDING à l'enum quote_status
*/

-- Ajout du statut PENDING
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'PENDING' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'quote_status')
  ) THEN
    ALTER TYPE quote_status ADD VALUE 'PENDING';
  END IF;
END $$;
