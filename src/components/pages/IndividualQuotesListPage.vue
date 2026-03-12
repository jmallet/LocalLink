<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import IndividualDashboardLayout from '../dashboard/IndividualDashboardLayout.vue'

interface QuoteRequest {
  id: string
  title: string
  description: string
  volume_estimated: string | null
  frequency: string | null
  location: string | null
  budget_range: string | null
  urgency: string | null
  status: string
  created_at: string
  proposals_count?: number
  accepted_count?: number
  unanswered_clarifications_count?: number
}

const router = useRouter()
const quotes = ref<QuoteRequest[]>([])
const loading = ref(true)
const error = ref('')
const activeFilter = ref<string>('all')

function getStatusLabel(quote: QuoteRequest): string {
  if (quote.accepted_count && quote.accepted_count > 0) {
    return 'Accepté'
  }
  if (quote.unanswered_clarifications_count && quote.unanswered_clarifications_count > 0) {
    return 'À compléter'
  }
  if (quote.status === 'RESPONDED' || (quote.proposals_count && quote.proposals_count > 0)) {
    return 'Propositions reçues'
  }
  if (quote.status === 'CLOSED') {
    return 'Clôturé'
  }
  return 'En attente'
}

function getStatusColor(quote: QuoteRequest): string {
  if (quote.accepted_count && quote.accepted_count > 0) {
    return '#059669'
  }
  if (quote.unanswered_clarifications_count && quote.unanswered_clarifications_count > 0) {
    return '#f59e0b'
  }
  if (quote.status === 'RESPONDED' || (quote.proposals_count && quote.proposals_count > 0)) {
    return '#10b981'
  }
  if (quote.status === 'CLOSED') {
    return '#6b7280'
  }
  return '#3b82f6'
}

const filterCounts = computed(() => {
  return {
    all: quotes.value.length,
    to_complete: quotes.value.filter(q => q.unanswered_clarifications_count && q.unanswered_clarifications_count > 0).length,
    pending: quotes.value.filter(q => !q.proposals_count && !q.unanswered_clarifications_count && q.status !== 'CLOSED' && (!q.accepted_count || q.accepted_count === 0)).length,
    received: quotes.value.filter(q => q.proposals_count && q.proposals_count > 0 && (!q.accepted_count || q.accepted_count === 0)).length,
    accepted: quotes.value.filter(q => q.accepted_count && q.accepted_count > 0).length,
    closed: quotes.value.filter(q => q.status === 'CLOSED').length
  }
})

const filteredQuotes = computed(() => {
  let filtered = quotes.value

  if (activeFilter.value === 'to_complete') {
    filtered = filtered.filter(q => q.unanswered_clarifications_count && q.unanswered_clarifications_count > 0)
  } else if (activeFilter.value === 'pending') {
    filtered = filtered.filter(q => !q.proposals_count && !q.unanswered_clarifications_count && q.status !== 'CLOSED' && (!q.accepted_count || q.accepted_count === 0))
  } else if (activeFilter.value === 'received') {
    filtered = filtered.filter(q => q.proposals_count && q.proposals_count > 0 && (!q.accepted_count || q.accepted_count === 0))
  } else if (activeFilter.value === 'accepted') {
    filtered = filtered.filter(q => q.accepted_count && q.accepted_count > 0)
  } else if (activeFilter.value === 'closed') {
    filtered = filtered.filter(q => q.status === 'CLOSED')
  }

  return filtered
})

