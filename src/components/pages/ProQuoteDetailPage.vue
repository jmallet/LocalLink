<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user, currentCompany } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { QuoteRequest, Company, Profile } from '../../types/database'

interface QuoteWithDetails extends QuoteRequest {
  target_company?: Company
  requester?: Profile
}

interface QuoteProposal {
  id: string
  quote_request_id: string
  producer_company_id: string
  proposal_type: 'FIXED_PRICE' | 'PRICE_RANGE'
  proposed_amount: number | null
  price_min: number | null
  price_max: number | null
  proposal_message: string | null
  delivery_time: string | null
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED'
  accepted_at: string | null
  rejected_at: string | null
  rejection_reason: string | null
  created_at: string
  updated_at: string
}

interface QuoteClarification {
  id: string
  quote_request_id: string
  producer_company_id: string
  question: string
  answer: string | null
  answered_at: string | null
  created_at: string
  updated_at: string
}

const route = useRoute()
const router = useRouter()
const loading = ref(true)
const quote = ref<QuoteWithDetails | null>(null)

const proposal = ref<QuoteProposal | null>(null)
const clarifications = ref<QuoteClarification[]>([])

const showResponseModal = ref(false)
const responseType = ref<'FIXED_PRICE' | 'PRICE_RANGE' | 'CLARIFICATION' | null>(null)

const proposalForm = ref({
  fixedPrice: null as number | null,
  priceMin: null as number | null,
  priceMax: null as number | null,
  message: '',
  deliveryTime: ''
})

const clarificationQuestion = ref('')
const submittingResponse = ref(false)

const hasActiveProposal = computed(() => {
  return proposal.value && (proposal.value.status === 'PENDING' || proposal.value.status === 'ACCEPTED')
})

const hasClarification = computed(() => {
  return clarifications.value.some(c => !c.answer)
})

onMounted(async () => {
  await loadQuote()
})

async function loadQuote() {
  const quoteId = route.params.id as string

  loading.value = true
  try {
    const { data, error } = await supabase
      .from('quote_requests')
      .select(`
        *,
        target_company:companies!quote_requests_target_company_id_fkey(*),
        requester:profiles!quote_requests_requester_id_profiles_fkey(*)
      `)
      .eq('id', quoteId)
      .single()

    if (error) throw error

    quote.value = data

    if (quote.value.status === 'SENT' && quote.value.target_company_id === currentCompany.value?.id) {
      await supabase
        .from('quote_requests')
        .update({ status: 'VIEWED' })
        .eq('id', quoteId)

      if (quote.value) {
        quote.value.status = 'VIEWED'
      }
    }

    const { data: proposalData } = await supabase
      .from('quote_proposals')
      .select('*')
      .eq('quote_request_id', quoteId)
      .eq('producer_company_id', currentCompany.value?.id)
      .maybeSingle()

    proposal.value = proposalData

    const { data: clarificationsData } = await supabase
      .from('quote_clarifications')
      .select('*')
      .eq('quote_request_id', quoteId)
      .eq('producer_company_id', currentCompany.value?.id)
      .order('created_at', { ascending: true })

    clarifications.value = clarificationsData || []
  } catch (error) {
    console.error('Error loading quote:', error)
    router.push({ name: 'pro-dashboard' })
  } finally {
    loading.value = false
  }
}

async function closeQuote() {
  if (!quote.value) return

  try {
    await supabase
      .from('quote_requests')
      .update({ status: 'CLOSED' })
      .eq('id', quote.value.id)

    if (quote.value) {
      quote.value.status = 'CLOSED'
    }
  } catch (error) {
    console.error('Error closing quote:', error)
  }
}

function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    SENT: 'Nouveau',
    VIEWED: 'Vu',
    RESPONDED: 'Répondu',
    ACCEPTED: 'Validé',
    WAITING_FOR_INFO: 'En attente d\'infos',
    CLOSED: 'Fermé'
  }
  return labels[status] || status
}

function getOriginLabel(type: string): string {
  return type === 'PARTICULIER' ? 'Particulier' : 'Professionnel'
}

