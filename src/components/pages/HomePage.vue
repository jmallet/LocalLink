<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { isAuthenticated } from '../../stores/auth'
import { navigateTo } from '../../router'
import type { Company } from '../../types/database'
import CompanyCard from '../common/CompanyCard.vue'

const featuredCompanies = ref<Company[]>([])
const otherCompanies = ref<Company[]>([])
const loading = ref(true)
const showLoginModal = ref(false)
const selectedCompany = ref<Company | null>(null)

const displayedOtherCompanies = computed(() => {
  if (isAuthenticated.value) {
    return otherCompanies.value
  }
  return otherCompanies.value.slice(0, 3)
})

onMounted(async () => {
  await loadCompanies()
})

async function loadCompanies() {
  loading.value = true
  try {
    const { data: boostedCompanyIds } = await supabase
      .from('visibility_boosts')
      .select('company_id')
      .eq('active', true)
      .gte('end_date', new Date().toISOString().split('T')[0])

    const boostedIds = boostedCompanyIds?.map(b => b.company_id) || []

    const { data: companies, error } = await supabase
      .from('companies')
      .select('*')
      .eq('producer_active', true)
      .eq('verified', true)

    if (error) throw error

    if (companies) {
      featuredCompanies.value = companies
        .filter(c => boostedIds.includes(c.id))
        .slice(0, 3)

      otherCompanies.value = companies
        .filter(c => !boostedIds.includes(c.id))
        .slice(0, 6)
    }
  } catch (error) {
    console.error('Error loading companies:', error)
  } finally {
    loading.value = false
  }
}

function handleCompanyClick(company: Company) {
  navigateTo({ name: 'company-detail', params: { id: company.id } })
}

function handleContact(company: Company) {
  if (!isAuthenticated.value) {
    selectedCompany.value = company
    showLoginModal.value = true
  } else {
    navigateTo({ name: 'company-detail', params: { id: company.id } })
  }
}

function handleViewMore() {
  if (!isAuthenticated.value) {
    showLoginModal.value = true
  } else {
    navigateTo({ name: 'pros-locaux' })
  }
}
</script>

<template>
  <div class="home-page">
    <section class="hero">
      <div class="hero-content">
        <h1 class="hero-title">
          Connectez-vous avec des<br />
          <span class="highlight">professionnels locaux</span>
        </h1>
        <p class="hero-subtitle">
          LocalLink facilite la mise en relation entre entreprises pour favoriser
          le circuit court et l'économie locale.
        </p>
        <div class="hero-actions">
          <button class="btn-primary-large" @click="navigateTo({ name: 'pros-locaux' })">
            Découvrir les pros locaux
          </button>
          <button v-if="!isAuthenticated" class="btn-secondary-large" @click="navigateTo({ name: 'login' })">
            Créer mon compte
          </button>
        </div>
      </div>
      <div class="hero-image">
        <img src="https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg" alt="Professionnels locaux" />
      </div>
    </section>

    <section class="features">
      <div class="container">
        <div class="features-grid">
          <div class="feature-item">
            <span class="feature-icon">🤝</span>
            <h3>Mise en relation directe</h3>
            <p>Connectez-vous facilement avec des producteurs et fournisseurs locaux vérifiés.</p>
          </div>
          <div class="feature-item">
            <span class="feature-icon">📋</span>
            <h3>Demandes de devis</h3>
            <p>Envoyez vos demandes à plusieurs professionnels en quelques clics.</p>
          </div>
          <div class="feature-item">
            <span class="feature-icon">✅</span>
            <h3>Entreprises vérifiées</h3>
            <p>Toutes les entreprises sont vérifiées et certifiées par nos soins.</p>
          </div>
          <div class="feature-item">
            <span class="feature-icon">🌱</span>
            <h3>Circuit court</h3>
            <p>Soutenez l'économie locale et réduisez votre empreinte carbone.</p>
          </div>
        </div>
      </div>
    </section>

    <section v-if="!loading && featuredCompanies.length > 0" class="featured-companies">
      <div class="container">
        <h2 class="section-title">Pros locaux mis en avant</h2>
        <p class="section-subtitle">Ils ont choisi d'augmenter leur visibilité</p>

        <div class="companies-grid">
          <CompanyCard
            v-for="company in featuredCompanies"
            :key="company.id"
            :company="company"
            :featured="true"
            @click="handleCompanyClick(company)"
            @contact="handleContact(company)"
          />
        </div>
      </div>
    </section>

    <section v-if="!loading" class="other-companies">
      <div class="container">
        <h2 class="section-title">Découvrez d'autres pros locaux</h2>

        <div class="companies-grid">
          <CompanyCard
            v-for="company in displayedOtherCompanies"
            :key="company.id"
            :company="company"
            @click="handleCompanyClick(company)"
            @contact="handleContact(company)"
          />
        </div>

        <div v-if="!isAuthenticated && otherCompanies.length > 3" class="view-more-container">
          <button class="btn-view-more" @click="handleViewMore">
            Voir plus de professionnels
          </button>
          <p class="login-hint">Inscrivez-vous pour accéder à tous les professionnels</p>
        </div>

        <div v-else-if="isAuthenticated" class="view-more-container">
          <button class="btn-view-more" @click="navigateTo({ name: 'pros-locaux' })">
            Voir tous les professionnels
          </button>
        </div>
      </div>
    </section>

    <div v-if="loading" class="loading-container">
      <div class="spinner"></div>
      <p>Chargement des entreprises...</p>
    </div>
  </div>
