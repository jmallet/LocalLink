/*
  # Données de test pour LocalLink (version 2)

  ## Description
  Ajout de données de test sans dépendances auth.users pour faciliter le développement.
  
  ## Note
  Pour les tests, nous désactivons temporairement la contrainte de clé étrangère
  et créons des entreprises avec des user_id fictifs.
*/

-- Temporairement désactiver la contrainte
ALTER TABLE companies DROP CONSTRAINT IF EXISTS companies_user_id_fkey;

-- Articles de blog
INSERT INTO blog_posts (title, slug, excerpt, content, author, cover_image, published, published_at) VALUES
(
  'Le circuit court : un avantage économique pour votre entreprise',
  'circuit-court-avantage-economique',
  'Découvrez comment le circuit court peut réduire vos coûts et améliorer votre rentabilité tout en soutenant l''économie locale.',
  E'# Le circuit court : un avantage économique pour votre entreprise\n\nLe circuit court représente bien plus qu''une simple tendance : c''est un modèle économique viable et rentable pour les entreprises.\n\n## Réduction des coûts de transport\n\nEn s''approvisionnant localement, les entreprises réduisent significativement leurs coûts de transport et leur empreinte carbone.\n\n## Qualité et fraîcheur garanties\n\nLes produits locaux arrivent plus rapidement, garantissant une meilleure qualité et une fraîcheur optimale.\n\n## Relations durables\n\nTravailler avec des fournisseurs locaux permet de créer des relations commerciales solides et durables.\n\n## Conclusion\n\nLe circuit court est un investissement intelligent pour l''avenir de votre entreprise.',
  'Marie Dubois',
  'https://images.pexels.com/photos/6169668/pexels-photo-6169668.jpeg',
  true,
  now()
),
(
  'Pourquoi privilégier les producteurs locaux pour votre activité B2B',
  'producteurs-locaux-b2b',
  'Les avantages de travailler avec des producteurs locaux dépassent largement les considérations environnementales.',
  E'# Pourquoi privilégier les producteurs locaux pour votre activité B2B\n\nLe partenariat avec des producteurs locaux transforme votre chaîne d''approvisionnement.\n\n## Réactivité et flexibilité\n\nLes producteurs locaux peuvent s''adapter rapidement à vos besoins spécifiques.\n\n## Traçabilité optimale\n\nVous connaissez l''origine exacte de vos produits et pouvez la communiquer à vos clients.\n\n## Soutien à l''économie locale\n\nChaque euro dépensé localement génère un impact positif sur votre région.\n\n## Image de marque\n\nVos clients apprécient les entreprises qui s''engagent pour le local.',
  'Pierre Martin',
  'https://images.pexels.com/photos/5632402/pexels-photo-5632402.jpeg',
  true,
  now() - interval '7 days'
),
(
  'Comment LocalLink facilite vos approvisionnements en circuit court',
  'locallink-facilite-approvisionnements',
  'Notre plateforme simplifie la mise en relation entre entreprises locales pour des échanges B2B efficaces.',
  E'# Comment LocalLink facilite vos approvisionnements en circuit court\n\nLocalLink révolutionne la façon dont les entreprises se connectent et collaborent.\n\n## Une plateforme centralisée\n\nPlus besoin de chercher pendant des heures : tous les producteurs locaux sont référencés.\n\n## Système de devis simplifié\n\nDemandez des devis à plusieurs producteurs en quelques clics.\n\n## Sécurité et confiance\n\nToutes les entreprises sont vérifiées et certifiées.\n\n## Gagnez du temps\n\nConcentrez-vous sur votre cœur de métier, nous nous occupons de vous mettre en relation.',
  'Sophie Laurent',
  'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg',
  true,
  now() - interval '14 days'
)
ON CONFLICT (slug) DO NOTHING;

