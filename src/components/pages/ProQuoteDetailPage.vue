<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user, currentCompany } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { QuoteRequest, QuoteMessage, Company, Profile } from '../../types/database'

interface QuoteWithDetails extends QuoteRequest {
  target_company?: Company
  requester?: Profile
  quote_messages?: QuoteMessage[]
}

const route = useRoute()
const router = useRouter()
const loading = ref(true)
const quote = ref<QuoteWithDetails | null>(null)
const messages = ref<QuoteMessage[]>([])
const newMessage = ref('')
const sending = ref(false)

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
        requester:profiles!quote_requests_requester_id_fkey(*)
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

    const { data: messagesData } = await supabase
      .from('quote_messages')
      .select('*')
      .eq('quote_request_id', quoteId)
      .order('created_at', { ascending: true })

    messages.value = messagesData || []
  } catch (error) {
    console.error('Error loading quote:', error)
    router.push({ name: 'pro-dashboard' })
  } finally {
    loading.value = false
  }
}

async function sendMessage() {
  if (!quote.value || !user.value || !newMessage.value.trim()) return

  sending.value = true
  try {
    const { data, error } = await supabase
      .from('quote_messages')
      .insert({
        quote_request_id: quote.value.id,
        sender_user_id: user.value.id,
        message: newMessage.value.trim(),
      })
      .select()
      .single()

    if (error) throw error

    messages.value.push(data)
    newMessage.value = ''

    if (quote.value.status !== 'RESPONDED') {
      await supabase
        .from('quote_requests')
        .update({ status: 'RESPONDED' })
        .eq('id', quote.value.id)

      if (quote.value) {
        quote.value.status = 'RESPONDED'
      }
    }
  } catch (error) {
    console.error('Error sending message:', error)
  } finally {
    sending.value = false
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
    CLOSED: 'Fermé'
  }
  return labels[status] || status
}

function getOriginLabel(type: string): string {
  return type === 'PARTICULIER' ? 'Particulier' : 'Professionnel'
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

        <div class="messages-section">
          <h2>Messages</h2>

          <div v-if="messages.length === 0" class="no-messages">
            <p>Aucun message pour le moment</p>
          </div>

          <div v-else class="messages-list">
            <div
              v-for="message in messages"
              :key="message.id"
              class="message"
              :class="{ own: message.sender_user_id === user?.id }"
            >
              <div class="message-content">{{ message.message }}</div>
              <div class="message-time">
                {{ new Date(message.created_at).toLocaleDateString('fr-FR', {
                  day: 'numeric',
                  month: 'short',
                  hour: '2-digit',
                  minute: '2-digit'
                }) }}
              </div>
            </div>
          </div>

          <form v-if="quote.status !== 'CLOSED'" @submit.prevent="sendMessage" class="message-form">
            <textarea
              v-model="newMessage"
              placeholder="Écrivez votre message..."
              rows="3"
              :disabled="sending"
            ></textarea>
            <button type="submit" class="btn-send" :disabled="sending || !newMessage.trim()">
              {{ sending ? 'Envoi...' : 'Envoyer' }}
            </button>
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
  background: #d1fae5;
  color: #065f46;
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

.messages-section {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 2rem;
}

.messages-section h2 {
  margin: 0 0 1.5rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1a1a1a;
}

.no-messages {
  text-align: center;
  padding: 2rem;
  color: #6b7280;
}

.messages-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.message {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  max-width: 70%;
}

.message.own {
  align-items: flex-end;
  margin-left: auto;
}

.message-content {
  padding: 0.75rem 1rem;
  background: #f3f4f6;
  border-radius: 12px;
  color: #1a1a1a;
  line-height: 1.5;
  white-space: pre-wrap;
}

.message.own .message-content {
  background: #2563eb;
  color: white;
}

.message-time {
  font-size: 0.75rem;
  color: #6b7280;
  margin-top: 0.25rem;
  padding: 0 0.5rem;
}

.message-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
}

.message-form textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 1rem;
  font-family: inherit;
  resize: vertical;
  transition: border-color 0.2s;
}

.message-form textarea:focus {
  outline: none;
  border-color: #2563eb;
}

.message-form textarea:disabled {
  background: #f9fafb;
  cursor: not-allowed;
}

.btn-send {
  align-self: flex-end;
  padding: 0.75rem 1.5rem;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-send:hover:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
}

.btn-send:disabled {
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

  .message {
    max-width: 85%;
  }
}
</style>
