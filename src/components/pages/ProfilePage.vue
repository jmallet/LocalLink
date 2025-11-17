<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { Company } from '../../types/database'

const company = ref<Company | null>(null)
const loading = ref(true)
const saving = ref(false)
const message = ref({ type: '', text: '' })

const formData = ref({
  company_name: '',
  siret_bce: '',
  address: '',
  postal_code: '',
  city: '',
  country: 'FR',
  phone: '',
  website: '',
  contact_first_name: '',
  contact_last_name: '',
  contact_email: '',
  description: '',
  category: '',
  tags: [] as string[],
  logo_url: '',
  is_producer: false,
  producer_active: false
})

const categories = [
  'Agriculture & Alimentation',
  'Construction & Rénovation',
  'Services aux entreprises',
  'Transport & Logistique',
  'Commerce de détail',
  'Industrie & Fabrication',
  'Artisanat',
  'Autre'
]

const newTag = ref('')

onMounted(async () => {
  await loadProfile()
})

async function loadProfile() {
  loading.value = true
  try {
    const { data } = await supabase
      .from('companies')
      .select('*')
      .eq('user_id', user.value?.id)
      .maybeSingle()

    if (data) {
      company.value = data
      formData.value = {
        company_name: data.company_name,
        siret_bce: data.siret_bce,
        address: data.address,
        postal_code: data.postal_code,
        city: data.city,
        country: data.country,
        phone: data.phone,
        website: data.website || '',
        contact_first_name: data.contact_first_name,
        contact_last_name: data.contact_last_name,
        contact_email: data.contact_email,
        description: data.description || '',
        category: data.category || '',
        tags: data.tags || [],
        logo_url: data.logo_url || '',
        is_producer: data.is_producer,
        producer_active: data.producer_active
      }
    }
  } catch (error) {
    console.error('Error loading profile:', error)
  } finally {
    loading.value = false
  }
}

async function handleSubmit() {
  message.value = { type: '', text: '' }
  saving.value = true

  try {
    if (company.value) {
      const { error } = await supabase
        .from('companies')
        .update({
          company_name: formData.value.company_name,
          address: formData.value.address,
          postal_code: formData.value.postal_code,
          city: formData.value.city,
          phone: formData.value.phone,
          website: formData.value.website,
          contact_first_name: formData.value.contact_first_name,
          contact_last_name: formData.value.contact_last_name,
          contact_email: formData.value.contact_email,
          description: formData.value.description,
          category: formData.value.category,
          tags: formData.value.tags,
          logo_url: formData.value.logo_url,
          is_producer: formData.value.is_producer,
          producer_active: formData.value.producer_active,
          updated_at: new Date().toISOString()
        })
        .eq('id', company.value.id)

      if (error) throw error

      message.value = {
        type: 'success',
        text: 'Profil mis à jour avec succès !'
      }

      await loadProfile()
    } else {
      const { error } = await supabase
        .from('companies')
        .insert({
          user_id: user.value?.id,
          email: user.value?.email,
          ...formData.value
        })

      if (error) throw error

      message.value = {
        type: 'success',
        text: 'Profil créé avec succès !'
      }

      await loadProfile()
    }
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    saving.value = false
  }
}

function addTag() {
  if (newTag.value && !formData.value.tags.includes(newTag.value)) {
    formData.value.tags.push(newTag.value)
    newTag.value = ''
  }
}

function removeTag(index: number) {
  formData.value.tags.splice(index, 1)
}
</script>

