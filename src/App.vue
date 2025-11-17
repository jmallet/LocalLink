<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { initAuth, loading } from './stores/auth'
import { currentRoute, navigateTo } from './router'
import NavigationBar from './components/common/NavigationBar.vue'
import HomePage from './components/pages/HomePage.vue'
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
      <NavigationBar />

      <main>
        <HomePage v-if="currentRoute.name === 'home'" />

        <div v-else class="construction-container">
          <div class="construction-notice">
            <h1>Page {{ currentRoute.name }}</h1>
            <p>Cette page est en cours de développement.</p>

            <div class="status-card">
              <h2>✅ Fonctionnalités actuelles :</h2>
              <ul>
                <li>Page d'accueil avec entreprises mises en avant</li>
                <li>8 entreprises de test avec produits/services</li>
                <li>3 articles de blog</li>
                <li>3 entreprises mises en avant (boost visibilité)</li>
                <li>Système d'authentification fonctionnel</li>
                <li>Base de données complète avec RLS</li>
              </ul>
            </div>

            <div class="info-card">
              <h3>🎯 Pages disponibles :</h3>
              <ul>
                <li>✅ Accueil (page d'accueil avec entreprises)</li>
                <li>⏳ Pros locaux (en développement)</li>
                <li>⏳ À propos (en développement)</li>
                <li>⏳ Blog (en développement)</li>
                <li>⏳ Contact (en développement)</li>
                <li>⏳ Dashboard (en développement)</li>
              </ul>
            </div>

            <button class="btn-back" @click="navigateTo({ name: 'home' })">
              ← Retour à l'accueil
            </button>
          </div>
        </div>
      </main>

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
