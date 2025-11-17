<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { Company } from '../../types/database'

interface QuoteWithDetails {
  id: string
  quote_id: string
  company_id: string
  status: string
  viewed_at: string | null
  responded_at: string | null
  created_at: string
  quote_request?: {
    title: string
    description: string
    budget: number | null
    delivery_date: string | null
    created_at: string
    requester_company?: Company
  }
}

const company = ref<Company | null>(null)
const quotes = ref<QuoteWithDetails[]>([])
const loading = ref(true)
const selectedQuote = ref<QuoteWithDetails | null>(null)
const showDetailModal = ref(false)

const statusLabels: Record<string, { label: string; color: string }> = {
  pending: { label: 'En attente', color: '#f59e0b' },
  viewed: { label: 'Vue', color: '#3b82f6' },
  responded: { label: 'Répondue', color: '#10b981' },
  declined: { label: 'Refusée', color: '#ef4444' }
}

const filteredQuotes = computed(() => {
  return quotes.value
})

onMounted(async () => {
  await loadData()
})

async function loadData() {
  loading.value = true
  try {
    const { data: companyData } = await supabase
      .from('companies')
      .select('*')
      .eq('user_id', user.value?.id)
      .maybeSingle()

    company.value = companyData

    if (companyData) {
      const { data: quotesData } = await supabase
        .from('quote_recipients')
        .select(`
          *,
          quote_request:quote_requests!inner (
            title,
            description,
            budget,
            delivery_date,
            created_at,
            requester_company:companies!quote_requests_company_id_fkey (
              id,
              company_name,
              city,
              logo_url,
              phone,
              email
            )
          )
        `)
        .eq('company_id', companyData.id)
        .order('created_at', { ascending: false })

      quotes.value = quotesData || []
    }
  } catch (error) {
    console.error('Error loading quotes:', error)
  } finally {
    loading.value = false
  }
}

function openQuoteDetail(quote: QuoteWithDetails) {
  selectedQuote.value = quote
  showDetailModal.value = true

  if (quote.status === 'pending') {
    markAsViewed(quote)
  }
}

function closeDetailModal() {
  showDetailModal.value = false
  selectedQuote.value = null
}

async function markAsViewed(quote: QuoteWithDetails) {
  try {
    await supabase
      .from('quote_recipients')
      .update({ status: 'viewed', viewed_at: new Date().toISOString() })
      .eq('id', quote.id)

    await loadData()
  } catch (error) {
    console.error('Error marking as viewed:', error)
  }
}

async function updateStatus(quoteId: string, status: string) {
  try {
    await supabase
      .from('quote_recipients')
      .update({ status, responded_at: new Date().toISOString() })
      .eq('id', quoteId)

    await loadData()
    closeDetailModal()
  } catch (error) {
    console.error('Error updating status:', error)
  }
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric'
  })
}

function getTimeAgo(dateString: string) {
  const date = new Date(dateString)
  const now = new Date()
  const diffInMs = now.getTime() - date.getTime()
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))

  if (diffInDays === 0) return "Aujourd'hui"
  if (diffInDays === 1) return 'Hier'
  if (diffInDays < 7) return `Il y a ${diffInDays} jours`
  if (diffInDays < 30) return `Il y a ${Math.floor(diffInDays / 7)} semaines`
  return `Il y a ${Math.floor(diffInDays / 30)} mois`
}
</script>

