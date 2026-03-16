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
const currentStep = ref(1)

const formData = ref({
  category: '',
  title: '',
  description: '',
  budget: '',
  deadline: '',
  location: '',
  contact: ''
})

const categories = [
  'Rénovation / Maçonnerie',
  'Plomberie',
  'Électricité',
  'Peinture / Décoration',
  'Menuiserie',
  'Toiture / Couverture',
  'Jardinage / Paysagisme',
  'Chauffage / Climatisation'
]

const budgetRanges = [
  '500 - 2 000 €',
  '2 000 - 5 000 €',
  '5 000 - 10 000 €',
  '10 000 - 20 000 €',
  'Plus de 20 000 €'
]

const deadlines = [
  'Dans le mois',
  'Dans 2-3 mois',
  'Dans 4-6 mois',
  'Plus de 6 mois'
]

const isStepValid = computed(() => {
  switch (currentStep.value) {
    case 1:
      return formData.value.category !== ''
    case 2:
      return formData.value.title.trim() !== '' &&
             formData.value.description.trim() !== '' &&
             formData.value.budget !== '' &&
             formData.value.deadline !== ''
    case 3:
      return formData.value.location.trim() !== ''
    case 4:
      return formData.value.contact.trim() !== ''
    default:
      return false
  }
})

function nextStep() {
  if (isStepValid.value && currentStep.value < 4) {
    currentStep.value++
    error.value = ''
  }
}

function prevStep() {
  if (currentStep.value > 1) {
    currentStep.value--
    error.value = ''
  }
}

function modifyCategory() {
  currentStep.value = 1
}

async function handleSubmit() {
  if (!isStepValid.value) {
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
</script>

<template>
  <IndividualDashboardLayout>
    <div class="new-quote-page">
      <div class="stepper">
        <div class="step" :class="{ active: currentStep === 1, completed: currentStep > 1 }">
          <div class="step-number">{{ currentStep > 1 ? '✓' : '1' }}</div>
          <div class="step-label">Catégorie</div>
        </div>
        <div class="step-line" :class="{ active: currentStep > 1 }"></div>
        <div class="step" :class="{ active: currentStep === 2, completed: currentStep > 2 }">
          <div class="step-number">{{ currentStep > 2 ? '✓' : '2' }}</div>
          <div class="step-label">Description</div>
        </div>
        <div class="step-line" :class="{ active: currentStep > 2 }"></div>
        <div class="step" :class="{ active: currentStep === 3, completed: currentStep > 3 }">
          <div class="step-number">{{ currentStep > 3 ? '✓' : '3' }}</div>
          <div class="step-label">Localisation</div>
        </div>
        <div class="step-line" :class="{ active: currentStep > 3 }"></div>
        <div class="step" :class="{ active: currentStep === 4 }">
          <div class="step-number">4</div>
          <div class="step-label">Contact</div>
        </div>
      </div>

      <div v-if="message" class="message success">{{ message }}</div>
      <div v-if="error" class="message error">{{ error }}</div>

      <form @submit.prevent="handleSubmit" class="quote-form">
        <div v-if="currentStep === 1" class="step-content">
          <div v-if="formData.category" class="selected-category">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span class="category-label">Catégorie sélectionnée :</span>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14.7 6.3a1 1 0 000 1.4l1.6 1.6a1 1 0 001.4 0l3.77-3.77a6 6 0 01-7.94 7.94l-6.91 6.91a2.12 2.12 0 01-3-3l6.91-6.91a6 6 0 017.94-7.94l-3.76 3.76z"/>
            </svg>
            <strong>{{ formData.category }}</strong>
            <button type="button" class="btn-modify" @click="modifyCategory">Modifier</button>
          </div>
          <div v-else class="category-grid">
            <button
              v-for="category in categories"
              :key="category"
              type="button"
              class="category-card"
              @click="formData.category = category; nextStep()"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14.7 6.3a1 1 0 000 1.4l1.6 1.6a1 1 0 001.4 0l3.77-3.77a6 6 0 01-7.94 7.94l-6.91 6.91a2.12 2.12 0 01-3-3l6.91-6.91a6 6 0 017.94-7.94l-3.76 3.76z"/>
              </svg>
              {{ category }}
            </button>
          </div>
        </div>

        <div v-if="currentStep === 2" class="step-content">
          <div class="step-header">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <path d="M12 16v-4M12 8h.01"/>
            </svg>
            <h2>Décrivez votre besoin</h2>
          </div>

          <div class="form-group">
            <label for="title">Titre de votre demande *</label>
            <input
              id="title"
              v-model="formData.title"
              type="text"
              required
              placeholder="Réfection de la toiture — maison 120m²"
              maxlength="150"
            />
          </div>

          <div class="form-group">
            <label for="description">Description détaillée *</label>
            <textarea
              id="description"
              v-model="formData.description"
              required
              rows="6"
              placeholder="Toiture en tuiles, ~80m², présence de mousse importante. Besoin d'un devis pour nettoyage, traitement hydrofuge et remplacement de 10-15 tuiles cassées. Travaux souhaités courant mai."
            ></textarea>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="budget">Budget estimé</label>
              <select id="budget" v-model="formData.budget">
                <option value="">Sélectionnez</option>
                <option v-for="range in budgetRanges" :key="range" :value="range">{{ range }}</option>
              </select>
            </div>
            <div class="form-group">
              <label for="deadline">Délai souhaité</label>
              <select id="deadline" v-model="formData.deadline">
                <option value="">Sélectionnez</option>
                <option v-for="d in deadlines" :key="d" :value="d">{{ d }}</option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label for="photos">Photos / documents (optionnel)</label>
            <div class="upload-zone">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                <circle cx="8.5" cy="8.5" r="1.5"/>
                <polyline points="21 15 16 10 5 21"/>
              </svg>
              <span>Cliquez ou glissez vos photos ici</span>
            </div>
          </div>
        </div>

        <div v-if="currentStep === 3" class="step-content">
          <div class="step-header">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
              <circle cx="12" cy="10" r="3"/>
            </svg>
            <h2>Où se situe votre projet ?</h2>
          </div>

          <div class="form-group">
            <label for="location">Adresse, ville ou code postal *</label>
            <input
              id="location"
              v-model="formData.location"
              type="text"
              required
              placeholder="Ex: Rennes ou 35000"
            />
          </div>
        </div>

        <div v-if="currentStep === 4" class="step-content">
          <div class="step-header">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
              <circle cx="8.5" cy="7" r="4"/>
              <path d="M20 8v6M23 11h-6"/>
            </svg>
            <h2>Vos coordonnées</h2>
          </div>

          <div class="form-group">
            <label for="contact">Email ou téléphone *</label>
            <input
              id="contact"
              v-model="formData.contact"
              type="text"
              required
              placeholder="votre@email.com ou 06 12 34 56 78"
            />
          </div>
        </div>

        <div class="form-actions">
          <button
            v-if="currentStep > 1"
            type="button"
            class="btn-secondary"
            @click="prevStep"
            :disabled="loading"
          >
            Étape précédente
          </button>
          <button
            v-if="currentStep < 4"
            type="button"
            class="btn-primary"
            @click="nextStep"
            :disabled="!isStepValid"
          >
            Continuer →
          </button>
          <button
            v-if="currentStep === 4"
            type="submit"
            class="btn-primary"
            :disabled="loading || !isStepValid"
          >
            {{ loading ? 'Envoi en cours...' : 'Envoyer la demande' }}
          </button>
        </div>
      </form>
    </div>
  </IndividualDashboardLayout>
</template>

<style scoped>
.new-quote-page {
  max-width: 1200px;
  margin: 0 auto;
}

.stepper {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 48px;
  padding: 24px 0;
}

.step {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  position: relative;
}

.step-number {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: #d1d5db;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 18px;
  transition: all 0.3s;
}

.step.active .step-number {
  background: #1a1d2e;
  transform: scale(1.1);
}

.step.completed .step-number {
  background: #ea580c;
}

.step-label {
  font-size: 14px;
  font-weight: 500;
  color: #9ca3af;
  transition: color 0.3s;
}

.step.active .step-label {
  color: #1a1d2e;
  font-weight: 600;
}

.step-line {
  width: 80px;
  height: 2px;
  background: #e5e7eb;
  margin: 0 -4px;
  transition: background 0.3s;
}

.step-line.active {
  background: #ea580c;
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
  background: #fafafa;
  padding: 40px;
  border-radius: 16px;
  min-height: 450px;
}

.step-content {
  animation: fadeIn 0.3s;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.selected-category {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  margin-bottom: 24px;
}

.selected-category svg:first-child {
  color: #10b981;
  flex-shrink: 0;
}

.selected-category svg:nth-child(3) {
  color: #ea580c;
  flex-shrink: 0;
}

.category-label {
  font-size: 14px;
  color: #6b7280;
}

.selected-category strong {
  color: #ea580c;
  font-weight: 600;
  flex: 1;
}

.btn-modify {
  padding: 6px 16px;
  background: white;
  color: #374151;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-modify:hover {
  background: #f9fafb;
  border-color: #9ca3af;
}

.category-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 16px;
}

.category-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
  text-align: left;
}

.category-card svg {
  color: #ea580c;
  flex-shrink: 0;
}

.category-card:hover {
  border-color: #ea580c;
  background: #fff7ed;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(234, 88, 12, 0.15);
}

.step-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  margin-bottom: 32px;
}