const sortedQuotes = computed(() => {
  return [...filteredQuotes.value].sort((a, b) => {
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
})

onMounted(async () => {
  await loadQuotes()
})

async function loadQuotes() {
  loading.value = true
  error.value = ''

  try {
    if (!user.value?.id) {
      error.value = 'Utilisateur non connecté'
      return
    }

    const { data, error: fetchError } = await supabase
      .from('quote_requests')
      .select(`
        id,
        title,
        description,
        volume_estimated,
        frequency,
        location,
        budget_range,
        urgency,
        status,
        created_at,
        quote_proposals(status),
        quote_clarifications(answer)
      `)
      .eq('requester_id', user.value.id)
      .order('created_at', { ascending: false })

    if (fetchError) throw fetchError

    quotes.value = (data || []).map((quote: any) => {
      const proposals = quote.quote_proposals || []
      const clarifications = quote.quote_clarifications || []
      // Ne compter que les propositions actives (non rejetées, non en attente d'approbation)
      const activeProposals = proposals.filter((p: any) => p.status !== 'REJECTED' && p.status !== 'PENDING')
      return {
        id: quote.id,
        title: quote.title,
        description: quote.description,
        volume_estimated: quote.volume_estimated,
        frequency: quote.frequency,
        location: quote.location,
        budget_range: quote.budget_range,
        urgency: quote.urgency,
        status: quote.status,
        created_at: quote.created_at,
        proposals_count: activeProposals.length,
        accepted_count: proposals.filter((p: any) => p.status === 'ACCEPTED').length,
        unanswered_clarifications_count: clarifications.filter((c: any) => !c.answer).length
      }
    })
  } catch (err) {
    console.error('Error loading quotes:', err)
    error.value = 'Erreur lors du chargement des demandes'
  } finally {
    loading.value = false
  }
}

function viewQuoteDetail(quoteId: string) {
  router.push({ name: 'individual-quote-detail', params: { id: quoteId } })
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  }).format(date)
}

function getUrgencyLabel(urgency: string): string {
  const labels: Record<string, string> = {
    'URGENT_48H': 'Urgent (48h)',
    'THIS_WEEK': 'Cette semaine',
    'FLEXIBLE': 'Flexible'
  }
  return labels[urgency] || urgency
}
</script>

<template>
  <IndividualDashboardLayout>
    <div class="quotes-page">
      <div class="page-header">
        <div>
          <h2>Mes demandes de devis</h2>
          <p>Consultez toutes vos demandes et les réponses reçues</p>
        </div>
      </div>

      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="error" class="error-message">
        {{ error }}
      </div>

      <div v-else-if="quotes.length === 0" class="empty-state">
        <span class="empty-icon">📋</span>
        <h3>Aucune demande de devis</h3>
        <p>Vous n'avez pas encore créé de demande de devis.</p>
        <button class="btn-primary" @click="router.push({ name: 'individual-new-quote' })">
          Créer une demande
        </button>
      </div>

      <div v-else>
        <div class="filters-container">
          <button
            class="filter-btn"
            :class="{ active: activeFilter === 'all' }"
            @click="activeFilter = 'all'"
          >
            Tous
            <span class="count">{{ filterCounts.all }}</span>
          </button>
          <button
            class="filter-btn"
            :class="{ active: activeFilter === 'to_complete' }"
            @click="activeFilter = 'to_complete'"
          >
            À compléter
            <span class="count">{{ filterCounts.to_complete }}</span>
          </button>
          <button
            class="filter-btn"
            :class="{ active: activeFilter === 'pending' }"
            @click="activeFilter = 'pending'"
          >
            En attente
            <span class="count">{{ filterCounts.pending }}</span>
          </button>
          <button
            class="filter-btn"
            :class="{ active: activeFilter === 'received' }"
            @click="activeFilter = 'received'"
          >
            Propositions reçues
            <span class="count">{{ filterCounts.received }}</span>
          </button>
          <button
            class="filter-btn"
            :class="{ active: activeFilter === 'accepted' }"
            @click="activeFilter = 'accepted'"
          >
            Acceptés
            <span class="count">{{ filterCounts.accepted }}</span>
          </button>
          <button
            class="filter-btn"
            :class="{ active: activeFilter === 'closed' }"
            @click="activeFilter = 'closed'"
          >
            Clôturés
            <span class="count">{{ filterCounts.closed }}</span>
          </button>
        </div>

        <div v-if="sortedQuotes.length === 0" class="empty-filter">
          <p>Aucune demande pour ce filtre</p>
        </div>

        <div v-else class="quotes-list">
        <div
          v-for="quote in sortedQuotes"
          :key="quote.id"
          class="quote-card"
          @click="viewQuoteDetail(quote.id)"
        >
          <div class="quote-header">
            <h3>{{ quote.title }}</h3>
            <span
              class="status-badge"
              :style="{ backgroundColor: getStatusColor(quote) }"
            >
              {{ getStatusLabel(quote) }}
            </span>
          </div>

          <p class="quote-description">{{ quote.description }}</p>

          <div class="quote-meta">
            <span v-if="quote.location" class="meta-item">
              <strong>Lieu:</strong> {{ quote.location }}
            </span>
            <span v-if="quote.volume_estimated" class="meta-item">
              <strong>Volume:</strong> {{ quote.volume_estimated }}
            </span>
            <span v-if="quote.urgency" class="meta-item">
              <strong>Urgence:</strong> {{ getUrgencyLabel(quote.urgency) }}
            </span>
            <span class="meta-item">
              <strong>Créée le:</strong> {{ formatDate(quote.created_at) }}
            </span>
          </div>

          <div class="quote-footer">
            <div v-if="quote.proposals_count && quote.proposals_count > 0" class="proposals-info">
              <span class="proposals-badge">
                {{ quote.proposals_count }} {{ quote.proposals_count === 1 ? 'proposition reçue' : 'propositions reçues' }}
              </span>
              <span v-if="quote.accepted_count && quote.accepted_count > 0" class="accepted-badge">
                {{ quote.accepted_count }} acceptée{{ quote.accepted_count > 1 ? 's' : '' }}
              </span>
            </div>
            <span class="view-link">Voir les détails →</span>
          </div>
        </div>
        </div>
      </div>
    </div>
  </IndividualDashboardLayout>
