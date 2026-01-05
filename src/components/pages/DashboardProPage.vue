<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user, companies, currentCompany, userCompanies, setCurrentCompany } from '../../stores/auth'
import type { QuoteRequest, UserCompany, Company } from '../../types/database'

const router = useRouter()

const activeTab = ref<'acheter' | 'vendre'>('acheter')
const myQuotes = ref<QuoteRequest[]>([])
const receivedQuotes = ref<QuoteRequest[]>([])
const loading = ref(true)

const currentUserCompany = computed(() => {
  if (!currentCompany.value) return null
  return userCompanies.value.find(uc => uc.company_id === currentCompany.value!.id)
})

const isAcheteur = computed(() => currentUserCompany.value?.is_acheteur_pro || false)
const isProducteur = computed(() => currentUserCompany.value?.is_producteur || false)

watch(currentCompany, () => {
  loadData()
})

onMounted(async () => {
  if (companies.value.length === 0) {
    router.push({ name: 'claim-company' })
    return
  }

  await loadData()
})

async function loadData() {
  if (!currentCompany.value || !user.value) return

  loading.value = true
  try {
    if (isAcheteur.value) {
      const { data: quotesData } = await supabase
        .from('quote_requests')
        .select(`
          *,
          target_company:companies!quote_requests_target_company_id_fkey(*)
        `)
        .eq('requester_id', user.value.id)
        .eq('requester_type', 'ACHETEUR_PRO')
        .order('created_at', { ascending: false })

      myQuotes.value = quotesData || []
    }

    if (isProducteur.value) {
      const { data: receivedData } = await supabase
        .from('quote_requests')
        .select(`
          *,
          requester:users!quote_requests_requester_id_fkey(email, first_name, last_name)
        `)
        .eq('target_company_id', currentCompany.value.id)
        .order('created_at', { ascending: false })

      receivedQuotes.value = receivedData || []
    }
  } catch (error) {
    console.error('Error loading quotes:', error)
  } finally {
    loading.value = false
  }
}

function handleCompanyChange(companyId: string) {
  setCurrentCompany(companyId)
}

function getStatusBadgeClass(status?: string) {
  switch (status) {
    case 'SENT':
      return 'status-sent'
    case 'VIEWED':
      return 'status-viewed'
    case 'RESPONDED':
      return 'status-responded'
    case 'CLOSED':
      return 'status-closed'
    default:
      return 'status-sent'
  }
}