-- Entreprises de test
INSERT INTO companies (
  id, user_id, email, company_name, siret_bce, address, postal_code, city, country, phone,
  contact_first_name, contact_last_name, contact_email, is_buyer, is_producer, producer_active,
  description, category, tags, logo_url, verified
) VALUES
(
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  'contact@fermebio.fr',
  'Ferme Bio du Terroir',
  '12345678901234',
  '15 Chemin des Champs',
  '69001',
  'Lyon',
  'FR',
  '+33 4 78 12 34 56',
  'Jean',
  'Dupont',
  'j.dupont@fermebio.fr',
  false,
  true,
  true,
  'Producteur bio depuis 3 générations. Nous proposons des légumes, fruits et œufs bio de qualité supérieure. Notre exploitation de 25 hectares privilégie les méthodes traditionnelles et respectueuses de l''environnement.',
  'Agriculture & Alimentation',
  ARRAY['bio', 'légumes', 'fruits', 'oeufs', 'local'],
  'https://images.pexels.com/photos/2252618/pexels-photo-2252618.jpeg',
  true
),
(
  '22222222-2222-2222-2222-222222222222',
  '22222222-2222-2222-2222-222222222222',
  'contact@boulangeriemartin.fr',
  'Boulangerie Artisanale Martin',
  '23456789012345',
  '8 Rue de la Paix',
  '69002',
  'Lyon',
  'FR',
  '+33 4 78 23 45 67',
  'Marie',
  'Martin',
  'm.martin@boulangeriemartin.fr',
  false,
  true,
  true,
  'Boulangerie artisanale familiale. Pain au levain naturel, viennoiseries et pâtisseries faits maison. Nous travaillons avec des farines locales et bio. Possibilité de livraison pour professionnels.',
  'Agriculture & Alimentation',
  ARRAY['pain', 'boulangerie', 'artisan', 'bio', 'levain'],
  'https://images.pexels.com/photos/1775043/pexels-photo-1775043.jpeg',
  true
),
(
  '33333333-3333-3333-3333-333333333333',
  '33333333-3333-3333-3333-333333333333',
  'contact@fromagerie-alpes.fr',
  'Fromagerie des Alpes',
  '34567890123456',
  '22 Route de Montagne',
  '74000',
  'Annecy',
  'FR',
  '+33 4 50 12 34 56',
  'Pierre',
  'Blanc',
  'p.blanc@fromagerie-alpes.fr',
  false,
  true,
  true,
  'Fromagerie artisanale spécialisée dans les fromages de montagne. Production traditionnelle avec le lait de nos propres vaches. Tomme, Reblochon, Beaufort et créations originales.',
  'Agriculture & Alimentation',
  ARRAY['fromage', 'lait', 'montagne', 'artisan', 'tradition'],
  'https://images.pexels.com/photos/821365/pexels-photo-821365.jpeg',
  true
),
(
  '44444444-4444-4444-4444-444444444444',
  '44444444-4444-4444-4444-444444444444',
  'contact@menuiserie-moderne.fr',
  'Menuiserie Moderne',
  '45678901234567',
  '5 Zone Artisanale',
  '69003',
  'Lyon',
  'FR',
  '+33 4 78 34 56 78',
  'Luc',
  'Petit',
  'l.petit@menuiserie-moderne.fr',
  false,
  true,
  true,
  'Menuiserie sur mesure pour professionnels. Agencement de commerces, mobilier sur mesure, menuiserie intérieure et extérieure. 20 ans d''expérience. Bois locaux et certifiés.',
  'Construction & Rénovation',
  ARRAY['menuiserie', 'bois', 'sur-mesure', 'agencement', 'professionnel'],
  'https://images.pexels.com/photos/5974401/pexels-photo-5974401.jpeg',
  true
),
(
  '55555555-5555-5555-5555-555555555555',
  '55555555-5555-5555-5555-555555555555',
  'contact@imprimerie-rapide.fr',
  'Imprimerie Rapide',
  '56789012345678',
  '12 Boulevard du Commerce',
  '69004',
  'Lyon',
  'FR',
  '+33 4 78 45 67 89',
  'Sophie',
  'Rousseau',
  's.rousseau@imprimerie-rapide.fr',
  false,
  true,
  true,
  'Impression professionnelle tous supports. Cartes de visite, flyers, affiches, bâches, signalétique. Délais rapides, qualité premium. Service de création graphique disponible.',
  'Services aux entreprises',
  ARRAY['impression', 'graphisme', 'communication', 'rapide', 'qualité'],
  'https://images.pexels.com/photos/1509428/pexels-photo-1509428.jpeg',
  true
),
(
  '66666666-6666-6666-6666-666666666666',
  '66666666-6666-6666-6666-666666666666',
  'contact@nettoyage-pro.fr',
  'Nettoyage Pro Services',
  '67890123456789',
  '30 Avenue des Entreprises',
  '69005',
  'Lyon',
  'FR',
  '+33 4 78 56 78 90',
  'Thomas',
  'Bernard',
  't.bernard@nettoyage-pro.fr',
  false,
  true,
  true,
  'Services de nettoyage professionnel pour entreprises. Bureaux, commerces, entrepôts. Équipe qualifiée, produits écologiques. Interventions quotidiennes ou ponctuelles.',
  'Services aux entreprises',
  ARRAY['nettoyage', 'entretien', 'écologique', 'professionnel', 'bureaux'],
  'https://images.pexels.com/photos/4239091/pexels-photo-4239091.jpeg',
  true
),
(
  '77777777-7777-7777-7777-777777777777',
  '77777777-7777-7777-7777-777777777777',
  'contact@transport-express.fr',
  'Transport Express Local',
  '78901234567890',
  '45 Rue de la Logistique',
  '69006',
  'Lyon',
  'FR',
  '+33 4 78 67 89 01',
  'Julie',
  'Moreau',
  'j.moreau@transport-express.fr',
  false,
  true,
  true,
  'Transport et livraison express dans la région Auvergne-Rhône-Alpes. Livraison le jour même possible. Spécialiste des produits frais et fragiles. Flotte de véhicules adaptés.',
  'Transport & Logistique',
  ARRAY['transport', 'livraison', 'express', 'local', 'frais'],
  'https://images.pexels.com/photos/4391470/pexels-photo-4391470.jpeg',
  true
),
(
  '88888888-8888-8888-8888-888888888888',
  '88888888-8888-8888-8888-888888888888',
  'contact@conseil-marketing.fr',
  'Conseil Marketing Digital',
  '89012345678901',
  '18 Place de l''Innovation',
  '69007',
  'Lyon',
  'FR',
  '+33 4 78 78 90 12',
  'Alexandre',
  'Durand',
  'a.durand@conseil-marketing.fr',
  false,
  true,
  true,
  'Agence de conseil en marketing digital. Stratégie digitale, réseaux sociaux, SEO, publicité en ligne. Accompagnement des PME locales dans leur transformation digitale.',
  'Services aux entreprises',
  ARRAY['marketing', 'digital', 'conseil', 'seo', 'réseaux-sociaux'],
  'https://images.pexels.com/photos/3183150/pexels-photo-3183150.jpeg',
  true
)
ON CONFLICT (id) DO NOTHING;

