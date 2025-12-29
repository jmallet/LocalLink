<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { initAuth, loading } from './stores/auth'
import NavigationBar from './components/common/NavigationBar.vue'
import Footer from './components/common/Footer.vue'
import LoginForm from './components/auth/LoginForm.vue'

const route = useRoute()
const showLoginModal = ref(false)

onMounted(async () => {
  await initAuth()
})

function closeLoginModal() {
  showLoginModal.value = false
}

function isDashboardOrAdmin(routeName: string | symbol | null | undefined): boolean {
  if (!routeName || typeof routeName !== 'string') return false
  return routeName.startsWith('dashboard') || routeName.startsWith('admin') || routeName.startsWith('individual-')
}
</script>

<template>
  <div class="app">
    <div v-if="loading" class="loading-screen">
      <div class="spinner"></div>
      <p>Chargement...</p>
    </div>

    <template v-else>
      <NavigationBar v-if="!isDashboardOrAdmin(route.name)" @show-login="showLoginModal = true" />

      <main>
        <router-view />
      </main>

      <Footer v-if="!isDashboardOrAdmin(route.name)" />

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
</style>
