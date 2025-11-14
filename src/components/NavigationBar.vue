<script setup lang="ts">
import { ref } from 'vue'

defineProps<{
  currentPage?: 'home' | 'about'
}>()

const emit = defineEmits<{
  (e: 'navigate', page: 'home' | 'about'): void
  (e: 'open-signup'): void
}>()

const mobileMenuOpen = ref(false)

const toggleMobileMenu = () => {
  mobileMenuOpen.value = !mobileMenuOpen.value
}

const handleNavigate = (page: 'home' | 'about') => {
  emit('navigate', page)
  mobileMenuOpen.value = false
}
</script>

<template>
  <nav class="navbar">
    <div class="nav-container">
      <div class="nav-brand">
        <span class="logo-icon">🏪</span>
        <span class="logo-text">LocalLink</span>
      </div>

      <div class="nav-links" :class="{ 'mobile-open': mobileMenuOpen }">
        <a @click.prevent="handleNavigate('home')" href="#" :class="['nav-link', { active: currentPage === 'home' }]">Découvrir</a>
        <a href="#" class="nav-link">Mes favoris</a>
        <a href="#" class="nav-link">Messages</a>
        <a @click.prevent="handleNavigate('about')" href="#" :class="['nav-link', { active: currentPage === 'about' }]">À propos</a>
      </div>

      <div class="nav-actions">
        <button class="btn-secondary">Connexion</button>
        <button class="btn-primary" @click="emit('open-signup')">Créer un compte</button>
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
  position: relative;
}

.nav-link:hover {
  color: #111827;
}

.nav-link.active {
  color: #059669;
}

.nav-link.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: #059669;
}

.nav-actions {
  display: flex;
  gap: 12px;
}

.btn-secondary,
.btn-primary {
  padding: 10px 20px;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
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
