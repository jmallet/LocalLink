<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { isAuthenticated, user, signOut, isAdmin as isUserAdmin, loading as authLoading } from '../../stores/auth'

const router = useRouter()
const route = useRoute()

const currentPage = ref('dashboard')
const loading = ref(true)

const menuItems = [
  { id: 'dashboard', label: 'Tableau de bord', icon: '📊', isInternal: true, badge: null },
  { id: 'users', label: 'Utilisateurs', icon: '👥', isInternal: true, badge: null },
  { id: 'companies', label: 'Sociétés', icon: '🏢', isInternal: true, badge: null },
  { name: 'admin-quote-requests', label: 'Gestion des devis', icon: '✅', path: '/admin/demandes-devis', badge: null },
  { name: 'admin-quotes-monitoring', label: 'Suivi des devis', icon: '📈', path: '/admin/suivi-devis', badge: null }
]

const userInitials = computed(() => {
  const email = user.value?.email || ''
  const parts = email.split('@')[0].split('.')
  if (parts.length > 1) {
    return (parts[0][0] + parts[1][0]).toUpperCase()
  }
  return email.substring(0, 2).toUpperCase()
})

const userName = computed(() => {
  const email = user.value?.email || ''
  const name = email.split('@')[0]
  return name.split('.').map(part =>
    part.charAt(0).toUpperCase() + part.slice(1)
  ).join(' ')
})

onMounted(async () => {
  if (!isAuthenticated.value) {
    router.push({ name: 'home' })
    return
  }

  await checkAdminStatus()
})

async function checkAdminStatus() {
  loading.value = true
  try {
    while (authLoading.value) {
      await new Promise(resolve => setTimeout(resolve, 50))
    }

    if (!isUserAdmin.value) {
      router.push({ name: 'home' })
    }
  } catch (error) {
    console.error('Error checking admin status:', error)
    router.push({ name: 'home' })
  } finally {
    loading.value = false
  }
}

function selectPage(pageId: string) {
  if (route.name !== 'admin') {
    router.push({ name: 'admin' })
  }
  currentPage.value = pageId
}

async function handleSignOut() {
  await signOut()
  router.push({ name: 'home' })
}
</script>

<template>
  <div v-if="loading" class="loading-screen">
    <div class="spinner"></div>
    <p>Vérification des permissions...</p>
  </div>

  <div v-else-if="isUserAdmin" class="admin-layout">
    <aside class="admin-sidebar">
      <div class="sidebar-header">
        <div class="user-avatar">{{ userInitials }}</div>
        <h2 class="user-name">{{ userName }}</h2>
        <div class="user-role">
          <svg class="role-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 2L2 7l10 5 10-5-10-5z"/>
            <path d="M2 17l10 5 10-5"/>
            <path d="M2 12l10 5 10-5"/>
          </svg>
          Administrateur
        </div>
      </div>

      <nav class="sidebar-nav">
        <template v-for="item in menuItems" :key="item.id || item.name">
          <router-link
            v-if="item.path"
            :to="{ name: item.name }"
            class="nav-item nav-link"
            active-class="active"
          >
            <span class="nav-icon">{{ item.icon }}</span>
            <span class="nav-label">{{ item.label }}</span>
            <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
          </router-link>
          <button
            v-else
            class="nav-item"
            :class="{ active: currentPage === item.id }"
            @click="selectPage(item.id)"
          >
            <span class="nav-icon">{{ item.icon }}</span>
            <span class="nav-label">{{ item.label }}</span>
            <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
          </button>
        </template>
      </nav>

      <div class="sidebar-footer">
        <button class="btn-logout" @click="handleSignOut">
          Déconnexion
        </button>
      </div>
    </aside>

    <main class="admin-main">
      <slot :current-page="currentPage"></slot>
    </main>
  </div>
</template>

<style scoped>
.loading-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: #f9fafb;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.loading-screen p {
  color: #6b7280;
  font-size: 14px;
}

.admin-layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  min-height: 100vh;
  background: #f5f5f5;
}

.admin-sidebar {
  background: linear-gradient(180deg, #1a1d2e 0%, #0f1117 100%);
  display: flex;
  flex-direction: column;
  position: sticky;
  top: 0;
  height: 100vh;
  border-radius: 0 16px 16px 0;
}

.sidebar-header {
  padding: 32px 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.user-avatar {
  width: 64px;
  height: 64px;
  border-radius: 12px;
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 24px;
  margin-bottom: 16px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.user-name {
  font-size: 18px;
  font-weight: 600;
  color: white;
  margin: 0 0 8px 0;
}

.user-role {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #9ca3af;
  font-weight: 400;
}

.role-icon {
  opacity: 0.7;
}

.sidebar-nav {
  flex: 1;
  padding: 24px 16px;
  overflow-y: auto;
}

.nav-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border: none;
  background: transparent;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 4px;
  font-size: 15px;
  font-weight: 400;
  color: #9ca3af;
  position: relative;
  border-left: 3px solid transparent;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.05);
  color: #d1d5db;
}

.nav-item.active {
  background: rgba(255, 255, 255, 0.08);
  color: white;
  font-weight: 500;
  border-left-color: #3b82f6;
}

.nav-icon {
  font-size: 18px;
  width: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.nav-label {
  flex: 1;
  font-size: 15px;
}

.nav-badge {
  background: #dc2626;
  color: white;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 12px;
  min-width: 20px;
  text-align: center;
}

.nav-link {
  text-decoration: none;
  color: inherit;
}

.sidebar-footer {
  padding: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.btn-logout {
  width: 100%;
  padding: 12px 16px;
  background: rgba(220, 38, 38, 0.1);
  color: #ef4444;
  border: 1px solid rgba(220, 38, 38, 0.2);
  border-radius: 8px;
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-logout:hover {
  background: rgba(220, 38, 38, 0.15);
  border-color: rgba(220, 38, 38, 0.3);
}

.admin-main {
  padding: 32px;
  overflow-y: auto;
  max-height: 100vh;
}

@media (max-width: 1024px) {
  .admin-layout {
    grid-template-columns: 1fr;
  }

  .admin-sidebar {
    display: none;
  }
}
</style>
