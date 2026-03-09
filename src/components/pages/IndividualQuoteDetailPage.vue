<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import IndividualDashboardLayout from '../dashboard/IndividualDashboardLayout.vue'

interface QuoteRequest {
  id: string
  title: string
  description: string
  location: string | null
  urgency: string | null
  category: string | null
  quantity: string | null
  deadline: string | null
  budget_range: string | null
  status: string
  created_at: string
}

interface Company {
  id: string
  name: string
  description: string | null
  city: string | null
  postal_code: string | null
  phone: string | null
  website: string | null
  logo_url: string | null
}

interface QuoteProposal {
  id: string
  producer_company_id: string
  proposal_type: 'FIXED_PRICE' | 'PRICE_RANGE'
  proposed_amount: number | null
  price_min: number | null
  price_max: number | null
  proposal_message: string | null
  delivery_time: string | null
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED'
  created_at: string
  company?: Company
}

interface QuoteClarification {
  id: string
  producer_company_id: string
  question: string
  answer: string | null
  answered_at: string | null
  created_at: string
  company?: Company
}

const route = useRoute()
const router = useRouter()

const quoteRequest = ref<QuoteRequest | null>(null)
const proposals = ref<QuoteProposal[]>([])
const clarifications = ref<QuoteClarification[]>([])
const loading = ref(true)
const error = ref('')

const statusLabels: Record<string, string> = {
  'SENT': 'Envoyée',
  'VIEWED': 'Vue',
  'RESPONDED': 'Réponses reçues',
  'WAITING_FOR_INFO': 'En attente d\'infos',
  'CLOSED': 'Fermée'
}

const statusColors: Record<string, string> = {
  'SENT': '#3b82f6',
  'VIEWED': '#f59e0b',
  'RESPONDED': '#10b981',
  'WAITING_FOR_INFO': '#f59e0b',
  'CLOSED': '#9ca3af'
}

const urgencyLabels: Record<string, string> = {
  'URGENT_48H': '🔥 Urgent (48h)',
  'THIS_WEEK': '⚡ Cette semaine',
  'FLEXIBLE': '📅 Flexible'
}

const pendingClarifications = computed(() => {
  return clarifications.value.filter(c => !c.answer)
})

const answeredClarifications = computed(() => {
  return clarifications.value.filter(c => c.answer)
})

onMounted(async () => {
  await loadQuoteDetail()
})

async function loadQuoteDetail() {
  loading.value = true
  error.value = ''

  try {
    const quoteId = route.params.id as string

    if (!user.value?.id) {
      error.value = 'Utilisateur non connecté'
      return
    }

    const { data: quoteData, error: quoteError } = await supabase
      .from('quote_requests')
      .select('*')
      .eq('id', quoteId)
      .eq('requester_id', user.value.id)
      .maybeSingle()

    if (quoteError) throw quoteError
    if (!quoteData) {
      error.value = 'Demande de devis non trouvée'
      return
    }

    quoteRequest.value = quoteData

    const { data: proposalsData, error: proposalsError } = await supabase
      .from('quote_proposals')
      .select(`
        *,
        company:companies!producer_company_id(*)
      `)
      .eq('quote_request_id', quoteId)
      .order('created_at', { ascending: false })

    if (proposalsError) throw proposalsError
    proposals.value = proposalsData || []

    const { data: clarificationsData, error: clarificationsError } = await supabase
      .from('quote_clarifications')
      .select(`
        *,
        company:companies!producer_company_id(*)
      `)
      .eq('quote_request_id', quoteId)
      .order('created_at', { ascending: false })

    if (clarificationsError) throw clarificationsError
    clarifications.value = clarificationsData || []
  } catch (err) {
    console.error('Error loading quote detail:', err)
    error.value = 'Erreur lors du chargement des détails'
  } finally {
    loading.value = false
  }
}

async function answerClarification(clarificationId: string, answer: string) {
  if (!answer.trim()) {
    alert('Veuillez saisir une réponse')
    return
  }

  try {
    const { error } = await supabase
      .from('quote_clarifications')
      .update({
        answer: answer.trim(),
        answered_at: new Date().toISOString()
      })
      .eq('id', clarificationId)

    if (error) throw error

    if (quoteRequest.value) {
      await supabase
        .from('quote_requests')
        .update({ status: 'WAITING_FOR_INFO' })
        .eq('id', quoteRequest.value.id)
    }

    await loadQuoteDetail()
  } catch (err) {
    console.error('Error answering clarification:', err)
    alert('Erreur lors de l\'envoi de la réponse')
  }
}

