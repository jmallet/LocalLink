<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { Company } from '../../types/database'

interface QuoteWithDetails {
  id: string
  unlocked: boolean
  unlocked_at: string | null
  created_at: string
  quote_request?: {
    id: string
    title: string
    description: string
    deadline: string | null
    category: string
    created_at: string
    requester_company?: Company
  }
}

interface TokenBalance {
  token_balance: number
  total_purchased: number
}

const company = ref<Company | null>(null)
const quotes = ref<QuoteWithDetails[]>([])
const tokenBalance = ref<TokenBalance | null>(null)
const loading = ref(true)
const selectedQuote = ref<QuoteWithDetails | null>(null)
const showDetailModal = ref(false)
const showTokenModal = ref(false)
const tokenAmount = ref(10)
const unlocking = ref(false)
const purchasing = ref(false)
const message = ref({ type: '', text: '' })

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
      const [quotesRes, tokensRes] = await Promise.all([
        supabase
          .from('quote_recipients')
          .select(`
            *,
            quote_request:quote_requests!quote_recipients_quote_request_id_fkey (
              id,
              title,
              description,
              category,
              deadline,
              created_at,
              requester_company:companies!quote_requests_buyer_company_id_fkey (
                id,
                company_name,
                city,
                logo_url,
                phone,
                email
              )
            )
          `)
          .eq('producer_company_id', companyData.id)
          .eq('quote_request.approved_by_admin', true)
          .order('created_at', { ascending: false }),
        supabase
          .from('company_tokens')
          .select('token_balance, total_purchased')
          .eq('company_id', companyData.id)
          .maybeSingle()
      ])

      quotes.value = quotesRes.data || []
      tokenBalance.value = tokensRes.data || { token_balance: 0, total_purchased: 0 }
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
}

function closeDetailModal() {
  showDetailModal.value = false
  selectedQuote.value = null
}

function openTokenModal() {
  showTokenModal.value = true
  message.value = { type: '', text: '' }
}

function closeTokenModal() {
  showTokenModal.value = false
  tokenAmount.value = 10
}

async function unlockQuote(quote: QuoteWithDetails) {
  if (!company.value) return

  if (tokenBalance.value && tokenBalance.value.token_balance < 1) {
    openTokenModal()
    return
  }

  unlocking.value = true
  message.value = { type: '', text: '' }

  try {
    const { data, error } = await supabase.rpc('unlock_quote_with_token', {
      p_company_id: company.value.id,
      p_quote_recipient_id: quote.id
    })

    if (error) throw error

    const result = data as { success: boolean; error?: string; balance?: number }

    if (!result.success) {
      if (result.error === 'Insufficient tokens') {
        openTokenModal()
      } else {
        throw new Error(result.error || 'Erreur inconnue')
      }
      return
    }

    await loadData()

    if (selectedQuote.value && selectedQuote.value.id === quote.id) {
      selectedQuote.value.unlocked = true
    }

    message.value = {
      type: 'success',
      text: 'Devis déverrouillé avec succès !'
    }

    setTimeout(() => {
      message.value = { type: '', text: '' }
    }, 3000)
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    unlocking.value = false
  }
}

