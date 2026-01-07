<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { supabase } from '../../lib/supabase'
import { companies, currentCompany, setCurrentCompany, loadCompanies } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { ProducerProfile } from '../../types/database'

const loading = ref(true)
const saving = ref(false)
const message = ref('')
const producerProfile = ref<ProducerProfile | null>(null)

const formData = ref({
  name: '',
  description: '',
  phone: '',
  website: '',
  address: '',
  postal_code: '',
  city: '',
  accept_quotes: true,
})

const producerFormData = ref({
  is_active: false,
  intervention_radius_km: 50,
  delivery_available: false,
  minimum_order_amount: null as number | null,
})

onMounted(async () => {
  await loadCompanies()
  await loadData()
})

watch(currentCompany, async () => {
  await loadData()
})

async function loadData() {
  if (!currentCompany.value) return

  loading.value = true
  try {
    formData.value = {
      name: currentCompany.value.name || '',
      description: currentCompany.value.description || '',
      phone: currentCompany.value.phone || '',
      website: currentCompany.value.website || '',
      address: currentCompany.value.address || '',
      postal_code: currentCompany.value.postal_code || '',
      city: currentCompany.value.city || '',
      accept_quotes: true,
    }

    const { data: profile } = await supabase
      .from('producer_profiles')
      .select('*')
      .eq('company_id', currentCompany.value.id)
      .maybeSingle()

    if (profile) {
      producerProfile.value = profile
      producerFormData.value = {
        is_active: profile.is_active,
        intervention_radius_km: profile.intervention_radius_km || 50,
        delivery_available: profile.delivery_available,
        minimum_order_amount: profile.minimum_order_amount,
      }
    }
  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

async function saveChanges() {
  if (!currentCompany.value) return

  saving.value = true
  message.value = ''

  try {
    const { error: companyError } = await supabase
      .from('companies')
      .update({
        name: formData.value.name,
        description: formData.value.description,
        phone: formData.value.phone,
        website: formData.value.website,
        address: formData.value.address,
        postal_code: formData.value.postal_code,
        city: formData.value.city,
      })
      .eq('id', currentCompany.value.id)

    if (companyError) throw companyError

    if (producerProfile.value) {
      const { error: profileError } = await supabase
        .from('producer_profiles')
        .update({
          is_active: producerFormData.value.is_active,
          intervention_radius_km: producerFormData.value.intervention_radius_km,
          delivery_available: producerFormData.value.delivery_available,
          minimum_order_amount: producerFormData.value.minimum_order_amount,
        })
        .eq('id', producerProfile.value.id)

      if (profileError) throw profileError
    }

    await loadCompanies()
    message.value = 'Modifications enregistrées avec succès'
  } catch (error: any) {
    console.error('Error saving changes:', error)
    message.value = 'Erreur lors de l\'enregistrement'
  } finally {
    saving.value = false
  }
}

function handleCompanyChange(event: Event) {
  const target = event.target as HTMLSelectElement
  setCurrentCompany(target.value)
}
</script>

<template>
  <DashboardLayout>
    <div class="pro-company-profile">
      <div class="page-header">
        <h1>Ma fiche entreprise</h1>
        <p class="subtitle">Gérez les informations de votre entreprise</p>
      </div>

      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else class="content">
        <div v-if="companies.length > 1" class="company-selector">
          <label for="company-select">Entreprise :</label>
          <select
            id="company-select"
            :value="currentCompany?.id"
            @change="handleCompanyChange"
          >
            <option v-for="company in companies" :key="company.id" :value="company.id">
              {{ company.name }}
            </option>
          </select>
        </div>

        <form @submit.prevent="saveChanges" class="profile-form">
          <section class="form-section">
            <h2>Informations générales</h2>

            <div class="form-group">
              <label for="name">Nom de l'entreprise *</label>
              <input
                id="name"
                v-model="formData.name"
                type="text"
                required
              />
            </div>

            <div class="form-group">
              <label for="description">Description</label>
              <textarea
                id="description"
                v-model="formData.description"
                rows="4"
                placeholder="Décrivez votre entreprise, vos services..."
              ></textarea>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="phone">Téléphone</label>
                <input
                  id="phone"
                  v-model="formData.phone"
                  type="tel"
                />
              </div>

              <div class="form-group">
                <label for="website">Site web</label>
                <input
                  id="website"
                  v-model="formData.website"
                  type="url"
                  placeholder="https://"
                />
              </div>
            </div>
          </section>

          <section class="form-section">
            <h2>Adresse</h2>

            <div class="form-group">
              <label for="address">Adresse</label>
              <input
                id="address"
                v-model="formData.address"
                type="text"
              />
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="postal_code">Code postal</label>
                <input
                  id="postal_code"
                  v-model="formData.postal_code"
                  type="text"
                />
              </div>

              <div class="form-group">
                <label for="city">Ville</label>
                <input
                  id="city"
                  v-model="formData.city"
                  type="text"
                />
              </div>
            </div>
          </section>

          <section v-if="producerProfile" class="form-section producer-section">
            <h2>Configuration producteur</h2>

            <div class="form-group">
              <label class="checkbox-label">
                <input
                  v-model="producerFormData.is_active"
                  type="checkbox"
                />
                <span>Profil producteur actif</span>
              </label>
              <p class="field-hint">Activez cette option pour recevoir des demandes de devis</p>
            </div>

            <div class="form-group">
              <label for="radius">Rayon d'intervention (km)</label>
              <input
                id="radius"
                v-model.number="producerFormData.intervention_radius_km"
                type="number"
                min="0"
              />
            </div>

            <div class="form-group">
              <label class="checkbox-label">
                <input
                  v-model="producerFormData.delivery_available"
                  type="checkbox"
                />
                <span>Livraison disponible</span>
              </label>
            </div>

            <div class="form-group">
              <label for="minimum_order">Montant minimum de commande</label>
              <input
                id="minimum_order"
                v-model.number="producerFormData.minimum_order_amount"
                type="number"
                min="0"
                step="0.01"
                placeholder="0.00"
              />
            </div>
          </section>

          <section class="form-section">
            <h2>Demandes de devis</h2>

            <div class="form-group">
              <label class="checkbox-label">
                <input
                  v-model="formData.accept_quotes"
                  type="checkbox"
                />
                <span>Accepter les demandes de devis</span>
              </label>
              <p class="field-hint">Les clients pourront vous envoyer des demandes de devis</p>
            </div>
          </section>

          <div v-if="message" class="message" :class="{ success: message.includes('succès') }">
            {{ message }}
          </div>

          <div class="form-actions">
            <button type="submit" class="btn-primary" :disabled="saving">
              {{ saving ? 'Enregistrement...' : 'Enregistrer les modifications' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.pro-company-profile {
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

.company-selector {
  background: white;
  padding: 1.5rem;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  margin-bottom: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.company-selector label {
  font-weight: 600;
  color: #374151;
}

.company-selector select {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 1rem;
}

.profile-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-section {
  background: white;
  padding: 1.5rem;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
}

.form-section h2 {
  margin: 0 0 1.5rem 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1a1a1a;
}

.producer-section {
  border-left: 4px solid #2563eb;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group:last-child {
  margin-bottom: 0;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
}

.form-group input[type="text"],
.form-group input[type="tel"],
.form-group input[type="url"],
.form-group input[type="number"],
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #2563eb;
}

.form-group textarea {
  resize: vertical;
  font-family: inherit;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  cursor: pointer;
  font-weight: 500;
  color: #1a1a1a;
}

.checkbox-label input[type="checkbox"] {
  width: 1.25rem;
  height: 1.25rem;
  cursor: pointer;
}

.field-hint {
  margin: 0.5rem 0 0 0;
  font-size: 0.875rem;
  color: #6b7280;
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

.form-actions {
  display: flex;
  justify-content: flex-end;
  padding-top: 1rem;
}

.btn-primary {
  padding: 0.75rem 1.5rem;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .pro-company-profile {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .company-selector {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
