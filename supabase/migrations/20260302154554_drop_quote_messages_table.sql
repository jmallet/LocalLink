/*
  # Suppression de la table quote_messages

  ## Description
  Cette migration supprime la fonctionnalité de messagerie directe qui n'est plus utilisée.
  Le système utilise désormais uniquement :
  - quote_proposals : pour les propositions de devis
  - quote_clarifications : pour les demandes de précisions

  ## Modifications
  - Suppression de la table `quote_messages`
  - Suppression des policies RLS associées
*/

-- Supprimer la table quote_messages si elle existe
DROP TABLE IF EXISTS quote_messages CASCADE;
