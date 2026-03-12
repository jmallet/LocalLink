<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import AdminLayout from '../admin/AdminLayout.vue'

interface QuoteRequest {
  id: string
  requester_id: string
  requester_type: string
  target_company_id: string
  title: string
  description: string | null
  volume_estimated: string | null
  frequency: string | null
  location: string | null
  budget_range: string | null
  status: string
  admin_approved: boolean
  created_at: string
  updated_at: string
  requester?: any
  target_company?: any
  clarifications_count?: number
  proposals_count?: number
  accepted_proposals_count?: number
  lead_access?: any
}

interface QuoteClarification {
  id: string
  quote_request_id: string
  producer_company_id: string
  question: string
  answer: string | null
  created_at: string
  answered_at: string | null
  company?: any
}

interface QuoteProposal {
  id: string
  quote_request_id: string
  producer_company_id: string
  proposed_amount: number | null
  price_min: number | null
  price_max: number | null
  proposal_message: string | null
  delivery_time: string | null
  status: string
  created_at: string
  accepted_at: string | null
  rejected_at: string | null
  rejection_reason: string | null
  company?: any
}

const quotes = ref<QuoteRequest[]>([])
const quoteClarifications = ref<Record<string, QuoteClarification[]>>({})
const quoteProposals = ref<Record<string, QuoteProposal[]>>({})
const loading = ref(true)
const selectedQuote = ref<QuoteRequest | null>(null)
const clarifications = ref<QuoteClarification[]>([])
const proposals = ref<QuoteProposal[]>([])
const loadingDetails = ref(false)
const showDetailsModal = ref(false)
const filterStatus = ref<'all' | 'pending' | 'waiting_for_info' | 'responded' | 'accepted' | 'sold' | 'closed'>('all')
const message = ref({ type: '', text: '' })

const filteredQuotes = computed(() => {
  if (filterStatus.value === 'all') return quotes.value

  if (filterStatus.value === 'sold') {
    return quotes.value.filter(q => q.lead_access !== null)
  }

  const statusMap: Record<string, string> = {
    pending: 'PENDING',
    waiting_for_info: 'WAITING_FOR_INFO',
    responded: 'RESPONDED',
    accepted: 'ACCEPTED',
    closed: 'CLOSED'
  }

  return quotes.value.filter(q => q.status === statusMap[filterStatus.value] && !q.lead_access)
})

const statusCounts = computed(() => ({
  all: quotes.value.length,
  pending: quotes.value.filter(q => q.status === 'PENDING' && !q.lead_access).length,
  waiting_for_info: quotes.value.filter(q => q.status === 'WAITING_FOR_INFO' && !q.lead_access).length,
  responded: quotes.value.filter(q => q.status === 'RESPONDED' && !q.lead_access).length,
  accepted: quotes.value.filter(q => q.status === 'ACCEPTED' && !q.lead_access).length,
  sold: quotes.value.filter(q => q.lead_access !== null).length,
  closed: quotes.value.filter(q => q.status === 'CLOSED' && !q.lead_access).length
}))

onMounted(async () => {
  await loadQuotes()
})

async function loadQuotes() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('quote_requests')
      .select(`
        *,
        requester:profiles!quote_requests_requester_id_profiles_fkey(user_id, first_name, last_name, user_type),
        target_company:companies!quote_requests_target_company_id_fkey(id, name, city)
      `)
      .eq('admin_approved', true)
      .order('updated_at', { ascending: false })

    if (error) throw error

    const quotesData = data || []

    for (const quote of quotesData) {
      const [clarificationsRes, proposalsRes, leadAccessRes] = await Promise.all([
        supabase
          .from('quote_clarifications')
          .select(`
            *,
            company:companies!quote_clarifications_producer_company_id_fkey(id, name)
          `)
          .eq('quote_request_id', quote.id)
          .order('created_at', { ascending: false }),
        supabase
          .from('quote_proposals')
          .select(`
            *,
            company:companies!quote_proposals_producer_company_id_fkey(id, name, city)
          `)
          .eq('quote_request_id', quote.id)
          .order('created_at', { ascending: false }),
        supabase
          .from('lead_accesses')
          .select('*')
          .eq('quote_request_id', quote.id)
          .maybeSingle()
      ])

      if (clarificationsRes.error) throw clarificationsRes.error
      if (proposalsRes.error) throw proposalsRes.error
      if (leadAccessRes.error) throw leadAccessRes.error

      quote.clarifications_count = clarificationsRes.data?.length || 0
      quote.proposals_count = proposalsRes.data?.length || 0
      quote.accepted_proposals_count = proposalsRes.data?.filter((p: any) => p.status === 'ACCEPTED').length || 0
      quote.lead_access = leadAccessRes.data

      quoteClarifications.value[quote.id] = clarificationsRes.data || []
      quoteProposals.value[quote.id] = proposalsRes.data || []
    }

    quotes.value = quotesData
  } catch (error) {
    console.error('Error loading quotes:', error)
    showMessage('error', 'Erreur lors du chargement des devis')
  } finally {
    loading.value = false
  }
}

