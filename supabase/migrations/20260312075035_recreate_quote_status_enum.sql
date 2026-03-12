/*
  # Re-création de l'enum quote_status simplifié

  ## Description
  Nettoie l'enum quote_status pour ne garder que les statuts utilisés.

  ## Statuts finaux
  - **PENDING** : En attente (bleu "En attente")
  - **WAITING_FOR_INFO** : Questions en attente (orange "À compléter")
  - **RESPONDED** : Propositions reçues (vert "Propositions reçues")
  - **ACCEPTED** : Accepté (vert foncé "Accepté")
  - **CLOSED** : Clôturé (gris "Clôturé")

  ## Modifications
  - Suppression de SENT et VIEWED
  - Définition de PENDING comme valeur par défaut
*/

-- Retirer temporairement la valeur par défaut
ALTER TABLE quote_requests 
  ALTER COLUMN status DROP DEFAULT;

-- Créer le nouveau type avec uniquement les statuts nécessaires
CREATE TYPE quote_status_simplified AS ENUM (
  'PENDING',
  'WAITING_FOR_INFO', 
  'RESPONDED',
  'ACCEPTED',
  'CLOSED'
);

-- Modifier la colonne pour utiliser le nouveau type
ALTER TABLE quote_requests 
  ALTER COLUMN status TYPE quote_status_simplified 
  USING status::text::quote_status_simplified;

-- Supprimer l'ancien type et renommer le nouveau
DROP TYPE quote_status;
ALTER TYPE quote_status_simplified RENAME TO quote_status;

-- Redéfinir PENDING comme valeur par défaut
ALTER TABLE quote_requests 
  ALTER COLUMN status SET DEFAULT 'PENDING'::quote_status;
