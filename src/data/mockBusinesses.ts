import type { Business } from '../types'

export const mockBusinesses: Business[] = [
  {
    id: 1,
    name: 'Ferme Bio du Val',
    category: 'producer',
    description: 'Production de légumes biologiques et fruits de saison. Livraison quotidienne possible.',
    location: 'Versailles, 78000',
    distance: 2.5,
    image: 'https://images.pexels.com/photos/1459339/pexels-photo-1459339.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Bio', 'Légumes', 'Fruits', 'Livraison'],
    verified: true,
    contact: {
      email: 'contact@fermebioval.fr',
      phone: '01 23 45 67 89'
    }
  },
  {
    id: 2,
    name: 'Boulangerie Artisan',
    category: 'producer',
    description: 'Pain artisanal et viennoiseries faits maison. Commandes en gros pour restaurants.',
    location: 'Paris 15ème, 75015',
    distance: 5.2,
    image: 'https://images.pexels.com/photos/1775043/pexels-photo-1775043.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Pain', 'Viennoiseries', 'Artisanal'],
    verified: true,
    contact: {
      email: 'hello@boulangerieartisan.fr',
      phone: '01 34 56 78 90'
    }
  },
  {
    id: 3,
    name: 'Le Bistrot Gourmand',
    category: 'restaurant',
    description: 'Restaurant gastronomique recherchant des producteurs locaux de viande et légumes.',
    location: 'Boulogne, 92100',
    distance: 3.8,
    image: 'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Gastronomie', 'Cuisine française', 'Local'],
    verified: true,
    contact: {
      email: 'contact@bistrotgourmand.fr',
      phone: '01 45 67 89 01'
    }
  },
  {
    id: 4,
    name: 'Traiteur Excellence',
    category: 'caterer',
    description: 'Service traiteur événementiel et corporate. Spécialisé dans les produits du terroir.',
    location: 'Saint-Cloud, 92210',
    distance: 4.1,
    image: 'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Événementiel', 'Terroir', 'Prestations'],
    verified: true,
    contact: {
      email: 'info@traiteurexcellence.fr',
      phone: '01 56 78 90 12'
    }
  },
  {
    id: 5,
    name: 'Fromagerie du Terroir',
    category: 'producer',
    description: 'Fromages artisanaux de la région. Production locale et affinés sur place.',
    location: 'Sèvres, 92310',
    distance: 3.2,
    image: 'https://images.pexels.com/photos/821365/pexels-photo-821365.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Fromage', 'Artisanal', 'Terroir'],
    verified: false,
    contact: {
      email: 'contact@fromagerieterroir.fr',
      phone: '01 67 89 01 23'
    }
  },
  {
    id: 6,
    name: 'Épicerie Fine Local',
    category: 'retailer',
    description: 'Épicerie fine proposant des produits locaux sélectionnés. Vente en gros disponible.',
    location: 'Issy-les-Moulineaux, 92130',
    distance: 4.5,
    image: 'https://images.pexels.com/photos/264636/pexels-photo-264636.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Épicerie', 'Produits fins', 'Gros'],
    verified: true,
    contact: {
      email: 'hello@epiceriefine.fr',
      phone: '01 78 90 12 34'
    }
  },
  {
    id: 7,
    name: 'Maraîcher des Halles',
    category: 'producer',
    description: 'Exploitation maraîchère familiale. Légumes de saison et production raisonnée.',
    location: 'Meudon, 92190',
    distance: 2.9,
    image: 'https://images.pexels.com/photos/1300972/pexels-photo-1300972.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Maraîcher', 'Légumes', 'Saison'],
    verified: true,
    contact: {
      email: 'contact@maraicherhalles.fr',
      phone: '01 89 01 23 45'
    }
  },
  {
    id: 8,
    name: 'Logistique Pro Services',
    category: 'service',
    description: 'Service de livraison et logistique pour professionnels. Réseau local optimisé.',
    location: 'Vanves, 92170',
    distance: 3.7,
    image: 'https://images.pexels.com/photos/4391470/pexels-photo-4391470.jpeg?auto=compress&cs=tinysrgb&w=800',
    tags: ['Logistique', 'Livraison', 'B2B'],
    verified: true,
    contact: {
      email: 'info@logistiquepro.fr',
      phone: '01 90 12 34 56'
    }
  }
]
