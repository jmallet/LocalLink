<script setup lang="ts">
import { ref, computed } from 'vue'
import BusinessCard from './BusinessCard.vue'
import SearchFilters from './SearchFilters.vue'
import { mockBusinesses } from '../data/mockBusinesses'
import type { Business, Category } from '../types'

const searchQuery = ref('')
const selectedCategory = ref<Category>('all')

const emit = defineEmits<{
  (e: 'contact', business: Business): void
}>()

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
  emit('contact', business)
}
</script>

<template>
  <section class="pros-locaux-page">
    <div class="page-header">
      <h1 class="page-title">Nos Pros Locaux</h1>
      <p class="page-subtitle">Découvrez tous les professionnels et producteurs de votre région</p>
    </div>

    <div class="filters-container">
      <SearchFilters
        @update:search="searchQuery = $event"
        @update:category="selectedCategory = $event"
      />
    </div>

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
  </section>
</template>

<style scoped>
.pros-locaux-page {
  min-height: calc(100vh - 72px);
  background: #f9fafb;
}

.page-header {
  background: white;
  padding: 64px 24px;
  border-bottom: 1px solid #e5e7eb;
  text-align: center;
}

.page-title {
  font-size: 48px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
}

.page-subtitle {
  font-size: 18px;
  color: #6b7280;
  margin: 0;
}

.filters-container {
  background: white;
  border-bottom: 1px solid #e5e7eb;
}

.main-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 48px 24px 80px;
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
  .page-header {
    padding: 48px 24px;
  }

  .page-title {
    font-size: 36px;
  }

  .page-subtitle {
    font-size: 16px;
  }

  .business-grid {
    grid-template-columns: 1fr;
  }

  .results-title {
    font-size: 22px;
  }

  .main-content {
    padding: 32px 24px 80px;
  }
}
</style>
