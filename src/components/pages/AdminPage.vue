<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import AdminLayout from '../admin/AdminLayout.vue'

interface Stats {
  totalUsers: number
  totalCompanies: number
  totalQuotes: number
  activeProducers: number
}

const stats = ref<Stats>({
  totalUsers: 0,
  totalCompanies: 0,
  totalQuotes: 0,
  activeProducers: 0
})

const allUsers = ref<any[]>([])
const allCompanies = ref<any[]>([])
const allQuotes = ref<any[]>([])
const loading = ref(true)
const selectedUser = ref<any>(null)
const selectedCompany = ref<any>(null)
const selectedQuote = ref<any>(null)
const showUserModal = ref(false)
const showCompanyModal = ref(false)
const showQuoteModal = ref(false)
const actionLoading = ref(false)
const message = ref({ type: '', text: '' })

onMounted(async () => {
  await loadDashboardData()
})

async function loadDashboardData() {
  loading.value = true
  try {
    console.log('Loading admin dashboard data...')

    const [usersRes, companiesRes, quotesRes, producersRes] = await Promise.all([
      supabase.rpc('get_admin_user_list'),
      supabase.from('companies').select('*'),
      supabase.from('quote_requests').select(`
        *,
        requester:profiles!quote_requests_requester_id_fkey(user_id, first_name, last_name, user_type),
        target_company:companies!quote_requests_target_company_id_fkey(id, name, city)
      `),
      supabase.from('producer_profiles').select('id, company_id').eq('is_active', true)
    ])

    console.log('Users RPC result:', usersRes)
    console.log('Users data:', usersRes.data)
    console.log('Users error:', usersRes.error)

    const users = usersRes.data || []
    const companies = companiesRes.data || []
    const quotes = quotesRes.data || []
    const producers = producersRes.data || []

    allUsers.value = users.sort((a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )

    allCompanies.value = companies.sort((a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )

    allQuotes.value = quotes.sort((a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )

    stats.value = {
      totalUsers: users.length,
      totalCompanies: companies.length,
      totalQuotes: quotes.length,
      activeProducers: producers.length
    }
  } catch (error) {
    console.error('Error loading dashboard data:', error)
  } finally {
    loading.value = false
  }
}

function viewUserDetails(userItem: any) {
  selectedUser.value = userItem
  showUserModal.value = true
  message.value = { type: '', text: '' }
}

function getUserTypeLabel(userType: string) {
  const labels: Record<string, string> = {
    'PARTICULIER': 'Particulier',
    'PRO': 'Pro',
    'ADMIN': 'Admin'
  }
  return labels[userType] || userType
}

function getUserTypeBadgeClass(userType: string) {
  const classes: Record<string, string> = {
    'PARTICULIER': 'type-particulier',
    'PRO': 'type-pro',
    'ADMIN': 'type-admin'
  }
  return classes[userType] || 'type-particulier'
}

async function changeUserType(userItem: any, newType: string) {
  actionLoading.value = true
  message.value = { type: '', text: '' }

  try {
    const { error } = await supabase
      .from('profiles')
      .update({ user_type: newType })
      .eq('user_id', userItem.user_id)

    if (error) throw error

    message.value = {
      type: 'success',
      text: `Type d'utilisateur changé en ${getUserTypeLabel(newType)} avec succès`
    }

    await loadDashboardData()

    if (selectedUser.value && selectedUser.value.user_id === userItem.user_id) {
      selectedUser.value.user_type = newType
    }
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    actionLoading.value = false
  }
}

function viewCompanyDetails(company: any) {
  selectedCompany.value = company
  showCompanyModal.value = true
  message.value = { type: '', text: '' }
}

async function deleteCompany(companyId: string) {
  if (!confirm('Êtes-vous sûr de vouloir supprimer cette entreprise ? Cette action est irréversible.')) {
    return
  }

  actionLoading.value = true
  message.value = { type: '', text: '' }

  try {
    const { error } = await supabase
      .from('companies')
      .delete()
      .eq('id', companyId)

    if (error) throw error

    message.value = {
      type: 'success',
      text: 'Entreprise supprimée avec succès'
    }

    showCompanyModal.value = false
    await loadDashboardData()
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    actionLoading.value = false
  }
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

function getRequesterName(requester: any) {
  if (!requester) return 'Non disponible'
  const firstName = requester.first_name || ''
  const lastName = requester.last_name || ''
  return `${firstName} ${lastName}`.trim() || 'Non renseigné'
}

function getStatusLabel(status: string) {
  const labels: Record<string, string> = {
    'SENT': 'Envoyée',
    'VIEWED': 'Vue',
    'RESPONDED': 'Répondue',
    'CLOSED': 'Clôturée'
  }
  return labels[status] || status
}

function getStatusBadgeClass(status: string) {
  const classes: Record<string, string> = {
    'SENT': 'status-sent',
    'VIEWED': 'status-viewed',
    'RESPONDED': 'status-responded',
    'CLOSED': 'status-closed'
  }
  return classes[status] || 'status-sent'
}

function viewQuoteDetails(quote: any) {
  selectedQuote.value = quote
  showQuoteModal.value = true
  message.value = { type: '', text: '' }
}

async function closeQuote(quoteId: string) {
  if (!confirm('Êtes-vous sûr de vouloir fermer cette demande de devis ?')) {
    return
  }

  actionLoading.value = true
  message.value = { type: '', text: '' }

  try {
    const { error } = await supabase
      .from('quote_requests')
      .update({ status: 'CLOSED' })
      .eq('id', quoteId)

    if (error) throw error

    message.value = {
      type: 'success',
      text: 'Demande de devis fermée avec succès'
    }

    await loadDashboardData()

    if (selectedQuote.value && selectedQuote.value.id === quoteId) {
      selectedQuote.value.status = 'CLOSED'
    }
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    actionLoading.value = false
  }
}

async function deleteQuote(quoteId: string) {
  if (!confirm('Êtes-vous sûr de vouloir supprimer cette demande de devis ? Cette action est irréversible.')) {
    return
  }

  actionLoading.value = true
  message.value = { type: '', text: '' }

  try {
    const { error } = await supabase
      .from('quote_requests')
      .delete()
      .eq('id', quoteId)

    if (error) throw error

    message.value = {
      type: 'success',
      text: 'Demande de devis supprimée avec succès'
    }

    showQuoteModal.value = false
    await loadDashboardData()
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    actionLoading.value = false
  }
}
</script>

<template>
  <AdminLayout v-slot="{ currentPage }">
    <div v-if="currentPage === 'dashboard'" class="admin-dashboard">
      <div class="page-header">
        <h1 class="page-title">Administration de la plateforme</h1>
      </div>

      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement des statistiques...</p>
      </div>

      <div v-else class="dashboard-content">
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon users">👥</div>
            <div class="stat-info">
              <span class="stat-label">Utilisateurs</span>
              <span class="stat-value">{{ stats.totalUsers }}</span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon companies">🏢</div>
            <div class="stat-info">
              <span class="stat-label">Sociétés</span>
              <span class="stat-value">{{ stats.totalCompanies }}</span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon quotes">📋</div>
            <div class="stat-info">
              <span class="stat-label">Demandes de devis</span>
              <span class="stat-value">{{ stats.totalQuotes }}</span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon producers">🎯</div>
            <div class="stat-info">
              <span class="stat-label">Producteurs actifs</span>
              <span class="stat-value">{{ stats.activeProducers }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="currentPage === 'users'" class="admin-page">
      <div class="page-header">
        <h1 class="page-title">Utilisateurs</h1>
        <p class="page-subtitle">{{ allUsers.length }} utilisateurs au total</p>
      </div>

      <div v-if="message.text && !showUserModal" class="message-banner" :class="message.type">
        {{ message.text }}
      </div>

      <div class="users-list">
        <div class="data-table">
          <div v-if="allUsers.length === 0" class="empty-state">
            Aucun utilisateur pour le moment
          </div>
          <div v-else class="table-rows">
            <div v-for="userItem in allUsers" :key="userItem.user_id" class="table-row clickable" @click="viewUserDetails(userItem)">
              <div class="row-main">
                <div class="user-info">
                  <span class="user-email">{{ userItem.email || 'Email non disponible' }}</span>
                  <span class="user-name">{{ userItem.first_name }} {{ userItem.last_name }}</span>
                </div>
                <div class="row-meta">
                  <span class="user-type-badge" :class="getUserTypeBadgeClass(userItem.user_type)">
                    {{ getUserTypeLabel(userItem.user_type) }}
                  </span>
                  <span class="user-date">{{ formatDate(userItem.created_at) }}</span>
                  <button class="btn-action" @click.stop="viewUserDetails(userItem)">
                    Voir le profil
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showUserModal && selectedUser" class="modal-overlay" @click="showUserModal = false">
        <div class="modal-content user-modal" @click.stop>
          <button class="close-btn" @click="showUserModal = false">✕</button>

          <div class="modal-header-content">
            <h2>{{ selectedUser.email || 'Utilisateur' }}</h2>
            <span class="user-type-badge" :class="getUserTypeBadgeClass(selectedUser.user_type)">
              {{ getUserTypeLabel(selectedUser.user_type) }}
            </span>
          </div>

          <div v-if="message.text" class="message-banner" :class="message.type">
            {{ message.text }}
          </div>

          <div class="user-details-grid">
            <div class="detail-row">
              <span class="detail-label">Prénom</span>
              <span class="detail-value">{{ selectedUser.first_name || 'Non renseigné' }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Nom</span>
              <span class="detail-value">{{ selectedUser.last_name || 'Non renseigné' }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Email</span>
              <span class="detail-value">{{ selectedUser.email || 'Non disponible' }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Téléphone</span>
              <span class="detail-value">{{ selectedUser.phone || 'Non renseigné' }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Type d'utilisateur</span>
              <span class="detail-value">{{ getUserTypeLabel(selectedUser.user_type) }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Inscrit le</span>
              <span class="detail-value">{{ formatDate(selectedUser.created_at) }}</span>
            </div>
          </div>

          <div class="modal-actions">
            <button
              v-if="selectedUser.user_type === 'PARTICULIER'"
              class="btn-change-type"
              :disabled="actionLoading"
              @click="changeUserType(selectedUser, 'PRO')"
            >
              Passer en PRO
            </button>
            <button
              v-if="selectedUser.user_type === 'PRO'"
              class="btn-change-type"
              :disabled="actionLoading"
              @click="changeUserType(selectedUser, 'ADMIN')"
            >
              Passer en ADMIN
            </button>
            <button
              v-if="selectedUser.user_type === 'PRO'"
              class="btn-change-type"
              :disabled="actionLoading"
              @click="changeUserType(selectedUser, 'PARTICULIER')"
            >
              Passer en PARTICULIER
            </button>
            <button
              v-if="selectedUser.user_type === 'ADMIN'"
              class="btn-change-type"
              :disabled="actionLoading"
              @click="changeUserType(selectedUser, 'PRO')"
            >
              Retirer ADMIN
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="currentPage === 'companies'" class="admin-page">
      <div class="page-header">
        <h1 class="page-title">Sociétés référencées</h1>
        <p class="page-subtitle">{{ allCompanies.length }} sociétés au total</p>
      </div>

      <div v-if="message.text && !showCompanyModal" class="message-banner" :class="message.type">
        {{ message.text }}
      </div>

      <div class="companies-list">
        <div class="data-table">
          <div v-if="allCompanies.length === 0" class="empty-state">
            Aucune société pour le moment
          </div>
          <div v-else class="table-rows">
            <div v-for="company in allCompanies" :key="company.id" class="table-row clickable" @click="viewCompanyDetails(company)">
              <div class="row-main">
                <div class="company-info">
                  <span class="company-name">{{ company.name }}</span>
                  <span class="company-siret">SIRET: {{ company.siret }}</span>
                </div>
                <div class="row-meta">
                  <span class="company-location">{{ company.city }}</span>
                  <span class="claim-badge" :class="company.is_claimed ? 'claimed' : 'unclaimed'">
                    {{ company.is_claimed ? 'Revendiquée' : 'Non revendiquée' }}
                  </span>
                  <button class="btn-action" @click.stop="viewCompanyDetails(company)">
                    Voir / Éditer
                  </button>
                  <button class="btn-delete-small" @click.stop="deleteCompany(company.id)" :disabled="actionLoading">
                    Supprimer
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showCompanyModal && selectedCompany" class="modal-overlay" @click="showCompanyModal = false">
        <div class="modal-content company-modal" @click.stop>
          <button class="close-btn" @click="showCompanyModal = false">✕</button>

          <div class="modal-header-content">
            <h2>{{ selectedCompany.name }}</h2>
            <span class="claim-badge" :class="selectedCompany.is_claimed ? 'claimed' : 'unclaimed'">
              {{ selectedCompany.is_claimed ? 'Revendiquée' : 'Non revendiquée' }}
            </span>
          </div>

          <div v-if="message.text" class="message-banner" :class="message.type">
            {{ message.text }}
          </div>

          <div class="company-details-grid">
            <div class="detail-row">
              <span class="detail-label">SIRET</span>
              <span class="detail-value">{{ selectedCompany.siret }}</span>
            </div>
            <div v-if="selectedCompany.siren" class="detail-row">
              <span class="detail-label">SIREN</span>
              <span class="detail-value">{{ selectedCompany.siren }}</span>
            </div>
            <div v-if="selectedCompany.naf_code" class="detail-row">
              <span class="detail-label">Code NAF</span>
              <span class="detail-value">{{ selectedCompany.naf_code }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Ville</span>
              <span class="detail-value">{{ selectedCompany.city }} ({{ selectedCompany.postal_code }})</span>
            </div>
            <div class="detail-row full-width">
              <span class="detail-label">Adresse</span>
              <span class="detail-value">{{ selectedCompany.address }}</span>
            </div>
            <div v-if="selectedCompany.phone" class="detail-row">
              <span class="detail-label">Téléphone</span>
              <span class="detail-value">{{ selectedCompany.phone }}</span>
            </div>
            <div v-if="selectedCompany.website" class="detail-row">
              <span class="detail-label">Site web</span>
              <span class="detail-value">
                <a :href="selectedCompany.website" target="_blank">{{ selectedCompany.website }}</a>
              </span>
            </div>
            <div v-if="selectedCompany.description" class="detail-row full-width">
              <span class="detail-label">Description</span>
              <span class="detail-value">{{ selectedCompany.description }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Source</span>
              <span class="detail-value">{{ selectedCompany.source }}</span>
            </div>
            <div v-if="selectedCompany.is_claimed && selectedCompany.claimed_at" class="detail-row">
              <span class="detail-label">Revendiquée le</span>
              <span class="detail-value">{{ formatDate(selectedCompany.claimed_at) }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Créée le</span>
              <span class="detail-value">{{ formatDate(selectedCompany.created_at) }}</span>
            </div>
          </div>

          <div class="modal-actions">
            <button class="btn-delete" :disabled="actionLoading" @click="deleteCompany(selectedCompany.id)">
              Supprimer
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="currentPage === 'quotes'" class="admin-page">
      <div class="page-header">
        <h1 class="page-title">Demandes de devis</h1>
        <p class="page-subtitle">{{ allQuotes.length }} demandes au total</p>
      </div>

      <div v-if="message.text && !showQuoteModal" class="message-banner" :class="message.type">
        {{ message.text }}
      </div>

      <div class="quotes-list">
        <div class="data-table">
          <div v-if="allQuotes.length === 0" class="empty-state">
            Aucune demande de devis pour le moment
          </div>
          <div v-else class="table-rows">
            <div v-for="quote in allQuotes" :key="quote.id" class="table-row clickable" @click="viewQuoteDetails(quote)">
              <div class="row-main">
                <div class="quote-info">
                  <span class="quote-title">{{ quote.title }}</span>
                  <span class="quote-requester">
                    Demandeur: {{ getRequesterName(quote.requester) }} ({{ getUserTypeLabel(quote.requester?.user_type) }})
                  </span>
                  <span class="quote-target">Société ciblée: {{ quote.target_company?.name }} ({{ quote.target_company?.city }})</span>
                </div>
                <div class="row-meta">
                  <span class="status-badge" :class="getStatusBadgeClass(quote.status)">
                    {{ getStatusLabel(quote.status) }}
                  </span>
                  <span class="quote-date">{{ formatDate(quote.created_at) }}</span>
                  <button class="btn-action" @click.stop="viewQuoteDetails(quote)">
                    Consulter
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showQuoteModal && selectedQuote" class="modal-overlay" @click="showQuoteModal = false">
        <div class="modal-content quote-modal" @click.stop>
          <button class="close-btn" @click="showQuoteModal = false">✕</button>

          <div class="modal-header-content">
            <h2>{{ selectedQuote.title }}</h2>
            <span class="status-badge" :class="getStatusBadgeClass(selectedQuote.status)">
              {{ getStatusLabel(selectedQuote.status) }}
            </span>
          </div>

          <div v-if="message.text" class="message-banner" :class="message.type">
            {{ message.text }}
          </div>

          <div class="quote-details-grid">
            <div class="detail-row full-width">
              <span class="detail-label">Description</span>
              <span class="detail-value">{{ selectedQuote.description }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Demandeur</span>
              <span class="detail-value">{{ getRequesterName(selectedQuote.requester) }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Type de demandeur</span>
              <span class="detail-value">{{ getUserTypeLabel(selectedQuote.requester?.user_type) }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Société ciblée</span>
              <span class="detail-value">{{ selectedQuote.target_company?.name }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Ville</span>
              <span class="detail-value">{{ selectedQuote.target_company?.city }}</span>
            </div>

            <div v-if="selectedQuote.volume_estimated" class="detail-row">
              <span class="detail-label">Volume estimé</span>
              <span class="detail-value">{{ selectedQuote.volume_estimated }}</span>
            </div>

            <div v-if="selectedQuote.frequency" class="detail-row">
              <span class="detail-label">Fréquence</span>
              <span class="detail-value">{{ selectedQuote.frequency }}</span>
            </div>

            <div v-if="selectedQuote.location" class="detail-row">
              <span class="detail-label">Localisation</span>
              <span class="detail-value">{{ selectedQuote.location }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Créée le</span>
              <span class="detail-value">{{ formatDate(selectedQuote.created_at) }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Statut actuel</span>
              <span class="detail-value">
                <span class="status-badge" :class="getStatusBadgeClass(selectedQuote.status)">
                  {{ getStatusLabel(selectedQuote.status) }}
                </span>
              </span>
            </div>
          </div>

          <div class="modal-actions-multi">
            <button class="btn-close-quote" :disabled="actionLoading" @click="closeQuote(selectedQuote.id)">
              Fermer
            </button>
            <button class="btn-delete" :disabled="actionLoading" @click="deleteQuote(selectedQuote.id)">
              Modérer (Supprimer)
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<style scoped>
.admin-dashboard,
.admin-page {
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
}

.page-title {
  font-size: 32px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 8px 0;
}

.page-subtitle {
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
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
  margin-bottom: 32px;
}

.stat-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
}

.stat-icon.users {
  background: #e0e7ff;
}

.stat-icon.companies {
  background: #dbeafe;
}

.stat-icon.quotes {
  background: #fef3c7;
}

.stat-icon.producers {
  background: #d1fae5;
}

.stat-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-label {
  font-size: 14px;
  color: #6b7280;
  font-weight: 500;
}

.stat-value {
  font-size: 32px;
  font-weight: 800;
  color: #111827;
}

.stat-detail {
  font-size: 12px;
  color: #9ca3af;
}

.dashboard-sections {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.dashboard-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.section-header {
  margin-bottom: 20px;
}

.section-title {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.data-table {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
}

.empty-state {
  padding: 40px;
  text-align: center;
  color: #6b7280;
  font-size: 14px;
}

.table-rows {
  display: flex;
  flex-direction: column;
}

.table-row {
  padding: 16px;
  border-bottom: 1px solid #e5e7eb;
  transition: background 0.2s;
}

.table-row:last-child {
  border-bottom: none;
}

.table-row:hover {
  background: #f9fafb;
}

.row-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.company-info,
.quote-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}

.company-name,
.quote-title {
  font-size: 15px;
  font-weight: 600;
  color: #111827;
}

.company-category,
.quote-description {
  font-size: 13px;
  color: #6b7280;
}

.row-meta {
  display: flex;
  align-items: center;
  gap: 12px;
}

.company-location,
.company-date,
.quote-date {
  font-size: 13px;
  color: #6b7280;
}

.verification-badge,
.status-badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  color: white;
}

.verification-badge.verified {
  background: #10b981;
}

.verification-badge.pending {
  background: #f59e0b;
}

.claim-badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  color: white;
}

.claim-badge.claimed {
  background: #10b981;
}

.claim-badge.unclaimed {
  background: #9ca3af;
}

.company-siret {
  font-size: 13px;
  color: #6b7280;
}

.btn-delete-small {
  padding: 6px 12px;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-delete-small:hover:not(:disabled) {
  background: #dc2626;
}

.btn-delete-small:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.user-type-badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  color: white;
}

.user-type-badge.type-particulier {
  background: #3b82f6;
}

.user-type-badge.type-pro {
  background: #10b981;
}

.user-type-badge.type-admin {
  background: #ef4444;
}

.user-email {
  font-size: 15px;
  font-weight: 600;
  color: #111827;
}

.user-name {
  font-size: 13px;
  color: #6b7280;
}

.user-date {
  font-size: 13px;
  color: #6b7280;
}

.user-details-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 24px;
}

.btn-change-type {
  flex: 1;
  padding: 12px 24px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-change-type:hover:not(:disabled) {
  background: #2563eb;
}

.btn-change-type:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.coming-soon {
  background: white;
  padding: 80px 40px;
  border-radius: 16px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.coming-soon .icon {
  font-size: 64px;
  display: block;
  margin-bottom: 24px;
}

.coming-soon p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.message-banner {
  margin-bottom: 20px;
  padding: 14px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
}

.message-banner.success {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #86efac;
}

.message-banner.error {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

.table-row.clickable {
  cursor: pointer;
}

.btn-action {
  padding: 6px 12px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-action:hover:not(:disabled) {
  background: #2563eb;
}

.btn-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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
  position: relative;
}

.close-btn {
  position: absolute;
  top: 16px;
  right: 16px;
  background: none;
  border: none;
  font-size: 24px;
  color: #6b7280;
  cursor: pointer;
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 8px;
  transition: all 0.2s;
  z-index: 10;
}

.close-btn:hover {
  background: #f3f4f6;
  color: #111827;
}

.company-modal {
  padding: 32px;
}

.modal-header-content {
  margin-bottom: 24px;
  padding-right: 40px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.modal-header-content h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.company-details-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 24px;
}

.detail-row {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-row.full-width {
  grid-column: 1 / -1;
}

.detail-label {
  font-size: 12px;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
}

.detail-value {
  font-size: 14px;
  color: #111827;
}

.detail-value a {
  color: #3b82f6;
  text-decoration: none;
}

.detail-value a:hover {
  text-decoration: underline;
}

.tags-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag {
  background: #f3f4f6;
  color: #374151;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
}

.modal-actions {
  display: flex;
  gap: 12px;
}

.btn-verify {
  flex: 1;
  padding: 12px 24px;
  background: #10b981;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-verify:hover:not(:disabled) {
  background: #059669;
}

.btn-verify:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-delete {
  padding: 12px 24px;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-delete:hover:not(:disabled) {
  background: #dc2626;
}

.btn-delete:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.quote-modal {
  padding: 32px;
}

.quote-requester,
.quote-target {
  font-size: 12px;
  color: #6b7280;
  margin-top: 2px;
}

.status-badge.status-sent {
  background: #dbeafe;
  color: #1e40af;
}

.status-badge.status-viewed {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.status-responded {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.status-closed {
  background: #f3f4f6;
  color: #6b7280;
}

.btn-close-quote {
  padding: 12px 24px;
  background: #f59e0b;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-close-quote:hover:not(:disabled) {
  background: #d97706;
}

.btn-close-quote:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.quote-details-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 24px;
}

.modal-actions-multi {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

@media (max-width: 768px) {
  .row-main {
    flex-direction: column;
    align-items: flex-start;
  }

  .row-meta {
    flex-wrap: wrap;
  }

  .company-details-grid {
    grid-template-columns: 1fr;
  }

  .modal-actions {
    flex-direction: column;
  }

  .modal-actions-multi {
    grid-template-columns: 1fr;
  }

  .quote-details-grid {
    grid-template-columns: 1fr;
  }
}
</style>
