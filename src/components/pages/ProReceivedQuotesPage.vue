<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { currentCompany } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { QuoteRequest, Profile } from '../../types/database'

interface QuoteWithRequester extends QuoteRequest {
  requester?: Profile
}

const router = useRouter()
const loading = ref(true)
const quotes = ref<QuoteWithRequester[]>([])
const selectedStatus = ref<string>('all')

const filteredQuotes = computed(() => {
  if (selectedStatus.value === 'all') return quotes.value
  return quotes.value.filter(q => q.status === selectedStatus.value.toUpperCase())
})

const statusCounts = computed(() => {
  return {
    all: quotes.value.length,
    new: quotes.value.filter(q => q.status === 'SENT').length,
    viewed: quotes.value.filter(q => q.status === 'VIEWED').length,
    responded: quotes.value.filter(q => q.status === 'RESPONDED').length,
    closed: quotes.value.filter(q => q.status === 'CLOSED').length,
  }
})

onMounted(async () => {
  await loadQuotes()
})

async function loadQuotes() {
  if (!currentCompany.value) {
    console.error('No current company set')
    loading.value = false
    return
  }

  loading.value = true
  try {
    console.log('Loading quotes for company:', currentCompany.value.id, currentCompany.value.name)

    const { data, error } = await supabase
      .from('quote_requests')
      .select(`
        *,
        requester:profiles!quote_requests_requester_id_profiles_fkey(*)
      `)
      .eq('target_company_id', currentCompany.value.id)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error loading quotes:', error)
      throw error
    }

    console.log('Loaded quotes:', data)
    quotes.value = data || []
  } catch (error) {
    console.error('Error loading quotes:', error)
  } finally {
    loading.value = false
  }
}

function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    SENT: 'Nouveau',
    VIEWED: 'Vu',
    RESPONDED: 'Répondu',
    CLOSED: 'Fermé'
  }
  return labels[status] || status
}

function getOriginLabel(type: string): string {
  return type === 'PARTICULIER' ? 'Particulier' : 'Professionnel'
}

function viewQuote(quoteId: string) {
  router.push({ name: 'pro-quote-detail', params: { id: quoteId } })
}
</script>

<template>
  <DashboardLayout>
    <div class="pro-received-quotes">
      <div class="page-header">
        <h1>Devis reçus</h1>
        <p class="subtitle">Gérez vos demandes de devis entrantes</p>
      </div>

      <div class="filters">
        <button
          v-for="(count, key) in statusCounts"
          :key="key"
          @click="selectedStatus = key"
          class="filter-btn"
          :class="{ active: selectedStatus === key }"
        >
          {{ key === 'all' ? 'Tous' : key === 'new' ? 'Nouveaux' : key === 'viewed' ? 'Vus' : key === 'responded' ? 'Répondus' : 'Fermés' }}
          <span class="count">{{ count }}</span>
        </button>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Chargement des devis...</p>
      </div>

      <div v-else-if="filteredQuotes.length === 0" class="empty-state">
        <div class="empty-icon">📭</div>
        <h2>Aucun devis</h2>
        <p>Vous n'avez pas encore reçu de demandes de devis.</p>
      </div>

      <div v-else class="quotes-list">
        <div
          v-for="quote in filteredQuotes"
          :key="quote.id"
          @click="viewQuote(quote.id)"
          class="quote-card"
          :class="{ unread: quote.status === 'SENT' }"
        >
          <div class="quote-header">
            <h3>{{ quote.title }}</h3>
            <span class="status-badge" :class="quote.status.toLowerCase()">
              {{ getStatusLabel(quote.status) }}
            </span>
          </div>

          <div class="quote-body">
            <p class="quote-description">{{ quote.description || 'Pas de description' }}</p>
            <div class="quote-meta">
              <div class="meta-item">
                <span class="meta-label">Origine :</span>
                <span class="meta-value">{{ getOriginLabel(quote.requester_type) }}</span>
              </div>
              <div v-if="quote.location" class="meta-item">
                <span class="meta-label">Localisation :</span>
                <span class="meta-value">{{ quote.location }}</span>
              </div>
              <div v-if="quote.volume_estimated" class="meta-item">
                <span class="meta-label">Volume :</span>
                <span class="meta-value">{{ quote.volume_estimated }}</span>
              </div>
              <div v-if="quote.frequency" class="meta-item">
                <span class="meta-label">Fréquence :</span>
                <span class="meta-value">{{ quote.frequency }}</span>
              </div>
            </div>
          </div>

          <div class="quote-footer">
            <span class="quote-date">{{ new Date(quote.created_at).toLocaleDateString('fr-FR', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
            }) }}</span>
            <span class="view-link">Voir le détail →</span>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.pro-received-quotes {
  padding: 2rem;
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
  cursor: pointer;
  transition: all 0.2s;
}

.quote-card.unread {
  border-left: 4px solid #2563eb;
  background: #eff6ff;
}

.quote-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  transform: translateY(-2px);
}

.quote-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
  gap: 1rem;
}

.quote-header h3 {
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

.status-badge.sent {
  background: #dbeafe;
  color: #1e40af;
}

.status-badge.viewed {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.responded {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.closed {
  background: #f3f4f6;
  color: #4b5563;
}

.quote-body {
  margin-bottom: 1rem;
}

.quote-description {
  color: #374151;
  margin: 0 0 1rem 0;
  line-height: 1.6;
}

.quote-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.meta-item {
  display: flex;
  gap: 0.25rem;
  font-size: 0.875rem;
}

.meta-label {
  color: #6b7280;
  font-weight: 500;
}

.meta-value {
  color: #1a1a1a;
}

.quote-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
}

.quote-date {
  font-size: 0.875rem;
  color: #6b7280;
}

.view-link {
  font-size: 0.875rem;
  color: #2563eb;
  font-weight: 500;
}

@media (max-width: 768px) {
  .pro-received-quotes {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .quote-header {
    flex-direction: column;
  }

  .quote-meta {
    flex-direction: column;
    gap: 0.5rem;
  }

  .quote-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
}
</style>