function openResponseModal(type: 'FIXED_PRICE' | 'PRICE_RANGE' | 'CLARIFICATION') {
  responseType.value = type
  showResponseModal.value = true

  if (type !== 'CLARIFICATION' && proposal.value) {
    if (proposal.value.proposal_type === 'FIXED_PRICE') {
      proposalForm.value.fixedPrice = proposal.value.proposed_amount ? Number(proposal.value.proposed_amount) : null
    } else {
      proposalForm.value.priceMin = proposal.value.price_min ? Number(proposal.value.price_min) : null
      proposalForm.value.priceMax = proposal.value.price_max ? Number(proposal.value.price_max) : null
    }
    proposalForm.value.message = proposal.value.proposal_message || ''
    proposalForm.value.deliveryTime = proposal.value.delivery_time || ''
  }
}

function closeResponseModal() {
  showResponseModal.value = false
  responseType.value = null
  proposalForm.value = {
    fixedPrice: null,
    priceMin: null,
    priceMax: null,
    message: '',
    deliveryTime: ''
  }
  clarificationQuestion.value = ''
}

async function submitResponse() {
  if (!quote.value || !currentCompany.value) return

  submittingResponse.value = true
  try {
    if (responseType.value === 'CLARIFICATION') {
      if (!clarificationQuestion.value.trim()) {
        alert('Veuillez saisir votre question')
        return
      }

      const { data, error } = await supabase
        .from('quote_clarifications')
        .insert({
          quote_request_id: quote.value.id,
          producer_company_id: currentCompany.value.id,
          question: clarificationQuestion.value.trim()
        })
        .select()
        .single()

      if (error) throw error

      clarifications.value.push(data)

      await supabase
        .from('quote_requests')
        .update({ status: 'WAITING_FOR_INFO' })
        .eq('id', quote.value.id)

      if (quote.value) {
        quote.value.status = 'WAITING_FOR_INFO'
      }

      alert('Votre demande de précisions a été envoyée !')
    } else if (responseType.value === 'FIXED_PRICE') {
      if (!proposalForm.value.fixedPrice) {
        alert('Veuillez saisir un montant')
        return
      }

      if (proposal.value) {
        const { data, error } = await supabase
          .from('quote_proposals')
          .update({
            proposal_type: 'FIXED_PRICE',
            proposed_amount: proposalForm.value.fixedPrice,
            price_min: null,
            price_max: null,
            proposal_message: proposalForm.value.message.trim() || null,
            delivery_time: proposalForm.value.deliveryTime.trim() || null,
            updated_at: new Date().toISOString()
          })
          .eq('id', proposal.value.id)
          .select()
          .single()

        if (error) throw error
        proposal.value = data
      } else {
        const { data, error } = await supabase
          .from('quote_proposals')
          .insert({
            quote_request_id: quote.value.id,
            producer_company_id: currentCompany.value.id,
            proposal_type: 'FIXED_PRICE',
            proposed_amount: proposalForm.value.fixedPrice,
            proposal_message: proposalForm.value.message.trim() || null,
            delivery_time: proposalForm.value.deliveryTime.trim() || null
          })
          .select()
          .single()

        if (error) throw error
        proposal.value = data
      }

      await supabase
        .from('quote_requests')
        .update({ status: 'RESPONDED' })
        .eq('id', quote.value.id)

      if (quote.value) {
        quote.value.status = 'RESPONDED'
      }

      alert('Votre proposition de prix a été envoyée !')
    } else if (responseType.value === 'PRICE_RANGE') {
      if (!proposalForm.value.priceMin || !proposalForm.value.priceMax) {
        alert('Veuillez saisir les deux montants')
        return
      }

      if (proposalForm.value.priceMin >= proposalForm.value.priceMax) {
        alert('Le prix minimum doit être inférieur au prix maximum')
        return
      }

      if (proposal.value) {
        const { data, error } = await supabase
          .from('quote_proposals')
          .update({
            proposal_type: 'PRICE_RANGE',
            proposed_amount: null,
            price_min: proposalForm.value.priceMin,
            price_max: proposalForm.value.priceMax,
            proposal_message: proposalForm.value.message.trim() || null,
            delivery_time: proposalForm.value.deliveryTime.trim() || null,
            updated_at: new Date().toISOString()
          })
          .eq('id', proposal.value.id)
          .select()
          .single()

        if (error) throw error
        proposal.value = data
      } else {
        const { data, error } = await supabase
          .from('quote_proposals')
          .insert({
            quote_request_id: quote.value.id,
            producer_company_id: currentCompany.value.id,
            proposal_type: 'PRICE_RANGE',
            price_min: proposalForm.value.priceMin,
            price_max: proposalForm.value.priceMax,
            proposal_message: proposalForm.value.message.trim() || null,
            delivery_time: proposalForm.value.deliveryTime.trim() || null
          })
          .select()
          .single()

        if (error) throw error
        proposal.value = data
      }

      await supabase
        .from('quote_requests')
        .update({ status: 'RESPONDED' })
        .eq('id', quote.value.id)

      if (quote.value) {
        quote.value.status = 'RESPONDED'
      }

      alert('Votre fourchette de prix a été envoyée !')
    }

    closeResponseModal()
  } catch (error) {
    console.error('Error submitting response:', error)
    alert('Erreur lors de l\'envoi de la réponse')
  } finally {
    submittingResponse.value = false
  }
}

function getProposalStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    PENDING: 'En attente',
    ACCEPTED: 'Acceptée',
    REJECTED: 'Refusée'
  }
  return labels[status] || status
}

function getUrgencyLabel(urgency: string | undefined): string {
  if (!urgency) return ''
  const labels: Record<string, string> = {
    URGENT_48H: '🔥 Urgent (48h)',
    THIS_WEEK: '⚡ Cette semaine',
    FLEXIBLE: '📅 Flexible'
  }
  return labels[urgency] || urgency
}

function unlockContact() {
  alert('Paiement de 10 €\n\nVous allez être redirigé vers la page de paiement pour débloquer les coordonnées du client.\n\nFonctionnalité en cours de développement.')
}
</script>

<template>
  <DashboardLayout>
    <div class="pro-quote-detail">
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="quote" class="content">
        <div class="header">
          <button @click="router.back()" class="btn-back">← Retour</button>
          <div class="header-actions">
            <span class="status-badge" :class="quote.status.toLowerCase()">
              {{ getStatusLabel(quote.status) }}
            </span>
            <button
              v-if="quote.status !== 'CLOSED'"
              @click="closeQuote"
              class="btn-close-quote"
            >
              Fermer la demande
            </button>
          </div>
        </div>

        <div class="quote-info">
          <h1>{{ quote.title }}</h1>

          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">Origine</span>
              <span class="info-value">{{ getOriginLabel(quote.requester_type) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Date</span>
              <span class="info-value">{{ new Date(quote.created_at).toLocaleDateString('fr-FR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              }) }}</span>
            </div>
            <div v-if="quote.urgency" class="info-item">
              <span class="info-label">Délai souhaité</span>
              <span class="info-value urgency">{{ getUrgencyLabel(quote.urgency) }}</span>
            </div>
            <div v-if="quote.location" class="info-item">
              <span class="info-label">Localisation</span>
              <span class="info-value">{{ quote.location }}</span>
            </div>
            <div v-if="quote.volume_estimated" class="info-item">
              <span class="info-label">Volume estimé</span>
              <span class="info-value">{{ quote.volume_estimated }}</span>
            </div>
            <div v-if="quote.frequency" class="info-item">
              <span class="info-label">Fréquence</span>
              <span class="info-value">{{ quote.frequency }}</span>
            </div>
            <div v-if="quote.budget_range" class="info-item">
              <span class="info-label">Budget</span>
              <span class="info-value">{{ quote.budget_range }}</span>
            </div>
          </div>

          <div v-if="quote.description" class="description">
            <h2>Description</h2>
            <p>{{ quote.description }}</p>
          </div>
        </div>

        <div v-if="!hasActiveProposal && quote.status !== 'CLOSED'" class="response-actions">
          <h2>Votre réponse</h2>
          <p class="response-subtitle">Choisissez comment répondre à cette demande :</p>

          <div class="action-buttons">
            <button @click="openResponseModal('FIXED_PRICE')" class="action-btn fixed-price">
              <span class="action-icon">💰</span>
              <span class="action-title">Proposer un prix</span>
              <span class="action-desc">Montant fixe + détails</span>
            </button>

            <button @click="openResponseModal('PRICE_RANGE')" class="action-btn price-range">
              <span class="action-icon">📊</span>
              <span class="action-title">Proposer une fourchette</span>
              <span class="action-desc">Prix min / max</span>
            </button>

            <button @click="openResponseModal('CLARIFICATION')" class="action-btn clarification">
              <span class="action-icon">❓</span>
              <span class="action-title">Demander des précisions</span>
              <span class="action-desc">Poser une question</span>
            </button>
          </div>
        </div>

        <div v-if="proposal" class="existing-proposal">
          <h2>Votre proposition</h2>

          <div class="proposal-card">
            <div class="proposal-header">
              <span class="proposal-status" :class="proposal.status.toLowerCase()">
                {{ getProposalStatusLabel(proposal.status) }}
              </span>
              <button
                v-if="proposal.status === 'PENDING'"
                @click="openResponseModal(proposal.proposal_type)"
                class="btn-edit-proposal"
              >
                Modifier
              </button>
            </div>

            <div class="proposal-details">
              <div v-if="proposal.proposal_type === 'FIXED_PRICE'" class="proposal-amount">
                <span class="label">Montant proposé</span>
                <span class="amount">{{ Number(proposal.proposed_amount).toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' }) }}</span>
              </div>

              <div v-else class="proposal-range">
                <span class="label">Fourchette de prix</span>
                <div class="range-values">
                  <span class="range-min">{{ Number(proposal.price_min).toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' }) }}</span>
                  <span class="range-separator">→</span>
                  <span class="range-max">{{ Number(proposal.price_max).toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' }) }}</span>
                </div>
              </div>

              <div v-if="proposal.delivery_time" class="proposal-info">
                <span class="label">Délai d'intervention</span>
                <span class="value">{{ proposal.delivery_time }}</span>
              </div>

              <div v-if="proposal.proposal_message" class="proposal-message">
                <span class="label">Détails</span>
                <p>{{ proposal.proposal_message }}</p>
              </div>

              <div v-if="proposal.status === 'ACCEPTED'" class="proposal-accepted-info">
                <span class="success-icon">✓</span>
                <span>Proposition acceptée le {{ new Date(proposal.accepted_at!).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }) }}</span>
              </div>

              <div v-if="proposal.status === 'REJECTED'" class="proposal-rejected-info">
                <span class="error-icon">✗</span>
                <div>
                  <p>Proposition refusée le {{ new Date(proposal.rejected_at!).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }) }}</p>
                  <p v-if="proposal.rejection_reason" class="rejection-reason">Raison: {{ proposal.rejection_reason }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-if="proposal && proposal.status === 'ACCEPTED'" class="contact-info-section">
          <h2>Coordonnées du client</h2>

          <div class="unlock-card">
            <div class="unlock-header">
              <span class="unlock-icon">🔓</span>
              <div>
                <h3>Proposition acceptée !</h3>
                <p>Le client souhaite poursuivre avec vous pour établir un devis final.</p>
              </div>
            </div>

            <div class="unlock-info">
              <div class="info-box">
                <span class="info-icon">ℹ️</span>
                <div>
                  <p class="info-title">Pour accéder aux coordonnées du client :</p>
                  <ul class="info-list">
                    <li>Coût : <strong>10 €</strong> (paiement unique par lead)</li>
                    <li>Accès immédiat aux coordonnées complètes</li>
                    <li>Contactez le client pour finaliser le devis</li>
                  </ul>
                </div>
              </div>

              <button class="btn-unlock" @click="unlockContact">
                💳 Débloquer les coordonnées (10 €)
              </button>
            </div>

            <div class="contact-details">
              <p class="contact-preview">
                <strong>Nom :</strong> {{ quote.requester?.first_name || 'Client' }} {{ quote.requester?.last_name?.[0] || '' }}.
              </p>
              <p class="contact-locked">📞 Téléphone : <span class="blurred">06 XX XX XX XX</span></p>
              <p class="contact-locked">✉️ Email : <span class="blurred">xxx@xxxxx.xx</span></p>
            </div>
          </div>
        </div>

        <div v-if="clarifications.length > 0" class="clarifications-section">
          <h2>Demandes de précisions</h2>

          <div v-for="clarification in clarifications" :key="clarification.id" class="clarification-card">
            <div class="clarification-question">
              <span class="question-icon">❓</span>
              <div>
                <span class="question-label">Votre question</span>
                <p>{{ clarification.question }}</p>
                <span class="question-date">{{ new Date(clarification.created_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' }) }}</span>
              </div>
            </div>

            <div v-if="clarification.answer" class="clarification-answer">
              <span class="answer-icon">💬</span>
              <div>
                <span class="answer-label">Réponse du client</span>
                <p>{{ clarification.answer }}</p>
                <span class="answer-date">{{ new Date(clarification.answered_at!).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' }) }}</span>
              </div>
            </div>

            <div v-else class="waiting-answer">
              <span>⏳ En attente de réponse du client</span>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showResponseModal" class="modal-overlay" @click="closeResponseModal">
        <div class="modal-content response-modal" @click.stop>
          <h3 v-if="responseType === 'FIXED_PRICE'">Proposer un prix</h3>
          <h3 v-else-if="responseType === 'PRICE_RANGE'">Proposer une fourchette</h3>
          <h3 v-else>Demander des précisions</h3>

          <form @submit.prevent="submitResponse" class="response-form">
            <template v-if="responseType === 'FIXED_PRICE'">
              <div class="form-group">
                <label for="fixedPrice">Montant (€) *</label>
                <input
                  id="fixedPrice"
                  v-model.number="proposalForm.fixedPrice"
                  type="number"
                  step="0.01"
                  min="0"
                  required
                  placeholder="ex: 1500.00"
                />
              </div>

              <div class="form-group">
                <label for="deliveryTime">Délai d'intervention</label>
                <input
                  id="deliveryTime"
                  v-model="proposalForm.deliveryTime"
                  type="text"
                  placeholder="ex: 2-3 jours"
                />
              </div>

              <div class="form-group">
                <label for="message">Commentaire (conditions, inclus/non inclus)</label>
                <textarea
                  id="message"
                  v-model="proposalForm.message"
                  rows="4"
                  placeholder="Décrivez ce qui est inclus, les conditions..."
                ></textarea>
              </div>
            </template>

            <template v-else-if="responseType === 'PRICE_RANGE'">
              <div class="form-row">
                <div class="form-group">
                  <label for="priceMin">Prix minimum (€) *</label>
                  <input
                    id="priceMin"
                    v-model.number="proposalForm.priceMin"
                    type="number"
                    step="0.01"
                    min="0"
                    required
                    placeholder="ex: 1000.00"
                  />
                </div>

                <div class="form-group">
                  <label for="priceMax">Prix maximum (€) *</label>
                  <input
                    id="priceMax"
                    v-model.number="proposalForm.priceMax"
                    type="number"
                    step="0.01"
                    min="0"
                    required
                    placeholder="ex: 2000.00"
                  />
                </div>
              </div>

              <div class="form-group">
                <label for="deliveryTime">Délai d'intervention</label>
                <input
                  id="deliveryTime"
                  v-model="proposalForm.deliveryTime"
                  type="text"
                  placeholder="ex: 2-3 jours"
                />
              </div>

              <div class="form-group">
                <label for="message">Commentaire explicatif</label>
                <textarea
                  id="message"
                  v-model="proposalForm.message"
                  rows="4"
                  placeholder="Expliquez la fourchette de prix..."
                ></textarea>
              </div>
            </template>

            <template v-else-if="responseType === 'CLARIFICATION'">
              <div class="form-group">
                <label for="clarificationQuestion">Votre question *</label>
                <textarea
                  id="clarificationQuestion"
                  v-model="clarificationQuestion"
                  rows="4"
                  required
                  placeholder="Pouvez-vous me préciser..."
                ></textarea>
              </div>
            </template>

            <div class="modal-actions">
              <button type="button" @click="closeResponseModal" class="btn-cancel" :disabled="submittingResponse">
                Annuler
              </button>
              <button type="submit" class="btn-submit" :disabled="submittingResponse">
                {{ submittingResponse ? 'Envoi...' : 'Envoyer' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.pro-quote-detail {
  padding: 2rem;
  max-width: 1000px;
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

.content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.btn-back {
  padding: 0.5rem 1rem;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-back:hover {
  background: #f9fafb;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.status-badge {
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 600;
  font-size: 0.875rem;
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
  background: #e0e7ff;
  color: #3730a3;
}

.status-badge.accepted {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.waiting_for_info {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.closed {
  background: #f3f4f6;
  color: #4b5563;
}

.btn-close-quote {
  padding: 0.5rem 1rem;
  background: #dc2626;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-close-quote:hover {
  background: #b91c1c;
}

.quote-info {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 2rem;
}

.quote-info h1 {
  margin: 0 0 1.5rem 0;
  font-size: 1.875rem;
  font-weight: 700;
  color: #1a1a1a;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.info-label {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

.info-value {
  font-size: 1rem;
  color: #1a1a1a;
  font-weight: 600;
}

.info-value.urgency {
  font-size: 0.95rem;
}

.description {
  padding-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
}

.description h2 {
  margin: 0 0 1rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1a1a1a;
}

.description p {
  margin: 0;
  color: #374151;
  line-height: 1.6;
  white-space: pre-wrap;
}

.response-actions {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 2rem;
}

.response-actions h2 {
  margin: 0 0 0.5rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1a1a1a;
}

.response-subtitle {
  margin: 0 0 1.5rem 0;
  color: #6b7280;
}

.action-buttons {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.action-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  padding: 1.5rem;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.action-btn:hover {
  border-color: #2563eb;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.15);
}

.action-icon {
  font-size: 2rem;
}

.action-title {
  font-weight: 600;
  font-size: 0.95rem;
  color: #111827;
  text-align: center;
}

.action-desc {
  font-size: 0.875rem;
  color: #6b7280;
  text-align: center;
}

.existing-proposal,
.clarifications-section {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 2rem;
}

.existing-proposal h2,
.clarifications-section h2 {
  margin: 0 0 1.5rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1a1a1a;
}

.proposal-card {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.proposal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.proposal-status {
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 600;
  font-size: 0.875rem;
}

.proposal-status.pending {
  background: #fef3c7;
  color: #92400e;
}

.proposal-status.accepted {
  background: #d1fae5;
  color: #065f46;
}

.proposal-status.rejected {
  background: #fee2e2;
  color: #991b1b;
}

.btn-edit-proposal {
  padding: 0.5rem 1rem;
  background: #f3f4f6;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-edit-proposal:hover {
  background: #e5e7eb;
}

.proposal-details {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 8px;
}

.proposal-amount,
.proposal-range {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.proposal-amount .amount {
  font-size: 2rem;
  font-weight: 700;
  color: #2563eb;
}

.range-values {
  display: flex;
  align-items: center;
  gap: 1rem;
  font-size: 1.5rem;
  font-weight: 700;
  color: #2563eb;
}

.range-separator {
  color: #6b7280;
  font-size: 1.25rem;
}

.proposal-info,
.proposal-message {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.proposal-details .label {
  font-size: 0.875rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.proposal-details .value {
  font-size: 1rem;
  color: #1a1a1a;
}

.proposal-message p {
  margin: 0;
  color: #374151;
  line-height: 1.6;
  white-space: pre-wrap;
}

.proposal-accepted-info,
.proposal-rejected-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  border-radius: 8px;
}

.proposal-accepted-info {
  background: #d1fae5;
  color: #065f46;
}

.proposal-rejected-info {
  background: #fee2e2;
  color: #991b1b;
}

.success-icon,
.error-icon {
  font-size: 1.5rem;
  font-weight: 700;
}

.rejection-reason {
  margin-top: 0.5rem;
  font-size: 0.875rem;
  opacity: 0.9;
}

.clarification-card {
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 1rem;
}

.clarification-card:last-child {
  margin-bottom: 0;
}

.clarification-question,
.clarification-answer {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.clarification-answer {
  margin-bottom: 0;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
}

.question-icon,
.answer-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.question-label,
.answer-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  display: block;
  margin-bottom: 0.5rem;
}

.clarification-question p,
.clarification-answer p {
  margin: 0 0 0.5rem 0;
  color: #1a1a1a;
  line-height: 1.6;
}

.question-date,
.answer-date {
  font-size: 0.75rem;
  color: #9ca3af;
}

.contact-info-section {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

.contact-info-section h2 {
  margin: 0 0 1.5rem 0;
  font-size: 1.5rem;
  font-weight: 700;
  color: #111827;
}

.unlock-card {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.unlock-header {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 1.5rem;
  background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
  border-radius: 8px;
}

.unlock-icon {
  font-size: 2rem;
  flex-shrink: 0;
}

.unlock-header h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.25rem;
  font-weight: 700;
  color: #065f46;
}

.unlock-header p {
  margin: 0;
  color: #047857;
  font-size: 0.95rem;
}

.unlock-info {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.info-box {
  display: flex;
  gap: 1rem;
  padding: 1.5rem;
  background: #eff6ff;
  border-radius: 8px;
  border-left: 4px solid #2563eb;
}

.info-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.info-title {
  margin: 0 0 0.75rem 0;
  font-weight: 600;
  color: #1e40af;
  font-size: 1rem;
}

.info-list {
  margin: 0;
  padding-left: 1.25rem;
  color: #1e40af;
  font-size: 0.95rem;
}

.info-list li {
  margin-bottom: 0.5rem;
}

.info-list li:last-child {
  margin-bottom: 0;
}

.btn-unlock {
  align-self: center;
  padding: 1rem 2rem;
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: 700;
  font-size: 1.05rem;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
}

.btn-unlock:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(37, 99, 235, 0.4);
  background: linear-gradient(135deg, #1d4ed8 0%, #1e40af 100%);
}

.contact-details {
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 8px;
  border: 1px dashed #d1d5db;
}

.contact-preview,
.contact-locked {
  margin: 0 0 0.75rem 0;
  color: #374151;
  font-size: 0.95rem;
}

.contact-preview strong,
.contact-locked strong {
  font-weight: 600;
  color: #111827;
}

.contact-locked:last-child {
  margin-bottom: 0;
}

.blurred {
  filter: blur(4px);
  user-select: none;
  color: #9ca3af;
}

.waiting-answer {
  padding: 1rem;
  background: #fffbeb;
  border-radius: 6px;
  text-align: center;
  color: #92400e;
  font-size: 0.875rem;
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

.modal-content {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-content h3 {
  margin: 0 0 1.5rem 0;
  font-size: 1.5rem;
  font-weight: 700;
  color: #111827;
}

.response-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-weight: 600;
  color: #374151;
  font-size: 0.875rem;
}

.form-group input,
.form-group textarea {
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 1rem;
  font-family: inherit;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #2563eb;
}

.form-group textarea {
  resize: vertical;
}

.info-text {
  padding: 1rem;
  background: #eff6ff;
  border-radius: 8px;
  color: #1e40af;
  font-size: 0.875rem;
  margin: 0;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 0.5rem;
}

.btn-cancel,
.btn-submit {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel {
  background: white;
  border: 1px solid #d1d5db;
  color: #374151;
}

.btn-cancel:hover:not(:disabled) {
  background: #f9fafb;
}

.btn-submit {
  background: #2563eb;
  color: white;
  border: none;
}

.btn-submit:hover:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
}

.btn-cancel:disabled,
.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .pro-quote-detail {
    padding: 1rem;
  }

  .header {
    flex-direction: column;
    align-items: stretch;
  }

  .header-actions {
    justify-content: space-between;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .action-buttons {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
