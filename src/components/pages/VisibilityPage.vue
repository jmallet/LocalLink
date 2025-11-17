<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { Company } from '../../types/database'

interface VisibilityBoost {
  id: string
  company_id: string
  zone: string
  start_date: string
  end_date: string
  price: number
  active: boolean
  created_at: string
}

const company = ref<Company | null>(null)
const activeBoosts = ref<VisibilityBoost[]>([])
const loading = ref(true)
const showPaymentModal = ref(false)
const processing = ref(false)
const message = ref({ type: '', text: '' })

const selectedPlan = ref({
  duration: 30,
  zone: '',
  price: 0
})

const plans = [
  {
    name: '1 mois',
    duration: 30,
    price: 49,
    popular: false,
    features: [
      'Apparaître en haut des résultats',
      'Badge "Mis en avant"',
      'Statistiques de visibilité',
      '1 zone géographique'
    ]
  },
  {
    name: '3 mois',
    duration: 90,
    price: 129,
    popular: true,
    discount: 12,
    features: [
      'Tout du plan 1 mois',
      '12% de réduction',
      'Priorité dans les recherches',
      'Support prioritaire'
    ]
  },
  {
    name: '6 mois',
    duration: 180,
    price: 239,
    popular: false,
    discount: 20,
    features: [
      'Tout du plan 3 mois',
      '20% de réduction',
      'Visibilité maximale',
      'Rapport mensuel détaillé'
    ]
  }
]

const cities = [
  'Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice',
  'Nantes', 'Strasbourg', 'Montpellier', 'Bordeaux', 'Lille'
]

const hasCompany = computed(() => !!company.value)
const hasActiveBoost = computed(() => activeBoosts.value.length > 0)

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
      const { data: boostsData } = await supabase
        .from('visibility_boosts')
        .select('*')
        .eq('company_id', companyData.id)
        .eq('active', true)
        .gte('end_date', new Date().toISOString().split('T')[0])
        .order('end_date', { ascending: false })

      activeBoosts.value = boostsData || []
    }
  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

function selectPlan(plan: typeof plans[0]) {
  selectedPlan.value = {
    duration: plan.duration,
    zone: company.value?.city || '',
    price: plan.price
  }
  showPaymentModal.value = true
  message.value = { type: '', text: '' }
}

function closePaymentModal() {
  showPaymentModal.value = false
  message.value = { type: '', text: '' }
}

async function processPayment() {
  if (!company.value || !selectedPlan.value.zone) return

  processing.value = true
  message.value = { type: '', text: '' }

  try {
    const startDate = new Date()
    const endDate = new Date()
    endDate.setDate(endDate.getDate() + selectedPlan.value.duration)

    const { error } = await supabase
      .from('visibility_boosts')
      .insert({
        company_id: company.value.id,
        zone: selectedPlan.value.zone,
        start_date: startDate.toISOString().split('T')[0],
        end_date: endDate.toISOString().split('T')[0],
        price: selectedPlan.value.price,
        active: true
      })

    if (error) throw error

    message.value = {
      type: 'success',
      text: 'Paiement effectué avec succès ! Votre boost est maintenant actif.'
    }

    await loadData()
    setTimeout(() => closePaymentModal(), 2000)
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue lors du paiement'
    }
  } finally {
    processing.value = false
  }
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric'
  })
}

function getDaysRemaining(endDate: string) {
  const end = new Date(endDate)
  const now = new Date()
  const diffInMs = end.getTime() - now.getTime()
  return Math.ceil(diffInMs / (1000 * 60 * 60 * 24))
}
</script>

