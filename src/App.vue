<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { initAuth, loading } from './stores/auth'
import { currentRoute, navigateTo } from './router'
import NavigationBar from './components/common/NavigationBar.vue'
import Footer from './components/common/Footer.vue'
import HomePage from './components/pages/HomePage.vue'
import ProsLocauxPage from './components/pages/ProsLocauxPage.vue'
import CompanyDetailPage from './components/pages/CompanyDetailPage.vue'
import BlogPage from './components/pages/BlogPage.vue'
import BlogPostPage from './components/pages/BlogPostPage.vue'
import AboutPage from './components/pages/AboutPage.vue'
import ContactPage from './components/pages/ContactPage.vue'
import DashboardPage from './components/pages/DashboardPage.vue'
import ProfilePage from './components/pages/ProfilePage.vue'
import ProductsPage from './components/pages/ProductsPage.vue'
import QuotesPage from './components/pages/QuotesPage.vue'
import VisibilityPage from './components/pages/VisibilityPage.vue'
import AdminPage from './components/pages/AdminPage.vue'
import LoginForm from './components/auth/LoginForm.vue'

const showLoginModal = ref(false)

onMounted(async () => {
  await initAuth()
})

watch(currentRoute, (route) => {
  if (route.name === 'login') {
    showLoginModal.value = true
  }
})

function closeLoginModal() {
  showLoginModal.value = false
  if (currentRoute.value.name === 'login') {
    navigateTo({ name: 'home' })
  }
}
</script>

<template>
  <div class="app">
    <div v-if="loading" class="loading-screen">
      <div class="spinner"></div>
      <p>Chargement...</p>
    </div>

    <template v-else>
      <NavigationBar v-if="!['dashboard', 'dashboard-profile', 'dashboard-products', 'dashboard-quotes', 'dashboard-visibility', 'admin'].includes(currentRoute.name)" />

      <main>
        <HomePage v-if="currentRoute.name === 'home'" />
        <ProsLocauxPage v-else-if="currentRoute.name === 'pros-locaux'" />
        <CompanyDetailPage v-else-if="currentRoute.name === 'company-detail'" />
        <BlogPage v-else-if="currentRoute.name === 'blog'" />
        <BlogPostPage v-else-if="currentRoute.name === 'blog-post'" />
        <AboutPage v-else-if="currentRoute.name === 'about'" />
        <ContactPage v-else-if="currentRoute.name === 'contact'" />
        <DashboardPage v-else-if="currentRoute.name === 'dashboard'" />
        <ProfilePage v-else-if="currentRoute.name === 'dashboard-profile'" />
        <ProductsPage v-else-if="currentRoute.name === 'dashboard-products'" />
        <QuotesPage v-else-if="currentRoute.name === 'dashboard-quotes'" />
        <VisibilityPage v-else-if="currentRoute.name === 'dashboard-visibility'" />
        <AdminPage v-else-if="currentRoute.name === 'admin'" />

        <div v-else class="construction-container">
          <div class="construction-notice">
            <h1>Page {{ currentRoute.name }}</h1>
            <p>Cette page est en cours de développement.</p>

            <div class="status-card">
              <h2>✅ Pages disponibles :</h2>
              <ul>
                <li>Accueil - Page d'accueil avec entreprises mises en avant</li>
                <li>Pros locaux - Liste complète avec filtres et recherche</li>
                <li>Détail entreprise - Fiche complète avec produits/services</li>
                <li>Blog - Liste des articles</li>
                <li>Article de blog - Lecture complète d'un article</li>
                <li>À propos - Présentation de LocalLink</li>
                <li>Contact - Formulaire de contact et FAQ</li>
              </ul>
            </div>

            <div class="info-card">
              <h3>📊 Données de test :</h3>
              <ul>
                <li>8 entreprises avec profils complets</li>
                <li>14 produits et services</li>
                <li>3 articles de blog publiés</li>
                <li>3 entreprises avec boost de visibilité</li>
              </ul>
            </div>

            <div class="info-card">
              <h3>🚀 Prochaines fonctionnalités :</h3>
              <ul>
                <li>⏳ Dashboard entreprise complet</li>
                <li>⏳ Système de demande de devis</li>
                <li>⏳ Interface d'administration</li>
                <li>⏳ Paiements Stripe</li>
              </ul>
            </div>

            <button class="btn-back" @click="navigateTo({ name: 'home' })">
              ← Retour à l'accueil
            </button>
          </div>
        </div>
      </main>

      <Footer v-if="!['dashboard', 'dashboard-profile', 'dashboard-products', 'dashboard-quotes', 'dashboard-visibility', 'admin'].includes(currentRoute.name)" />

      <LoginForm v-if="showLoginModal" @close="closeLoginModal" />
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

main {
  flex: 1;
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

.construction-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 48px 24px;
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

.info-card ul {
  margin-left: 24px;
  color: #374151;
}

.info-card li {
  margin: 8px 0;
}

.btn-back {
  padding: 12px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-back:hover {
  background: #047857;
  transform: translateY(-1px);
}

@media (max-width: 768px) {
  .construction-notice {
    padding: 24px;
  }

  .construction-notice h1 {
    font-size: 28px;
  }

  .construction-container {
    padding: 24px 16px;
  }
}
</style>
