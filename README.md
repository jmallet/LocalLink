# LocalLink - Plateforme B2B de Circuit Court

Application web connectant les entreprises locales pour favoriser le circuit court et l'économie locale.

## 🎯 Vue d'ensemble

LocalLink est une plateforme B2B permettant aux entreprises de :
- Se connecter avec des producteurs et fournisseurs locaux vérifiés
- Envoyer et recevoir des demandes de devis
- Augmenter leur visibilité via des mises en avant payantes
- Gérer leur vitrine de produits et services

## ✅ Fonctionnalités implémentées

### Pages publiques
- **✅ Page d'accueil** - Hero section, features, top 3 entreprises mises en avant, limitation pour non-connectés
- **✅ Pros locaux** - Liste complète avec filtres (catégorie, ville) et recherche en temps réel
- **✅ Détail entreprise** - Fiche complète avec informations, produits/services, demande de devis
- **✅ Blog** - Liste des articles publiés
- **✅ Article de blog** - Lecture complète avec navigation

### Authentification
- **✅ Modal de connexion/inscription** - Formulaire avec basculement entre modes
- **✅ Système d'authentification Supabase** - Gestion centralisée des sessions
- **✅ Protection des contenus** - Limitation de l'accès pour non-connectés

### Navigation
- **✅ Barre de navigation responsive** - Menu desktop et mobile
- **✅ Router personnalisé** - Navigation fluide entre pages
- **✅ États actifs** - Indication visuelle de la page courante

## 📊 Base de données (Supabase PostgreSQL)

### Tables créées (7)
1. **companies** - Informations des entreprises (8 entreprises de test)
2. **products_services** - Produits/services (14 entrées)
3. **quote_requests** - Demandes de devis
4. **quote_recipients** - Destinataires des demandes
5. **visibility_boosts** - Mises en avant (3 actives)
6. **payments** - Historique des paiements
7. **blog_posts** - Articles de blog (3 articles)

### Sécurité
- Row Level Security (RLS) activé sur toutes les tables
- Politiques restrictives par défaut
- Accès basé sur auth.uid()

## 🏢 Données de test

### 8 Entreprises
1. **Ferme Bio du Terroir** - Agriculture & Alimentation (⭐ boost régional)
2. **Boulangerie Artisanale Martin** - Agriculture & Alimentation (⭐ boost local)
3. **Fromagerie des Alpes** - Agriculture & Alimentation
4. **Menuiserie Moderne** - Construction & Rénovation
5. **Imprimerie Rapide** - Services aux entreprises (⭐ boost local)
6. **Nettoyage Pro Services** - Services aux entreprises
7. **Transport Express Local** - Transport & Logistique
8. **Conseil Marketing Digital** - Services aux entreprises

### 14 Produits/Services
Répartis sur les 8 entreprises avec descriptions, prix, catégories

### 3 Articles de blog
- Le circuit court : un avantage économique
- Pourquoi privilégier les producteurs locaux
- Comment LocalLink facilite vos approvisionnements

## 🚀 Installation et lancement

```bash
# Installation des dépendances
npm install

# Lancement en développement
npm run dev

# Build de production
npm run build
```

## 📁 Structure du projet

```
project/
├── src/
│   ├── components/
│   │   ├── auth/
│   │   │   └── LoginForm.vue              ✅ Modal connexion/inscription
│   │   ├── common/
│   │   │   ├── NavigationBar.vue          ✅ Navigation principale
│   │   │   ├── CompanyCard.vue            ✅ Carte entreprise
│   │   │   └── SearchFilters.vue          ✅ Filtres de recherche
│   │   └── pages/
│   │       ├── HomePage.vue               ✅ Page d'accueil
│   │       ├── ProsLocauxPage.vue         ✅ Liste pros locaux
│   │       ├── CompanyDetailPage.vue      ✅ Détail entreprise
│   │       ├── BlogPage.vue               ✅ Liste articles
│   │       └── BlogPostPage.vue           ✅ Détail article
│   ├── stores/
│   │   └── auth.ts                        ✅ Store authentification
│   ├── lib/
│   │   └── supabase.ts                    ✅ Client Supabase
│   ├── router/
│   │   └── index.ts                       ✅ Router personnalisé
│   ├── types/
│   │   └── database.ts                    ✅ Types TypeScript
│   ├── App.vue                            ✅ Composant principal
│   └── main.ts                            ✅ Point d'entrée
├── supabase/
│   └── migrations/
│       ├── create_initial_schema.sql      ✅ Schéma complet
│       └── add_test_data_v2.sql           ✅ Données de test
└── package.json
```

