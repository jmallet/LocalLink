<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { signOut, user, currentCompany } from '../../stores/auth'

const route = useRoute()
const router = useRouter()

const mobileMenuOpen = ref(false)

const menuItems = computed(() => {
  return [
    { name: 'pro-dashboard' as const, label: 'Tableau de bord', icon: '📊', badge: null },
    { name: 'pro-received-quotes' as const, label: 'Leads disponibles', icon: '📋', badge: 12 },
    { name: 'pro-sent-quotes' as const, label: 'Mes devis envoyés', icon: '📨', badge: null },
    { name: 'dashboard-products' as const, label: 'Achats de leads', icon: '💳', badge: null }
  ]
})

const profilItems = computed(() => {
  return [
    { name: 'pro-company-profile' as const, label: 'Mon profil pro', icon: '👤' },
    { name: 'pro-settings' as const, label: 'Paramètres', icon: '⚙️' }
  ]
})

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

const userRole = computed(() => {
  return currentCompany.value?.name || 'Professionnel'
})

async function handleSignOut() {
  await signOut()
  router.push({ name: 'home' })
}
</script>

<template>
  <div class="dashboard-layout">
    <aside class="sidebar" :class="{ 'mobile-open': mobileMenuOpen }">
      <button class="close-mobile-menu" @click="mobileMenuOpen = false">✕</button>

      <div class="sidebar-header">
        <div class="user-avatar">{{ userInitials }}</div>
        <h2 class="user-name">{{ userName }}</h2>
        <div class="user-role">
          <svg class="role-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M20 7h-9M14 17H5M17 12L22 7l-5-5M7 17l-5 5 5 5"/>
          </svg>
          {{ userRole }}
        </div>
      </div>

      <nav class="sidebar-nav">
        <router-link
          v-for="item in menuItems"
          :key="item.name"
          :to="{ name: item.name }"
          class="nav-item"
          :class="{ active: route.name === item.name }"
          @click="mobileMenuOpen = false"
        >
          <span class="nav-icon">{{ item.icon }}</span>
          <span class="nav-label">{{ item.label }}</span>
          <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
        </router-link>

        <div class="nav-section">PROFIL</div>

        <router-link
          v-for="item in profilItems"
          :key="item.name"
          :to="{ name: item.name }"
          class="nav-item"
          :class="{ active: route.name === item.name }"
          @click="mobileMenuOpen = false"
        >
          <span class="nav-icon">{{ item.icon }}</span>
          <span class="nav-label">{{ item.label }}</span>
        </router-link>
      </nav>

      <div class="sidebar-footer">
        <router-link to="/" class="btn-home">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
            <polyline points="9 22 9 12 15 12 15 22"/>
          </svg>
          Retour à l'accueil
        </router-link>
        <button class="btn-signout" @click="handleSignOut">
          Déconnexion
        </button>
      </div>
    </aside>

    <div class="main-content">
      <header class="dashboard-header">
        <button class="mobile-menu-btn" @click="mobileMenuOpen = true">
          ☰
        </button>
        <h1 class="page-title">
          {{ menuItems.find(item => item.name === route.name)?.label || profilItems.find(item => item.name === route.name)?.label || 'Dashboard' }}
        </h1>
      </header>

      <div class="content-wrapper">
        <slot></slot>
      </div>
    </div>

    <div
      v-if="mobileMenuOpen"
      class="mobile-overlay"
      @click="mobileMenuOpen = false"
    ></div>
  </div>
</template>

<style scoped>
.dashboard-layout {
  display: flex;
  min-height: 100vh;
  background: #f5f5f5;
}

.sidebar {
  width: 280px;
  background: linear-gradient(180deg, #1a1d2e 0%, #0f1117 100%);
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  z-index: 100;
  transition: transform 0.3s;
  border-radius: 0 16px 16px 0;
}

.close-mobile-menu {
  display: none;
  position: absolute;
  top: 16px;
  right: 16px;
  background: none;
  border: none;
  font-size: 24px;
  color: #6b7280;
  cursor: pointer;
  padding: 8px;
  z-index: 101;
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
  background: linear-gradient(135deg, #c0574e 0%, #a0443d 100%);
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

.nav-section {
  font-size: 11px;
  font-weight: 600;
  color: #6b7280;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  margin: 24px 0 12px 12px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: 12px 16px;
  background: none;
  border: none;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 400;
  color: #9ca3af;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 4px;
  text-align: left;
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
  border-left-color: #ea580c;
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

.sidebar-footer {
  padding: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.btn-home {
  width: 100%;
  padding: 12px 16px;
  background: rgba(59, 130, 246, 0.1);
  color: #60a5fa;
  border: 1px solid rgba(59, 130, 246, 0.2);
  border-radius: 8px;
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-home:hover {
  background: rgba(59, 130, 246, 0.15);
  border-color: rgba(59, 130, 246, 0.3);
}

.btn-signout {
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

.btn-signout:hover {
  background: rgba(220, 38, 38, 0.15);
  border-color: rgba(220, 38, 38, 0.3);
}

.main-content {
  flex: 1;
  margin-left: 280px;
  display: flex;
  flex-direction: column;
}

.dashboard-header {
  background: white;
  border-bottom: 1px solid #e5e7eb;
  padding: 20px 32px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.mobile-menu-btn {
  display: none;
  background: none;
  border: none;
  font-size: 24px;
  color: #374151;
  cursor: pointer;
  padding: 8px;
}

.page-title {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.content-wrapper {
  flex: 1;
  padding: 32px;
  overflow-y: auto;
}

.mobile-overlay {
  display: none;
}

@media (max-width: 1024px) {
  .sidebar {
    transform: translateX(-100%);
    border-radius: 0;
  }

  .sidebar.mobile-open {
    transform: translateX(0);
  }

  .close-mobile-menu {
    display: block;
  }

  .main-content {
    margin-left: 0;
  }

  .mobile-menu-btn {
    display: block;
  }

  .mobile-overlay {
    display: block;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: 99;
  }

  .content-wrapper {
    padding: 24px 16px;
  }

  .dashboard-header {
    padding: 16px 20px;
  }
}
</style>
