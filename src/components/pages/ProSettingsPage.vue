<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user, profile, currentCompany, currentCompanyUser, loadCompanies } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'

const router = useRouter()
const loading = ref(true)
const saving = ref(false)
const message = ref('')

const profileData = ref({
  first_name: '',
  last_name: '',
  phone: '',
})

const producerActivation = ref(false)

onMounted(async () => {
  await loadData()
})

async function loadData() {
  loading.value = true
  try {
    if (profile.value) {
      profileData.value = {
        first_name: profile.value.first_name || '',
        last_name: profile.value.last_name || '',
        phone: profile.value.phone || '',
      }
    }

    producerActivation.value = currentCompanyUser.value?.is_producteur || false
  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

async function saveProfile() {
  if (!user.value) return

  saving.value = true
  message.value = ''

  try {
    const { error } = await supabase
      .from('profiles')
      .update({
        first_name: profileData.value.first_name,
        last_name: profileData.value.last_name,
        phone: profileData.value.phone,
      })
      .eq('user_id', user.value.id)

    if (error) throw error

    message.value = 'Profil mis à jour avec succès'
  } catch (error: any) {
    console.error('Error saving profile:', error)
    message.value = 'Erreur lors de la mise à jour du profil'
  } finally {
    saving.value = false
  }
}

async function activateProducer() {
  if (!currentCompanyUser.value || !currentCompany.value) return

  saving.value = true
  message.value = ''

  try {
    const { error: companyUserError } = await supabase
      .from('company_users')
      .update({ is_producteur: true })
      .eq('id', currentCompanyUser.value.id)

    if (companyUserError) throw companyUserError

    const { error: profileError } = await supabase
      .from('producer_profiles')
      .upsert({
        company_id: currentCompany.value.id,
        is_active: true,
        delivery_available: false,
      })

    if (profileError) throw profileError

    await loadCompanies()
    producerActivation.value = true
    message.value = 'Profil producteur activé avec succès'
  } catch (error: any) {
    console.error('Error activating producer:', error)
    message.value = 'Erreur lors de l\'activation du profil producteur'
  } finally {
    saving.value = false
  }
}

async function deactivateProducer() {
  if (!currentCompanyUser.value) return

  saving.value = true
  message.value = ''

  try {
    const { error } = await supabase
      .from('company_users')
      .update({ is_producteur: false })
      .eq('id', currentCompanyUser.value.id)

    if (error) throw error

    await loadCompanies()
    producerActivation.value = false
    message.value = 'Profil producteur désactivé'
  } catch (error: any) {
    console.error('Error deactivating producer:', error)
    message.value = 'Erreur lors de la désactivation du profil producteur'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <DashboardLayout>
    <div class="pro-settings">
      <div class="page-header">
        <h1>Paramètres</h1>
        <p class="subtitle">Gérez vos préférences et paramètres de compte</p>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else class="content">
        <section class="settings-section">
          <h2>Profil utilisateur</h2>
          <form @submit.prevent="saveProfile" class="settings-form">
            <div class="form-row">
              <div class="form-group">
                <label for="first_name">Prénom</label>
                <input
                  id="first_name"
                  v-model="profileData.first_name"
                  type="text"
                />
              </div>

              <div class="form-group">
                <label for="last_name">Nom</label>
                <input
                  id="last_name"
                  v-model="profileData.last_name"
                  type="text"
                />
              </div>
            </div>

            <div class="form-group">
              <label for="phone">Téléphone</label>
              <input
                id="phone"
                v-model="profileData.phone"
                type="tel"
              />
            </div>

            <div class="form-group">
              <label for="email">Email</label>
              <input
                id="email"
                :value="user?.email"
                type="email"
                disabled
              />
              <p class="field-hint">L'email ne peut pas être modifié</p>
            </div>

            <button type="submit" class="btn-primary" :disabled="saving">
              {{ saving ? 'Enregistrement...' : 'Enregistrer' }}
            </button>
          </form>
        </section>

        <section class="settings-section producer-section">
          <h2>Profil producteur</h2>
          <p class="section-description">
            Le profil producteur vous permet de recevoir des demandes de devis de la part de clients.
            Vous pourrez gérer vos produits et services, définir votre rayon d'intervention, et plus encore.
          </p>

          <div v-if="!producerActivation" class="activation-card">
            <div class="card-content">
              <div class="card-icon">🎯</div>
              <h3>Activez votre profil producteur</h3>
              <p>Développez votre activité en recevant des demandes de devis qualifiées</p>
              <ul class="benefits-list">
                <li>Recevez des demandes de clients potentiels</li>
                <li>Gérez vos produits et services</li>
                <li>Définissez votre zone d'intervention</li>
                <li>Augmentez votre visibilité</li>
              </ul>
              <button
                @click="activateProducer"
                class="btn-activate"
                :disabled="saving"
              >
                {{ saving ? 'Activation...' : 'Activer le profil producteur' }}
              </button>
            </div>
          </div>

          <div v-else class="activation-card active">
            <div class="card-content">
              <div class="card-icon">✅</div>
              <h3>Profil producteur actif</h3>
              <p>Vous pouvez maintenant recevoir des demandes de devis</p>
              <div class="active-actions">
                <router-link to="/dashboard/pro/fiche-entreprise" class="btn-primary">
                  Gérer ma fiche entreprise
                </router-link>
                <button
                  @click="deactivateProducer"
                  class="btn-secondary"
                  :disabled="saving"
                >
                  Désactiver
                </button>
              </div>
            </div>
          </div>
        </section>

        <section class="settings-section">
          <h2>Acheteur professionnel</h2>
          <p class="section-description">
            En tant qu'acheteur professionnel, vous pouvez envoyer des demandes de devis à d'autres professionnels.
          </p>
          <div class="status-badge" :class="{ active: currentCompanyUser?.is_acheteur_pro }">
            {{ currentCompanyUser?.is_acheteur_pro ? 'Actif' : 'Inactif' }}
          </div>
        </section>

        <div v-if="message" class="message" :class="{ success: message.includes('succès') }">
          {{ message }}
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.pro-settings {
  padding: 2rem;
  max-width: 900px;
}

.page-header {
  margin-bottom: 2rem;
}

.page-header h1 {
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

.content {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.settings-section {
  background: white;
  padding: 1.5rem;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
}

.settings-section h2 {
  margin: 0 0 1rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1a1a1a;
}

.section-description {
  color: #6b7280;
  margin: 0 0 1.5rem 0;
  line-height: 1.6;
}

.producer-section {
  border-left: 4px solid #2563eb;
}

.settings-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-weight: 500;
  color: #374151;
}

.form-group input {
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.form-group input:focus {
  outline: none;
  border-color: #2563eb;
}

.form-group input:disabled {
  background: #f9fafb;
  color: #6b7280;
  cursor: not-allowed;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.field-hint {
  margin: 0;
  font-size: 0.875rem;
  color: #6b7280;
}

.activation-card {
  background: linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%);
  border: 2px dashed #d1d5db;
  border-radius: 12px;
  padding: 2rem;
}

.activation-card.active {
  background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
  border: 2px solid #2563eb;
}

.card-content {
  text-align: center;
}

.card-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.card-content h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.5rem;
  font-weight: 700;
  color: #1a1a1a;
}

.card-content > p {
  color: #6b7280;
  margin: 0 0 1.5rem 0;
}

.benefits-list {
  list-style: none;
  padding: 0;
  margin: 0 0 1.5rem 0;
  text-align: left;
}

.benefits-list li {
  padding: 0.5rem 0;
  color: #374151;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.benefits-list li::before {
  content: '✓';
  color: #2563eb;
  font-weight: bold;
}

.btn-primary,
.btn-activate {
  padding: 0.75rem 1.5rem;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
  display: inline-block;
}

.btn-primary:hover:not(:disabled),
.btn-activate:hover:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
}

.btn-primary:disabled,
.btn-activate:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  padding: 0.75rem 1.5rem;
  background: white;
  color: #6b7280;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary:hover:not(:disabled) {
  border-color: #9ca3af;
  color: #374151;
}

.btn-secondary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.active-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1.5rem;
}

.status-badge {
  display: inline-block;
  padding: 0.5rem 1rem;
  background: #f3f4f6;
  color: #6b7280;
  border-radius: 8px;
  font-weight: 600;
}

.status-badge.active {
  background: #d1fae5;
  color: #065f46;
}

.message {
  padding: 1rem;
  border-radius: 8px;
  background: #fee2e2;
  color: #991b1b;
  text-align: center;
}

.message.success {
  background: #d1fae5;
  color: #065f46;
}

@media (max-width: 768px) {
  .pro-settings {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .active-actions {
    flex-direction: column;
  }
}
</style>
