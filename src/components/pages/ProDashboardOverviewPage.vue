<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { user, currentCompany, currentCompanyUser } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { QuoteRequest } from '../../types/database'

const loading = ref(true)
const receivedQuotes = ref<QuoteRequest[]>([])
const sentQuotes = ref<QuoteRequest[]>([])

const stats = computed(() => {
  return {
    receivedTotal: receivedQuotes.value.length,
    receivedNew: receivedQuotes.value.filter(q => q.status === 'SENT').length,
    sentTotal: sentQuotes.value.length,
    sentResponded: sentQuotes.value.filter(q => q.status === 'RESPONDED').length,
  }
})

onMounted(async () => {
  await loadDashboardData()
})

async function loadDashboardData() {
  if (!currentCompany.value) return

  loading.value = true
  try {
    const { data: received } = await supabase
      .from('quote_requests')
      .select('*')
      .eq('target_company_id', currentCompany.value.id)
      .order('created_at', { ascending: false })

    receivedQuotes.value = received || []

    const { data: sent } = await supabase
      .from('quote_requests')
      .select('*')
      .eq('requester_id', user.value?.id)
      .eq('requester_type', 'ACHETEUR_PRO')
      .order('created_at', { ascending: false })

    sentQuotes.value = sent || []
  } catch (error) {
    console.error('Error loading dashboard data:', error)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <DashboardLayout>
    <div class="pro-dashboard-overview">
      <div class="dashboard-header">
        <h1>Tableau de bord</h1>
        <p class="subtitle">Vue d'ensemble de votre activité</p>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else class="dashboard-content">
        <div class="company-info-card">
          <h2>{{ currentCompany?.name }}</h2>
          <p class="company-details">{{ currentCompany?.city }}</p>
          <div class="producer-status">
            <span class="status-label">Profil producteur :</span>
            <span class="status-badge" :class="{ active: currentCompanyUser?.is_producteur }">
              {{ currentCompanyUser?.is_producteur ? 'Actif' : 'Inactif' }}
            </span>
          </div>
          <div v-if="!currentCompanyUser?.is_producteur" class="cta-container">
            <router-link to="/dashboard/pro/parametres" class="btn-primary">
              Activer le profil producteur
            </router-link>
          </div>
        </div>

        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon">📥</div>
            <div class="stat-content">
              <h3>{{ stats.receivedTotal }}</h3>
              <p>Devis reçus</p>
              <span class="stat-detail">{{ stats.receivedNew }} nouveaux</span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">📤</div>
            <div class="stat-content">
              <h3>{{ stats.sentTotal }}</h3>
              <p>Devis envoyés</p>
              <span class="stat-detail">{{ stats.sentResponded }} réponses</span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">⭐</div>
            <div class="stat-content">
              <h3>{{ currentCompanyUser?.is_acheteur_pro ? 'Oui' : 'Non' }}</h3>
              <p>Acheteur professionnel</p>
            </div>
          </div>
        </div>

        <div class="recent-activity">
          <h2>Activité récente</h2>

          <div v-if="currentCompanyUser?.is_producteur && receivedQuotes.length > 0" class="activity-section">
            <h3>Derniers devis reçus</h3>
            <div class="quote-list">
              <router-link
                v-for="quote in receivedQuotes.slice(0, 3)"
                :key="quote.id"
                :to="{ name: 'pro-received-quotes' }"
                class="quote-item"
              >
                <div class="quote-title">{{ quote.title }}</div>
                <div class="quote-meta">
                  <span class="quote-origin">{{ quote.requester_type === 'PARTICULIER' ? 'Particulier' : 'Professionnel' }}</span>
                  <span class="quote-date">{{ new Date(quote.created_at).toLocaleDateString('fr-FR') }}</span>
                  <span class="quote-status" :class="quote.status.toLowerCase()">
                    {{ quote.status === 'SENT' ? 'Nouveau' : quote.status === 'VIEWED' ? 'Vu' : quote.status === 'RESPONDED' ? 'Répondu' : 'Fermé' }}
                  </span>
                </div>
              </router-link>
            </div>
          </div>

          <div v-if="sentQuotes.length > 0" class="activity-section">
            <h3>Derniers devis envoyés</h3>
            <div class="quote-list">
              <router-link
                v-for="quote in sentQuotes.slice(0, 3)"
                :key="quote.id"
                :to="{ name: 'pro-sent-quotes' }"
                class="quote-item"
              >
                <div class="quote-title">{{ quote.title }}</div>
                <div class="quote-meta">
                  <span class="quote-date">{{ new Date(quote.created_at).toLocaleDateString('fr-FR') }}</span>
                  <span class="quote-status" :class="quote.status.toLowerCase()">
                    {{ quote.status === 'SENT' ? 'Envoyé' : quote.status === 'VIEWED' ? 'Vu' : quote.status === 'RESPONDED' ? 'Répondu' : 'Fermé' }}
                  </span>
                </div>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.pro-dashboard-overview {
  padding: 2rem;
}

.dashboard-header {
  margin-bottom: 2rem;
}

.dashboard-header h1 {
  font-size: 2rem;
  font-weight: 700;
  color: #1a1a1a;
  margin: 0 0 0.5rem 0;
}

.subtitle {
  color: #666;
  margin: 0;
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

.dashboard-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.company-info-card {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  color: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.company-info-card h2 {
  margin: 0 0 0.5rem 0;
  font-size: 1.5rem;
}

.company-details {
  margin: 0 0 1rem 0;
  opacity: 0.9;
}

.producer-status {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-top: 1rem;
}

.status-label {
  font-weight: 500;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 600;
}

.status-badge.active {
  background: rgba(34, 197, 94, 0.9);
}

.cta-container {
  margin-top: 1.5rem;
}

.btn-primary {
  display: inline-block;
  background: white;
  color: #2563eb;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 600;
  text-decoration: none;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  transition: box-shadow 0.2s;
}

.stat-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.stat-icon {
  font-size: 2.5rem;
}

.stat-content h3 {
  margin: 0 0 0.25rem 0;
  font-size: 1.875rem;
  font-weight: 700;
  color: #1a1a1a;
}

.stat-content p {
  margin: 0;
  color: #666;
  font-size: 0.875rem;
}

.stat-detail {
  display: block;
  color: #2563eb;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.recent-activity {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 1.5rem;
}

.recent-activity h2 {
  margin: 0 0 1.5rem 0;
  font-size: 1.25rem;
  font-weight: 700;
  color: #1a1a1a;
}

.activity-section {
  margin-bottom: 2rem;
}

.activity-section:last-child {
  margin-bottom: 0;
}

.activity-section h3 {
  margin: 0 0 1rem 0;
  font-size: 1rem;
  font-weight: 600;
  color: #374151;
}

.quote-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.quote-item {
  display: block;
  padding: 1rem;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  text-decoration: none;
  transition: background 0.2s, border-color 0.2s;
}

.quote-item:hover {
  background: #f3f4f6;
  border-color: #d1d5db;
}

.quote-title {
  font-weight: 600;
  color: #1a1a1a;
  margin-bottom: 0.5rem;
}

.quote-meta {
  display: flex;
  align-items: center;
  gap: 1rem;
  font-size: 0.875rem;
  color: #666;
}

.quote-origin, .quote-date {
  color: #666;
}

.quote-status {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-weight: 500;
  font-size: 0.75rem;
}

.quote-status.sent {
  background: #dbeafe;
  color: #1e40af;
}

.quote-status.viewed {
  background: #fef3c7;
  color: #92400e;
}

.quote-status.responded {
  background: #d1fae5;
  color: #065f46;
}

.quote-status.closed {
  background: #f3f4f6;
  color: #4b5563;
}

@media (max-width: 768px) {
  .pro-dashboard-overview {
    padding: 1rem;
  }

  .dashboard-header h1 {
    font-size: 1.5rem;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .quote-meta {
    flex-wrap: wrap;
  }
}
</style>
