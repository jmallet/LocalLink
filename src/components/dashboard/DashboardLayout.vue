<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { signOut, user } from '../../stores/auth'

const route = useRoute()
const router = useRouter()

const mobileMenuOpen = ref(false)

const menuItems = [
  { name: 'dashboard' as const, label: 'Tableau de bord', icon: '📊' },
  { name: 'dashboard-profile' as const, label: 'Mon profil', icon: '🏢' },
  { name: 'dashboard-products' as const, label: 'Produits & Services', icon: '📦' },
  { name: 'dashboard-quotes' as const, label: 'Demandes de devis', icon: '📋' },
  { name: 'dashboard-visibility' as const, label: 'Visibilité', icon: '⭐' },
]

async function handleSignOut() {
  await signOut()
  router.push({ name: 'home' })
}
</script>

<template>
  <div class="dashboard-layout">
    <aside class="sidebar" :class="{ 'mobile-open': mobileMenuOpen }">
      <div class="sidebar-header">
        <router-link to="/" class="sidebar-brand">
          <span class="logo-icon">🏪</span>
          <span class="logo-text">LocalLink</span>
        </router-link>
        <button class="close-mobile-menu" @click="mobileMenuOpen = false">✕</button>
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
        </router-link>
      </nav>

      <div class="sidebar-footer">
        <div class="user-info">
          <div class="user-avatar">{{ user?.email?.[0].toUpperCase() }}</div>
          <div class="user-details">
            <div class="user-email">{{ user?.email }}</div>
          </div>
        </div>
        <button class="btn-signout" @click="handleSignOut">
          <span>🚪</span> Déconnexion
        </button>
      </div>
    </aside>

    <div class="main-content">
      <header class="dashboard-header">
        <button class="mobile-menu-btn" @click="mobileMenuOpen = true">
          ☰
        </button>
        <h1 class="page-title">
          {{ menuItems.find(item => item.name === route.name)?.label || 'Dashboard' }}
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
  background: #f9fafb;
}

.sidebar {
  width: 280px;
  background: white;
  border-right: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  z-index: 100;
  transition: transform 0.3s;
}

.sidebar-header {
  padding: 24px 20px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 700;
  font-size: 20px;
  cursor: pointer;
  transition: opacity 0.2s;
}

.sidebar-brand:hover {
  opacity: 0.7;
}

.logo-icon {
  font-size: 24px;
}

.close-mobile-menu {
  display: none;
  background: none;
  border: none;
  font-size: 24px;
  color: #6b7280;
  cursor: pointer;
  padding: 8px;
}

.sidebar-nav {
  flex: 1;
  padding: 16px 12px;
  overflow-y: auto;
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
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 4px;
  text-align: left;
}

.nav-item:hover {
  background: #f3f4f6;
}

.nav-item.active {
  background: #d1fae5;
  color: #059669;
  font-weight: 600;
}

.nav-icon {
  font-size: 20px;
}

.sidebar-footer {
  padding: 16px;
  border-top: 1px solid #e5e7eb;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 12px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #059669;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 16px;
}

.user-details {
  flex: 1;
  min-width: 0;
}

.user-email {
  font-size: 13px;
  color: #374151;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.btn-signout {
  width: 100%;
  padding: 10px 16px;
  background: transparent;
  color: #dc2626;
  border: 1px solid #fecaca;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-signout:hover {
  background: #fef2f2;
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
