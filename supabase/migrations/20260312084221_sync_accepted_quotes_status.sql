/*
  # Synchroniser le statut des demandes de devis avec les propositions acceptées
  
  1. Modifications
    - Met à jour le statut de quote_requests à 'ACCEPTED' pour toutes les demandes 
      ayant au moins une proposition avec le statut 'ACCEPTED'
    - Corrige les données existantes où une proposition a été acceptée mais 
      le statut de la demande n'a pas été mis à jour
  
  2. Logique
    - Recherche toutes les propositions avec status = 'ACCEPTED'
    - Met à jour le quote_request correspondant à status = 'ACCEPTED'
*/

UPDATE quote_requests
SET status = 'ACCEPTED'
WHERE id IN (
  SELECT DISTINCT quote_request_id
  FROM quote_proposals
  WHERE status = 'ACCEPTED'
)
AND status != 'ACCEPTED';