</template>

<style scoped>
.home-page {
  min-height: 100vh;
  background: #f9fafb;
}

.hero {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  color: white;
  padding: 80px 24px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 60px;
  align-items: center;
  max-width: 1400px;
  margin: 0 auto;
}

.hero-content {
  max-width: 600px;
}

.hero-title {
  font-size: 56px;
  font-weight: 800;
  line-height: 1.1;
  margin: 0 0 24px 0;
}

.highlight {
  color: #fbbf24;
}

.hero-subtitle {
  font-size: 20px;
  line-height: 1.6;
  margin: 0 0 32px 0;
  opacity: 0.95;
}

.hero-actions {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.btn-primary-large,
.btn-secondary-large {
  padding: 16px 32px;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary-large {
  background: white;
  color: #059669;
}

.btn-primary-large:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(255, 255, 255, 0.3);
}

.btn-secondary-large {
  background: transparent;
  color: white;
  border: 2px solid white;
}

.btn-secondary-large:hover {
  background: rgba(255, 255, 255, 0.1);
}

.hero-image {
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.hero-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.features {
  padding: 80px 24px;
  background: white;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 32px;
}

.feature-item {
  text-align: center;
}

.feature-icon {
  font-size: 48px;
  display: block;
  margin-bottom: 16px;
}

.feature-item h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.feature-item p {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
}

.featured-companies,
.other-companies {
  padding: 80px 24px;
}

.section-title {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 12px 0;
  text-align: center;
}

.section-subtitle {
  font-size: 18px;
  color: #6b7280;
  margin: 0 0 48px 0;
  text-align: center;
}

.companies-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
  margin-bottom: 48px;
}

.view-more-container {
  text-align: center;
}

.btn-view-more {
  padding: 14px 32px;
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

.login-hint {
  margin-top: 16px;
  color: #6b7280;
  font-size: 14px;
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

@media (max-width: 1024px) {
  .hero {
    grid-template-columns: 1fr;
    padding: 60px 24px;
    gap: 40px;
  }

  .hero-title {
    font-size: 42px;
  }

  .hero-image {
    height: 300px;
  }
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 36px;
  }

  .hero-subtitle {
    font-size: 18px;
  }

  .companies-grid {
    grid-template-columns: 1fr;
  }

  .section-title {
    font-size: 28px;
  }

  .features,
  .featured-companies,
  .other-companies {
    padding: 48px 16px;
  }
}
</style>
