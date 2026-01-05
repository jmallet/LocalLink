<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import type { QuoteRequest, Company } from '../../types/database'

const router = useRouter()

interface QuoteWithCompany extends QuoteRequest {
  target_company?: Company
}

const quotes = ref<QuoteWithCompany[]>([])
const loading = ref(true)

const quotesByStatus = computed(() => {
  return {
    sent: quotes.value.filter(q => q.status === 'SENT'),
    viewed: quotes.value.filter(q => q.status === 'VIEWED'),
    responded: quotes.value.filter(q => q.status === 'RESPONDED'),
    closed: quotes.value.filter(q => q.status === 'CLOSED')
  }
})

onMounted(async () => {
  await loadQuotes()
})

async function loadQuotes() {
  if (!user.value) return

  loading.value = true
  try {
    const { data, error } = await supabase
      .from('quote_requests')
      .select(`
        *,
        target_company:companies!quote_requests_target_company_id_fkey(*)
      `)
      .eq('requester_id', user.value.id)
      .order('created_at', { ascending: false })

    if (error) throw error

    quotes.value = data || []
  } catch (error) {
    console.error('Error loading quotes:', error)
  } finally {
    loading.value = false
  }
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

function viewQuoteDetail(quoteId: string) {
  router.push({ name: 'quote-detail-particulier', params: { id: quoteId } })
}

function createNewQuote() {
  router.push({ name: 'new-quote-particulier' })
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  })
}
</script>

<template>
  <div class="dashboard-page">
    <div class="container">
      <div class="header">
        <div class="header-content">
          <h1>Mon espace particulier</h1>
          <p>Gérez vos demandes de devis</p>
        </div>
        <button class="btn-primary" @click="createNewQuote">
          <span class="btn-icon">+</span>
          Nouvelle demande
        </button>
      </div>

      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="quotes.length === 0" class="empty-state">
        <span class="empty-icon">📋</span>
        <h2>Aucune demande de devis</h2>
        <p>Commencez par créer votre première demande</p>
        <button class="btn-primary-large" @click="createNewQuote">
          Créer une demande
        </button>
      </div>

      <div v-else class="quotes-container">
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-number">{{ quotesByStatus.sent.length }}</div>
            <div class="stat-label">Envoyées</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">{{ quotesByStatus.viewed.length }}</div>
            <div class="stat-label">Vues</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">{{ quotesByStatus.responded.length }}</div>
            <div class="stat-label">Répondues</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">{{ quotesByStatus.closed.length }}</div>
            <div class="stat-label">Clôturées</div>
          </div>
        </div>

        <div class="quotes-list">
          <h2>Toutes mes demandes</h2>

          <div class="quote-cards">
            <div
              v-for="quote in quotes"
              :key="quote.id"
              class="quote-card"
              @click="viewQuoteDetail(quote.id)"
            >
              <div class="quote-header">
                <span class="status-badge" :class="getStatusBadgeClass(quote.status)">
                  {{ getStatusLabel(quote.status) }}
                </span>
                <span class="quote-date">{{ formatDate(quote.created_at) }}</span>
              </div>

              <h3 class="quote-title">{{ quote.title }}</h3>

              <div class="quote-company">
                <span class="company-icon">🏢</span>
                <span>{{ quote.target_company?.name || quote.target_company?.company_name || 'Entreprise' }}</span>
              </div>

              <p v-if="quote.description" class="quote-description">
                {{ quote.description.substring(0, 150) }}{{ quote.description.length > 150 ? '...' : '' }}
              </p>

              <div class="quote-footer">
                <button class="btn-view" @click.stop="viewQuoteDetail(quote.id)">
                  Voir détails →
                </button>
              </div>
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
  align-items: center;
  margin-bottom: 40px;
}

.header-content h1 {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 8px 0;
}

.header-content p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.btn-primary {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 28px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

.btn-icon {
  font-size: 20px;
  line-height: 1;
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
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.empty-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 24px;
}

.empty-state h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-primary-large {
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

.btn-primary-large:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

.quotes-container {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.stat-card {
  background: white;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  text-align: center;
  transition: all 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.stat-number {
  font-size: 48px;
  font-weight: 800;
  color: #059669;
  line-height: 1;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #6b7280;
  font-weight: 600;
}

.quotes-list h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 24px 0;
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

.quote-company {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  font-size: 14px;
  color: #6b7280;
}

.company-icon {
  font-size: 16px;
}

.quote-description {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.quote-footer {
  display: flex;
  justify-content: flex-end;
}

.btn-view {
  padding: 8px 16px;
  background: #f3f4f6;
  color: #059669;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-view:hover {
  background: #d1fae5;
}

@media (max-width: 768px) {
  .header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .header-content h1 {
    font-size: 28px;
  }

  .quote-cards {
    grid-template-columns: 1fr;
  }
}
</style>
