<script setup lang="ts">
import { onMounted } from 'vue'
import { initAuth, isAuthenticated, loading } from './stores/auth'
import NavigationBar from './components/common/NavigationBar.vue'

onMounted(async () => {
  await initAuth()
})
</script>

<template>
  <div class="app">
    <div v-if="loading" class="loading-screen">
      <div class="spinner"></div>
      <p>Chargement...</p>
    </div>

    <template v-else>
      <NavigationBar />

      <main class="main-container">
        <div class="construction-notice">
          <h1>🚧 Application en construction</h1>
          <p>La structure complète de l'application LocalLink est en cours de développement.</p>

          <div class="status-card">
            <h2>✅ Éléments terminés:</h2>
            <ul>
              <li>Schéma de base de données PostgreSQL complet (7 tables)</li>
              <li>Système d'authentification Supabase</li>
              <li>Router et navigation</li>
              <li>Types TypeScript</li>
              <li>Store auth centralisé</li>
            </ul>
          </div>

          <div class="status-card">
            <h2>📋 Structure des fonctionnalités:</h2>
            <ul>
              <li><strong>Authentification:</strong> Inscription/Connexion avec validation SIRET/BCE</li>
              <li><strong>Dashboard Entreprise:</strong> Profil, produits, devis, visibilité, paiements</li>
              <li><strong>Pages Publiques:</strong> Accueil, Pros locaux, À propos, Blog, Contact</li>
              <li><strong>Système de devis:</strong> Création, modération admin, paiement leads (10€)</li>
              <li><strong>Visibilité:</strong> Mise en avant payante (zone locale/régionale/nationale)</li>
              <li><strong>Admin:</strong> Validation entreprises, modération devis, gestion paiements</li>
              <li><strong>API:</strong> 5 Edge Functions (vérification SIRET, Stripe, notifications)</li>
            </ul>
          </div>

          <div class="info-card">
            <h3>📊 Base de données</h3>
            <p>7 tables créées avec RLS:</p>
            <ul>
              <li>companies (entreprises)</li>
              <li>products_services (vitrine)</li>
              <li>quote_requests (demandes de devis)</li>
              <li>quote_recipients (destinataires)</li>
              <li>visibility_boosts (mises en avant)</li>
              <li>payments (historique)</li>
              <li>blog_posts (articles)</li>
            </ul>
          </div>

          <div class="info-card">
            <h3>🎯 Workflow principal</h3>
            <ol>
              <li>Inscription avec vérification SIRET/BCE automatique</li>
              <li>Activation profil producteur optionnelle</li>
              <li>Création vitrine produits/services</li>
              <li>Réception demandes de devis (payantes: 10€)</li>
              <li>Option visibilité accrue (50-200€/semaine)</li>
            </ol>
          </div>

          <p class="doc-link">
            📖 Consultez <strong>PROJECT_STRUCTURE.md</strong> pour la structure complète
          </p>

          <div class="auth-status">
            <p v-if="isAuthenticated">
              ✅ Vous êtes connecté
            </p>
            <p v-else>
              ℹ️ Non connecté
            </p>
          </div>
        </div>
      </main>
    </template>
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  line-height: 1.6;
  color: #111827;
  background: #f9fafb;
}

.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.loading-screen {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #e5e7eb;
  border-top-color: #059669;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.main-container {
  flex: 1;
  max-width: 1200px;
  margin: 0 auto;
  padding: 48px 24px;
  width: 100%;
}

.construction-notice {
  background: white;
  border-radius: 16px;
  padding: 48px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.construction-notice h1 {
  font-size: 36px;
  margin-bottom: 16px;
  color: #111827;
}

.construction-notice > p {
  font-size: 18px;
  color: #6b7280;
  margin-bottom: 32px;
}

.status-card {
  background: #f0fdf4;
  border: 1px solid #86efac;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
}

.status-card h2 {
  font-size: 20px;
  margin-bottom: 16px;
  color: #059669;
}

.status-card ul {
  list-style: none;
  padding-left: 0;
}

.status-card li {
  padding: 8px 0;
  padding-left: 28px;
  position: relative;
}

.status-card li::before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #059669;
  font-weight: bold;
}

.info-card {
  background: #eff6ff;
  border: 1px solid #93c5fd;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
}

.info-card h3 {
  font-size: 18px;
  margin-bottom: 12px;
  color: #1e40af;
}

.info-card ul,
.info-card ol {
  margin-left: 24px;
  color: #374151;
}

.info-card li {
  margin: 8px 0;
}

.doc-link {
  text-align: center;
  font-size: 16px;
  color: #6b7280;
  margin: 32px 0;
  padding: 16px;
  background: #fef3c7;
  border-radius: 8px;
}

.auth-status {
  text-align: center;
  padding: 16px;
  background: #f3f4f6;
  border-radius: 8px;
  margin-top: 24px;
}

@media (max-width: 768px) {
  .construction-notice {
    padding: 24px;
  }

  .construction-notice h1 {
    font-size: 28px;
  }

  .main-container {
    padding: 24px 16px;
  }
}
</style>
