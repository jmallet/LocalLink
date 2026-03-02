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
  location: '',
  urgency: 'FLEXIBLE' as 'URGENT_48H' | 'THIS_WEEK' | 'FLEXIBLE'
})

const urgencyOptions = [
  { value: 'URGENT_48H', label: 'Urgent (48h)', icon: '🔥' },
  { value: 'THIS_WEEK', label: 'Cette semaine', icon: '⚡' },
  { value: 'FLEXIBLE', label: 'Flexible', icon: '📅' }
]

const isFormValid = computed(() => {
  return formData.value.title.trim() !== '' &&
         formData.value.description.trim() !== '' &&
         formData.value.location.trim() !== ''
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
    location: '',
    urgency: 'FLEXIBLE'
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
        <div class="form-group">
          <label for="title">Titre de la demande *</label>
          <input
            id="title"
            v-model="formData.title"
            type="text"
            required
            placeholder="Ex: Fuite sous évier cuisine"
            maxlength="100"
          />
        </div>

        <div class="form-group">
          <label for="description">Description *</label>
          <textarea
            id="description"
            v-model="formData.description"
            required
            rows="6"
            placeholder="Décrivez votre besoin..."
          ></textarea>
        </div>

        <div class="form-group">
          <label for="location">Ville / Code postal *</label>
          <input
            id="location"
            v-model="formData.location"
            type="text"
            required
            placeholder="Ex: Rennes ou 35000"
          />
        </div>

        <div class="form-group">
          <label>Délai souhaité *</label>
          <div class="urgency-options">
            <label
              v-for="option in urgencyOptions"
              :key="option.value"
              class="urgency-option"
              :class="{ active: formData.urgency === option.value }"
            >
              <input
                type="radio"
                name="urgency"
                :value="option.value"
                v-model="formData.urgency"
              />
              <span class="urgency-icon">{{ option.icon }}</span>
              <span class="urgency-label">{{ option.label }}</span>
            </label>
          </div>
        </div>

        <div class="info-box">
          <span class="info-icon">💡</span>
          <div>
            <strong>Conseil</strong>
            <p>
              Plus votre description est précise, plus les professionnels pourront vous proposer
              des devis adaptés rapidement.
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

.urgency-options {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.urgency-option {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
}

.urgency-option:hover {
  border-color: #2563eb;
  background: #f0f7ff;
}

.urgency-option.active {
  border-color: #2563eb;
  background: #eff6ff;
}

.urgency-option input[type="radio"] {
  position: absolute;
  opacity: 0;
  pointer-events: none;
}

.urgency-icon {
  font-size: 32px;
}

.urgency-label {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  text-align: center;
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

  .urgency-options {
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