<template>
  <DashboardLayout>
    <div class="visibility-page">
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="!hasCompany" class="empty-state">
        <span class="empty-icon">🏢</span>
        <h2>Profil entreprise requis</h2>
        <p>Vous devez d'abord créer votre profil entreprise.</p>
      </div>

      <div v-else class="visibility-content">
        <div class="page-header">
          <div>
            <h1 class="page-title">Boost de visibilité</h1>
            <p class="page-subtitle">Apparaissez en haut des résultats de recherche</p>
          </div>
        </div>

        <div v-if="hasActiveBoost" class="active-boosts-section">
          <h2 class="section-title">Vos boosts actifs</h2>
          <div class="boosts-grid">
            <div v-for="boost in activeBoosts" :key="boost.id" class="boost-card active">
              <div class="boost-header">
                <span class="boost-icon">⭐</span>
                <span class="boost-status">Actif</span>
              </div>
              <div class="boost-info">
                <h3>{{ boost.zone }}</h3>
                <p class="boost-dates">
                  Du {{ formatDate(boost.start_date) }} au {{ formatDate(boost.end_date) }}
                </p>
                <p class="boost-remaining">
                  Encore {{ getDaysRemaining(boost.end_date) }} jours
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="plans-section">
          <div class="section-header">
            <h2 class="section-title">Choisissez votre plan</h2>
            <p class="section-description">
              Augmentez votre visibilité et recevez plus de demandes de devis
            </p>
          </div>

          <div class="plans-grid">
            <div
              v-for="plan in plans"
              :key="plan.name"
              class="plan-card"
              :class="{ popular: plan.popular }"
            >
              <div v-if="plan.popular" class="popular-badge">Le plus populaire</div>
              <div v-if="plan.discount" class="discount-badge">-{{ plan.discount }}%</div>

              <div class="plan-header">
                <h3 class="plan-name">{{ plan.name }}</h3>
                <div class="plan-price">
                  <span class="price-amount">{{ plan.price }}€</span>
                  <span v-if="plan.discount" class="price-original">
                    {{ Math.round(plan.price / (1 - plan.discount / 100)) }}€
                  </span>
                </div>
              </div>

              <ul class="plan-features">
                <li v-for="(feature, index) in plan.features" :key="index">
                  <span class="feature-icon">✓</span>
                  {{ feature }}
                </li>
              </ul>

              <button class="btn-select-plan" @click="selectPlan(plan)">
                Choisir ce plan
              </button>
            </div>
          </div>
        </div>

        <div class="benefits-section">
          <h2 class="section-title">Pourquoi booster votre visibilité ?</h2>
          <div class="benefits-grid">
            <div class="benefit-card">
              <span class="benefit-icon">🎯</span>
              <h3>Visibilité maximale</h3>
              <p>Apparaissez en premier dans les résultats de recherche de votre zone</p>
            </div>
            <div class="benefit-card">
              <span class="benefit-icon">📈</span>
              <h3>Plus de demandes</h3>
              <p>Recevez jusqu'à 3x plus de demandes de devis</p>
            </div>
            <div class="benefit-card">
              <span class="benefit-icon">⭐</span>
              <h3>Badge premium</h3>
              <p>Affichez un badge "Mis en avant" sur votre fiche</p>
            </div>
            <div class="benefit-card">
              <span class="benefit-icon">📊</span>
              <h3>Statistiques</h3>
              <p>Suivez vos performances avec des rapports détaillés</p>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showPaymentModal" class="modal-overlay" @click="closePaymentModal">
        <div class="modal-content payment-modal" @click.stop>
          <div class="modal-header">
            <h2>Finaliser votre boost</h2>
            <button class="close-btn" @click="closePaymentModal">✕</button>
          </div>

          <div v-if="message.text" class="message-banner" :class="message.type">
            {{ message.text }}
          </div>

          <div class="modal-body">
            <div class="payment-summary">
              <h3>Récapitulatif</h3>
              <div class="summary-item">
                <span>Durée</span>
                <span class="summary-value">{{ selectedPlan.duration }} jours</span>
              </div>
              <div class="summary-item">
                <span>Zone géographique</span>
                <select v-model="selectedPlan.zone" class="form-select">
                  <option value="">Sélectionnez une ville</option>
                  <option v-for="city in cities" :key="city" :value="city">
                    {{ city }}
                  </option>
                </select>
              </div>
              <div class="summary-item total">
                <span>Total</span>
                <span class="summary-value">{{ selectedPlan.price }}€</span>
              </div>
            </div>

            <div class="payment-info">
              <h3>Paiement simulé</h3>
              <p class="info-text">
                Cette fonctionnalité simule un paiement. En production,
                un vrai système de paiement serait intégré (Stripe, PayPal, etc.).
              </p>
            </div>

            <div class="modal-actions">
              <button class="btn-cancel" @click="closePaymentModal">
                Annuler
              </button>
              <button
                class="btn-pay"
                :disabled="processing || !selectedPlan.zone"
                @click="processPayment"
              >
                {{ processing ? 'Traitement...' : `Payer ${selectedPlan.price}€` }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.visibility-page {
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
  margin: 0;
}

.page-header {
  margin-bottom: 48px;
}

.page-title {
  font-size: 32px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.page-subtitle {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.active-boosts-section {
  margin-bottom: 48px;
}

.section-title {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 24px 0;
}

.boosts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.boost-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  border: 2px solid transparent;
}

.boost-card.active {
  border-color: #fbbf24;
  background: #fffbeb;
}

.boost-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.boost-icon {
  font-size: 32px;
}

.boost-status {
  padding: 4px 12px;
  background: #fbbf24;
  color: #78350f;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 700;
}

.boost-info h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.boost-dates {
  font-size: 14px;
  color: #6b7280;
  margin: 0 0 4px 0;
}

.boost-remaining {
  font-size: 14px;
  font-weight: 600;
  color: #059669;
  margin: 0;
}

.plans-section {
  margin-bottom: 48px;
}

.section-header {
  text-align: center;
  margin-bottom: 40px;
}

.section-description {
  font-size: 16px;
  color: #6b7280;
  margin: 8px 0 0 0;
}

.plans-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
}

.plan-card {
  background: white;
  border-radius: 16px;
  padding: 32px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  position: relative;
  transition: all 0.2s;
  border: 2px solid transparent;
}

.plan-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.plan-card.popular {
  border-color: #059669;
  box-shadow: 0 4px 16px rgba(5, 150, 105, 0.15);
}

.popular-badge {
  position: absolute;
  top: 16px;
  right: 16px;
  padding: 6px 12px;
  background: #059669;
  color: white;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 700;
}

.discount-badge {
  position: absolute;
  top: 16px;
  left: 16px;
  padding: 6px 12px;
  background: #ef4444;
  color: white;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 700;
}

.plan-header {
  margin-bottom: 24px;
}

.plan-name {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 16px 0;
}

.plan-price {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.price-amount {
  font-size: 40px;
  font-weight: 700;
  color: #059669;
}

.price-original {
  font-size: 20px;
  color: #9ca3af;
  text-decoration: line-through;
}

.plan-features {
  list-style: none;
  padding: 0;
  margin: 0 0 32px 0;
}

.plan-features li {
  padding: 12px 0;
  font-size: 15px;
  color: #374151;
  display: flex;
  align-items: center;
  gap: 12px;
}

.feature-icon {
  color: #059669;
  font-weight: 700;
  font-size: 18px;
}

.btn-select-plan {
  width: 100%;
  padding: 14px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-select-plan:hover {
  background: #047857;
  transform: translateY(-1px);
}

.benefits-section {
  margin-bottom: 48px;
}

.benefits-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 24px;
}

.benefit-card {
  background: white;
  padding: 32px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  text-align: center;
}

.benefit-icon {
  font-size: 48px;
  display: block;
  margin-bottom: 16px;
}

.benefit-card h3 {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.benefit-card p {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
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
  max-width: 500px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
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
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 8px;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #f3f4f6;
  color: #111827;
}

.message-banner {
  margin: 16px 24px;
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

.modal-body {
  padding: 24px;
}

.payment-summary {
  background: #f9fafb;
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 24px;
}

.payment-summary h3 {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 16px 0;
}

.summary-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  font-size: 14px;
  color: #374151;
}

.summary-item:not(:last-child) {
  border-bottom: 1px solid #e5e7eb;
}

.summary-item.total {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  padding-top: 16px;
  border-top: 2px solid #d1d5db;
  border-bottom: none;
}

.summary-value {
  font-weight: 600;
  color: #111827;
}

.form-select {
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.2s;
}

.form-select:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

.payment-info {
  margin-bottom: 24px;
}

.payment-info h3 {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.info-text {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
  padding: 12px;
  background: #eff6ff;
  border-left: 3px solid #3b82f6;
  border-radius: 4px;
}

.modal-actions {
  display: flex;
  gap: 12px;
}

.btn-cancel {
  flex: 1;
  padding: 12px 24px;
  background: transparent;
  color: #6b7280;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel:hover {
  background: #f3f4f6;
}

.btn-pay {
  flex: 2;
  padding: 12px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-pay:hover:not(:disabled) {
  background: #047857;
}

.btn-pay:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .plans-grid {
    grid-template-columns: 1fr;
  }

  .benefits-grid {
    grid-template-columns: 1fr;
  }

  .modal-actions {
    flex-direction: column;
  }
}
</style>
