<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { isAuthenticated, isParticulier, profile } from '../../stores/auth'
import IndividualSignupModal from '../auth/IndividualSignupModal.vue'

const router = useRouter()
const showIndividualSignup = ref(false)

function navigateToRequestQuote() {
  if (isAuthenticated.value) {
    if (isParticulier.value || profile.value?.user_type === 'ADMIN') {
      router.push({ name: 'individual-new-quote' })
    } else {
      alert('Cette fonctionnalité est réservée aux particuliers. Veuillez créer un compte particulier.')
    }
  } else {
    showIndividualSignup.value = true
  }
}

function closeIndividualSignup() {
  showIndividualSignup.value = false
}

function navigateToFindPro() {
  router.push({ name: 'pros-locaux' })
}

function navigateToProSpace() {
  if (isAuthenticated.value) {
    router.push({ name: 'dashboard-pro' })
  } else {
    router.push({ name: 'login' })
  }
}
</script>

<template>
  <div class="home-page">
    <IndividualSignupModal
      v-if="showIndividualSignup"
      @close="closeIndividualSignup"
    />
    <section class="hero">
      <div class="hero-content">
        <div class="hero-badge">
          <span class="badge-icon">🏠</span>
          Le pro du quartier, à votre porte
        </div>

        <h1 class="hero-title">
          Trouvez le bon
          <span class="highlight">professionnel</span>
          près de chez vous
        </h1>

        <p class="hero-subtitle">
          Déposez votre demande en 2 minutes et recevez des devis<br />
          de professionnels locaux vérifiés.
        </p>

        <div class="hero-actions">
          <button class="btn-primary-hero" @click="navigateToRequestQuote">
            <span class="btn-icon">📝</span>
            Déposer une demande
          </button>
          <button class="btn-secondary-hero" @click="navigateToFindPro">
            <span class="btn-icon">🔍</span>
            Trouver un pro →
          </button>
        </div>
      </div>
    </section>

    <section class="stats">
      <div class="container-stats">
        <div class="stat-item">
          <div class="stat-number">1240</div>
          <div class="stat-label">Demandes ce mois</div>
        </div>
        <div class="stat-divider"></div>
        <div class="stat-item">
          <div class="stat-number">340</div>
          <div class="stat-label">Pros locaux actifs</div>
        </div>
        <div class="stat-divider"></div>
        <div class="stat-item">
          <div class="stat-number">4.8★</div>
          <div class="stat-label">Satisfaction moyenne</div>
        </div>
      </div>
    </section>

    <section class="user-types">
      <div class="container">
        <div class="user-type-card particulier">
          <div class="card-icon">🏡</div>
          <h2 class="card-title">Particulier</h2>
          <p class="card-description">
            Déposez une demande et recevez des devis, ou parcourez directement l'annuaire des pros.
          </p>
          <div class="card-actions">
            <button class="btn-card-primary" @click="navigateToRequestQuote">
              <span class="btn-icon">📝</span>
              Déposer une demande
            </button>
            <button class="btn-card-secondary" @click="navigateToFindPro">
              <span class="btn-icon">🔍</span>
              Trouver un pro
            </button>
          </div>
        </div>

        <div class="user-type-card professionnel">
          <div class="card-icon">🔧</div>
          <h2 class="card-title">Professionnel</h2>
          <p class="card-description">
            Accédez aux demandes de clients locaux et développez votre activité avec des leads qualifiés.
          </p>
          <div class="card-actions">
            <button class="btn-card-pro" @click="navigateToProSpace">
              Espace pro →
            </button>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.home-page {
  min-height: 100vh;
  background: linear-gradient(180deg, #1a1a1a 0%, #2d2520 100%);
}

.hero {
  max-width: 1200px;
  margin: 0 auto;
  padding: 100px 24px 80px;
  text-align: center;
}

.hero-content {
  max-width: 900px;
  margin: 0 auto;
}

.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(234, 88, 12, 0.15);
  border: 1px solid rgba(234, 88, 12, 0.3);
  color: #fb923c;
  padding: 8px 16px;
  border-radius: 24px;
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 32px;
}