async function acceptProposal(proposalId: string) {
  if (!confirm('Êtes-vous sûr de vouloir accepter cette proposition ?')) {
    return
  }

  try {
    const { error } = await supabase
      .from('quote_proposals')
      .update({
        status: 'ACCEPTED',
        accepted_at: new Date().toISOString()
      })
      .eq('id', proposalId)

    if (error) throw error

    await loadQuoteDetail()
    alert('Proposition acceptée !')
  } catch (err) {
    console.error('Error accepting proposal:', err)
    alert('Erreur lors de l\'acceptation de la proposition')
  }
}

async function rejectProposal(proposalId: string) {
  const reason = prompt('Pourquoi refusez-vous cette proposition ? (optionnel)')

  try {
    const { error } = await supabase
      .from('quote_proposals')
      .update({
        status: 'REJECTED',
        rejected_at: new Date().toISOString(),
        rejection_reason: reason?.trim() || null
      })
      .eq('id', proposalId)

    if (error) throw error

    await loadQuoteDetail()
    alert('Proposition refusée')
  } catch (err) {
    console.error('Error rejecting proposal:', err)
    alert('Erreur lors du refus de la proposition')
  }
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  }).format(date)
}

function formatDateTime(dateString: string) {
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('fr-FR', {
    day: 'numeric',
    month: 'long',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

function formatPrice(amount: number) {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR'
  }).format(amount)
}

function goBack() {
  router.push({ name: 'individual-quotes' })
}
</script>

<template>
  <IndividualDashboardLayout>
    <div class="quote-detail-page">
      <button class="btn-back" @click="goBack">
        ← Retour à mes demandes
      </button>

      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="error" class="error-message">
        {{ error }}
      </div>

      <div v-else-if="quoteRequest" class="quote-detail">
        <div class="quote-info-card">
          <div class="quote-header">
            <div>
              <h2>{{ quoteRequest.title }}</h2>
              <span
                class="status-badge"
                :style="{ backgroundColor: statusColors[quoteRequest.status] }"
              >
                {{ statusLabels[quoteRequest.status] }}
              </span>
            </div>
          </div>

          <div class="quote-details">
            <div class="detail-row">
              <span class="label">Date de création:</span>
              <span class="value">{{ formatDate(quoteRequest.created_at) }}</span>
            </div>

            <div v-if="quoteRequest.location" class="detail-row">
              <span class="label">Localisation:</span>
              <span class="value">{{ quoteRequest.location }}</span>
            </div>

            <div v-if="quoteRequest.urgency" class="detail-row">
              <span class="label">Délai souhaité:</span>
              <span class="value">{{ urgencyLabels[quoteRequest.urgency] }}</span>
            </div>
          </div>

          <div class="description-section">
            <h3>Description</h3>
            <p>{{ quoteRequest.description }}</p>
          </div>
        </div>

        <div v-if="pendingClarifications.length > 0" class="clarifications-section">
          <h3>Demandes de précisions en attente ({{ pendingClarifications.length }})</h3>

          <div
            v-for="clarification in pendingClarifications"
            :key="clarification.id"
            class="clarification-card pending"
          >
            <div class="company-header">
              <div class="company-logo">
                <img
                  v-if="clarification.company?.logo_url"
                  :src="clarification.company.logo_url"
                  :alt="clarification.company.name"
                />
                <span v-else class="logo-placeholder">
                  {{ clarification.company?.name?.[0] || '?' }}
                </span>
              </div>
              <div class="company-info">
                <h4>{{ clarification.company?.name || 'Entreprise' }}</h4>
                <p class="clarification-date">{{ formatDateTime(clarification.created_at) }}</p>
              </div>
            </div>

            <div class="clarification-question">
              <span class="question-label">Question:</span>
              <p>{{ clarification.question }}</p>
            </div>

            <form @submit.prevent="(e) => {
              const form = e.target as HTMLFormElement
              const input = form.querySelector('textarea') as HTMLTextAreaElement
              answerClarification(clarification.id, input.value)
              input.value = ''
            }" class="answer-form">
              <textarea
                placeholder="Votre réponse..."
                rows="3"
                required
              ></textarea>
              <button type="submit" class="btn-answer">Répondre</button>
            </form>
          </div>
        </div>

        <div class="proposals-section">
          <h3>Propositions de devis ({{ proposals.length }})</h3>

          <div v-if="proposals.length === 0 && pendingClarifications.length === 0" class="empty-responses">
            <span class="empty-icon">📭</span>
            <p>Aucune proposition pour le moment</p>
            <small>Les professionnels pourront consulter votre demande et vous envoyer leurs devis.</small>
          </div>

          <div v-else class="proposals-list">
            <div
              v-for="proposal in proposals"
              :key="proposal.id"
              class="proposal-card"
              :class="proposal.status.toLowerCase()"
            >
              <div class="company-header">
                <div class="company-logo">
                  <img
                    v-if="proposal.company?.logo_url"
                    :src="proposal.company.logo_url"
                    :alt="proposal.company.name"
                  />
                  <span v-else class="logo-placeholder">
                    {{ proposal.company?.name?.[0] || '?' }}
                  </span>
                </div>
                <div class="company-info">
                  <h4>{{ proposal.company?.name || 'Entreprise' }}</h4>
                  <p v-if="proposal.company?.city" class="company-location">
                    {{ proposal.company.city }}
                  </p>
                </div>
              </div>

              <div class="proposal-details">
                <div v-if="proposal.proposal_type === 'FIXED_PRICE'" class="price-info fixed">
                  <span class="price-label">Prix proposé</span>
                  <span class="price-value">{{ formatPrice(Number(proposal.proposed_amount)) }}</span>
                </div>

                <div v-else class="price-info range">
                  <span class="price-label">Fourchette de prix</span>
                  <div class="price-range">
                    <span class="price-min">{{ formatPrice(Number(proposal.price_min)) }}</span>
                    <span class="separator">→</span>
                    <span class="price-max">{{ formatPrice(Number(proposal.price_max)) }}</span>
                  </div>
                </div>

                <div v-if="proposal.delivery_time" class="delivery-info">
                  <span class="info-label">Délai d'intervention:</span>
                  <span class="info-value">{{ proposal.delivery_time }}</span>
                </div>

                <div v-if="proposal.proposal_message" class="message-info">
                  <span class="info-label">Message:</span>
                  <p class="info-value">{{ proposal.proposal_message }}</p>
                </div>
              </div>

              <div class="proposal-footer">
                <span class="proposal-date">{{ formatDateTime(proposal.created_at) }}</span>

                <div v-if="proposal.status === 'PENDING'" class="proposal-actions">
                  <button @click="rejectProposal(proposal.id)" class="btn-reject">
                    Refuser
                  </button>
                  <button @click="acceptProposal(proposal.id)" class="btn-accept">
                    Accepter
                  </button>
                </div>

                <span v-else-if="proposal.status === 'ACCEPTED'" class="status-indicator accepted">
                  ✓ Acceptée
                </span>

                <span v-else-if="proposal.status === 'REJECTED'" class="status-indicator rejected">
                  ✗ Refusée
                </span>
              </div>
            </div>
          </div>
        </div>

        <div v-if="answeredClarifications.length > 0" class="answered-clarifications-section">
          <h3>Précisions apportées ({{ answeredClarifications.length }})</h3>

          <div
            v-for="clarification in answeredClarifications"
            :key="clarification.id"
            class="clarification-card answered"
          >
            <div class="company-header">
              <div class="company-logo">
                <img
                  v-if="clarification.company?.logo_url"
                  :src="clarification.company.logo_url"
                  :alt="clarification.company.name"
                />
                <span v-else class="logo-placeholder">
                  {{ clarification.company?.name?.[0] || '?' }}
                </span>
              </div>
              <div class="company-info">
                <h4>{{ clarification.company?.name || 'Entreprise' }}</h4>
              </div>
            </div>

            <div class="clarification-exchange">
              <div class="question-block">
                <span class="block-label">Question:</span>
                <p>{{ clarification.question }}</p>
                <span class="block-date">{{ formatDateTime(clarification.created_at) }}</span>
              </div>

              <div class="answer-block">
                <span class="block-label">Votre réponse:</span>
                <p>{{ clarification.answer }}</p>
                <span class="block-date">{{ formatDateTime(clarification.answered_at!) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </IndividualDashboardLayout>
</template>

<style scoped>
.quote-detail-page {
  max-width: 1000px;
  margin: 0 auto;
}

.btn-back {
  padding: 8px 16px;
  background: white;
  color: #374151;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 24px;
}

.btn-back:hover {
  background: #f3f4f6;
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

.quote-detail {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.quote-info-card {
  background: white;
  padding: 32px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.quote-header {
  margin-bottom: 24px;
}

.quote-header > div {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.quote-header h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.status-badge {
  padding: 6px 14px;
  border-radius: 14px;
  font-size: 13px;
  font-weight: 600;
  color: white;
}

.quote-details {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 16px;
  padding: 20px;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 24px;
}

.detail-row {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-row .label {
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-row .value {
  font-size: 15px;
  color: #111827;
  font-weight: 500;
}

.description-section h3 {
  font-size: 18px;
  font-weight: 600;
  color: #111827;
  margin: 0 0 12px 0;
}

.description-section p {
  font-size: 15px;
  color: #374151;
  line-height: 1.6;
  margin: 0;
  white-space: pre-wrap;
}

.proposals-section,
.clarifications-section,
.answered-clarifications-section {
  background: white;
  padding: 32px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.proposals-section h3,
.clarifications-section h3,
.answered-clarifications-section h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 24px 0;
}

.empty-responses {
  text-align: center;
  padding: 60px 24px;
}

.empty-icon {
  font-size: 48px;
  display: block;
  margin-bottom: 16px;
}

.empty-responses p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 8px 0;
}

.empty-responses small {
  font-size: 14px;
  color: #9ca3af;
}

.proposals-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.proposal-card,
.clarification-card {
  padding: 24px;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  transition: all 0.2s;
}

.proposal-card.accepted {
  border-color: #10b981;
  background: #f0fdf4;
}

.proposal-card.rejected {
  border-color: #ef4444;
  background: #fef2f2;
  opacity: 0.7;
}

.clarification-card.pending {
  border-color: #f59e0b;
  background: #fffbeb;
}

.company-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
}

.company-logo {
  width: 60px;
  height: 60px;
  border-radius: 8px;
  overflow: hidden;
  flex-shrink: 0;
}

.company-logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.logo-placeholder {
  width: 100%;
  height: 100%;
  background: #2563eb;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: 700;
}

.company-info h4 {
  font-size: 18px;
  font-weight: 600;
  color: #111827;
  margin: 0 0 4px 0;
}

.company-location,
.clarification-date {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.proposal-details {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 16px;
}

.price-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.price-label {
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.price-value {
  font-size: 32px;
  font-weight: 700;
  color: #2563eb;
}

.price-range {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 24px;
  font-weight: 700;
  color: #2563eb;
}

.separator {
  color: #6b7280;
  font-size: 18px;
}

.delivery-info,
.message-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
}

.info-value {
  font-size: 15px;
  color: #111827;
  margin: 0;
  line-height: 1.6;
}

.proposal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 16px;
  border-top: 1px solid #e5e7eb;
}

.proposal-date {
  font-size: 13px;
  color: #9ca3af;
}

.proposal-actions {
  display: flex;
  gap: 8px;
}

.btn-accept,
.btn-reject {
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-accept {
  background: #10b981;
  color: white;
}

.btn-accept:hover {
  background: #059669;
  transform: translateY(-1px);
}

.btn-reject {
  background: #f3f4f6;
  color: #6b7280;
}

.btn-reject:hover {
  background: #e5e7eb;
}

.status-indicator {
  font-size: 14px;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: 8px;
}

.status-indicator.accepted {
  background: #d1fae5;
  color: #065f46;
}

.status-indicator.rejected {
  background: #fee2e2;
  color: #991b1b;
}

.clarification-question {
  margin-bottom: 16px;
}

.question-label {
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
  display: block;
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.clarification-question p {
  font-size: 15px;
  color: #111827;
  margin: 0;
  line-height: 1.6;
}

.answer-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.answer-form textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 15px;
  font-family: inherit;
  resize: vertical;
  transition: border-color 0.2s;
}

.answer-form textarea:focus {
  outline: none;
  border-color: #2563eb;
}

.btn-answer {
  align-self: flex-end;
  padding: 10px 20px;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-answer:hover {
  background: #1d4ed8;
  transform: translateY(-1px);
}

.clarification-exchange {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.question-block,
.answer-block {
  padding: 16px;
  border-radius: 8px;
}

.question-block {
  background: #f9fafb;
}

.answer-block {
  background: #eff6ff;
}

.block-label {
  font-size: 12px;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  display: block;
  margin-bottom: 8px;
}

.question-block p,
.answer-block p {
  margin: 0 0 8px 0;
  color: #111827;
  line-height: 1.6;
}

.block-date {
  font-size: 12px;
  color: #9ca3af;
}

@media (max-width: 768px) {
  .quote-info-card,
  .proposals-section,
  .clarifications-section,
  .answered-clarifications-section {
    padding: 24px;
  }

  .quote-details {
    grid-template-columns: 1fr;
  }

  .company-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .proposal-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .proposal-actions {
    width: 100%;
  }

  .btn-accept,
  .btn-reject {
    flex: 1;
  }
}
</style>
