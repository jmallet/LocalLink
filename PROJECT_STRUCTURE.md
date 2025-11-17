# Structure complète du projet LocalLink

## Architecture générale

```
project/
├── src/
│   ├── components/
│   │   ├── auth/
│   │   │   ├── LoginForm.vue
│   │   │   ├── SignupForm.vue
│   │   │   └── AuthModal.vue
│   │   ├── common/
│   │   │   ├── NavigationBar.vue
│   │   │   ├── Footer.vue
│   │   │   ├── CompanyCard.vue
│   │   │   ├── SearchFilters.vue
│   │   │   └── LoadingSpinner.vue
│   │   ├── dashboard/
│   │   │   ├── DashboardLayout.vue
│   │   │   ├── DashboardSidebar.vue
│   │   │   ├── ProfileForm.vue
│   │   │   ├── ProductsList.vue
│   │   │   ├── ProductForm.vue
│   │   │   ├── QuotesList.vue
│   │   │   ├── VisibilityBoostForm.vue
│   │   │   └── PaymentHistory.vue
│   │   ├── admin/
│   │   │   ├── AdminLayout.vue
│   │   │   ├── AdminSidebar.vue
│   │   │   ├── CompaniesManager.vue
│   │   │   ├── QuotesManager.vue
│   │   │   ├── PaymentsManager.vue
│   │   │   └── BlogEditor.vue
│   │   ├── quotes/
│   │   │   ├── QuoteRequestForm.vue
│   │   │   ├── QuoteRequestModal.vue
│   │   │   └── QuoteCard.vue
│   │   └── pages/
│   │       ├── HomePage.vue
│   │       ├── ProsLocauxPage.vue
│   │       ├── AboutPage.vue
│   │       ├── ContactPage.vue
│   │       ├── BlogPage.vue
│   │       ├── BlogPostPage.vue
│   │       └── CompanyDetailPage.vue
│   ├── stores/
│   │   ├── auth.ts (✓ créé)
│   │   ├── companies.ts
│   │   ├── quotes.ts
│   │   └── payments.ts
│   ├── lib/
│   │   ├── supabase.ts (✓ créé)
│   │   ├── stripe.ts
│   │   └── validation.ts
│   ├── router/
│   │   └── index.ts (✓ créé)
│   ├── types/
│   │   └── database.ts (✓ créé)
│   ├── App.vue
│   └── main.ts
├── supabase/
│   ├── functions/
│   │   ├── verify-siret/
│   │   │   └── index.ts
│   │   ├── create-checkout-session/
│   │   │   └── index.ts
│   │   ├── webhook-stripe/
│   │   │   └── index.ts
│   │   ├── send-quote-notifications/
│   │   │   └── index.ts
│   │   └── unlock-quote/
│   │       └── index.ts
│   └── migrations/
│       └── create_initial_schema.sql (✓ créé)
└── package.json
```

## Base de données (✓ Créée)

### Tables principales:
1. **companies** - Informations des entreprises
2. **products_services** - Produits/services des producteurs
3. **quote_requests** - Demandes de devis
4. **quote_recipients** - Destinataires des demandes
5. **visibility_boosts** - Mises en avant payantes
6. **payments** - Historique des paiements
7. **blog_posts** - Articles de blog

## Fonctionnalités par rôle

### Public (non connecté)
- Voir page d'accueil avec top 3 entreprises mises en avant
- Voir page "Pros locaux" (limité à 3 entreprises + bouton "Voir plus")
- Voir détails entreprise (limité)
- Bouton "Contacter" → Modal d'inscription
- Lire articles de blog
- Pages: À propos, Contact

### Utilisateur connecté (Acheteur)
- Voir tous les producteurs
- Voir détails complets des entreprises
- Envoyer demandes de devis
- Tableau de bord:
  - Mes demandes de devis
  - Profil entreprise
  - Historique paiements

### Utilisateur connecté (Producteur)
- Tout ce que l'acheteur peut faire +
- Activer/désactiver profil producteur
- Gérer vitrine produits/services
- Recevoir demandes de devis (payantes à débloquer: 10€/demande)
- Payer pour visibilité (mise en avant)
- Tableau de bord:
  - Profil & paramètres
  - Mes produits/services
  - Demandes reçues
  - Visibilité & promotion
  - Historique paiements

### Administrateur
- Valider les entreprises
- Modérer les demandes de devis avant envoi
- Gérer les paiements
- Modérer les contenus
- Gérer le blog
- Interface admin complète

## API / Edge Functions

### 1. verify-siret
- Vérification SIRET via API gouvernementale
- POST /functions/v1/verify-siret
- Body: { siret: string, country: 'FR' | 'BE' }
- Return: { valid: boolean, companyInfo?: object }

### 2. create-checkout-session
- Création session Stripe pour paiements
- POST /functions/v1/create-checkout-session
- Body: { type: 'lead' | 'visibility', amount: number, metadata: object }
- Return: { sessionId: string, url: string }

### 3. webhook-stripe
- Webhook pour events Stripe
- POST /functions/v1/webhook-stripe
- Gestion: payment_intent.succeeded, checkout.session.completed

### 4. send-quote-notifications
- Envoi notifications email pour nouvelles demandes
- POST /functions/v1/send-quote-notifications
- Body: { quoteRequestId: string, recipientIds: string[] }

### 5. unlock-quote
- Débloquer une demande de devis après paiement
- POST /functions/v1/unlock-quote
- Body: { quoteRecipientId: string, paymentId: string }

## Tarification

### Leads (Demandes de devis)
- 10€ par demande débloquée
- Paiement Stripe
- Entreprise reçoit email de notification
- Doit payer pour voir détails complets

### Visibilité (Mise en avant)
- Zone locale: 50€/semaine
- Zone régionale: 100€/semaine
- Zone nationale: 200€/semaine
- Minimum 7 jours
- Apparaît en top 3 des résultats

## Workflow principal

### 1. Inscription entreprise
1. Utilisateur remplit formulaire
2. Vérification SIRET/BCE via API
3. Création compte Supabase Auth
4. Création entrée dans table companies
5. Email de confirmation
6. Connexion automatique

### 2. Activation profil producteur
1. Entreprise active "Mode producteur"
2. Remplit description, photos
3. Ajoute produits/services
4. Profil devient visible publiquement

### 3. Demande de devis
1. Acheteur connecté crée demande
2. Sélectionne catégorie/critères
3. Demande → statut "pending_approval"
4. Admin valide/rejette
5. Si validé → envoi aux producteurs matchés
6. Producteurs reçoivent notification email
7. Producteur paie 10€ pour débloquer détails
8. Après paiement, accès complet à la demande

### 4. Mise en avant
1. Producteur va dans "Visibilité"
2. Choisit zone, catégorie, durée
3. Calcul prix automatique
4. Paiement Stripe
5. Activation immédiate
6. Apparaît en top des résultats

## Prochaines étapes d'implémentation

1. ✓ Schéma base de données
2. ✓ Configuration router & auth
3. Composants authentification
4. Pages publiques
5. Dashboard entreprise
6. Système quotes
7. Interface admin
8. Edge Functions
9. Intégration Stripe
10. Tests & déploiement