async function viewDetails(quote: QuoteRequest) {
  selectedQuote.value = quote
  showDetailsModal.value = true
  loadingDetails.value = true
  clarifications.value = []
  proposals.value = []

  try {
    const [clarificationsRes, proposalsRes] = await Promise.all([
      supabase
        .from('quote_clarifications')
        .select('*')
        .eq('quote_request_id', quote.id)
        .order('created_at', { ascending: true }),
      supabase
        .from('quote_proposals')
        .select(`
          *,
          company:companies!quote_proposals_producer_company_id_fkey(id, name, city)
        `)
        .eq('quote_request_id', quote.id)
        .order('created_at', { ascending: false })
    ])

    if (clarificationsRes.error) throw clarificationsRes.error
    if (proposalsRes.error) throw proposalsRes.error

    clarifications.value = clarificationsRes.data || []
    proposals.value = proposalsRes.data || []
  } catch (error) {
    console.error('Error loading quote details:', error)
    showMessage('error', 'Erreur lors du chargement des détails')
  } finally {
    loadingDetails.value = false
  }
}

function showMessage(type: string, text: string) {
  message.value = { type, text }
  setTimeout(() => {
    message.value = { type: '', text: '' }
  }, 5000)
}

function getStatusBadge(quote: QuoteRequest) {
  if (quote.lead_access) {
    return { label: 'Lead vendu', class: 'sold' }
  }

  switch (quote.status) {
    case 'PENDING':
      return { label: 'En discussion', class: 'pending' }
    case 'WAITING_FOR_INFO':
      return { label: 'En attente d\'info', class: 'waiting' }
    case 'RESPONDED':
      return { label: 'Propositions reçues', class: 'responded' }
    case 'ACCEPTED':
      return { label: 'Proposition acceptée', class: 'accepted' }
    case 'CLOSED':
      return { label: 'Clôturé', class: 'closed' }
    default:
      return { label: quote.status, class: 'default' }
  }
}

function getQuoteActivity(quote: QuoteRequest) {
  const activities = []

  if (quote.clarifications_count && quote.clarifications_count > 0) {
    activities.push(`${quote.clarifications_count} question(s)`)
  }

  if (quote.proposals_count && quote.proposals_count > 0) {
    activities.push(`${quote.proposals_count} proposition(s)`)
  }

  if (quote.accepted_proposals_count && quote.accepted_proposals_count > 0) {
    activities.push(`${quote.accepted_proposals_count} acceptée(s)`)
  }

  if (quote.lead_access) {
    activities.push('Lead payé et ouvert')
  }

  return activities.length > 0 ? activities.join(' • ') : 'Aucune activité'
}

function getClarificationsForQuote(quoteId: string): QuoteClarification[] {
  return quoteClarifications.value[quoteId] || []
}

function getProposalsForQuote(quoteId: string): QuoteProposal[] {
  return quoteProposals.value[quoteId] || []
}
</script>

