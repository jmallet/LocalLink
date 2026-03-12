/*
  # Migration vers le statut PENDING

  ## Description
  Migre les anciens statuts SENT et VIEWED vers PENDING.

  ## Modifications
  - SENT → PENDING
  - VIEWED → PENDING
*/

-- Migration des données
UPDATE quote_requests 
SET status = 'PENDING' 
WHERE status IN ('SENT', 'VIEWED');
