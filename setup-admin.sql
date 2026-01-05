-- Script pour mettre à jour un utilisateur en ADMIN
-- Remplacez l'email ci-dessous par l'email de l'utilisateur à promouvoir admin

UPDATE profiles
SET user_type = 'ADMIN'
WHERE user_id IN (
  SELECT id FROM auth.users WHERE email = 'admin@localproconnect.fr'
);

-- Vérification
SELECT
  u.email,
  p.user_type
FROM auth.users u
JOIN profiles p ON p.user_id = u.id
WHERE u.email = 'admin@localproconnect.fr';
