<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { initAuth, loading, needsOnboarding } from './stores/auth'
import NavigationBar from './components/common/NavigationBar.vue'
import Footer from './components/common/Footer.vue'
import LoginForm from './components/auth/LoginForm.vue'
import OnboardingModal from './components/auth/OnboardingModal.vue'
import type { UserType } from './types/database'

const route = useRoute()
const router = useRouter()
const showLoginModal = ref(false)
const showOnboardingModal = ref(false)

onMounted(async () => {
  await initAuth()
})

watch(needsOnboarding, (needs) => {
  if (needs && !showOnboardingModal.value) {
    showOnboardingModal.value = true
  }
})

function closeLoginModal() {
  showLoginModal.value = false
}

function closeOnboardingModal() {
  showOnboardingModal.value = false
  needsOnboarding.value = false
}

function handleProRegistration() {
  showLoginModal.value = false
  showOnboardingModal.value = true
}

function handleOnboardingComplete(userType: UserType) {
  showOnboardingModal.value = false
  needsOnboarding.value = false

  if (userType === 'PARTICULIER') {
    router.push({ name: 'dashboard-particulier' })
  } else if (userType === 'PRO') {
    router.push({ name: 'dashboard-pro' })
  } else if (userType === 'ADMIN') {
    router.push({ name: 'admin' })
  }
}

function isDashboardOrAdmin(routeName: string | symbol | null | undefined): boolean {
  if (!routeName || typeof routeName !== 'string') return false
  return routeName.startsWith('dashboard') || routeName.startsWith('admin') || routeName.startsWith('individual-') || routeName.startsWith('pro-')
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

      <LoginForm
        v-if="showLoginModal"
        @close="closeLoginModal"
        @pro-registration="handleProRegistration"
      />
      <OnboardingModal
        v-if="showOnboardingModal"
        @close="closeOnboardingModal"
        @complete="handleOnboardingComplete"
      />
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
