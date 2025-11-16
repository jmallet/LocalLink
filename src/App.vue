<script setup lang="ts">
import { ref, computed } from 'vue'
import NavigationBar from './components/NavigationBar.vue'
import HeroSection from './components/HeroSection.vue'
import SearchFilters from './components/SearchFilters.vue'
import BusinessCard from './components/BusinessCard.vue'
import ContactModal from './components/ContactModal.vue'
import AboutPage from './components/AboutPage.vue'
import SignupModal from './components/SignupModal.vue'
import ProsLocauxPage from './components/ProsLocauxPage.vue'
import { mockBusinesses } from './data/mockBusinesses'
import type { Business, Category } from './types'

const currentPage = ref<'home' | 'about' | 'pros-locaux'>('home')
const isSignupOpen = ref(false)
const searchQuery = ref('')
const selectedCategory = ref<Category>('all')
const isModalOpen = ref(false)
const selectedBusiness = ref<Business | null>(null)

const filteredBusinesses = computed(() => {
  let result = mockBusinesses

  if (selectedCategory.value !== 'all') {
    result = result.filter(b => b.category === selectedCategory.value)
  }

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(b =>
      b.name.toLowerCase().includes(query) ||
      b.description.toLowerCase().includes(query) ||
      b.tags.some(tag => tag.toLowerCase().includes(query))
    )
  }

  return result
})

const handleContactBusiness = (business: Business) => {
  selectedBusiness.value = business
  isModalOpen.value = true
}

const closeModal = () => {
  isModalOpen.value = false
  selectedBusiness.value = null
}

const navigateToPage = (page: 'home' | 'about' | 'pros-locaux') => {
  currentPage.value = page
}

const openSignup = () => {
  isSignupOpen.value = true
}

const closeSignup = () => {
  isSignupOpen.value = false
}
</script>

<template>
  <div class="app">
    <NavigationBar :current-page="currentPage" @navigate="navigateToPage" @open-signup="openSignup" />

    <AboutPage v-if="currentPage === 'about'" />
    <ProsLocauxPage v-else-if="currentPage === 'pros-locaux'" @contact="handleContactBusiness" />

    <template v-else>
      <HeroSection />
      <SearchFilters
        @update:search="searchQuery = $event"
        @update:category="selectedCategory = $event"
      />

      <main class="main-content">
        <div class="results-header">
          <h2 class="results-title">
            {{ filteredBusinesses.length }}
            {{ filteredBusinesses.length > 1 ? 'entreprises trouvées' : 'entreprise trouvée' }}
          </h2>
        </div>

        <div v-if="filteredBusinesses.length > 0" class="business-grid">
          <BusinessCard
            v-for="business in filteredBusinesses"
            :key="business.id"
            :business="business"
            @contact="handleContactBusiness"
          />
        </div>

        <div v-else class="empty-state">
          <span class="empty-icon">🔍</span>
          <h3>Aucune entreprise trouvée</h3>
          <p>Essayez de modifier vos critères de recherche</p>
        </div>
      </main>
    </template>

    <ContactModal
      :business="selectedBusiness"
      :is-open="isModalOpen"
      @close="closeModal"
    />

    <SignupModal v-if="isSignupOpen" @close="closeSignup" />
  </div>
</template>

<style scoped>
.app {
  min-height: 100vh;
  background: #f9fafb;
}

.main-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 24px 80px;
}

.results-header {
  margin-bottom: 32px;
}

.results-title {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.business-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
}

.empty-state {
  text-align: center;
  padding: 80px 24px;
}

.empty-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 24px;
}

.empty-state h3 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

@media (max-width: 768px) {
  .business-grid {
    grid-template-columns: 1fr;
  }

  .results-title {
    font-size: 22px;
  }
}
</style>
