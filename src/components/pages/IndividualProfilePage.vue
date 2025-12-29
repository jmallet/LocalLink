<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import IndividualDashboardLayout from '../dashboard/IndividualDashboardLayout.vue'

interface Individual {
  id: string
  email: string
  first_name: string
  last_name: string
  phone: string | null
  city: string | null
  postal_code: string | null
}

const individual = ref<Individual | null>(null)
const loading = ref(true)
const saving = ref(false)
const message = ref('')
const error = ref('')

const formData = ref({
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  city: '',
  postalCode: ''
})

onMounted(async () => {
  await loadProfile()
})

async function loadProfile() {
  loading.value = true
  try {
    const { data, error: fetchError } = await supabase
      .from('individuals')
      .select('*')
      .eq('user_id', user.value?.id)
      .maybeSingle()

    if (fetchError) throw fetchError

    if (data) {
      individual.value = data
      formData.value = {
        firstName: data.first_name,
        lastName: data.last_name,
        email: data.email,
        phone: data.phone || '',
        city: data.city || '',
        postalCode: data.postal_code || ''
      }
    }
  } catch (err) {
    console.error('Error loading profile:', err)
    error.value = 'Erreur lors du chargement du profil'
  } finally {
    loading.value = false
  }
}

async function handleSave() {
  error.value = ''
  message.value = ''
  saving.value = true

  try {
    if (!individual.value?.id) {
      throw new Error('Profil non trouvé')
    }

    const { error: updateError } = await supabase
      .from('individuals')
      .update({
        first_name: formData.value.firstName,
        last_name: formData.value.lastName,
        email: formData.value.email,
        phone: formData.value.phone || null,
        city: formData.value.city || null,
        postal_code: formData.value.postalCode || null
      })
      .eq('id', individual.value.id)

    if (updateError) throw updateError

    message.value = 'Profil mis à jour avec succès'
    await loadProfile()
  } catch (err) {
    console.error('Error saving profile:', err)
    error.value = 'Erreur lors de la sauvegarde du profil'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <IndividualDashboardLayout>
    <div class="profile-page">
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else class="profile-content">
        <div class="profile-header">
          <h2>Mon profil</h2>
          <p>Gérez vos informations personnelles</p>
        </div>

        <div v-if="message" class="message success">{{ message }}</div>
        <div v-if="error" class="message error">{{ error }}</div>

        <form @submit.prevent="handleSave" class="profile-form">
          <div class="form-section">
            <h3>Informations personnelles</h3>

            <div class="form-row">
              <div class="form-group">
                <label for="firstName">Prénom *</label>
                <input
                  id="firstName"
                  v-model="formData.firstName"
                  type="text"
                  required
                  placeholder="Votre prénom"
                />
              </div>

              <div class="form-group">
                <label for="lastName">Nom *</label>
                <input
                  id="lastName"
                  v-model="formData.lastName"
                  type="text"
                  required
                  placeholder="Votre nom"
                />
              </div>
            </div>

            <div class="form-group">
              <label for="email">Email *</label>
              <input
                id="email"
                v-model="formData.email"
                type="email"
                required
                placeholder="votre@email.fr"
              />
            </div>

            <div class="form-group">
              <label for="phone">Téléphone</label>
              <input
                id="phone"
                v-model="formData.phone"
                type="tel"
                placeholder="06 12 34 56 78"
              />
            </div>
          </div>

          <div class="form-section">
            <h3>Localisation</h3>

            <div class="form-row">
              <div class="form-group">
                <label for="city">Ville</label>
                <input
                  id="city"
                  v-model="formData.city"
                  type="text"
                  placeholder="Votre ville"
                />
              </div>

              <div class="form-group">
                <label for="postalCode">Code postal</label>
                <input
                  id="postalCode"
                  v-model="formData.postalCode"
                  type="text"
                  placeholder="75001"
                />
              </div>
            </div>
          </div>

          <div class="form-actions">
            <button type="submit" class="btn-primary" :disabled="saving">
              {{ saving ? 'Enregistrement...' : 'Enregistrer les modifications' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </IndividualDashboardLayout>
</template>

<style scoped>
.profile-page {
  max-width: 900px;
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
  border-top-color: #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.profile-content {
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.profile-header {
  padding: 32px;
  border-bottom: 1px solid #e5e7eb;
}

.profile-header h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.profile-header p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.message {
  margin: 24px 32px;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
}

.message.success {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #6ee7b7;
}

.message.error {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fca5a5;
}

.profile-form {
  padding: 32px;
}

.form-section {
  margin-bottom: 32px;
}

.form-section h3 {
  font-size: 18px;
  font-weight: 600;
  color: #111827;
  margin: 0 0 20px 0;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  margin-bottom: 6px;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 15px;
  transition: all 0.2s;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}

.form-actions {
  display: flex;
  gap: 12px;
  padding-top: 24px;
  border-top: 1px solid #e5e7eb;
}

.btn-primary {
  padding: 12px 24px;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(-1px);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }

  .profile-header,
  .profile-form {
    padding: 24px;
  }
}
</style>
