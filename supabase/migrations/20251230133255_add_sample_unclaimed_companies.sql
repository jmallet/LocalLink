/*
  # Add Sample Unclaimed Companies

  ## Description
  Ajout d'entreprises non réclamées pour peupler la plateforme avec du contenu.
  Ces entreprises peuvent être réclamées par des utilisateurs lors de leur inscription.

  ## Données ajoutées
  - 15 entreprises dans différents secteurs d'activité
  - Données réalistes avec SIRET/SIREN fictifs
  - Entreprises actives et visibles sur la plateforme
  - Réparties sur différentes villes françaises

  ## Secteurs couverts
  - Agroalimentaire
  - Mobilier et menuiserie
  - Textile et mode
  - Cosmétiques naturels
  - Équipements professionnels
  - Imprimerie
  - Électronique
*/

-- Entreprises agroalimentaires
INSERT INTO companies (
  company_name, siret_bce, siren, address, postal_code, city, country,
  category, description, is_buyer, is_producer, producer_active, 
  claimed, verified, tags
) VALUES
(
  'Fromagerie du Terroir',
  '12345678901234',
  '123456789',
  '15 Rue des Fromagers',
  '69001',
  'Lyon',
  'FR',
  'Agroalimentaire',
  'Fromagerie artisanale produisant des fromages AOP et fermiers de qualité supérieure.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['fromage', 'produits laitiers', 'bio', 'local']
),
(
  'Boulangerie Bio des Alpes',
  '23456789012345',
  '234567890',
  '8 Place du Marché',
  '74000',
  'Annecy',
  'FR',
  'Agroalimentaire',
  'Boulangerie artisanale utilisant des farines biologiques et locales.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['boulangerie', 'bio', 'artisanal', 'local']
),
(
  'Maraîchage du Sud',
  '34567890123456',
  '345678901',
  '23 Chemin des Cultures',
  '84000',
  'Avignon',
  'FR',
  'Agroalimentaire',
  'Production de fruits et légumes biologiques en circuit court.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['fruits', 'légumes', 'bio', 'maraîchage']
),
(
  'Conserverie Bretonne',
  '45678901234567',
  '456789012',
  '12 Rue du Port',
  '29200',
  'Brest',
  'FR',
  'Agroalimentaire',
  'Conserverie artisanale spécialisée dans les produits de la mer.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['conserves', 'produits de la mer', 'artisanal']
),

-- Mobilier et menuiserie
(
  'Ateliers du Bois Noble',
  '56789012345678',
  '567890123',
  '45 Avenue des Artisans',
  '31000',
  'Toulouse',
  'FR',
  'Mobilier',
  'Menuiserie artisanale créant du mobilier sur-mesure en bois massif.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['menuiserie', 'mobilier', 'artisanal', 'bois']
),
(
  'Ébénisterie Moderne',
  '67890123456789',
  '678901234',
  '78 Rue de la Création',
  '33000',
  'Bordeaux',
  'FR',
  'Mobilier',
  'Ébénisterie contemporaine alliant design et savoir-faire traditionnel.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['ébénisterie', 'design', 'mobilier', 'sur-mesure']
),

-- Textile et mode
(
  'Tissage Lyonnais',
  '78901234567890',
  '789012345',
  '34 Rue des Canuts',
  '69004',
  'Lyon',
  'FR',
  'Textile',
  'Atelier de tissage traditionnel produisant des étoffes de luxe.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['textile', 'tissage', 'luxe', 'artisanal']
),
(
  'Couture Éthique Paris',
  '89012345678901',
  '890123456',
  '56 Rue du Faubourg',
  '75011',
  'Paris',
  'FR',
  'Textile',
  'Atelier de couture éco-responsable et fabrication française.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['couture', 'éthique', 'mode', 'eco-responsable']
),

-- Cosmétiques naturels
(
  'Savonnerie Artisanale du Midi',
  '90123456789012',
  '901234567',
  '9 Rue des Oliviers',
  '13100',
  'Aix-en-Provence',
  'FR',
  'Cosmétiques',
  'Savonnerie artisanale produisant des savons naturels et biologiques.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['savon', 'cosmétiques', 'bio', 'naturel']
),
(
  'Laboratoire Nature & Beauté',
  '01234567890123',
  '012345678',
  '67 Avenue de la République',
  '44000',
  'Nantes',
  'FR',
  'Cosmétiques',
  'Fabrication de cosmétiques naturels et produits de beauté bio.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['cosmétiques', 'bio', 'beauté', 'naturel']
),

-- Équipements professionnels
(
  'Forge Industrielle du Centre',
  '11234567890124',
  '112345679',
  '89 Zone Artisanale',
  '63000',
  'Clermont-Ferrand',
  'FR',
  'Équipements',
  'Forge spécialisée dans les équipements professionnels sur-mesure.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['forge', 'équipements', 'sur-mesure', 'industrie']
),
(
  'Outils & Machines Pro',
  '21234567890125',
  '212345680',
  '43 Rue de l''Industrie',
  '59000',
  'Lille',
  'FR',
  'Équipements',
  'Fabrication d''outils et machines pour professionnels.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['outils', 'machines', 'équipements', 'professionnel']
),

-- Imprimerie
(
  'Imprimerie Verte',
  '31234567890126',
  '312345681',
  '25 Rue Gutenberg',
  '67000',
  'Strasbourg',
  'FR',
  'Imprimerie',
  'Imprimerie éco-responsable utilisant des encres végétales et papiers recyclés.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['imprimerie', 'eco-responsable', 'recyclé', 'local']
),

-- Électronique
(
  'Électronique Locale',
  '41234567890127',
  '412345682',
  '78 Avenue des Technologies',
  '35000',
  'Rennes',
  'FR',
  'Électronique',
  'Assemblage de composants électroniques et réparation professionnelle.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['électronique', 'réparation', 'assemblage', 'high-tech']
),
(
  'Circuit Court Tech',
  '51234567890128',
  '512345683',
  '91 Rue de l''Innovation',
  '38000',
  'Grenoble',
  'FR',
  'Électronique',
  'Fabrication de circuits imprimés et prototypage électronique.',
  false,
  true,
  true,
  false,
  true,
  ARRAY['électronique', 'circuits', 'prototypage', 'innovation']
);
