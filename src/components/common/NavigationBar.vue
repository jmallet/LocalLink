<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { isAuthenticated, signOut, user } from '../../stores/auth'
import { supabase } from '../../lib/supabase'

const router = useRouter()

const mobileMenuOpen = ref(false)
const isAdmin = ref(false)

const toggleMobileMenu = () => {
  mobileMenuOpen.value = !mobileMenuOpen.value
}

const handleSignOut = async () => {
  await signOut()
  router.push({ name: 'home' })
}

async function checkAdminStatus() {
  if (!isAuthenticated.value || !user.value) {
    isAdmin.value = false
    return
  }

  const { data } = await supabase
    .from('companies')
    .select('role')
    .eq('user_id', user.value.id)
    .maybeSingle()

  isAdmin.value = data?.role === 'admin'
}

onMounted(() => {
  checkAdminStatus()
})
</script>

<template>
  <nav class="navbar">
    <div class="nav-container">
      <router-link to="/" class="nav-brand">
        <span class="logo-icon">🏪</span>
        <span class="logo-text">LocalLink</span>
      </router-link>

      <div class="nav-links" :class="{ 'mobile-open': mobileMenuOpen }">
        <router-link to="/" class="nav-link">Accueil</router-link>
        <router-link to="/pros-locaux" class="nav-link">Pros locaux</router-link>
        <router-link to="/a-propos" class="nav-link">À propos</router-link>
        <router-link to="/blog" class="nav-link">Blog</router-link>
        <router-link to="/contact" class="nav-link">Contact</router-link>
      </div>

      <div class="nav-actions">
        <template v-if="isAuthenticated">
          <button v-if="isAdmin" class="btn-admin" @click="router.push({ name: 'admin' })">
            Admin
          </button>
          <button class="btn-secondary" @click="router.push({ name: 'dashboard' })">
            Dashboard
          </button>
          <button class="btn-secondary" @click="handleSignOut">
            Déconnexion
          </button>
        </template>
        <template v-else>
          <button class="btn-secondary" @click="$emit('show-login')">
            Connexion
          </button>
          <button class="btn-primary" @click="$emit('show-login')">
            Créer un compte
          </button>
        </template>
      </div>

      <button class="mobile-menu-btn" @click="toggleMobileMenu">
        <span class="hamburger"></span>
      </button>
    </div>
  </nav>
</template>

<style scoped>
.navbar {
  background: #ffffff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  position: sticky;
  top: 0;
  z-index: 100;
  border-bottom: 1px solid #e5e7eb;
}

.nav-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 72px;
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 700;
  font-size: 24px;
  color: #111827;
  cursor: pointer;
}

.logo-icon {
  font-size: 28px;
}

.nav-links {
  display: flex;
  gap: 32px;
  align-items: center;
}

.nav-link {
  color: #6b7280;
  text-decoration: none;
  font-weight: 500;
  font-size: 15px;
  transition: color 0.2s;
  padding: 8px 0;
  cursor: pointer;
}

.nav-link:hover {
  color: #059669;
}

.nav-actions {
  display: flex;
  gap: 12px;
}

.btn-secondary,
.btn-primary,
.btn-admin {
  padding: 10px 20px;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-admin {
  background: #3b82f6;
  color: white;
}

.btn-admin:hover {
  background: #2563eb;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.btn-secondary {
  background: transparent;
  color: #374151;
  border: 1px solid #d1d5db;
}

.btn-secondary:hover {
  background: #f9fafb;
  border-color: #9ca3af;
}

.btn-primary {
  background: #059669;
  color: white;
}

.btn-primary:hover {
  background: #047857;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);
}

.mobile-menu-btn {
  display: none;
}

@media (max-width: 768px) {
  .nav-links {
    position: fixed;
    top: 72px;
    left: 0;
    right: 0;
    background: white;
    flex-direction: column;
    padding: 24px;
    gap: 16px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    transform: translateY(-100%);
    opacity: 0;
    transition: all 0.3s;
    pointer-events: none;
  }

  .nav-links.mobile-open {
    transform: translateY(0);
    opacity: 1;
    pointer-events: all;
  }

  .nav-actions {
    display: none;
  }

  .mobile-menu-btn {
    display: block;
    background: none;
    border: none;
    cursor: pointer;
    padding: 8px;
  }

  .hamburger {
    display: block;
    width: 24px;
    height: 2px;
    background: #374151;
    position: relative;
  }

  .hamburger::before,
  .hamburger::after {
    content: '';
    position: absolute;
    width: 24px;
    height: 2px;
    background: #374151;
    left: 0;
  }

  .hamburger::before {
    top: -8px;
  }

  .hamburger::after {
    top: 8px;
  }
}
</style>