</template>

<style scoped>
.quotes-page {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
}

.page-header h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.page-header p {
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
  border-top-color: #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-message {
  background: #fee2e2;
  color: #991b1b;
  padding: 16px;
  border-radius: 8px;
  text-align: center;
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

.empty-state h3 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-primary {
  padding: 14px 28px;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #1d4ed8;
  transform: translateY(-1px);
}

.quotes-list {
  display: flex;
  flex-direction: column;
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
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.quote-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
  gap: 16px;
}

.quote-header h3 {
  font-size: 20px;
  font-weight: 600;
  color: #111827;
  margin: 0;
  flex: 1;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 13px;
  font-weight: 600;
  color: white;
  flex-shrink: 0;
}

.quote-description {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.5;
  margin: 0 0 16px 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.quote-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  padding: 12px 0;
  border-top: 1px solid #e5e7eb;
  border-bottom: 1px solid #e5e7eb;
  margin-bottom: 16px;
}

.meta-item {
  font-size: 13px;
  color: #6b7280;
}

.meta-item strong {
  color: #374151;
  font-weight: 600;
}

.quote-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.proposals-info {
  display: flex;
  gap: 8px;
  align-items: center;
}

.proposals-badge {
  padding: 4px 12px;
  background: #eff6ff;
  color: #1e40af;
  border-radius: 12px;
  font-size: 13px;
  font-weight: 600;
}

.accepted-badge {
  padding: 4px 12px;
  background: #d1fae5;
  color: #065f46;
  border-radius: 12px;
  font-size: 13px;
  font-weight: 600;
}

.view-link {
  font-size: 14px;
  font-weight: 600;
  color: #2563eb;
  flex-shrink: 0;
}

.filters-container {
  display: flex;
  gap: 8px;
  margin-bottom: 24px;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 10px 18px;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-btn:hover {
  border-color: #2563eb;
  color: #2563eb;
}

.filter-btn.active {
  background: #2563eb;
  border-color: #2563eb;
  color: white;
}

.filter-btn .count {
  padding: 2px 8px;
  background: #f3f4f6;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 700;
  color: #374151;
}

.filter-btn.active .count {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.empty-filter {
  text-align: center;
  padding: 60px 24px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.empty-filter p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 16px;
  }

  .quote-meta {
    flex-direction: column;
    gap: 8px;
  }
}
</style>
