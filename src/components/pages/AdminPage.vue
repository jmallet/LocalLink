<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import AdminLayout from '../admin/AdminLayout.vue'

interface Stats {
  totalCompanies: number
  verifiedCompanies: number
  pendingCompanies: number
  totalQuotes: number
  pendingQuotes: number
  totalPosts: number
  publishedPosts: number
}

const stats = ref<Stats>({
  totalCompanies: 0,
  verifiedCompanies: 0,
  pendingCompanies: 0,
  totalQuotes: 0,
  pendingQuotes: 0,
  totalPosts: 0,
  publishedPosts: 0
})

const recentCompanies = ref<any[]>([])
const recentQuotes = ref<any[]>([])
const allCompanies = ref<any[]>([])
const allQuotes = ref<any[]>([])
const loading = ref(true)
const selectedCompany = ref<any>(null)
const selectedQuote = ref<any>(null)
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
    const [companiesRes, quotesRes, postsRes] = await Promise.all([
      supabase.from('companies').select('*', { count: 'exact' }),
      supabase.from('quote_requests').select(`
        *,
        company:companies!quote_requests_buyer_company_id_fkey(id, company_name, city, email, phone)
      `, { count: 'exact' }),
      supabase.from('blog_posts').select('*', { count: 'exact' })
    ])

    const companies = companiesRes.data || []
    const quotes = quotesRes.data || []
    const posts = postsRes.data || []

    stats.value = {
      totalCompanies: companies.length,
      verifiedCompanies: companies.filter(c => c.verified).length,
      pendingCompanies: companies.filter(c => !c.verified).length,
      totalQuotes: quotes.length,
      pendingQuotes: quotes.filter(q => q.status === 'pending_approval').length,
      totalPosts: posts.length,
      publishedPosts: posts.filter(p => p.published).length
    }

    allCompanies.value = companies.sort((a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )

    recentCompanies.value = allCompanies.value.slice(0, 5)

    allQuotes.value = quotes.sort((a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )

    recentQuotes.value = allQuotes.value.slice(0, 5)
  } catch (error) {
    console.error('Error loading dashboard data:', error)
  } finally {
    loading.value = false
  }
}

function viewCompanyDetails(company: any) {
  selectedCompany.value = company
  showCompanyModal.value = true
  message.value = { type: '', text: '' }
}