function getStatusLabel(status?: string) {
  switch (status) {
    case 'SENT':
      return 'Envoyée'
    case 'VIEWED':
      return 'Vue'
    case 'RESPONDED':
      return 'Répondue'
    case 'CLOSED':
      return 'Clôturée'
    default:
      return 'Envoyée'
  }
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function createNewQuote() {
  router.push({ name: 'new-quote-pro' })
}

function editProducerProfile() {
  router.push({ name: 'producer-profile' })
}

function manageProducts() {
  router.push({ name: 'producer-products' })
}

function viewQuoteDetail(quoteId: string) {
  router.push({ name: 'quote-detail-pro', params: { id: quoteId } })
}

function claimNewCompany() {
  router.push({ name: 'claim-company' })
}
</script>

<template>
  <div class="dashboard-page">
    <div class="container">
      <div class="header">
        <div class="header-left">
          <h1>Espace professionnel</h1>
          <div v-if="companies.length > 1" class="company-selector">
            <label>Société active :</label>
            <select
              :value="currentCompany?.id"
              @change="handleCompanyChange(($event.target as HTMLSelectElement).value)"
            >
              <option v-for="company in companies" :key="company.id" :value="company.id">
                {{ company.name || company.company_name }}
              </option>
            </select>
          </div>
          <div v-else-if="currentCompany" class="current-company">
            <span class="company-icon">🏢</span>
            <span class="company-name">{{ currentCompany.name || currentCompany.company_name }}</span>
          </div>
        </div>

        <button class="btn-secondary" @click="claimNewCompany">
          + Revendiquer une société
        </button>
      </div>

      <div class="tabs">
        <button
          v-if="isAcheteur"
          class="tab"
          :class="{ active: activeTab === 'acheter' }"
          @click="activeTab = 'acheter'"
        >
          <span class="tab-icon">🛒</span>
          Acheter
        </button>

        <button
          v-if="isProducteur"
          class="tab"
          :class="{ active: activeTab === 'vendre' }"
          @click="activeTab = 'vendre'"
        >
          <span class="tab-icon">📦</span>
          Vendre
        </button>
      </div>

      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else>
        <div v-if="activeTab === 'acheter' && isAcheteur" class="tab-content">
          <div class="section-header">
            <h2>Mes demandes envoyées</h2>
            <button class="btn-primary" @click="createNewQuote">
              + Nouvelle demande
            </button>
          </div>

          <div v-if="myQuotes.length === 0" class="empty-state">
            <span class="empty-icon">📋</span>
            <p>Aucune demande envoyée</p>
            <button class="btn-primary-large" @click="createNewQuote">
              Créer une demande
            </button>
          </div>

          <div v-else class="quote-cards">
            <div
              v-for="quote in myQuotes"
              :key="quote.id"
              class="quote-card"
              @click="viewQuoteDetail(quote.id)"
            >
              <div class="quote-header">
                <span class="status-badge" :class="getStatusBadgeClass(quote.new_status)">
                  {{ getStatusLabel(quote.new_status) }}
                </span>
                <span class="quote-date">{{ formatDate(quote.created_at) }}</span>
              </div>

              <h3 class="quote-title">{{ quote.title }}</h3>

              <div class="quote-company">
                <span class="company-icon">🏢</span>
                <span>{{ quote.target_company?.name || quote.target_company?.company_name }}</span>
              </div>

              <p v-if="quote.description" class="quote-description">
                {{ quote.description.substring(0, 100) }}{{ quote.description.length > 100 ? '...' : '' }}
              </p>
            </div>
          </div>
        </div>

        <div v-if="activeTab === 'vendre' && isProducteur" class="tab-content">
          <div class="section-header">
            <h2>Demandes reçues</h2>
            <div class="actions-group">
              <button class="btn-secondary" @click="manageProducts">
                📦 Mes produits
              </button>
              <button class="btn-secondary" @click="editProducerProfile">
                ✏️ Ma fiche
              </button>
            </div>
          </div>

          <div v-if="receivedQuotes.length === 0" class="empty-state">
            <span class="empty-icon">📬</span>
            <p>Aucune demande reçue</p>
            <button class="btn-secondary-large" @click="editProducerProfile">
              Compléter ma fiche producteur
            </button>
          </div>

          <div v-else class="quote-cards">
            <div
              v-for="quote in receivedQuotes"
              :key="quote.id"
              class="quote-card received"
              @click="viewQuoteDetail(quote.id)"
            >
              <div class="quote-header">
                <span class="status-badge" :class="getStatusBadgeClass(quote.new_status)">
                  {{ getStatusLabel(quote.new_status) }}
                </span>
                <span class="quote-date">{{ formatDate(quote.created_at) }}</span>
              </div>

              <h3 class="quote-title">{{ quote.title }}</h3>

              <div class="quote-requester">
                <span class="requester-icon">👤</span>
                <span>
                  {{ quote.requester_type === 'PARTICULIER' ? 'Particulier' : 'Acheteur pro' }}
                </span>
              </div>

              <p v-if="quote.description" class="quote-description">
                {{ quote.description.substring(0, 100) }}{{ quote.description.length > 100 ? '...' : '' }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dashboard-page {
  min-height: 100vh;
  background: #f9fafb;
  padding: 40px 24px;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
  gap: 24px;
}

.header-left h1 {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
}

.company-selector {
  display: flex;
  align-items: center;
  gap: 12px;
}

.company-selector label {
  font-size: 14px;
  font-weight: 600;
  color: #6b7280;
}

.company-selector select {
  padding: 10px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  color: #111827;
  background: white;
  cursor: pointer;
}

.current-company {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
  background: #f9fafb;
  border-radius: 8px;
}

.company-icon {
  font-size: 20px;
}

.company-name {
  font-size: 16px;
  font-weight: 600;
  color: #111827;
}

.btn-secondary {
  padding: 12px 24px;
  background: white;
  color: #374151;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-secondary:hover {
  background: #f9fafb;
  border-color: #9ca3af;
}

.tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 32px;
  border-bottom: 2px solid #e5e7eb;
}

.tab {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px 24px;
  background: transparent;
  border: none;
  border-bottom: 3px solid transparent;
  font-size: 16px;
  font-weight: 600;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: -2px;
}

.tab:hover {
  color: #059669;
}

.tab.active {
  color: #059669;
  border-bottom-color: #059669;
}

.tab-icon {
  font-size: 20px;
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

.tab-content {
  animation: fadeIn 0.3s;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.section-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.actions-group {
  display: flex;
  gap: 12px;
}

.btn-primary {
  padding: 12px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #047857;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);
}

.empty-state {
  text-align: center;
  padding: 80px 24px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.empty-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-primary-large,
.btn-secondary-large {
  padding: 14px 32px;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary-large {
  background: #059669;
  color: white;
}

.btn-primary-large:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

.btn-secondary-large {
  background: white;
  color: #374151;
  border: 2px solid #e5e7eb;
}

.btn-secondary-large:hover {
  background: #f9fafb;
  border-color: #9ca3af;
}

.quote-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 20px;
}

.quote-card {
  background: white;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  cursor: pointer;
  transition: all 0.2s;
}

.quote-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.quote-card.received {
  border-left: 4px solid #059669;
}

.quote-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.status-badge {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
}

.status-badge.status-sent {
  background: #dbeafe;
  color: #1e40af;
}

.status-badge.status-viewed {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.status-responded {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.status-closed {
  background: #f3f4f6;
  color: #6b7280;
}

.quote-date {
  font-size: 13px;
  color: #9ca3af;
}

.quote-title {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.quote-company,
.quote-requester {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  font-size: 14px;
  color: #6b7280;
}

.requester-icon {
  font-size: 16px;
}

.quote-description {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
}

@media (max-width: 768px) {
  .header {
    flex-direction: column;
    align-items: flex-start;
  }

  .header-left h1 {
    font-size: 28px;
  }

  .section-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .actions-group {
    width: 100%;
    flex-direction: column;
  }

  .quote-cards {
    grid-template-columns: 1fr;
  }
}
</style>
