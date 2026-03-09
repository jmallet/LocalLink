/*
  # Ajout du statut ACCEPTED pour les devis validés

  ## Description
  Ajoute un nouveau statut "ACCEPTED" pour distinguer les devis qui ont été acceptés
  par le particulier de ceux qui ont simplement reçu une réponse.

  ## Modifications
  - Ajoute la valeur 'ACCEPTED' à l'enum quote_status
  
  ## Workflow
  - SENT: Devis envoyé, pas encore vu
  - VIEWED: Devis vu par le professionnel
  - RESPONDED: Le professionnel a répondu (proposition envoyée)
  - ACCEPTED: Le particulier a accepté la proposition
  - WAITING_FOR_INFO: En attente de précisions
  - CLOSED: Devis fermé/annulé
*/

-- Ajouter le statut ACCEPTED
ALTER TYPE quote_status ADD VALUE IF NOT EXISTS 'ACCEPTED';
