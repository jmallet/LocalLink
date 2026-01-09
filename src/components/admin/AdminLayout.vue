<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { isAuthenticated, user, signOut, isAdmin as isUserAdmin, loading as authLoading } from '../../stores/auth'

const router = useRouter()

const currentPage = ref('dashboard')
const loading = ref(true)

const menuItems = [
  { id: 'dashboard', label: 'Tableau de bord', icon: '📊', isInternal: true },
  { id: 'users', label: 'Utilisateurs', icon: '👥', isInternal: true },
  { id: 'companies', label: 'Sociétés', icon: '🏢', isInternal: true },
  { name: 'admin-quote-requests', label: 'Gestion des devis', icon: '✅', path: '/admin/demandes-devis' }
]

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
        <router-link to="/" class="brand">
          <span class="brand-icon">🏪</span>
          <div class="brand-text">
            <h1>LocalLink</h1>
            <span class="badge-admin">Admin</span>
          </div>
        </router-link>
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
          </router-link>
          <button
            v-else
            class="nav-item"
            :class="{ active: currentPage === item.id }"
            @click="selectPage(item.id)"
          >
            <span class="nav-icon">{{ item.icon }}</span>
            <span class="nav-label">{{ item.label }}</span>
          </button>
        </template>
      </nav>

      <div class="sidebar-footer">
        <div class="user-info">
          <div class="user-avatar">{{ user?.email?.charAt(0).toUpperCase() }}</div>
          <div class="user-details">
            <span class="user-email">{{ user?.email }}</span>
            <span class="user-role">Administrateur</span>
          </div>
        </div>
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
  background: #f9fafb;
}

.admin-sidebar {
  background: #ffffff;
  border-right: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  position: sticky;
  top: 0;
  height: 100vh;
}

.sidebar-header {
  padding: 24px;
  border-bottom: 1px solid #e5e7eb;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  transition: opacity 0.2s;
}

.brand:hover {
  opacity: 0.8;
}

.brand-icon {
  font-size: 32px;
}

.brand-text h1 {
  font-size: 20px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 4px 0;
}

.badge-admin {
  display: inline-block;
  padding: 2px 8px;
  background: #dbeafe;
  color: #1e40af;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
}

.sidebar-nav {
  flex: 1;
  padding: 16px;
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
}

.nav-item:hover {
  background: #f3f4f6;
}

.nav-item.active {
  background: #eff6ff;
  color: #1e40af;
}

.nav-icon {
  font-size: 20px;
}

.nav-label {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}

.nav-item.active .nav-label {
  color: #1e40af;
}

.nav-link {
  text-decoration: none;
  color: inherit;
}

.nav-divider {
  height: 1px;
  background: #e5e7eb;
  margin: 12px 0;
}

.sidebar-footer {
  padding: 16px;
  border-top: 1px solid #e5e7eb;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #3b82f6;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 16px;
}

.user-details {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.user-email {
  font-size: 13px;
  font-weight: 600;
  color: #111827;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.user-role {
  font-size: 11px;
  color: #6b7280;
}

.btn-logout {
  width: 100%;
  padding: 10px;
  background: transparent;
  color: #ef4444;
  border: 1px solid #fecaca;
  border-radius: 8px;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-logout:hover {
  background: #fee2e2;
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