async function toggleVerification(company: any) {
  actionLoading.value = true
  message.value = { type: '', text: '' }

  try {
    const { error } = await supabase
      .from('companies')
      .update({ verified: !company.verified })
      .eq('id', company.id)

    if (error) throw error

    message.value = {
      type: 'success',
      text: `Entreprise ${!company.verified ? 'vérifiée' : 'non vérifiée'} avec succès`
    }

    await loadDashboardData()

    if (selectedCompany.value && selectedCompany.value.id === company.id) {
      selectedCompany.value.verified = !company.verified
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

function getStatusColor(status: string) {
  const colors: Record<string, string> = {
    draft: '#9ca3af',
    pending_approval: '#f59e0b',
    approved: '#10b981',
    rejected: '#ef4444',
    sent: '#6366f1'
  }
  return colors[status] || '#6b7280'
}

function getStatusLabel(status: string) {
  const labels: Record<string, string> = {
    draft: 'Brouillon',
    pending_approval: 'En attente d\'approbation',
    approved: 'Approuvé',
    rejected: 'Rejeté',
    sent: 'Envoyé'
  }
  return labels[status] || status
}

function viewQuoteDetails(quote: any) {
  selectedQuote.value = quote
  showQuoteModal.value = true
  message.value = { type: '', text: '' }
}

async function updateQuoteStatus(quote: any, newStatus: string) {
  actionLoading.value = true
  message.value = { type: '', text: '' }

  try {
    const { error } = await supabase
      .from('quote_requests')
      .update({ status: newStatus })
      .eq('id', quote.id)

    if (error) throw error

    message.value = {
      type: 'success',
      text: `Demande ${getStatusLabel(newStatus).toLowerCase()} avec succès`
    }

    await loadDashboardData()

    if (selectedQuote.value && selectedQuote.value.id === quote.id) {
      selectedQuote.value.status = newStatus
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
        <h1 class="page-title">Tableau de bord administrateur</h1>
        <p class="page-subtitle">Vue d'ensemble de la plateforme LocalLink</p>
      </div>

      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement des statistiques...</p>
      </div>

      <div v-else class="dashboard-content">
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon companies">🏢</div>
            <div class="stat-info">
              <span class="stat-label">Entreprises</span>
              <span class="stat-value">{{ stats.totalCompanies }}</span>
              <span class="stat-detail">
                {{ stats.verifiedCompanies }} vérifiées • {{ stats.pendingCompanies }} en attente
              </span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon quotes">📋</div>
            <div class="stat-info">
              <span class="stat-label">Demandes de devis</span>
              <span class="stat-value">{{ stats.totalQuotes }}</span>
              <span class="stat-detail">
                {{ stats.pendingQuotes }} en attente de modération
              </span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon blog">📝</div>
            <div class="stat-info">
              <span class="stat-label">Articles de blog</span>
              <span class="stat-value">{{ stats.totalPosts }}</span>
              <span class="stat-detail">
                {{ stats.publishedPosts }} publiés
              </span>
            </div>
          </div>
        </div>

        <div class="dashboard-sections">
          <section class="dashboard-section">
            <div class="section-header">
              <h2 class="section-title">Entreprises récentes</h2>
            </div>
            <div class="data-table">
              <div v-if="recentCompanies.length === 0" class="empty-state">
                Aucune entreprise pour le moment
              </div>
              <div v-else class="table-rows">
                <div v-for="company in recentCompanies" :key="company.id" class="table-row">
                  <div class="row-main">
                    <div class="company-info">
                      <span class="company-name">{{ company.company_name }}</span>
                      <span class="company-category">{{ company.category }}</span>
                    </div>
                    <div class="row-meta">
                      <span class="company-location">{{ company.city }}</span>
                      <span
                        class="verification-badge"
                        :class="company.verified ? 'verified' : 'pending'"
                      >
                        {{ company.verified ? 'Vérifiée' : 'En attente' }}
                      </span>
                      <span class="company-date">{{ formatDate(company.created_at) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section class="dashboard-section">
            <div class="section-header">
              <h2 class="section-title">Demandes de devis récentes</h2>
            </div>
            <div class="data-table">
              <div v-if="recentQuotes.length === 0" class="empty-state">
                Aucune demande pour le moment
              </div>
              <div v-else class="table-rows">
                <div v-for="quote in recentQuotes" :key="quote.id" class="table-row">
                  <div class="row-main">
                    <div class="quote-info">
                      <span class="quote-title">{{ quote.title }}</span>
                      <span class="quote-description">{{ quote.description.substring(0, 80) }}...</span>
                    </div>
                    <div class="row-meta">
                      <span
                        class="status-badge"
                        :style="{ backgroundColor: getStatusColor(quote.status) }"
                      >
                        {{ quote.status }}
                      </span>
                      <span class="quote-date">{{ formatDate(quote.created_at) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>

    <div v-else-if="currentPage === 'companies'" class="admin-page">
      <div class="page-header">
        <h1 class="page-title">Gestion des entreprises</h1>
        <p class="page-subtitle">{{ allCompanies.length }} entreprises au total</p>
      </div>

      <div v-if="message.text && !showCompanyModal" class="message-banner" :class="message.type">
        {{ message.text }}
      </div>

      <div class="companies-list">
        <div class="data-table">
          <div v-if="allCompanies.length === 0" class="empty-state">
            Aucune entreprise pour le moment
          </div>
          <div v-else class="table-rows">
            <div v-for="company in allCompanies" :key="company.id" class="table-row clickable" @click="viewCompanyDetails(company)">
              <div class="row-main">
                <div class="company-info">
                  <span class="company-name">{{ company.company_name }}</span>
                  <span class="company-category">{{ company.category }}</span>
                </div>
                <div class="row-meta">
                  <span class="company-location">{{ company.city }}</span>
                  <span class="verification-badge" :class="company.verified ? 'verified' : 'pending'">
                    {{ company.verified ? 'Vérifiée' : 'En attente' }}
                  </span>
                  <span class="company-date">{{ formatDate(company.created_at) }}</span>
                  <button class="btn-action" @click.stop="toggleVerification(company)" :disabled="actionLoading">
                    {{ company.verified ? 'Retirer vérification' : 'Vérifier' }}
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
            <h2>{{ selectedCompany.company_name }}</h2>
            <span class="verification-badge" :class="selectedCompany.verified ? 'verified' : 'pending'">
              {{ selectedCompany.verified ? 'Vérifiée' : 'En attente' }}
            </span>
          </div>

          <div v-if="message.text" class="message-banner" :class="message.type">
            {{ message.text }}
          </div>

          <div class="company-details-grid">
            <div class="detail-row">
              <span class="detail-label">Catégorie</span>
              <span class="detail-value">{{ selectedCompany.category }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Ville</span>
              <span class="detail-value">{{ selectedCompany.city }} ({{ selectedCompany.postal_code }})</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Adresse</span>
              <span class="detail-value">{{ selectedCompany.address }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Téléphone</span>
              <span class="detail-value">{{ selectedCompany.phone }}</span>
            </div>
            <div v-if="selectedCompany.email" class="detail-row">
              <span class="detail-label">Email</span>
              <span class="detail-value">{{ selectedCompany.email }}</span>
            </div>
            <div v-if="selectedCompany.website" class="detail-row">
              <span class="detail-label">Site web</span>
              <span class="detail-value">
                <a :href="selectedCompany.website" target="_blank">{{ selectedCompany.website }}</a>
              </span>
            </div>
            <div class="detail-row full-width">
              <span class="detail-label">Description</span>
              <span class="detail-value">{{ selectedCompany.description }}</span>
            </div>
            <div v-if="selectedCompany.tags && selectedCompany.tags.length > 0" class="detail-row full-width">
              <span class="detail-label">Tags</span>
              <div class="tags-list">
                <span v-for="tag in selectedCompany.tags" :key="tag" class="tag">{{ tag }}</span>
              </div>
            </div>
            <div class="detail-row">
              <span class="detail-label">Créée le</span>
              <span class="detail-value">{{ formatDate(selectedCompany.created_at) }}</span>
            </div>
          </div>

          <div class="modal-actions">
            <button class="btn-verify" :disabled="actionLoading" @click="toggleVerification(selectedCompany)">
              {{ selectedCompany.verified ? 'Retirer la vérification' : 'Vérifier l\'entreprise' }}
            </button>
            <button class="btn-delete" :disabled="actionLoading" @click="deleteCompany(selectedCompany.id)">
              Supprimer
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="currentPage === 'quotes'" class="admin-page">
      <div class="page-header">
        <h1 class="page-title">Gestion des demandes de devis</h1>
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
                  <span class="quote-description">{{ quote.description.substring(0, 80) }}...</span>
                  <span class="quote-company">Par {{ quote.company?.company_name }} ({{ quote.company?.city }})</span>
                </div>
                <div class="row-meta">
                  <span class="status-badge" :style="{ backgroundColor: getStatusColor(quote.status) }">
                    {{ getStatusLabel(quote.status) }}
                  </span>
                  <span class="quote-date">{{ formatDate(quote.created_at) }}</span>
                  <button class="btn-action" @click.stop="updateQuoteStatus(quote, quote.status === 'pending_approval' ? 'approved' : 'pending_approval')" :disabled="actionLoading">
                    {{ quote.status === 'pending_approval' ? 'Approuver' : 'Remettre en attente' }}
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
            <span class="status-badge" :style="{ backgroundColor: getStatusColor(selectedQuote.status) }">
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
              <span class="detail-label">Entreprise demandeuse</span>
              <span class="detail-value">{{ selectedQuote.company?.company_name }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Ville</span>
              <span class="detail-value">{{ selectedQuote.company?.city }}</span>
            </div>

            <div v-if="selectedQuote.company?.email" class="detail-row">
              <span class="detail-label">Email</span>
              <span class="detail-value">
                <a :href="`mailto:${selectedQuote.company.email}`">{{ selectedQuote.company.email }}</a>
              </span>
            </div>

            <div v-if="selectedQuote.company?.phone" class="detail-row">
              <span class="detail-label">Téléphone</span>
              <span class="detail-value">
                <a :href="`tel:${selectedQuote.company.phone}`">{{ selectedQuote.company.phone }}</a>
              </span>
            </div>

            <div v-if="selectedQuote.deadline" class="detail-row">
              <span class="detail-label">Date de livraison souhaitée</span>
              <span class="detail-value">{{ formatDate(selectedQuote.deadline) }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Créée le</span>
              <span class="detail-value">{{ formatDate(selectedQuote.created_at) }}</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Statut actuel</span>
              <span class="detail-value">
                <span class="status-badge" :style="{ backgroundColor: getStatusColor(selectedQuote.status) }">
                  {{ getStatusLabel(selectedQuote.status) }}
                </span>
              </span>
            </div>
          </div>

          <div class="modal-actions-multi">
            <button class="btn-approve" :disabled="actionLoading" @click="updateQuoteStatus(selectedQuote, 'approved')">
              Approuver
            </button>
            <button class="btn-reject" :disabled="actionLoading" @click="updateQuoteStatus(selectedQuote, 'rejected')">
              Rejeter
            </button>
            <button class="btn-pending" :disabled="actionLoading" @click="updateQuoteStatus(selectedQuote, 'pending_approval')">
              Remettre en attente
            </button>
            <button class="btn-delete" :disabled="actionLoading" @click="deleteQuote(selectedQuote.id)">
              Supprimer
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="currentPage === 'blog'" class="admin-page">
      <div class="page-header">
        <h1 class="page-title">Gestion du blog</h1>
      </div>
      <div class="coming-soon">
        <span class="icon">📝</span>
        <p>Module de gestion du blog en cours de développement</p>
      </div>
    </div>

    <div v-else-if="currentPage === 'payments'" class="admin-page">
      <div class="page-header">
        <h1 class="page-title">Gestion des paiements</h1>
      </div>
      <div class="coming-soon">
        <span class="icon">💳</span>
        <p>Module de gestion des paiements en cours de développement</p>
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

.stat-icon.companies {
  background: #dbeafe;
}

.stat-icon.quotes {
  background: #fef3c7;
}

.stat-icon.blog {
  background: #ddd6fe;
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

.quote-company {
  font-size: 12px;
  color: #9ca3af;
  margin-top: 2px;
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

.btn-approve {
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

.btn-approve:hover:not(:disabled) {
  background: #059669;
}

.btn-approve:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-reject {
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

.btn-reject:hover:not(:disabled) {
  background: #dc2626;
}

.btn-reject:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-pending {
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

.btn-pending:hover:not(:disabled) {
  background: #d97706;
}

.btn-pending:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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
