<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
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
  admin_approved_at: string | null
  admin_approved_by: string | null
  admin_rejection_reason: string | null
  created_at: string
  requester?: any
  target_company?: any
}

const quotes = ref<QuoteRequest[]>([])
const loading = ref(true)
const actionLoading = ref(false)
const selectedQuote = ref<QuoteRequest | null>(null)
const showDetailsModal = ref(false)
const showRejectModal = ref(false)
const rejectionReason = ref('')
const filterStatus = ref<'all' | 'pending' | 'approved' | 'rejected'>('pending')
const message = ref({ type: '', text: '' })

const filteredQuotes = computed(() => {
  if (filterStatus.value === 'all') return quotes.value
  if (filterStatus.value === 'pending') return quotes.value.filter(q => !q.admin_approved && !q.admin_rejection_reason)
  if (filterStatus.value === 'approved') return quotes.value.filter(q => q.admin_approved)
  if (filterStatus.value === 'rejected') return quotes.value.filter(q => q.admin_rejection_reason)
  return quotes.value
})

const statusCounts = computed(() => ({
  all: quotes.value.length,
  pending: quotes.value.filter(q => !q.admin_approved && !q.admin_rejection_reason).length,
  approved: quotes.value.filter(q => q.admin_approved).length,
  rejected: quotes.value.filter(q => q.admin_rejection_reason).length
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
        requester:profiles!requester_id(user_id, first_name, last_name, user_type),
        target_company:companies!target_company_id(id, name, city)
      `)
      .order('created_at', { ascending: false })

    if (error) throw error
    quotes.value = data || []
  } catch (error) {
    console.error('Error loading quotes:', error)
    showMessage('error', 'Erreur lors du chargement des devis')
  } finally {
    loading.value = false
  }
}

function viewDetails(quote: QuoteRequest) {
  selectedQuote.value = quote
  showDetailsModal.value = true
}

function openRejectModal(quote: QuoteRequest) {
  selectedQuote.value = quote
  rejectionReason.value = quote.admin_rejection_reason || ''
  showRejectModal.value = true
}

async function approveQuote(quote: QuoteRequest) {
  if (!user.value) return

  actionLoading.value = true
  try {
    const { error } = await supabase
      .from('quote_requests')
      .update({
        admin_approved: true,
        admin_approved_at: new Date().toISOString(),
        admin_approved_by: user.value.id,
        admin_rejection_reason: null,
        status: 'SENT'
      })
      .eq('id', quote.id)

    if (error) throw error

    showMessage('success', 'Demande de devis approuvée avec succès')
    await loadQuotes()
    showDetailsModal.value = false
  } catch (error) {
    console.error('Error approving quote:', error)
    showMessage('error', 'Erreur lors de l\'approbation')
  } finally {
    actionLoading.value = false
  }
}

async function rejectQuote() {
  if (!selectedQuote.value || !user.value) return
  if (!rejectionReason.value.trim()) {
    showMessage('error', 'Veuillez indiquer une raison de rejet')
    return
  }

  actionLoading.value = true
  try {
    const { error } = await supabase
      .from('quote_requests')
      .update({
        admin_approved: false,
        admin_rejection_reason: rejectionReason.value,
        status: 'CLOSED'
      })
      .eq('id', selectedQuote.value.id)

    if (error) throw error

    showMessage('success', 'Demande de devis rejetée')
    await loadQuotes()
    showRejectModal.value = false
    showDetailsModal.value = false
    rejectionReason.value = ''
  } catch (error) {
    console.error('Error rejecting quote:', error)
    showMessage('error', 'Erreur lors du rejet')
  } finally {
    actionLoading.value = false
  }
}

function showMessage(type: string, text: string) {
  message.value = { type, text }
  setTimeout(() => {
    message.value = { type: '', text: '' }
  }, 5000)
}

function getStatusBadge(quote: QuoteRequest) {
  if (quote.admin_rejection_reason) return { label: 'Rejeté', class: 'rejected' }
  if (quote.admin_approved) return { label: 'Approuvé', class: 'approved' }
  return { label: 'En attente', class: 'pending' }
}
</script>

<template>
  <AdminLayout>
    <div class="admin-quotes-page">
      <div class="page-header">
        <h1>Gestion des demandes de devis</h1>
        <p class="subtitle">Validez ou rejetez les demandes de devis avant qu'elles soient envoyées aux professionnels</p>
      </div>

      <div v-if="message.text" class="message" :class="message.type">
        {{ message.text }}
      </div>

      <div class="filters">
        <button
          @click="filterStatus = 'pending'"
          class="filter-btn"
          :class="{ active: filterStatus === 'pending' }"
        >
          En attente <span class="count">{{ statusCounts.pending }}</span>
        </button>
        <button
          @click="filterStatus = 'approved'"
          class="filter-btn"
          :class="{ active: filterStatus === 'approved' }"
        >
          Approuvés <span class="count">{{ statusCounts.approved }}</span>
        </button>
        <button
          @click="filterStatus = 'rejected'"
          class="filter-btn"
          :class="{ active: filterStatus === 'rejected' }"
        >
          Rejetés <span class="count">{{ statusCounts.rejected }}</span>
        </button>
        <button
          @click="filterStatus = 'all'"
          class="filter-btn"
          :class="{ active: filterStatus === 'all' }"
        >
          Tous <span class="count">{{ statusCounts.all }}</span>
        </button>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Chargement des demandes...</p>
      </div>

      <div v-else-if="filteredQuotes.length === 0" class="empty-state">
        <div class="empty-icon">📋</div>
        <h2>Aucune demande</h2>
        <p>Aucune demande de devis {{ filterStatus === 'pending' ? 'en attente' : filterStatus === 'approved' ? 'approuvée' : filterStatus === 'rejected' ? 'rejetée' : '' }}</p>
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
              <span class="meta-label">De:</span>
              <span class="meta-value">
                {{ quote.requester?.first_name || 'Anonyme' }} {{ quote.requester?.last_name || '' }}
                ({{ quote.requester_type === 'PARTICULIER' ? 'Particulier' : 'Pro' }})
              </span>
            </div>
            <div class="quote-meta">
              <span class="meta-label">Pour:</span>
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

          <div class="quote-footer">
            <span class="quote-date">
              {{ new Date(quote.created_at).toLocaleDateString('fr-FR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
              }) }}
            </span>
            <div class="quote-actions">
              <button @click="viewDetails(quote)" class="btn-view">
                Détails
              </button>
              <button
                v-if="!quote.admin_approved && !quote.admin_rejection_reason"
                @click="approveQuote(quote)"
                class="btn-approve"
                :disabled="actionLoading"
              >
                Approuver
              </button>
              <button
                v-if="!quote.admin_rejection_reason"
                @click="openRejectModal(quote)"
                class="btn-reject"
                :disabled="actionLoading"
              >
                Rejeter
              </button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showDetailsModal && selectedQuote" class="modal-overlay" @click="showDetailsModal = false">
        <div class="modal" @click.stop>
          <div class="modal-header">
            <h2>Détails de la demande</h2>
            <button @click="showDetailsModal = false" class="modal-close">✕</button>
          </div>
          <div class="modal-body">
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
            <div v-if="selectedQuote.admin_rejection_reason" class="detail-row">
              <span class="detail-label">Raison du rejet:</span>
              <span class="detail-value rejection-reason">{{ selectedQuote.admin_rejection_reason }}</span>
            </div>
          </div>
          <div class="modal-footer">
            <button
              v-if="!selectedQuote.admin_approved && !selectedQuote.admin_rejection_reason"
              @click="approveQuote(selectedQuote)"
              class="btn-approve"
              :disabled="actionLoading"
            >
              Approuver
            </button>
            <button
              v-if="!selectedQuote.admin_rejection_reason"
              @click="openRejectModal(selectedQuote)"
              class="btn-reject"
              :disabled="actionLoading"
            >
              Rejeter
            </button>
            <button @click="showDetailsModal = false" class="btn-cancel">
              Fermer
            </button>
          </div>
        </div>
      </div>

      <div v-if="showRejectModal && selectedQuote" class="modal-overlay" @click="showRejectModal = false">
        <div class="modal" @click.stop>
          <div class="modal-header">
            <h2>Rejeter la demande</h2>
            <button @click="showRejectModal = false" class="modal-close">✕</button>
          </div>
          <div class="modal-body">
            <p>Vous êtes sur le point de rejeter la demande de devis "<strong>{{ selectedQuote.title }}</strong>".</p>
            <div class="form-group">
              <label>Raison du rejet:</label>
              <textarea
                v-model="rejectionReason"
                placeholder="Expliquez pourquoi cette demande est rejetée..."
                rows="4"
              ></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button @click="rejectQuote" class="btn-reject" :disabled="actionLoading || !rejectionReason.trim()">
              Confirmer le rejet
            </button>
            <button @click="showRejectModal = false" class="btn-cancel">
              Annuler
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<style scoped>
.admin-quotes-page {
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
  border-left: 4px solid #f59e0b;
  background: #fffbeb;
}

.quote-card.approved {
  border-left: 4px solid #10b981;
  background: #ecfdf5;
}

.quote-card.rejected {
  border-left: 4px solid #ef4444;
  background: #fef2f2;
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
  background: #fef3c7;
  color: #92400e;
}

.status-badge.approved {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.rejected {
  background: #fee2e2;
  color: #991b1b;
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

.quote-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-view,
.btn-approve,
.btn-reject,
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
  background: #f3f4f6;
  color: #374151;
}

.btn-view:hover {
  background: #e5e7eb;
}

.btn-approve {
  background: #10b981;
  color: white;
}

.btn-approve:hover {
  background: #059669;
}

.btn-approve:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-reject {
  background: #ef4444;
  color: white;
}

.btn-reject:hover {
  background: #dc2626;
}

.btn-reject:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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

.rejection-reason {
  color: #dc2626;
  font-style: italic;
}

.form-group {
  margin-top: 1.5rem;
}

.form-group label {
  display: block;
  font-weight: 600;
  color: #374151;
  margin-bottom: 0.5rem;
}

.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-family: inherit;
  font-size: 0.875rem;
  resize: vertical;
}

.form-group textarea:focus {
  outline: none;
  border-color: #2563eb;
}

.modal-footer {
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .admin-quotes-page {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .quote-footer {
    flex-direction: column;
    align-items: flex-start;
  }

  .quote-actions {
    width: 100%;
    justify-content: flex-start;
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
