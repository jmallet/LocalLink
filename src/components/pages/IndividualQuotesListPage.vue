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
  category: string
  quantity: string | null
  deadline: string | null
  budget_range: string | null
  status: string
  created_at: string
  quote_count?: number
}

const router = useRouter()
const quotes = ref<QuoteRequest[]>([])
const loading = ref(true)
const error = ref('')

const statusLabels: Record<string, string> = {
  'draft': 'Brouillon',
  'pending_approval': 'En attente',
  'approved': 'Approuvée',
  'rejected': 'Refusée',
  'sent': 'Envoyée'
}

const statusColors: Record<string, string> = {
  'draft': '#9ca3af',
  'pending_approval': '#f59e0b',
  'approved': '#10b981',
  'rejected': '#ef4444',
  'sent': '#3b82f6'
}

const sortedQuotes = computed(() => {
  return [...quotes.value].sort((a, b) => {
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
      .select('*')
      .eq('requester_id', user.value.id)
      .order('created_at', { ascending: false })

    if (fetchError) throw fetchError

    if (data) {
      const quotesWithCounts = await Promise.all(
        data.map(async (quote) => {
          const { count } = await supabase
            .from('quote_messages')
            .select('*', { count: 'exact', head: true })
            .eq('quote_request_id', quote.id)

          return {
            ...quote,
            quote_count: count || 0
          }
        })
      )

      quotes.value = quotesWithCounts
    }
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
              :style="{ backgroundColor: statusColors[quote.status] }"
            >
              {{ statusLabels[quote.status] }}
            </span>
          </div>

          <p class="quote-description">{{ quote.description }}</p>

          <div class="quote-meta">
            <span class="meta-item">
              <strong>Catégorie:</strong> {{ quote.category }}
            </span>
            <span v-if="quote.deadline" class="meta-item">
              <strong>Date limite:</strong> {{ formatDate(quote.deadline) }}
            </span>
            <span class="meta-item">
              <strong>Créée le:</strong> {{ formatDate(quote.created_at) }}
            </span>
          </div>

          <div class="quote-footer">
            <span class="quote-count">
              {{ quote.quote_count || 0 }} réponse{{ (quote.quote_count || 0) > 1 ? 's' : '' }}
            </span>
            <span class="view-link">Voir les détails →</span>
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
}

.quote-count {
  font-size: 14px;
  font-weight: 600;
  color: #2563eb;
}

.view-link {
  font-size: 14px;
  font-weight: 600;
  color: #2563eb;
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