<template>
  <DashboardLayout>
    <div class="quotes-page">
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="!company" class="empty-state">
        <span class="empty-icon">🏢</span>
        <h2>Profil entreprise requis</h2>
        <p>Vous devez d'abord créer votre profil entreprise.</p>
      </div>

      <div v-else class="quotes-content">
        <div class="quotes-header">
          <div>
            <h2 class="quotes-title">Demandes de devis reçues</h2>
            <p class="quotes-subtitle">{{ quotes.length }} demande(s)</p>
          </div>
        </div>

        <div v-if="quotes.length === 0" class="empty-quotes">
          <span class="empty-icon">📋</span>
          <h3>Aucune demande</h3>
          <p>Vous n'avez pas encore reçu de demande de devis.</p>
          <p class="help-text">
            Les acheteurs peuvent vous envoyer des demandes de devis depuis votre fiche entreprise.
          </p>
        </div>

        <div v-else class="quotes-list">
          <div
            v-for="quote in filteredQuotes"
            :key="quote.id"
            class="quote-card"
            @click="openQuoteDetail(quote)"
          >
            <div class="quote-header">
              <div class="company-info">
                <div class="company-logo">
                  <img
                    v-if="quote.quote_request?.requester_company?.logo_url"
                    :src="quote.quote_request.requester_company.logo_url"
                    :alt="quote.quote_request.requester_company.company_name"
                  />
                  <span v-else class="logo-placeholder">🏢</span>
                </div>
                <div>
                  <h3 class="company-name">
                    {{ quote.quote_request?.requester_company?.company_name || 'Entreprise' }}
                  </h3>
                  <p class="company-location">
                    {{ quote.quote_request?.requester_company?.city || 'Localisation inconnue' }}
                  </p>
                </div>
              </div>
              <span
                class="status-badge"
                :style="{ background: statusLabels[quote.status]?.color + '20', color: statusLabels[quote.status]?.color }"
              >
                {{ statusLabels[quote.status]?.label || quote.status }}
              </span>
            </div>

            <div class="quote-content">
              <h4 class="quote-title">{{ quote.quote_request?.title }}</h4>
              <p class="quote-description">{{ quote.quote_request?.description }}</p>
            </div>

            <div class="quote-footer">
              <div class="quote-meta">
                <span v-if="quote.quote_request?.budget" class="meta-item">
                  💰 Budget: {{ quote.quote_request.budget.toLocaleString() }}€
                </span>
                <span v-if="quote.quote_request?.delivery_date" class="meta-item">
                  📅 Livraison: {{ formatDate(quote.quote_request.delivery_date) }}
                </span>
              </div>
              <span class="quote-date">{{ getTimeAgo(quote.created_at) }}</span>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showDetailModal && selectedQuote" class="modal-overlay" @click="closeDetailModal">
        <div class="modal-content detail-modal" @click.stop>
          <div class="modal-header">
            <h2>Détail de la demande</h2>
            <button class="close-btn" @click="closeDetailModal">✕</button>
          </div>

          <div class="modal-body">
            <div class="detail-section">
              <h3>Entreprise demandeuse</h3>
              <div class="company-detail">
                <div class="company-logo-large">
                  <img
                    v-if="selectedQuote.quote_request?.requester_company?.logo_url"
                    :src="selectedQuote.quote_request.requester_company.logo_url"
                    :alt="selectedQuote.quote_request.requester_company.company_name"
                  />
                  <span v-else class="logo-placeholder">🏢</span>
                </div>
                <div>
                  <h4>{{ selectedQuote.quote_request?.requester_company?.company_name }}</h4>
                  <p>{{ selectedQuote.quote_request?.requester_company?.city }}</p>
                  <p v-if="selectedQuote.quote_request?.requester_company?.phone">
                    📞 {{ selectedQuote.quote_request.requester_company.phone }}
                  </p>
                  <p v-if="selectedQuote.quote_request?.requester_company?.email">
                    ✉️ {{ selectedQuote.quote_request.requester_company.email }}
                  </p>
                </div>
              </div>
            </div>

            <div class="detail-section">
              <h3>Demande</h3>
              <h4 class="request-title">{{ selectedQuote.quote_request?.title }}</h4>
              <p class="request-description">{{ selectedQuote.quote_request?.description }}</p>
            </div>

            <div class="detail-section">
              <h3>Informations</h3>
              <div class="info-grid">
                <div v-if="selectedQuote.quote_request?.budget" class="info-item">
                  <span class="info-label">Budget indicatif</span>
                  <span class="info-value">{{ selectedQuote.quote_request.budget.toLocaleString() }}€</span>
                </div>
                <div v-if="selectedQuote.quote_request?.delivery_date" class="info-item">
                  <span class="info-label">Date de livraison souhaitée</span>
                  <span class="info-value">{{ formatDate(selectedQuote.quote_request.delivery_date) }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Reçue le</span>
                  <span class="info-value">{{ formatDate(selectedQuote.created_at) }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Statut</span>
                  <span
                    class="info-value status-text"
                    :style="{ color: statusLabels[selectedQuote.status]?.color }"
                  >
                    {{ statusLabels[selectedQuote.status]?.label }}
                  </span>
                </div>
              </div>
            </div>

            <div v-if="selectedQuote.status !== 'responded' && selectedQuote.status !== 'declined'" class="actions-section">
              <h3>Actions</h3>
              <div class="action-buttons">
                <button class="btn-respond" @click="updateStatus(selectedQuote.id, 'responded')">
                  ✓ Marquer comme répondue
                </button>
                <button class="btn-decline" @click="updateStatus(selectedQuote.id, 'declined')">
                  ✕ Refuser
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.quotes-page {
  max-width: 1200px;
  margin: 0 auto;
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

.empty-state h2,
.empty-quotes h3 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.quotes-header {
  margin-bottom: 32px;
}

.quotes-title {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 4px 0;
}

.quotes-subtitle {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.empty-quotes {
  text-align: center;
  padding: 80px 24px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.empty-quotes p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 8px 0;
}

.help-text {
  font-size: 14px;
  color: #9ca3af;
  font-style: italic;
}

.quotes-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.quote-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  cursor: pointer;
  transition: all 0.2s;
}

.quote-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.quote-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.company-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.company-logo {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  overflow: hidden;
  background: #f3f4f6;
  display: flex;
  align-items: center;
  justify-content: center;
}

.company-logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.logo-placeholder {
  font-size: 24px;
}

.company-name {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.company-location {
  font-size: 13px;
  color: #6b7280;
  margin: 0;
}

.status-badge {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
}

.quote-content {
  margin-bottom: 16px;
}

.quote-title {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.quote-description {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.quote-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 16px;
  border-top: 1px solid #e5e7eb;
}

.quote-meta {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.meta-item {
  font-size: 13px;
  color: #6b7280;
}

.quote-date {
  font-size: 13px;
  color: #9ca3af;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
}

.modal-content {
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 700px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
}

.modal-header {
  padding: 24px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  color: #6b7280;
  cursor: pointer;
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 8px;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #f3f4f6;
  color: #111827;
}

.modal-body {
  padding: 24px;
}

.detail-section {
  margin-bottom: 32px;
}

.detail-section h3 {
  font-size: 14px;
  font-weight: 700;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin: 0 0 16px 0;
}

.company-detail {
  display: flex;
  align-items: start;
  gap: 16px;
  padding: 16px;
  background: #f9fafb;
  border-radius: 12px;
}

.company-logo-large {
  width: 64px;
  height: 64px;
  border-radius: 8px;
  overflow: hidden;
  background: white;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.company-logo-large img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.company-detail h4 {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 4px 0;
}

.company-detail p {
  font-size: 14px;
  color: #6b7280;
  margin: 4px 0;
}

.request-title {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.request-description {
  font-size: 15px;
  color: #374151;
  line-height: 1.7;
  margin: 0;
  white-space: pre-wrap;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 13px;
  color: #6b7280;
}

.info-value {
  font-size: 15px;
  font-weight: 600;
  color: #111827;
}

.status-text {
  font-weight: 700;
}

.actions-section h3 {
  font-size: 14px;
  font-weight: 700;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin: 0 0 16px 0;
}

.action-buttons {
  display: flex;
  gap: 12px;
}

.btn-respond,
.btn-decline {
  flex: 1;
  padding: 14px 24px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-respond {
  background: #059669;
  color: white;
}

.btn-respond:hover {
  background: #047857;
}

.btn-decline {
  background: #fee2e2;
  color: #991b1b;
}

.btn-decline:hover {
  background: #fecaca;
}

@media (max-width: 768px) {
  .quote-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .quote-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .action-buttons {
    flex-direction: column;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }
}
</style>