<template>
  <DashboardLayout>
    <div class="profile-page">
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else class="profile-content">
        <div v-if="message.text" class="message-banner" :class="message.type">
          {{ message.text }}
        </div>

        <form @submit.prevent="handleSubmit" class="profile-form">
          <section class="form-section">
            <h2 class="section-title">Informations générales</h2>

            <div class="form-row">
              <div class="form-field">
                <label for="company_name" class="form-label">Nom de l'entreprise *</label>
                <input
                  id="company_name"
                  v-model="formData.company_name"
                  type="text"
                  class="form-input"
                  required
                />
              </div>

              <div class="form-field">
                <label for="siret_bce" class="form-label">SIRET / BCE *</label>
                <input
                  id="siret_bce"
                  v-model="formData.siret_bce"
                  type="text"
                  class="form-input"
                  :disabled="!!company"
                  required
                />
              </div>
            </div>

            <div class="form-field">
              <label for="category" class="form-label">Catégorie *</label>
              <select
                id="category"
                v-model="formData.category"
                class="form-select"
                required
              >
                <option value="">Sélectionnez une catégorie</option>
                <option v-for="cat in categories" :key="cat" :value="cat">
                  {{ cat }}
                </option>
              </select>
            </div>

            <div class="form-field">
              <label for="description" class="form-label">Description</label>
              <textarea
                id="description"
                v-model="formData.description"
                class="form-textarea"
                rows="4"
                placeholder="Décrivez votre entreprise, vos spécialités..."
              ></textarea>
            </div>

            <div class="form-field">
              <label class="form-label">Tags</label>
              <div class="tags-input">
                <div class="tags-list">
                  <span v-for="(tag, index) in formData.tags" :key="index" class="tag">
                    {{ tag }}
                    <button type="button" @click="removeTag(index)" class="tag-remove">✕</button>
                  </span>
                </div>
                <div class="add-tag">
                  <input
                    v-model="newTag"
                    type="text"
                    class="form-input"
                    placeholder="Ajouter un tag..."
                    @keypress.enter.prevent="addTag"
                  />
                  <button type="button" @click="addTag" class="btn-add-tag">+</button>
                </div>
              </div>
            </div>

            <div class="form-field">
              <label for="logo_url" class="form-label">URL du logo</label>
              <input
                id="logo_url"
                v-model="formData.logo_url"
                type="url"
                class="form-input"
                placeholder="https://example.com/logo.png"
              />
            </div>
          </section>

          <section class="form-section">
            <h2 class="section-title">Coordonnées</h2>

            <div class="form-field">
              <label for="address" class="form-label">Adresse *</label>
              <input
                id="address"
                v-model="formData.address"
                type="text"
                class="form-input"
                required
              />
            </div>

            <div class="form-row">
              <div class="form-field">
                <label for="postal_code" class="form-label">Code postal *</label>
                <input
                  id="postal_code"
                  v-model="formData.postal_code"
                  type="text"
                  class="form-input"
                  required
                />
              </div>

              <div class="form-field">
                <label for="city" class="form-label">Ville *</label>
                <input
                  id="city"
                  v-model="formData.city"
                  type="text"
                  class="form-input"
                  required
                />
              </div>
            </div>

            <div class="form-row">
              <div class="form-field">
                <label for="phone" class="form-label">Téléphone *</label>
                <input
                  id="phone"
                  v-model="formData.phone"
                  type="tel"
                  class="form-input"
                  required
                />
              </div>

              <div class="form-field">
                <label for="website" class="form-label">Site web</label>
                <input
                  id="website"
                  v-model="formData.website"
                  type="url"
                  class="form-input"
                  placeholder="https://..."
                />
              </div>
            </div>
          </section>

          <section class="form-section">
            <h2 class="section-title">Contact</h2>

            <div class="form-row">
              <div class="form-field">
                <label for="contact_first_name" class="form-label">Prénom *</label>
                <input
                  id="contact_first_name"
                  v-model="formData.contact_first_name"
                  type="text"
                  class="form-input"
                  required
                />
              </div>

              <div class="form-field">
                <label for="contact_last_name" class="form-label">Nom *</label>
                <input
                  id="contact_last_name"
                  v-model="formData.contact_last_name"
                  type="text"
                  class="form-input"
                  required
                />
              </div>
            </div>

            <div class="form-field">
              <label for="contact_email" class="form-label">Email *</label>
              <input
                id="contact_email"
                v-model="formData.contact_email"
                type="email"
                class="form-input"
                required
              />
            </div>
          </section>

          <section class="form-section">
            <h2 class="section-title">Options producteur</h2>

            <div class="form-field-checkbox">
              <input
                id="is_producer"
                v-model="formData.is_producer"
                type="checkbox"
                class="form-checkbox"
              />
              <label for="is_producer" class="checkbox-label">
                Je suis un producteur / fournisseur
              </label>
            </div>

            <div v-if="formData.is_producer" class="form-field-checkbox">
              <input
                id="producer_active"
                v-model="formData.producer_active"
                type="checkbox"
                class="form-checkbox"
              />
              <label for="producer_active" class="checkbox-label">
                Rendre mon profil visible dans l'annuaire
              </label>
            </div>
          </section>

          <div class="form-actions">
            <button type="submit" class="btn-submit" :disabled="saving">
              {{ saving ? 'Enregistrement...' : 'Enregistrer les modifications' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.profile-page {
  max-width: 900px;
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

.message-banner {
  padding: 14px 20px;
  border-radius: 8px;
  margin-bottom: 24px;
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

.profile-form {
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.form-section {
  padding: 32px;
  border-bottom: 1px solid #e5e7eb;
}

.form-section:last-of-type {
  border-bottom: none;
}

.section-title {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 24px 0;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 20px;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 20px;
}

.form-label {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}

.form-input,
.form-select,
.form-textarea {
  padding: 12px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.2s;
}

.form-input:focus,
.form-select:focus,
.form-textarea:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

.form-input:disabled {
  background: #f3f4f6;
  cursor: not-allowed;
}

.form-textarea {
  resize: vertical;
}

.tags-input {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.tags-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag {
  background: #e0f2fe;
  color: #075985;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
}

.tag-remove {
  background: none;
  border: none;
  color: #075985;
  font-size: 14px;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}

.add-tag {
  display: flex;
  gap: 8px;
}

.btn-add-tag {
  padding: 12px 20px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-add-tag:hover {
  background: #047857;
}

.form-field-checkbox {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.form-checkbox {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.checkbox-label {
  font-size: 14px;
  color: #374151;
  cursor: pointer;
}

.form-actions {
  padding: 24px 32px;
  background: #f9fafb;
  display: flex;
  justify-content: flex-end;
}

.btn-submit {
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

.btn-submit:hover:not(:disabled) {
  background: #047857;
  transform: translateY(-1px);
}

.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }

  .form-section {
    padding: 24px 20px;
  }

  .form-actions {
    padding: 20px;
  }

  .btn-submit {
    width: 100%;
  }
}
</style>
