<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { isAuthenticated } from '../../stores/auth'
import type { Company } from '../../types/database'
import CompanyCard from '../common/CompanyCard.vue'
import SearchFilters from '../common/SearchFilters.vue'

const router = useRouter()

const companies = ref<Company[]>([])
const loading = ref(true)
const searchQuery = ref('')
const selectedCategory = ref('all')
const selectedCity = ref('all')
const showLoginModal = ref(false)

const filteredCompanies = computed(() => {
  let result = companies.value

  if (selectedCategory.value !== 'all') {
    result = result.filter(c => c.category === selectedCategory.value)
  }

  if (selectedCity.value !== 'all') {
    result = result.filter(c => c.city === selectedCity.value)
  }

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(c =>
      c.company_name.toLowerCase().includes(query) ||
      c.description?.toLowerCase().includes(query) ||
      c.tags.some(tag => tag.toLowerCase().includes(query))
    )
  }

  return result
})

const displayedCompanies = computed(() => {
  if (!isAuthenticated.value) {
    return filteredCompanies.value.slice(0, 3)
  }
  return filteredCompanies.value
})

const showViewMore = computed(() => {
  return !isAuthenticated.value && filteredCompanies.value.length > 3
})

onMounted(async () => {
  await loadCompanies()
})

async function loadCompanies() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('producer_active', true)
      .eq('verified', true)
      .order('company_name')

    if (error) throw error
    companies.value = data || []
  } catch (error) {
    console.error('Error loading companies:', error)
  } finally {
    loading.value = false
  }
}

function handleCompanyClick(company: Company) {
  router.push({ name: 'company-detail', params: { id: company.id } })
}

function handleContact(company: Company) {
  if (!isAuthenticated.value) {
    showLoginModal.value = true
  } else {
    router.push({ name: 'company-detail', params: { id: company.id } })
  }
}

function handleViewMore() {
  showLoginModal.value = true
}
</script>

<template>
  <div class="pros-locaux-page">
    <section class="page-header">
      <div class="container">
        <h1 class="page-title">Nos Pros Locaux</h1>
        <p class="page-subtitle">
          Découvrez tous les professionnels et producteurs de votre région
        </p>
      </div>
    </section>

    <SearchFilters
      @update:search="searchQuery = $event"
      @update:category="selectedCategory = $event"
      @update:city="selectedCity = $event"
    />

    <section class="companies-section">
      <div class="container">
        <div class="results-header">
          <h2 class="results-title">
            {{ filteredCompanies.length }}
            {{ filteredCompanies.length > 1 ? 'entreprises trouvées' : 'entreprise trouvée' }}
          </h2>
          <p v-if="!isAuthenticated" class="auth-notice">
            ℹ️ Connectez-vous pour voir tous les professionnels
          </p>
        </div>

        <div v-if="loading" class="loading-container">
          <div class="spinner"></div>
          <p>Chargement des entreprises...</p>
        </div>

        <div v-else-if="displayedCompanies.length > 0" class="companies-grid">
          <CompanyCard
            v-for="company in displayedCompanies"
            :key="company.id"
            :company="company"
            @click="handleCompanyClick(company)"
            @contact="handleContact(company)"
          />
        </div>

        <div v-else class="empty-state">
          <span class="empty-icon">🔍</span>
          <h3>Aucune entreprise trouvée</h3>
          <p>Essayez de modifier vos critères de recherche</p>
        </div>

        <div v-if="showViewMore" class="view-more-container">
          <div class="blur-overlay"></div>
          <div class="view-more-content">
            <h3>Vous souhaitez voir plus ?</h3>
            <p>Inscrivez-vous gratuitement pour accéder à tous les professionnels</p>
            <button class="btn-view-more" @click="handleViewMore">
              Créer mon compte gratuitement
            </button>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.pros-locaux-page {
  min-height: 100vh;
  background: #f9fafb;
}

.page-header {
  background: white;
  padding: 64px 24px;
  border-bottom: 1px solid #e5e7eb;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
}

.page-title {
  font-size: 48px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
  text-align: center;
}

.page-subtitle {
  font-size: 20px;
  color: #6b7280;
  margin: 0;
  text-align: center;
}

.companies-section {
  padding: 48px 24px 80px;
  position: relative;
}

.results-header {
  margin-bottom: 32px;
  text-align: center;
}

.results-title {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.auth-notice {
  font-size: 15px;
  color: #059669;
  font-weight: 500;
  margin: 0;
}

.companies-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
  margin-bottom: 48px;
}

.loading-container {
  text-align: center;
  padding: 80px 24px;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #e5e7eb;
  border-top-color: #059669;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
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

.view-more-container {
  position: relative;
  margin-top: -24px;
  padding-top: 120px;
}

.blur-overlay {
  position: absolute;
  top: 0;
  left: -24px;
  right: -24px;
  height: 200px;
  background: linear-gradient(to bottom, transparent, #f9fafb);
  pointer-events: none;
}

.view-more-content {
  background: white;
  border-radius: 16px;
  padding: 48px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  text-align: center;
  max-width: 600px;
  margin: 0 auto;
}

.view-more-content h3 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.view-more-content p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-view-more {
  padding: 16px 32px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-view-more:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

@media (max-width: 768px) {
  .page-header {
    padding: 48px 24px;
  }

  .page-title {
    font-size: 36px;
  }

  .page-subtitle {
    font-size: 18px;
  }

  .companies-grid {
    grid-template-columns: 1fr;
  }

  .results-title {
    font-size: 22px;
  }

  .companies-section {
    padding: 32px 16px 80px;
  }

  .view-more-content {
    padding: 32px 24px;
  }

  .view-more-content h3 {
    font-size: 22px;
  }
}
</style>