async function purchaseTokens() {
  if (!company.value || tokenAmount.value < 1) return

  purchasing.value = true
  message.value = { type: '', text: '' }

  try {
    const { data, error } = await supabase.functions.invoke('create-token-checkout', {
      body: {
        tokenAmount: tokenAmount.value,
        companyId: company.value.id
      }
    })

    if (error) {
      throw new Error(error.message)
    }

    if (data?.error) {
      throw new Error(data.error)
    }

    if (data?.url) {
      window.open(data.url, '_blank')
      closeTokenModal()
      message.value = {
        type: 'success',
        text: 'Redirection vers le paiement dans un nouvel onglet...'
      }
    }
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    purchasing.value = false
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

const tokenPrice = 5
const totalPrice = computed(() => tokenAmount.value * tokenPrice)
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
          <div class="token-info">
            <div class="token-balance">
              <span class="token-icon">🪙</span>
              <span class="token-count">{{ tokenBalance?.token_balance || 0 }}</span>
              <span class="token-label">jetons</span>
            </div>
            <button class="btn-buy-tokens" @click="openTokenModal">
              Acheter des jetons
            </button>
          </div>
        </div>

        <div v-if="message.text" class="message" :class="message.type">
          {{ message.text }}
        </div>

        <div v-if="quotes.length === 0" class="empty-quotes">
          <span class="empty-icon">📋</span>
          <h3>Aucune demande</h3>
          <p>Vous n'avez pas encore reçu de demande de devis approuvée.</p>
        </div>

        <div v-else class="quotes-list">
          <div
            v-for="quote in quotes"
            :key="quote.id"
            class="quote-card"
            :class="{ 'locked': !quote.unlocked }"
            @click="openQuoteDetail(quote)"
          >
            <div v-if="!quote.unlocked" class="lock-overlay">
              <div class="lock-icon">🔒</div>
              <p class="lock-text">Cliquez pour déverrouiller</p>
              <p class="lock-cost">1 jeton requis</p>
            </div>

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
                    {{ quote.unlocked ? quote.quote_request?.requester_company?.company_name : 'Entreprise' }}
                  </h3>
                  <p class="company-location">
                    {{ quote.unlocked ? quote.quote_request?.requester_company?.city : '••••••' }}
                  </p>
                </div>
              </div>
            </div>

            <div class="quote-content">
              <h4 class="quote-title">{{ quote.quote_request?.title }}</h4>
              <p class="quote-description">
                {{ quote.unlocked ? quote.quote_request?.description : 'Déverrouillez pour voir les détails de la demande...' }}
              </p>
            </div>

            <div class="quote-footer">
              <div class="quote-meta">
                <span class="meta-item">
                  📁 {{ quote.quote_request?.category }}
                </span>
                <span v-if="quote.quote_request?.deadline && quote.unlocked" class="meta-item">
                  📅 {{ formatDate(quote.quote_request.deadline) }}
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
            <h2>{{ selectedQuote.unlocked ? 'Détail de la demande' : 'Déverrouiller la demande' }}</h2>
            <button class="close-btn" @click="closeDetailModal">✕</button>
          </div>

          <div class="modal-body">
            <div v-if="!selectedQuote.unlocked" class="unlock-section">
              <div class="unlock-info">
                <div class="unlock-icon">🔒</div>
                <h3>Cette demande est verrouillée</h3>
                <p>Utilisez 1 jeton pour déverrouiller et accéder aux coordonnées complètes de l'entreprise.</p>
                <div class="token-status">
                  <span class="token-icon">🪙</span>
                  <span>Vos jetons : {{ tokenBalance?.token_balance || 0 }}</span>
                </div>
              </div>
              <div class="unlock-actions">
                <button
                  class="btn-unlock"
                  @click="unlockQuote(selectedQuote)"
                  :disabled="unlocking || !!(tokenBalance && tokenBalance.token_balance < 1)"
                >
                  {{ unlocking ? 'Déverrouillage...' : 'Déverrouiller (1 jeton)' }}
                </button>
                <button v-if="tokenBalance && tokenBalance.token_balance < 1" class="btn-buy" @click="openTokenModal">
                  Acheter des jetons
                </button>
              </div>
            </div>

            <div v-else>
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
                      📞 <a :href="`tel:${selectedQuote.quote_request.requester_company.phone}`">
                        {{ selectedQuote.quote_request.requester_company.phone }}
                      </a>
                    </p>
                    <p v-if="selectedQuote.quote_request?.requester_company?.email">
                      ✉️ <a :href="`mailto:${selectedQuote.quote_request.requester_company.email}`">
                        {{ selectedQuote.quote_request.requester_company.email }}
                      </a>
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
                  <div class="info-item">
                    <span class="info-label">Catégorie</span>
                    <span class="info-value">{{ selectedQuote.quote_request?.category }}</span>
                  </div>
                  <div v-if="selectedQuote.quote_request?.deadline" class="info-item">
                    <span class="info-label">Date de livraison souhaitée</span>
                    <span class="info-value">{{ formatDate(selectedQuote.quote_request.deadline) }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label">Reçue le</span>
                    <span class="info-value">{{ formatDate(selectedQuote.created_at) }}</span>
                  </div>
                  <div v-if="selectedQuote.unlocked_at" class="info-item">
                    <span class="info-label">Déverrouillée le</span>
                    <span class="info-value">{{ formatDate(selectedQuote.unlocked_at) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showTokenModal" class="modal-overlay" @click="closeTokenModal">
        <div class="modal-content token-modal" @click.stop>
          <div class="modal-header">
            <h2>Acheter des jetons</h2>
            <button class="close-btn" @click="closeTokenModal">✕</button>
          </div>

          <div class="modal-body">
            <div class="token-purchase-info">
              <p>Les jetons vous permettent de déverrouiller les demandes de devis et d'accéder aux coordonnées complètes des entreprises.</p>
              <div class="price-info">
                <span class="price-label">Prix unitaire :</span>
                <span class="price-value">{{ tokenPrice }}€ / jeton</span>
              </div>
            </div>

            <div class="token-selector">
              <label for="tokenAmount">Nombre de jetons</label>
              <div class="amount-controls">
                <button @click="tokenAmount = Math.max(1, tokenAmount - 1)" class="btn-adjust">−</button>
                <input
                  type="number"
                  id="tokenAmount"
                  v-model.number="tokenAmount"
                  min="1"
                  max="100"
                  class="token-input"
                />
                <button @click="tokenAmount = Math.min(100, tokenAmount + 1)" class="btn-adjust">+</button>
              </div>
              <div class="quick-select">
                <button @click="tokenAmount = 10" class="btn-quick">10 jetons</button>
                <button @click="tokenAmount = 25" class="btn-quick">25 jetons</button>
                <button @click="tokenAmount = 50" class="btn-quick">50 jetons</button>
              </div>
            </div>

            <div class="total-price">
              <span class="total-label">Total :</span>
              <span class="total-value">{{ totalPrice }}€</span>
            </div>

            <div v-if="message.text" class="message" :class="message.type">
              {{ message.text }}
            </div>

            <button class="btn-purchase" @click="purchaseTokens" :disabled="purchasing">
              {{ purchasing ? 'Redirection...' : `Acheter pour ${totalPrice}€` }}
            </button>

            <p class="secure-payment">
              🔒 Paiement sécurisé par Stripe
            </p>
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

.empty-state,
.empty-quotes {
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

.empty-state p,
.empty-quotes p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.quotes-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 24px;
  gap: 24px;
  flex-wrap: wrap;
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

.token-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.token-balance {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
  border-radius: 12px;
  color: white;
  font-weight: 700;
}

.token-icon {
  font-size: 24px;
}

.token-count {
  font-size: 24px;
}

.token-label {
  font-size: 14px;
  opacity: 0.9;
}

.btn-buy-tokens {
  padding: 12px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-buy-tokens:hover {
  background: #047857;
  transform: translateY(-1px);
}

.message {
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 24px;
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
  position: relative;
  overflow: hidden;
}

.quote-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.quote-card.locked {
  filter: blur(2px);
}

.quote-card.locked:hover {
  filter: blur(1px);
}

.lock-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.95);
  z-index: 1;
}

.lock-icon {
  font-size: 48px;
  margin-bottom: 12px;
}

.lock-text {
  font-size: 16px;
  font-weight: 600;
  color: #111827;
  margin: 0 0 4px 0;
}

.lock-cost {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.quote-header {
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
  flex-shrink: 0;
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
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
}

.detail-modal {
  max-width: 700px;
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

.unlock-section {
  text-align: center;
}

.unlock-info {
  padding: 32px;
  background: #f9fafb;
  border-radius: 12px;
  margin-bottom: 24px;
}

.unlock-icon {
  font-size: 64px;
  margin-bottom: 16px;
}

.unlock-info h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.unlock-info p {
  font-size: 15px;
  color: #6b7280;
  margin: 0 0 16px 0;
}

.token-status {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: white;
  border-radius: 8px;
  font-weight: 600;
  color: #111827;
}

.unlock-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.btn-unlock,
.btn-buy {
  padding: 14px 28px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-unlock {
  background: #059669;
  color: white;
}

.btn-unlock:hover:not(:disabled) {
  background: #047857;
}

.btn-unlock:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-buy {
  background: #f59e0b;
  color: white;
}

.btn-buy:hover {
  background: #d97706;
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

.company-detail a {
  color: #059669;
  text-decoration: none;
}

.company-detail a:hover {
  text-decoration: underline;
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

.token-purchase-info {
  margin-bottom: 24px;
}

.token-purchase-info p {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.price-info {
  display: flex;
  justify-content: space-between;
  padding: 12px 16px;
  background: #f9fafb;
  border-radius: 8px;
}

.price-label {
  font-size: 14px;
  color: #6b7280;
}

.price-value {
  font-size: 14px;
  font-weight: 700;
  color: #111827;
}

.token-selector {
  margin-bottom: 24px;
}

.token-selector label {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 8px;
}

.amount-controls {
  display: flex;
  gap: 12px;
  align-items: center;
  margin-bottom: 12px;
}

.btn-adjust {
  width: 40px;
  height: 40px;
  border: 1px solid #d1d5db;
  background: white;
  border-radius: 8px;
  font-size: 20px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-adjust:hover {
  background: #f3f4f6;
  border-color: #9ca3af;
}

.token-input {
  flex: 1;
  padding: 12px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 16px;
  text-align: center;
  font-weight: 600;
}

.quick-select {
  display: flex;
  gap: 8px;
}

.btn-quick {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  background: white;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-quick:hover {
  background: #059669;
  color: white;
  border-color: #059669;
}

.total-price {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 24px;
}

.total-label {
  font-size: 16px;
  font-weight: 600;
  color: #111827;
}

.total-value {
  font-size: 24px;
  font-weight: 700;
  color: #059669;
}

.btn-purchase {
  width: 100%;
  padding: 16px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 12px;
}

.btn-purchase:hover:not(:disabled) {
  background: #047857;
}

.btn-purchase:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.secure-payment {
  text-align: center;
  font-size: 13px;
  color: #6b7280;
  margin: 0;
}

@media (max-width: 768px) {
  .quotes-header {
    flex-direction: column;
    align-items: stretch;
  }

  .token-info {
    flex-direction: column;
    align-items: stretch;
  }

  .btn-buy-tokens {
    width: 100%;
  }

  .quote-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .unlock-actions {
    flex-direction: column;
  }

  .btn-unlock,
  .btn-buy {
    width: 100%;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }
}
</style>