## 🎨 Design & UX

### Principes appliqués
- Design moderne et épuré (pas de violet/indigo)
- Palette verte (#059669) pour l'identité
- Cartes avec ombres et hover effects
- Responsive design (mobile-first)
- Chargement avec spinners
- États vides élégants

### Interactions
- Navigation fluide entre pages
- Filtres en temps réel
- Limitation de contenu pour non-connectés
- Badges "Mis en avant" pour entreprises boostées
- Modal de connexion contextuelle

## 🔐 Authentification & Sécurité

### Supabase Auth
- Email/password par défaut
- Sessions gérées automatiquement
- Store centralisé réactif
- RLS pour protection données

### Workflow
1. Utilisateur non connecté → accès limité
2. Clic sur "Voir plus" → modal de connexion
3. Inscription → création compte Supabase
4. Connexion → accès complet aux fonctionnalités

## 📋 Fonctionnalités à développer

### Court terme
- ⏳ Page À propos
- ⏳ Page Contact avec formulaire
- ⏳ Formulaire complet d'inscription entreprise (avec SIRET)
- ⏳ Dashboard entreprise de base

### Moyen terme
- ⏳ Système de demande de devis complet
- ⏳ Gestion des produits/services (CRUD)
- ⏳ Paiement pour débloquer les leads (Stripe)
- ⏳ Système de boost de visibilité avec paiement

### Long terme
- ⏳ Interface d'administration
- ⏳ Modération des demandes de devis
- ⏳ Edge Functions API (vérification SIRET, webhooks Stripe)
- ⏳ Notifications par email
- ⏳ Statistiques et analytics

## 🎯 Tarification prévue

### Leads (Demandes de devis)
- **10€** par demande débloquée
- Paiement Stripe
- Notification email

### Visibilité (Mise en avant)
- **Zone locale** : 50€/semaine
- **Zone régionale** : 100€/semaine
- **Zone nationale** : 200€/semaine
- Minimum 7 jours
- Apparition en top 3 des résultats

## 🛠 Technologies utilisées

- **Frontend** : Vue.js 3 (Composition API), TypeScript
- **Base de données** : Supabase (PostgreSQL)
- **Authentification** : Supabase Auth
- **Styling** : CSS natif (scoped)
- **Build** : Vite
- **Images** : Pexels (photos stock)

## 📝 Variables d'environnement

Créer un fichier `.env` :

```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 🎓 Concepts mis en œuvre

### Architecture
- Composition API (Vue 3)
- Stores réactifs
- Router personnalisé
- Types TypeScript stricts
- Composants réutilisables

### Bonnes pratiques
- Single Responsibility Principle
- DRY (Don't Repeat Yourself)
- Responsive design
- Accessibility basics
- Security by default (RLS)

### Performance
- Lazy loading des images
- Optimisation des requêtes SQL
- Index sur colonnes fréquemment requêtées
- Build optimisé (tree-shaking)

## 📖 Documentation complémentaire

- `PROJECT_STRUCTURE.md` - Architecture détaillée
- `/supabase/migrations/` - Schéma et données

## 🚀 État actuel

**Version** : v1.0-alpha
**Statut** : Prototype fonctionnel avec données de test
**Prêt pour** : Démonstration, développement des fonctionnalités avancées

---

**Développé avec** ❤️ **pour favoriser le circuit court et l'économie locale**