.step-header svg {
  color: #ea580c;
  margin-bottom: 16px;
}

.step-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.form-group {
  margin-bottom: 24px;
}

.form-group label {
  display: block;
  font-size: 15px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 8px;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 14px 16px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 15px;
  transition: all 0.2s;
  font-family: inherit;
  background: white;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #ea580c;
  box-shadow: 0 0 0 3px rgba(234, 88, 12, 0.1);
}

.form-group textarea {
  resize: vertical;
  line-height: 1.6;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.upload-zone {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 48px 20px;
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
}

.upload-zone:hover {
  border-color: #ea580c;
  background: #fff7ed;
}

.upload-zone svg {
  color: #9ca3af;
}

.upload-zone span {
  font-size: 14px;
  color: #6b7280;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: space-between;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #e5e7eb;
}

.btn-primary,
.btn-secondary {
  padding: 14px 32px;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #ea580c;
  color: white;
  margin-left: auto;
}

.btn-primary:hover:not(:disabled) {
  background: #c2410c;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(234, 88, 12, 0.3);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary {
  background: white;
  color: #374151;
  border: 1px solid #d1d5db;
}

.btn-secondary:hover:not(:disabled) {
  background: #f9fafb;
  border-color: #9ca3af;
}

.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .quote-form {
    padding: 24px;
  }

  .stepper {
    padding: 16px 0;
  }

  .step-number {
    width: 40px;
    height: 40px;
    font-size: 16px;
  }

  .step-label {
    font-size: 12px;
  }

  .step-line {
    width: 40px;
  }

  .category-grid {
    grid-template-columns: 1fr;
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
    margin-left: 0;
  }
}
</style>
