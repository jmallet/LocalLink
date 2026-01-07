<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import IndividualDashboardLayout from '../dashboard/IndividualDashboardLayout.vue'

const router = useRouter()

const loading = ref(false)
const error = ref('')
const message = ref('')

const formData = ref({
  title: '',
  description: '',
  category: '',
  quantity: '',
  deadline: '',
  budgetRange: '',
  radius: '10',
  city: ''
})

const categories = [
  'Alimentation',
  'Artisanat',
  'Construction',
  'Services',
  'Agriculture',
  'Commerce',
  'Industrie',
  'Autre'
]

const budgetRanges = [
  'Moins de 500€',
  '500€ - 1000€',
  '1000€ - 5000€',
  '5000€ - 10000€',
  'Plus de 10000€',
  'À définir'
]

const radiusOptions = [
  { value: '10', label: '10 km' },
  { value: '25', label: '25 km' },
  { value: '50', label: '50 km' },
  { value: '100', label: '100 km' },
  { value: 'national', label: 'National' }
]

const isFormValid = computed(() => {
  return formData.value.title.trim() !== '' &&
         formData.value.description.trim() !== '' &&
         formData.value.category !== '' &&
         formData.value.city.trim() !== ''
})

async function handleSubmit() {
  if (!isFormValid.value) {
    error.value = 'Veuillez remplir tous les champs obligatoires'
    return
  }

  loading.value = true
  error.value = ''
  message.value = ''

  try {
    if (!user.value?.id) {
      throw new Error('Utilisateur non connecté')
    }

    error.value = 'Cette fonctionnalité nécessite de sélectionner une entreprise cible. Veuillez utiliser la page de recherche de professionnels pour envoyer une demande de devis à une entreprise spécifique.'

  } catch (err) {
    console.error('Error creating quote:', err)
    if (!error.value) {
      error.value = 'Erreur lors de la création de la demande'
    }
  } finally {
    loading.value = false
  }
}

function resetForm() {
  formData.value = {
    title: '',
    description: '',
    category: '',
    quantity: '',
    deadline: '',
    budgetRange: '',
    radius: '10',
    city: ''
  }
  error.value = ''
  message.value = ''
}
</script>

<template>
  <IndividualDashboardLayout>
    <div class="new-quote-page">
      <div class="page-header">
        <h2>Recherche de devis</h2>
        <p>Créez une demande de devis et recevez des propositions de professionnels locaux</p>
      </div>

      <div v-if="message" class="message success">{{ message }}</div>
      <div v-if="error" class="message error">{{ error }}</div>

      <form @submit.prevent="handleSubmit" class="quote-form">
        <div class="form-section">
          <h3>Informations générales</h3>

          <div class="form-group">
            <label for="title">Titre de votre demande *</label>
            <input
              id="title"
              v-model="formData.title"
              type="text"
              required
              placeholder="Ex: Recherche plombier pour rénovation salle de bain"
            />
          </div>

          <div class="form-group">
            <label for="category">Catégorie *</label>
            <select id="category" v-model="formData.category" required>
              <option value="">Sélectionnez une catégorie</option>
              <option v-for="cat in categories" :key="cat" :value="cat">
                {{ cat }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label for="description">Description détaillée *</label>
            <textarea
              id="description"
              v-model="formData.description"
              required
              rows="6"
              placeholder="Décrivez précisément votre besoin, les prestations attendues, le contexte..."
            ></textarea>
            <span class="helper-text">Plus votre description est détaillée, meilleures seront les réponses</span>
          </div>
        </div>

        <div class="form-section">
          <h3>Zone de recherche</h3>

          <div class="form-row">
            <div class="form-group">
              <label for="city">Ville *</label>
              <input
                id="city"
                v-model="formData.city"
                type="text"
                required
                placeholder="Votre ville"
              />
            </div>

            <div class="form-group">
              <label for="radius">Rayon de recherche *</label>
              <select id="radius" v-model="formData.radius" required>
                <option v-for="option in radiusOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
          </div>
        </div>

        <div class="form-section">
          <h3>Détails complémentaires</h3>

          <div class="form-row">
            <div class="form-group">
              <label for="quantity">Quantité / Volume</label>
              <input
                id="quantity"
                v-model="formData.quantity"
                type="text"
                placeholder="Ex: 20m², 5 pièces, 10 unités..."
              />
            </div>

            <div class="form-group">
              <label for="deadline">Date limite souhaitée</label>
              <input
                id="deadline"
                v-model="formData.deadline"
                type="date"
                :min="new Date().toISOString().split('T')[0]"
              />
            </div>
          </div>

          <div class="form-group">
            <label for="budgetRange">Budget estimé</label>
            <select id="budgetRange" v-model="formData.budgetRange">
              <option value="">Sélectionnez un budget</option>
              <option v-for="budget in budgetRanges" :key="budget" :value="budget">
                {{ budget }}
              </option>
            </select>
          </div>
        </div>

        <div class="info-box">
          <span class="info-icon">ℹ️</span>
          <div>
            <strong>Comment ça marche ?</strong>
            <p>
              Votre demande sera envoyée aux professionnels correspondant à votre catégorie dans le rayon choisi.
              Ils pourront consulter votre demande et vous envoyer leurs devis. Vous recevrez une notification
              pour chaque nouvelle réponse.
            </p>
          </div>
        </div>

        <div class="form-actions">
          <button type="button" class="btn-secondary" @click="resetForm" :disabled="loading">
            Réinitialiser
          </button>
          <button type="submit" class="btn-primary" :disabled="loading || !isFormValid">
            {{ loading ? 'Envoi en cours...' : 'Envoyer la demande' }}
          </button>
        </div>
      </form>
    </div>
  </IndividualDashboardLayout>
</template>

<style scoped>
.new-quote-page {
  max-width: 900px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
}

.page-header h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.page-header p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.message {
  margin-bottom: 24px;
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

.quote-form {
  background: white;
  padding: 32px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.form-section {
  margin-bottom: 32px;
  padding-bottom: 32px;
  border-bottom: 1px solid #e5e7eb;
}

.form-section:last-of-type {
  border-bottom: none;
  margin-bottom: 24px;
  padding-bottom: 0;
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

.form-group textarea {
  resize: vertical;
}

.helper-text {
  display: block;
  font-size: 13px;
  color: #6b7280;
  margin-top: 4px;
}

.info-box {
  display: flex;
  gap: 12px;
  padding: 16px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  margin-bottom: 24px;
}

.info-icon {
  font-size: 20px;
  flex-shrink: 0;
}

.info-box strong {
  display: block;
  color: #1e40af;
  margin-bottom: 4px;
  font-size: 14px;
}

.info-box p {
  font-size: 13px;
  color: #1e40af;
  line-height: 1.5;
  margin: 0;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.btn-primary,
.btn-secondary {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #2563eb;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #1d4ed8;
  transform: translateY(-1px);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary {
  background: #f3f4f6;
  color: #374151;
}

.btn-secondary:hover:not(:disabled) {
  background: #e5e7eb;
}

.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .quote-form {
    padding: 24px;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .form-actions {
    flex-direction: column-reverse;
  }

  .btn-primary,
  .btn-secondary {
    width: 100%;
  }
}
</style>