-- Produits et services
INSERT INTO products_services (company_id, name, description, category, price, unit, images) VALUES
('11111111-1111-1111-1111-111111111111', 'Panier de légumes bio', 'Assortiment de légumes de saison bio. Composition variable selon récolte.', 'Légumes', 25.00, 'panier 5kg', ARRAY['https://images.pexels.com/photos/1300972/pexels-photo-1300972.jpeg']),
('11111111-1111-1111-1111-111111111111', 'Œufs bio plein air', 'Œufs de poules élevées en plein air, alimentation bio 100%.', 'Œufs', 8.50, 'boîte de 30', ARRAY['https://images.pexels.com/photos/1556707/pexels-photo-1556707.jpeg']),
('11111111-1111-1111-1111-111111111111', 'Fruits de saison bio', 'Sélection de fruits frais bio cueillis à maturité.', 'Fruits', 18.00, 'caisse 3kg', ARRAY['https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg']),
('22222222-2222-2222-2222-222222222222', 'Pain au levain bio', 'Pain traditionnel au levain naturel, farine bio locale.', 'Pain', 4.50, 'pièce 800g', ARRAY['https://images.pexels.com/photos/1775043/pexels-photo-1775043.jpeg']),
('22222222-2222-2222-2222-222222222222', 'Assortiment viennoiseries', 'Croissants, pains au chocolat, brioches.', 'Viennoiserie', 35.00, 'plateau 20 pièces', ARRAY['https://images.pexels.com/photos/2673353/pexels-photo-2673353.jpeg']),
('33333333-3333-3333-3333-333333333333', 'Tomme de Savoie fermière', 'Tomme traditionnelle au lait cru. Affinage 3 mois minimum.', 'Fromage', 16.00, 'kg', ARRAY['https://images.pexels.com/photos/821365/pexels-photo-821365.jpeg']),
('33333333-3333-3333-3333-333333333333', 'Plateau de fromages assortis', 'Sélection de 5 fromages de notre production.', 'Fromage', 45.00, 'plateau 2kg', ARRAY['https://images.pexels.com/photos/4109998/pexels-photo-4109998.jpeg']),
('44444444-4444-4444-4444-444444444444', 'Agencement sur mesure', 'Conception et réalisation d''agencement commercial personnalisé.', 'Agencement', NULL, 'projet', ARRAY[]::text[]),
('55555555-5555-5555-5555-555555555555', 'Cartes de visite premium', 'Impression haute qualité, plusieurs finitions disponibles.', 'Impression', 45.00, '500 unités', ARRAY[]::text[]),
('55555555-5555-5555-5555-555555555555', 'Flyers A5', 'Impression couleur recto-verso, papier 170g.', 'Impression', 120.00, '1000 unités', ARRAY[]::text[]),
('66666666-6666-6666-6666-666666666666', 'Nettoyage bureaux quotidien', 'Nettoyage complet de vos locaux. Du lundi au vendredi.', 'Nettoyage', 450.00, 'mois / 100m²', ARRAY[]::text[]),
('77777777-7777-7777-7777-777777777777', 'Livraison express jour même', 'Livraison dans un rayon de 50km le jour même.', 'Transport', 25.00, 'course', ARRAY[]::text[]),
('88888888-8888-8888-8888-888888888888', 'Audit marketing digital', 'Analyse complète de votre présence en ligne.', 'Conseil', 800.00, 'audit', ARRAY[]::text[]),
('88888888-8888-8888-8888-888888888888', 'Gestion réseaux sociaux', 'Animation de vos comptes, création de contenu.', 'Marketing', 600.00, 'mois', ARRAY[]::text[])
ON CONFLICT DO NOTHING;

-- Visibilité boost (mises en avant)
INSERT INTO visibility_boosts (company_id, start_date, end_date, zone, category, price, active) VALUES
('11111111-1111-1111-1111-111111111111', CURRENT_DATE, CURRENT_DATE + interval '30 days', 'regional', 'Agriculture & Alimentation', 400.00, true),
('55555555-5555-5555-5555-555555555555', CURRENT_DATE, CURRENT_DATE + interval '14 days', 'local', 'Services aux entreprises', 100.00, true),
('22222222-2222-2222-2222-222222222222', CURRENT_DATE, CURRENT_DATE + interval '21 days', 'local', 'Agriculture & Alimentation', 150.00, true)
ON CONFLICT DO NOTHING;

-- Réactiver la contrainte (optionnel, à adapter selon vos besoins)
-- ALTER TABLE companies ADD CONSTRAINT companies_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
