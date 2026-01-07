<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
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
}

interface Company {
  id: string
  company_name: string
  description: string | null
  category: string | null
  city: string
  postal_code: string
  phone: string
  email: string
  website: string | null
  logo_url: string | null
}

interface QuoteRecipient {
  id: string
  producer_company_id: string
  unlocked: boolean
  unlocked_at: string | null
  created_at: string
  company?: Company
}

const route = useRoute()
const router = useRouter()

const quoteRequest = ref<QuoteRequest | null>(null)
const recipients = ref<QuoteRecipient[]>([])
const loading = ref(true)
const error = ref('')

const statusLabels: Record<string, string> = {
  'draft': 'Brouillon',
  'pending_approval': 'En attente d\'approbation',
  'approved': 'Approuvée',
  'rejected': 'Refusée',
  'sent': 'Envoyée aux professionnels'
}

const statusColors: Record<string, string> = {
  'draft': '#9ca3af',
  'pending_approval': '#f59e0b',
  'approved': '#10b981',
  'rejected': '#ef4444',
  'sent': '#3b82f6'
}

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

    const { data: recipientsData, error: recipientsError } = await supabase
      .from('quote_recipients')
      .select(`
        *,
        company:companies(*)
      `)
      .eq('quote_request_id', quoteId)

    if (recipientsError) throw recipientsError

    recipients.value = recipientsData || []
  } catch (err) {
    console.error('Error loading quote detail:', err)
    error.value = 'Erreur lors du chargement des détails'
  } finally {
    loading.value = false
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
              <span class="label">Catégorie:</span>
              <span class="value">{{ quoteRequest.category }}</span>
            </div>

            <div class="detail-row">
              <span class="label">Date de création:</span>
              <span class="value">{{ formatDate(quoteRequest.created_at) }}</span>
            </div>

            <div v-if="quoteRequest.deadline" class="detail-row">
              <span class="label">Date limite:</span>
              <span class="value">{{ formatDate(quoteRequest.deadline) }}</span>
            </div>

            <div v-if="quoteRequest.quantity" class="detail-row">
              <span class="label">Quantité / Volume:</span>
              <span class="value">{{ quoteRequest.quantity }}</span>
            </div>

            <div v-if="quoteRequest.budget_range" class="detail-row">
              <span class="label">Budget:</span>
              <span class="value">{{ quoteRequest.budget_range }}</span>
            </div>
          </div>

          <div class="description-section">
            <h3>Description</h3>
            <p>{{ quoteRequest.description }}</p>
          </div>
        </div>

        <div class="responses-section">
          <h3>Réponses des professionnels ({{ recipients.length }})</h3>

          <div v-if="recipients.length === 0" class="empty-responses">
            <span class="empty-icon">📭</span>
            <p>Aucune réponse pour le moment</p>
            <small>Les professionnels pourront consulter votre demande et vous envoyer leurs devis.</small>
          </div>

          <div v-else class="responses-list">
            <div
              v-for="recipient in recipients"
              :key="recipient.id"
              class="response-card"
            >
              <div class="company-header">
                <div class="company-logo">
                  <img
                    v-if="recipient.company?.logo_url"
                    :src="recipient.company.logo_url"
                    :alt="recipient.company.company_name"
                  />
                  <span v-else class="logo-placeholder">
                    {{ recipient.company?.company_name?.[0] || '?' }}
                  </span>
                </div>
                <div class="company-info">
                  <h4>{{ recipient.company?.company_name || 'Entreprise' }}</h4>
                  <p class="company-location">
                    {{ recipient.company?.city }} ({{ recipient.company?.postal_code }})
                  </p>
                </div>
              </div>

              <p v-if="recipient.company?.description" class="company-description">
                {{ recipient.company.description }}
              </p>

              <div class="company-contact">
                <div class="contact-item">
                  <span class="contact-label">📧 Email:</span>
                  <a :href="`mailto:${recipient.company?.email}`">{{ recipient.company?.email }}</a>
                </div>
                <div class="contact-item">
                  <span class="contact-label">📞 Téléphone:</span>
                  <a :href="`tel:${recipient.company?.phone}`">{{ recipient.company?.phone }}</a>
                </div>
                <div v-if="recipient.company?.website" class="contact-item">
                  <span class="contact-label">🌐 Site web:</span>
                  <a :href="recipient.company.website" target="_blank">Visiter</a>
                </div>
              </div>

              <div class="response-footer">
                <span class="response-date">
                  Réponse reçue le {{ formatDate(recipient.created_at) }}
                </span>
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

.responses-section {
  background: white;
  padding: 32px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.responses-section h3 {
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

.responses-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.response-card {
  padding: 24px;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  transition: all 0.2s;
}

.response-card:hover {
  border-color: #2563eb;
  box-shadow: 0 2px 8px rgba(37, 99, 235, 0.1);
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

.company-location {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.company-description {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.company-contact {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 16px;
}

.contact-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.contact-label {
  font-weight: 500;
  color: #6b7280;
}

.contact-item a {
  color: #2563eb;
  text-decoration: none;
  font-weight: 500;
}

.contact-item a:hover {
  text-decoration: underline;
}

.response-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid #e5e7eb;
}

.response-date {
  font-size: 13px;
  color: #9ca3af;
}

@media (max-width: 768px) {
  .quote-info-card,
  .responses-section {
    padding: 24px;
  }

  .quote-details {
    grid-template-columns: 1fr;
  }

  .company-header {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
