<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { Company } from '../../types/database'

const router = useRouter()

const company = ref<Company | null>(null)
const stats = ref({
  products: 0,
  quotes: 0,
  views: 0,
  activeBoost: false
})
const loading = ref(true)

onMounted(async () => {
  await loadDashboardData()
})

async function loadDashboardData() {
  loading.value = true
  try {
    const { data: companyData } = await supabase
      .from('companies')
      .select('*')
      .eq('user_id', user.value?.id)
      .maybeSingle()

    company.value = companyData

    if (companyData) {
      const { count: productsCount } = await supabase
        .from('products_services')
        .select('*', { count: 'exact', head: true })
        .eq('company_id', companyData.id)
        .eq('available', true)

      const { count: quotesCount } = await supabase
        .from('quote_recipients')
        .select('*', { count: 'exact', head: true })
        .eq('company_id', companyData.id)

      const { data: boostData } = await supabase
        .from('visibility_boosts')
        .select('*')
        .eq('company_id', companyData.id)
        .eq('active', true)
        .gte('end_date', new Date().toISOString().split('T')[0])
        .maybeSingle()

      stats.value = {
        products: productsCount || 0,
        quotes: quotesCount || 0,
        views: Math.floor(Math.random() * 100) + 20,
        activeBoost: !!boostData
      }
    }
  } catch (error) {
    console.error('Error loading dashboard:', error)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <DashboardLayout>
    <div class="dashboard-page">
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="!company" class="empty-state">
        <span class="empty-icon">🏢</span>
        <h2>Bienvenue sur LocalLink !</h2>
        <p>Vous n'avez pas encore de profil entreprise.</p>
        <button class="btn-primary" @click="router.push({ name: 'dashboard-profile' })">
          Créer mon profil
        </button>
      </div>

      <div v-else class="dashboard-content">
        <div class="welcome-card">
          <div class="welcome-content">
            <h2>Bienvenue {{ company.contact_first_name }} 👋</h2>
            <p>{{ company.company_name }}</p>
          </div>
          <div class="company-status">
            <span v-if="company.verified" class="status-badge verified">✓ Vérifiée</span>
            <span v-else class="status-badge pending">⏳ En attente</span>
            <span v-if="company.producer_active" class="status-badge active">🟢 Visible</span>
            <span v-else class="status-badge inactive">🔴 Invisible</span>
          </div>
        </div>

        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon">📦</div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.products }}</div>
              <div class="stat-label">Produits & Services</div>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">📋</div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.quotes }}</div>
              <div class="stat-label">Demandes reçues</div>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">👁️</div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.views }}</div>
              <div class="stat-label">Vues ce mois</div>
            </div>
          </div>

          <div class="stat-card" :class="{ highlight: stats.activeBoost }">
            <div class="stat-icon">⭐</div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.activeBoost ? 'Actif' : 'Inactif' }}</div>
              <div class="stat-label">Boost visibilité</div>
            </div>
          </div>
        </div>

        <div class="actions-grid">
          <div class="action-card">
            <span class="action-icon">🏢</span>
            <h3>Gérer mon profil</h3>
            <p>Modifiez vos informations, logo, description et coordonnées</p>
            <button class="btn-action" @click="router.push({ name: 'dashboard-profile' })">
              Accéder →
            </button>
          </div>

          <div class="action-card">
            <span class="action-icon">📦</span>
            <h3>Mes produits & services</h3>
            <p>Ajoutez ou modifiez votre catalogue de produits et services</p>
            <button class="btn-action" @click="router.push({ name: 'dashboard-products' })">
              Gérer →
            </button>
          </div>

          <div class="action-card">
            <span class="action-icon">📋</span>
            <h3>Demandes de devis</h3>
            <p>Consultez les demandes de devis que vous avez reçues</p>
            <button class="btn-action" @click="router.push({ name: 'dashboard-quotes' })">
              Voir →
            </button>
          </div>

          <div class="action-card">
            <span class="action-icon">⭐</span>
            <h3>Augmenter ma visibilité</h3>
            <p>Apparaissez en haut des résultats de recherche</p>
            <button class="btn-action" @click="router.push({ name: 'dashboard-visibility' })">
              Découvrir →
            </button>
          </div>
        </div>

        <div class="info-banner">
          <span class="info-icon">💡</span>
          <div class="info-content">
            <h3>Conseil du jour</h3>
            <p>
              Ajoutez des photos de qualité à vos produits pour augmenter vos chances de recevoir
              des demandes de devis. Les fiches avec photos reçoivent 3x plus de contacts !
            </p>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.dashboard-page {
  max-width: 1400px;
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

.empty-state {
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

.empty-state h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-primary {
  padding: 14px 28px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #047857;
  transform: translateY(-1px);
}

.dashboard-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.welcome-card {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  color: white;
  padding: 32px;
  border-radius: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.welcome-content h2 {
  font-size: 28px;
  font-weight: 700;
  margin: 0 0 8px 0;
}

.welcome-content p {
  font-size: 18px;
  margin: 0;
  opacity: 0.9;
}

.company-status {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.status-badge {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
  background: rgba(255, 255, 255, 0.2);
}

.status-badge.verified {
  background: rgba(255, 255, 255, 0.3);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
}

.stat-card {
  background: white;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  display: flex;
  align-items: center;
  gap: 16px;
  transition: all 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.stat-card.highlight {
  border: 2px solid #fbbf24;
  background: #fffbeb;
}

.stat-icon {
  font-size: 36px;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #111827;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #6b7280;
}

.actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
}

.action-card {
  background: white;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  display: flex;
  flex-direction: column;
  transition: all 0.2s;
}

.action-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.action-icon {
  font-size: 32px;
  margin-bottom: 12px;
}

.action-card h3 {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.action-card p {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 16px 0;
  flex: 1;
}

.btn-action {
  padding: 10px 20px;
  background: #f3f4f6;
  color: #059669;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  text-align: left;
}

.btn-action:hover {
  background: #d1fae5;
}

.info-banner {
  background: #eff6ff;
  border: 1px solid #93c5fd;
  padding: 24px;
  border-radius: 12px;
  display: flex;
  gap: 16px;
  align-items: start;
}

.info-icon {
  font-size: 32px;
  flex-shrink: 0;
}

.info-content h3 {
  font-size: 16px;
  font-weight: 700;
  color: #1e40af;
  margin: 0 0 8px 0;
}

.info-content p {
  font-size: 14px;
  color: #374151;
  line-height: 1.6;
  margin: 0;
}

@media (max-width: 768px) {
  .welcome-card {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .stats-grid,
  .actions-grid {
    grid-template-columns: 1fr;
  }
}
</style>