.badge-icon {
  font-size: 16px;
}

.hero-title {
  font-size: 72px;
  font-weight: 800;
  line-height: 1.1;
  margin: 0 0 32px 0;
  color: white;
}

.hero-title .highlight {
  color: #fb923c;
}

.hero-subtitle {
  font-size: 18px;
  line-height: 1.6;
  margin: 0 0 48px 0;
  color: rgba(255, 255, 255, 0.8);
}

.hero-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
  flex-wrap: wrap;
}

.btn-primary-hero,
.btn-secondary-hero {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 16px 28px;
  border-radius: 12px;
  font-weight: 600;
  font-size: 16px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary-hero {
  background: #ea580c;
  color: white;
}

.btn-primary-hero:hover {
  background: #dc2626;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(234, 88, 12, 0.3);
}

.btn-secondary-hero {
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.btn-secondary-hero:hover {
  background: rgba(255, 255, 255, 0.15);
  transform: translateY(-2px);
}

.btn-icon {
  font-size: 18px;
}

.stats {
  background: white;
  padding: 48px 24px;
}

.container-stats {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  justify-content: space-around;
  align-items: center;
  gap: 48px;
}

.stat-item {
  text-align: center;
}

.stat-number {
  font-size: 48px;
  font-weight: 800;
  color: #ea580c;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #6b7280;
  font-weight: 500;
}

.stat-divider {
  width: 1px;
  height: 60px;
  background: #e5e7eb;
}

.user-types {
  padding: 80px 24px;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 32px;
}

.user-type-card {
  background: white;
  border-radius: 16px;
  padding: 48px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition: all 0.3s;
}

.user-type-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.15);
}

.card-icon {
  width: 64px;
  height: 64px;
  background: #f3f4f6;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  margin-bottom: 24px;
}

.particulier .card-icon {
  background: rgba(234, 88, 12, 0.1);
}

.professionnel .card-icon {
  background: rgba(249, 115, 22, 0.1);
}

.card-title {
  font-size: 28px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
}

.card-description {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 32px 0;
}

.card-actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.btn-card-primary,
.btn-card-secondary,
.btn-card-pro {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 24px;
  border-radius: 10px;
  font-weight: 600;
  font-size: 15px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-card-primary {
  background: #ea580c;
  color: white;
}

.btn-card-primary:hover {
  background: #dc2626;
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(234, 88, 12, 0.3);
}

.btn-card-secondary {
  background: transparent;
  color: #374151;
  border: 2px solid #e5e7eb;
}

.btn-card-secondary:hover {
  background: #f9fafb;
  border-color: #d1d5db;
}

.btn-card-pro {
  background: #f97316;
  color: white;
}

.btn-card-pro:hover {
  background: #ea580c;
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(249, 115, 22, 0.3);
}

@media (max-width: 1024px) {
  .hero-title {
    font-size: 56px;
  }

  .container {
    grid-template-columns: 1fr;
  }

  .container-stats {
    flex-direction: column;
    gap: 32px;
  }

  .stat-divider {
    width: 100px;
    height: 1px;
  }
}

@media (max-width: 768px) {
  .hero {
    padding: 60px 16px 48px;
  }

  .hero-title {
    font-size: 40px;
  }

  .hero-subtitle {
    font-size: 16px;
  }

  .hero-actions {
    flex-direction: column;
    width: 100%;
  }

  .btn-primary-hero,
  .btn-secondary-hero {
    width: 100%;
    justify-content: center;
  }

  .user-type-card {
    padding: 32px 24px;
  }

  .card-title {
    font-size: 24px;
  }

  .stat-number {
    font-size: 36px;
  }
}
</style>