<template>
  <AdminLayout>
    <div class="admin-monitoring-page">
      <div class="page-header">
        <h1>Suivi des devis approuvés</h1>
        <p class="subtitle">Suivez le cycle de vie des demandes de devis approuvées</p>
      </div>

      <div v-if="message.text" class="message" :class="message.type">
        {{ message.text }}
      </div>

      <div class="filters">
        <button
          @click="filterStatus = 'all'"
          class="filter-btn"
          :class="{ active: filterStatus === 'all' }"
        >
          Tous <span class="count">{{ statusCounts.all }}</span>
        </button>
        <button
          @click="filterStatus = 'pending'"
          class="filter-btn"
          :class="{ active: filterStatus === 'pending' }"
        >
          En discussion <span class="count">{{ statusCounts.pending }}</span>
        </button>
        <button
          @click="filterStatus = 'waiting_for_info'"
          class="filter-btn"
          :class="{ active: filterStatus === 'waiting_for_info' }"
        >
          En attente d'info <span class="count">{{ statusCounts.waiting_for_info }}</span>
        </button>
        <button
          @click="filterStatus = 'responded'"
          class="filter-btn"
          :class="{ active: filterStatus === 'responded' }"
        >
          Propositions <span class="count">{{ statusCounts.responded }}</span>
        </button>
        <button
          @click="filterStatus = 'accepted'"
          class="filter-btn"
          :class="{ active: filterStatus === 'accepted' }"
        >
          Propositions acceptées <span class="count">{{ statusCounts.accepted }}</span>
        </button>
        <button
          @click="filterStatus = 'sold'"
          class="filter-btn filter-btn-sold"
          :class="{ active: filterStatus === 'sold' }"
        >
          Leads vendus <span class="count">{{ statusCounts.sold }}</span>
        </button>
        <button
          @click="filterStatus = 'closed'"
          class="filter-btn"
          :class="{ active: filterStatus === 'closed' }"
        >
          Clôturés <span class="count">{{ statusCounts.closed }}</span>
        </button>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Chargement des devis...</p>
      </div>

      <div v-else-if="filteredQuotes.length === 0" class="empty-state">
        <div class="empty-icon">📊</div>
        <h2>Aucun devis</h2>
        <p>Aucun devis approuvé pour le moment</p>
      </div>

      <div v-else class="quotes-list">
        <div
          v-for="quote in filteredQuotes"
          :key="quote.id"
          class="quote-card"
          :class="getStatusBadge(quote).class"
        >
          <div class="quote-header">
            <div class="quote-title-section">
              <h3>{{ quote.title }}</h3>
              <span class="status-badge" :class="getStatusBadge(quote).class">
                {{ getStatusBadge(quote).label }}
              </span>
            </div>
            <div class="quote-meta">
              <span class="meta-label">Demandeur:</span>
              <span class="meta-value">
                {{ quote.requester?.first_name || 'Anonyme' }} {{ quote.requester?.last_name || '' }}
                ({{ quote.requester_type === 'PARTICULIER' ? 'Particulier' : 'Pro' }})
              </span>
            </div>
            <div class="quote-meta">
              <span class="meta-label">Entreprise:</span>
              <span class="meta-value">{{ quote.target_company?.name || 'N/A' }}</span>
            </div>
          </div>

          <div class="quote-body">
            <p class="quote-description">{{ quote.description || 'Pas de description' }}</p>
            <div class="quote-details">
              <span v-if="quote.location" class="detail-item">📍 {{ quote.location }}</span>
              <span v-if="quote.volume_estimated" class="detail-item">📦 {{ quote.volume_estimated }}</span>
              <span v-if="quote.frequency" class="detail-item">🔄 {{ quote.frequency }}</span>
            </div>
          </div>

          <div class="quote-activity">
            <span class="activity-label">Activité:</span>
            <span class="activity-value">{{ getQuoteActivity(quote) }}</span>
          </div>

          <div v-if="quote.clarifications_count && quote.clarifications_count > 0" class="quote-section">
            <h4 class="section-header">Questions / Clarifications</h4>
            <div class="clarifications-preview">
              <div
                v-for="clarification in quoteClarifications[quote.id]?.slice(0, 3) || []"
                :key="clarification.id"
                class="clarification-preview-item"
              >
                <div class="clarification-meta">
                  <strong>{{ clarification.company?.name || 'Entreprise' }}</strong>
                  <span class="clarification-time">
                    {{ new Date(clarification.created_at).toLocaleDateString('fr-FR', {
                      day: 'numeric',
                      month: 'short',
                      hour: '2-digit',
                      minute: '2-digit'
                    }) }}
                  </span>
                </div>
                <p class="clarification-text">
                  <span class="label-question">Q:</span> {{ clarification.question }}
                </p>
                <p v-if="clarification.answer" class="clarification-text answer">
                  <span class="label-answer">R:</span> {{ clarification.answer }}
                </p>
                <p v-else class="clarification-pending-badge">En attente de réponse</p>
              </div>
              <p v-if="(quoteClarifications[quote.id]?.length || 0) > 3" class="see-more">
                +{{ (quoteClarifications[quote.id]?.length || 0) - 3 }} autre(s) question(s)
              </p>
            </div>
          </div>

          <div v-if="quote.proposals_count && quote.proposals_count > 0" class="quote-section">
            <h4 class="section-header">Propositions commerciales</h4>
            <div class="proposals-preview">
              <div
                v-for="proposal in quoteProposals[quote.id] || []"
                :key="proposal.id"
                class="proposal-preview-item"
                :class="proposal.status.toLowerCase()"
              >
                <div class="proposal-preview-header">
                  <div class="proposal-company-info">
                    <strong>{{ proposal.company?.name || 'Entreprise' }}</strong>
                    <span v-if="proposal.company?.city" class="proposal-city">{{ proposal.company.city }}</span>
                  </div>
                  <span class="proposal-mini-badge" :class="proposal.status.toLowerCase()">
                    {{ proposal.status === 'PENDING' ? 'En attente' : proposal.status === 'ACCEPTED' ? 'Acceptée' : 'Rejetée' }}
                  </span>
                </div>
                <div class="proposal-preview-details">
                  <div v-if="proposal.proposed_amount || (proposal.price_min && proposal.price_max)" class="proposal-price">
                    <span class="price-icon">💰</span>
                    <span v-if="proposal.proposed_amount">{{ proposal.proposed_amount }} €</span>
                    <span v-else>{{ proposal.price_min }} € - {{ proposal.price_max }} €</span>
                  </div>
                  <div v-if="proposal.delivery_time" class="proposal-delivery">
                    <span class="delivery-icon">⏱️</span>
                    <span>{{ proposal.delivery_time }}</span>
                  </div>
                </div>
                <p v-if="proposal.proposal_message" class="proposal-preview-message">
                  {{ proposal.proposal_message.length > 120 ? proposal.proposal_message.substring(0, 120) + '...' : proposal.proposal_message }}
                </p>
                <p v-if="proposal.status === 'ACCEPTED' && proposal.accepted_at" class="proposal-accepted-info">
                  Acceptée le {{ new Date(proposal.accepted_at).toLocaleDateString('fr-FR', {
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric'
                  }) }}
                </p>
              </div>
            </div>
          </div>

          <div class="quote-footer">
            <span class="quote-date">
              Mis à jour le {{ new Date(quote.updated_at).toLocaleDateString('fr-FR', {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
              }) }}
            </span>
            <button @click="viewDetails(quote)" class="btn-view">
              Voir détails
            </button>
          </div>
        </div>
      </div>

      <div v-if="showDetailsModal && selectedQuote" class="modal-overlay" @click="showDetailsModal = false">
        <div class="modal modal-large" @click.stop>
          <div class="modal-header">
            <h2>Détails du devis</h2>
            <button @click="showDetailsModal = false" class="modal-close">✕</button>
          </div>
          <div class="modal-body">
            <div class="detail-section">
              <h3 class="section-title">Informations générales</h3>
              <div class="detail-row">
                <span class="detail-label">Titre:</span>
                <span class="detail-value">{{ selectedQuote.title }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Description:</span>
                <span class="detail-value">{{ selectedQuote.description || 'N/A' }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Demandeur:</span>
                <span class="detail-value">
                  {{ selectedQuote.requester?.first_name || 'Anonyme' }}
                  {{ selectedQuote.requester?.last_name || '' }}
                  ({{ selectedQuote.requester_type === 'PARTICULIER' ? 'Particulier' : 'Pro' }})
                </span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Entreprise cible:</span>
                <span class="detail-value">{{ selectedQuote.target_company?.name || 'N/A' }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Localisation:</span>
                <span class="detail-value">{{ selectedQuote.location || 'N/A' }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Volume estimé:</span>
                <span class="detail-value">{{ selectedQuote.volume_estimated || 'N/A' }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Fréquence:</span>
                <span class="detail-value">{{ selectedQuote.frequency || 'N/A' }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Budget:</span>
                <span class="detail-value">{{ selectedQuote.budget_range || 'N/A' }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">Statut:</span>
                <span class="detail-value">
                  <span class="status-badge" :class="getStatusBadge(selectedQuote).class">
                    {{ getStatusBadge(selectedQuote).label }}
                  </span>
                </span>
              </div>
              <div v-if="selectedQuote.lead_access" class="detail-row">
                <span class="detail-label">Lead ouvert le:</span>
                <span class="detail-value">
                  {{ new Date(selectedQuote.lead_access.opened_at).toLocaleDateString('fr-FR', {
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  }) }}
                </span>
              </div>
            </div>

            <div v-if="loadingDetails" class="detail-section">
              <div class="loading-inline">
                <div class="spinner-small"></div>
                <p>Chargement des détails...</p>
              </div>
            </div>

            <div v-if="!loadingDetails && clarifications.length > 0" class="detail-section">
              <h3 class="section-title">Demandes de clarification ({{ clarifications.length }})</h3>
              <div class="clarifications-list">
                <div v-for="clarification in clarifications" :key="clarification.id" class="clarification-item">
                  <div class="clarification-question">
                    <strong>Question:</strong>
                    <p>{{ clarification.question }}</p>
                    <span class="clarification-date">
                      {{ new Date(clarification.created_at).toLocaleDateString('fr-FR', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      }) }}
                    </span>
                  </div>
                  <div v-if="clarification.answer" class="clarification-answer">
                    <strong>Réponse:</strong>
                    <p>{{ clarification.answer }}</p>
                    <span class="clarification-date">
                      {{ new Date(clarification.answered_at).toLocaleDateString('fr-FR', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      }) }}
                    </span>
                  </div>
                  <div v-else class="clarification-pending">
                    En attente de réponse
                  </div>
                </div>
              </div>
            </div>

            <div v-if="!loadingDetails && proposals.length > 0" class="detail-section">
              <h3 class="section-title">Propositions ({{ proposals.length }})</h3>
              <div class="proposals-list">
                <div v-for="proposal in proposals" :key="proposal.id" class="proposal-item" :class="proposal.status.toLowerCase()">
                  <div class="proposal-header">
                    <div class="proposal-company">
                      <strong>{{ proposal.company?.name || 'Entreprise inconnue' }}</strong>
                      <span v-if="proposal.company?.city" class="company-location">{{ proposal.company.city }}</span>
                    </div>
                    <span class="proposal-status-badge" :class="proposal.status.toLowerCase()">
                      {{ proposal.status === 'PENDING' ? 'En attente' : proposal.status === 'ACCEPTED' ? 'Acceptée' : 'Rejetée' }}
                    </span>
                  </div>

                  <div class="proposal-details">
                    <div v-if="proposal.proposed_amount" class="proposal-detail-item">
                      <span class="proposal-label">Montant proposé:</span>
                      <span class="proposal-value">{{ proposal.proposed_amount }} €</span>
                    </div>
                    <div v-if="proposal.price_min && proposal.price_max" class="proposal-detail-item">
                      <span class="proposal-label">Fourchette de prix:</span>
                      <span class="proposal-value">{{ proposal.price_min }} € - {{ proposal.price_max }} €</span>
                    </div>
                    <div v-if="proposal.delivery_time" class="proposal-detail-item">
                      <span class="proposal-label">Délai d'intervention:</span>
                      <span class="proposal-value">{{ proposal.delivery_time }}</span>
                    </div>
                    <div v-if="proposal.proposal_message" class="proposal-message">
                      <strong>Message:</strong>
                      <p>{{ proposal.proposal_message }}</p>
                    </div>
                    <div v-if="proposal.status === 'REJECTED' && proposal.rejection_reason" class="proposal-rejection">
                      <strong>Raison du rejet:</strong>
                      <p>{{ proposal.rejection_reason }}</p>
                    </div>
                  </div>

                  <div class="proposal-footer">
                    <span class="proposal-date">
                      Créée le {{ new Date(proposal.created_at).toLocaleDateString('fr-FR', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      }) }}
                    </span>
                    <span v-if="proposal.accepted_at" class="proposal-accepted-date">
                      Acceptée le {{ new Date(proposal.accepted_at).toLocaleDateString('fr-FR', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric'
                      }) }}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="!loadingDetails && clarifications.length === 0 && proposals.length === 0" class="detail-section">
              <p class="no-activity">Aucune activité pour cette demande de devis</p>
            </div>
          </div>
          <div class="modal-footer">
            <button @click="showDetailsModal = false" class="btn-cancel">
              Fermer
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<style scoped>
.admin-monitoring-page {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 2rem;
}

.page-header h1 {
  font-size: 2rem;
  font-weight: 700;
  color: #1a1a1a;
  margin: 0 0 0.5rem 0;
}

.subtitle {
  color: #666;
  margin: 0;
}

.message {
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
  font-weight: 500;
}

.message.success {
  background: #d1fae5;
  color: #065f46;
}

.message.error {
  background: #fee2e2;
  color: #991b1b;
}

.filters {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 0.5rem 1rem;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.filter-btn:hover {
  border-color: #2563eb;
  color: #2563eb;
}

.filter-btn.active {
  background: #2563eb;
  color: white;
  border-color: #2563eb;
}

.filter-btn .count {
  padding: 0.125rem 0.5rem;
  background: rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 600;
}

.filter-btn.active .count {
  background: rgba(255, 255, 255, 0.2);
}

.filter-btn-sold {
  border-color: #10b981;
  color: #065f46;
}

.filter-btn-sold:hover {
  border-color: #10b981;
  color: #065f46;
  background: #ecfdf5;
}

.filter-btn-sold.active {
  background: #10b981;
  color: white;
  border-color: #10b981;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem;
  color: #666;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f0f0f0;
  border-top: 4px solid #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-state h2 {
  margin: 0 0 0.5rem 0;
  color: #1a1a1a;
}

.quotes-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.quote-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 1.5rem;
  transition: all 0.2s;
}

.quote-card.pending {
  border-left: 4px solid #3b82f6;
  background: #eff6ff;
}

.quote-card.waiting {
  border-left: 4px solid #f59e0b;
  background: #fffbeb;
}

.quote-card.responded {
  border-left: 4px solid #8b5cf6;
  background: #faf5ff;
}

.quote-card.accepted {
  border-left: 4px solid #8b5cf6;
  background: #faf5ff;
}

.quote-card.sold {
  border-left: 4px solid #10b981;
  background: #ecfdf5;
}

.quote-card.closed {
  border-left: 4px solid #6b7280;
  background: #f9fafb;
}

.quote-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.quote-header {
  margin-bottom: 1rem;
}

.quote-title-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 0.75rem;
}

.quote-title-section h3 {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: #1a1a1a;
  flex: 1;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-weight: 500;
  font-size: 0.75rem;
  white-space: nowrap;
}

.status-badge.pending {
  background: #dbeafe;
  color: #1e40af;
}

.status-badge.waiting {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.responded {
  background: #ede9fe;
  color: #6b21a8;
}

.status-badge.accepted {
  background: #ede9fe;
  color: #6b21a8;
}

.status-badge.sold {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.closed {
  background: #f3f4f6;
  color: #374151;
}

.quote-meta {
  display: flex;
  gap: 0.5rem;
  font-size: 0.875rem;
  margin-bottom: 0.25rem;
}

.meta-label {
  color: #6b7280;
  font-weight: 500;
}

.meta-value {
  color: #1a1a1a;
}

.quote-body {
  margin-bottom: 1rem;
}

.quote-description {
  color: #374151;
  margin: 0 0 0.75rem 0;
  line-height: 1.6;
}

.quote-details {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.detail-item {
  font-size: 0.875rem;
  color: #6b7280;
  background: white;
  padding: 0.25rem 0.75rem;
  border-radius: 6px;
}

.quote-activity {
  display: flex;
  gap: 0.5rem;
  font-size: 0.875rem;
  padding: 0.75rem;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 6px;
  margin-bottom: 1rem;
}

.activity-label {
  color: #6b7280;
  font-weight: 600;
}

.activity-value {
  color: #1a1a1a;
}

.quote-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
  gap: 1rem;
}

.quote-date {
  font-size: 0.875rem;
  color: #6b7280;
}

.btn-view,
.btn-cancel {
  padding: 0.5rem 1rem;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.btn-view {
  background: #2563eb;
  color: white;
}

.btn-view:hover {
  background: #1d4ed8;
}

.btn-cancel {
  background: #f3f4f6;
  color: #374151;
}

.btn-cancel:hover {
  background: #e5e7eb;
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
  padding: 1rem;
}

.modal {
  background: white;
  border-radius: 12px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-large {
  max-width: 900px;
}

.modal-header {
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h2 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 700;
  color: #1a1a1a;
}

.modal-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #6b7280;
  cursor: pointer;
  padding: 0.25rem;
  line-height: 1;
}

.modal-close:hover {
  color: #1a1a1a;
}

.modal-body {
  padding: 1.5rem;
}

.detail-row {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #f3f4f6;
}

.detail-row:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

.detail-label {
  font-weight: 600;
  color: #6b7280;
  min-width: 140px;
}

.detail-value {
  color: #1a1a1a;
  flex: 1;
}

.modal-footer {
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
}

.detail-section {
  margin-bottom: 2rem;
  padding-bottom: 2rem;
  border-bottom: 2px solid #f3f4f6;
}

.detail-section:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

.section-title {
  font-size: 1.125rem;
  font-weight: 700;
  color: #1a1a1a;
  margin: 0 0 1rem 0;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid #e5e7eb;
}

.loading-inline {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 2rem;
  color: #6b7280;
}

.spinner-small {
  width: 24px;
  height: 24px;
  border: 3px solid #f0f0f0;
  border-top: 3px solid #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.clarifications-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.clarification-item {
  background: #f9fafb;
  border-radius: 8px;
  padding: 1rem;
  border-left: 3px solid #3b82f6;
}

.clarification-question,
.clarification-answer {
  margin-bottom: 0.75rem;
}

.clarification-question strong,
.clarification-answer strong {
  display: block;
  color: #374151;
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
}

.clarification-question p,
.clarification-answer p {
  margin: 0.5rem 0;
  color: #1a1a1a;
  line-height: 1.5;
}

.clarification-date {
  font-size: 0.75rem;
  color: #6b7280;
}

.clarification-answer {
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px solid #e5e7eb;
}

.clarification-pending {
  color: #f59e0b;
  font-style: italic;
  font-size: 0.875rem;
}

.proposals-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.proposal-item {
  background: #f9fafb;
  border-radius: 8px;
  padding: 1.25rem;
  border-left: 4px solid #e5e7eb;
}

.proposal-item.pending {
  border-left-color: #f59e0b;
}

.proposal-item.accepted {
  border-left-color: #10b981;
  background: #f0fdf4;
}

.proposal-item.rejected {
  border-left-color: #ef4444;
  background: #fef2f2;
}

.proposal-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
  gap: 1rem;
}

.proposal-company {
  flex: 1;
}

.proposal-company strong {
  display: block;
  font-size: 1rem;
  color: #1a1a1a;
  margin-bottom: 0.25rem;
}

.company-location {
  font-size: 0.875rem;
  color: #6b7280;
}

.proposal-status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-weight: 500;
  font-size: 0.75rem;
  white-space: nowrap;
}

.proposal-status-badge.pending {
  background: #fef3c7;
  color: #92400e;
}

.proposal-status-badge.accepted {
  background: #d1fae5;
  color: #065f46;
}

.proposal-status-badge.rejected {
  background: #fee2e2;
  color: #991b1b;
}

.proposal-details {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.proposal-detail-item {
  display: flex;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.proposal-label {
  font-weight: 600;
  color: #6b7280;
  min-width: 150px;
}

.proposal-value {
  color: #1a1a1a;
  font-weight: 500;
}

.proposal-message,
.proposal-rejection {
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px solid #e5e7eb;
}

.proposal-message strong,
.proposal-rejection strong {
  display: block;
  color: #374151;
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
}

.proposal-message p,
.proposal-rejection p {
  margin: 0;
  color: #1a1a1a;
  line-height: 1.5;
  font-size: 0.875rem;
}

.proposal-rejection p {
  color: #dc2626;
  font-style: italic;
}

.proposal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
  gap: 1rem;
  flex-wrap: wrap;
}

.proposal-date,
.proposal-accepted-date {
  font-size: 0.75rem;
  color: #6b7280;
}

.proposal-accepted-date {
  color: #059669;
  font-weight: 500;
}

.no-activity {
  text-align: center;
  color: #6b7280;
  font-style: italic;
  padding: 2rem;
}

.quote-section {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 2px solid rgba(0, 0, 0, 0.05);
}

.section-header {
  font-size: 0.875rem;
  font-weight: 700;
  color: #374151;
  margin: 0 0 1rem 0;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.clarifications-preview {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.clarification-preview-item {
  background: rgba(255, 255, 255, 0.6);
  border: 1px solid rgba(59, 130, 246, 0.2);
  border-radius: 8px;
  padding: 0.875rem;
}

.clarification-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
  gap: 0.5rem;
}

.clarification-meta strong {
  font-size: 0.875rem;
  color: #1a1a1a;
}

.clarification-time {
  font-size: 0.75rem;
  color: #6b7280;
  white-space: nowrap;
}

.clarification-text {
  margin: 0.5rem 0 0 0;
  font-size: 0.875rem;
  line-height: 1.5;
  color: #374151;
  display: flex;
  gap: 0.5rem;
}

.clarification-text.answer {
  padding-top: 0.5rem;
  border-top: 1px solid rgba(0, 0, 0, 0.05);
  margin-top: 0.5rem;
}

.label-question {
  font-weight: 700;
  color: #3b82f6;
  flex-shrink: 0;
}

.label-answer {
  font-weight: 700;
  color: #10b981;
  flex-shrink: 0;
}

.clarification-pending-badge {
  margin: 0.5rem 0 0 0;
  font-size: 0.75rem;
  color: #f59e0b;
  font-style: italic;
  font-weight: 500;
}

.see-more {
  text-align: center;
  font-size: 0.75rem;
  color: #6b7280;
  font-style: italic;
  margin: 0.5rem 0 0 0;
}

.proposals-preview {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.proposal-preview-item {
  background: rgba(255, 255, 255, 0.6);
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  padding: 1rem;
  transition: all 0.2s;
}

.proposal-preview-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.proposal-preview-item.accepted {
  border-left: 3px solid #8b5cf6;
  background: rgba(139, 92, 246, 0.05);
}

.proposal-preview-item.rejected {
  border-left: 3px solid #ef4444;
  background: rgba(239, 68, 68, 0.03);
  opacity: 0.7;
}

.proposal-preview-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.proposal-company-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
}

.proposal-company-info strong {
  font-size: 0.875rem;
  color: #1a1a1a;
}

.proposal-city {
  font-size: 0.75rem;
  color: #6b7280;
}

.proposal-mini-badge {
  padding: 0.25rem 0.625rem;
  border-radius: 12px;
  font-size: 0.625rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.025em;
  white-space: nowrap;
}

.proposal-mini-badge.pending {
  background: #fef3c7;
  color: #92400e;
}

.proposal-mini-badge.accepted {
  background: #ede9fe;
  color: #6b21a8;
}

.proposal-mini-badge.rejected {
  background: #fee2e2;
  color: #991b1b;
}

.proposal-preview-details {
  display: flex;
  gap: 1rem;
  margin-bottom: 0.75rem;
  flex-wrap: wrap;
}

.proposal-price,
.proposal-delivery {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: #1a1a1a;
}

.price-icon,
.delivery-icon {
  font-size: 1rem;
}

.proposal-preview-message {
  margin: 0.75rem 0 0 0;
  padding-top: 0.75rem;
  border-top: 1px solid rgba(0, 0, 0, 0.05);
  font-size: 0.875rem;
  line-height: 1.5;
  color: #6b7280;
  font-style: italic;
}

.proposal-accepted-info {
  margin: 0.75rem 0 0 0;
  padding: 0.5rem;
  background: rgba(139, 92, 246, 0.1);
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 600;
  color: #6b21a8;
  text-align: center;
}

@media (max-width: 768px) {
  .admin-monitoring-page {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .quote-footer {
    flex-direction: column;
    align-items: flex-start;
  }

  .detail-row {
    flex-direction: column;
    gap: 0.25rem;
  }

  .detail-label {
    min-width: auto;
  }

  .modal-footer {
    flex-direction: column;
  }

  .modal-footer button {
    width: 100%;
  }
}
</style>
