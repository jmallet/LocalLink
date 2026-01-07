<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user, profile } from '../../stores/auth'
import type { QuoteRequest } from '../../types/database'
import IndividualDashboardLayout from '../dashboard/IndividualDashboardLayout.vue'

const router = useRouter()

const quotes = ref<QuoteRequest[]>([])
const loading = ref(true)

const stats = computed(() => {
  return {
    total: quotes.value.length,
    sent: quotes.value.filter(q => q.status === 'SENT').length,
    viewed: quotes.value.filter(q => q.status === 'VIEWED').length,
    responded: quotes.value.filter(q => q.status === 'RESPONDED').length,
    closed: quotes.value.filter(q => q.status === 'CLOSED').length
  }
})

const recentQuotes = computed(() => {
  return quotes.value.slice(0, 5)
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

function formatDate(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

function viewAllQuotes() {
  router.push({ name: 'individual-quotes' })
}

function createNewQuote() {
  router.push({ name: 'individual-new-quote' })
}

function viewQuoteDetail(quoteId: string) {
  router.push({ name: 'individual-quote-detail', params: { id: quoteId } })
}
</script>

<template>
  <IndividualDashboardLayout>
    <div class="dashboard-page">
      <div class="welcome-section">
        <h1 class="welcome-title">
          Bonjour, {{ profile?.first_name || 'cher utilisateur' }}
        </h1>
        <p class="welcome-subtitle">
          Voici un aperçu de vos demandes de devis
        </p>
      </div>

      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement de vos données...</p>
      </div>

      <template v-else>
        <div class="stats-grid">
          <div class="stat-card primary">
            <div class="stat-icon">📊</div>
            <div class="stat-content">
              <div class="stat-number">{{ stats.total }}</div>
              <div class="stat-label">Total des demandes</div>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">📤</div>
            <div class="stat-content">
              <div class="stat-number">{{ stats.sent }}</div>
              <div class="stat-label">Envoyées</div>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">👁️</div>
            <div class="stat-content">
              <div class="stat-number">{{ stats.viewed }}</div>
              <div class="stat-label">Vues</div>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">✅</div>
            <div class="stat-content">
              <div class="stat-number">{{ stats.responded }}</div>
              <div class="stat-label">Répondues</div>
            </div>
          </div>
        </div>

        <div class="quick-actions">
          <button class="action-btn primary" @click="createNewQuote">
            <span class="action-icon">+</span>
            Nouvelle demande de devis
          </button>
          <button class="action-btn secondary" @click="viewAllQuotes">
            <span class="action-icon">📋</span>
            Voir toutes mes demandes
          </button>
        </div>

        <div class="recent-section">
          <div class="section-header">
            <h2 class="section-title">Demandes récentes</h2>
            <button class="btn-link" @click="viewAllQuotes">
              Voir tout →
            </button>
          </div>

          <div v-if="recentQuotes.length === 0" class="empty-state">
            <span class="empty-icon">📋</span>
            <h3>Aucune demande de devis</h3>
            <p>Commencez par créer votre première demande</p>
            <button class="btn-primary" @click="createNewQuote">
              Créer une demande
            </button>
          </div>

          <div v-else class="quotes-list">
            <div
              v-for="quote in recentQuotes"
              :key="quote.id"
              class="quote-item"
              @click="viewQuoteDetail(quote.id)"
            >
              <div class="quote-main">
                <div class="quote-header">
                  <h3 class="quote-title">{{ quote.title }}</h3>
                  <span class="status-badge" :class="getStatusBadgeClass(quote.status)">
                    {{ getStatusLabel(quote.status) }}
                  </span>
                </div>
                <p class="quote-date">{{ formatDate(quote.created_at) }}</p>
              </div>
              <button class="btn-view" @click.stop="viewQuoteDetail(quote.id)">
                Voir →
              </button>
            </div>
          </div>
        </div>
      </template>
    </div>
  </IndividualDashboardLayout>
</template>

<style scoped>
.dashboard-page {
  max-width: 1400px;
  margin: 0 auto;
}

.welcome-section {
  margin-bottom: 32px;
}

.welcome-title {
  font-size: 32px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 8px 0;
}

.welcome-subtitle {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
}

.stat-card {
  background: white;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  display: flex;
  align-items: center;
  gap: 16px;
  transition: all 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.stat-card.primary {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  color: white;
}

.stat-icon {
  font-size: 32px;
}

.stat-content {
  flex: 1;
}

.stat-number {
  font-size: 36px;
  font-weight: 800;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-card.primary .stat-number {
  color: white;
}

.stat-card:not(.primary) .stat-number {
  color: #059669;
}

.stat-label {
  font-size: 14px;
  font-weight: 500;
  opacity: 0.9;
}

.stat-card.primary .stat-label {
  color: rgba(255, 255, 255, 0.95);
}

.stat-card:not(.primary) .stat-label {
  color: #6b7280;
}

.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 16px;
  margin-bottom: 32px;
}

.action-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 20px 24px;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.action-btn.primary {
  background: #059669;
  color: white;
}

.action-btn.primary:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

.action-btn.secondary {
  background: white;
  color: #059669;
  border: 2px solid #059669;
}

.action-btn.secondary:hover {
  background: #ecfdf5;
  transform: translateY(-2px);
}

.action-icon {
  font-size: 20px;
  line-height: 1;
}

.recent-section {
  background: white;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-title {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.btn-link {
  background: none;
  border: none;
  color: #059669;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-link:hover {
  color: #047857;
}

.empty-state {
  text-align: center;
  padding: 60px 24px;
}

.empty-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 24px;
}

.empty-state h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.empty-state p {
  font-size: 14px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-primary {
  padding: 12px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #047857;
  transform: translateY(-2px);
}

.quotes-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.quote-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.quote-item:hover {
  background: #f3f4f6;
  transform: translateX(4px);
}

.quote-main {
  flex: 1;
  min-width: 0;
}

.quote-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 4px;
}

.quote-title {
  font-size: 15px;
  font-weight: 600;
  color: #111827;
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.status-badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  flex-shrink: 0;
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
  margin: 0;
}

.btn-view {
  padding: 8px 16px;
  background: white;
  color: #059669;
  border: 1px solid #d1fae5;
  border-radius: 6px;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.btn-view:hover {
  background: #d1fae5;
  border-color: #059669;
}

@media (max-width: 768px) {
  .welcome-title {
    font-size: 24px;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .quick-actions {
    grid-template-columns: 1fr;
  }

  .quote-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .quote-item {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }

  .btn-view {
    width: 100%;
    justify-content: center;
  }
}
</style>
