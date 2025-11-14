<script setup lang="ts">
import { ref } from 'vue'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const currentStep = ref(1)
const formData = ref({
  email: '',
  password: '',
  confirmPassword: '',
  companyName: '',
  siret: '',
  address: '',
  postalCode: '',
  city: '',
  country: 'FR',
  phone: '',
  website: '',
  contactFirstName: '',
  contactLastName: '',
  contactEmail: '',
  contactPhone: '',
  activityBuyer: false,
  activityProducer: false,
  acceptTerms: false,
  certifyLegal: false,
  captcha: false,
})

const passwordsMatch = ref(true)
const activitySelected = ref(false)

const validateStep = (step: number): boolean => {
  switch (step) {
    case 1:
      if (!formData.value.email || !formData.value.password || !formData.value.confirmPassword) {
        return false
      }
      if (formData.value.password !== formData.value.confirmPassword) {
        passwordsMatch.value = false
        return false
      }
      passwordsMatch.value = true
      return true
    case 2:
      if (!formData.value.companyName || !formData.value.address || !formData.value.postalCode || !formData.value.city) {
        return false
      }
      if (formData.value.country === 'FR' && !formData.value.siret) {
        return false
      }
      return true
    case 3:
      if (!formData.value.contactFirstName || !formData.value.contactLastName) {
        return false
      }
      return true
    case 4:
      if (!formData.value.activityBuyer && !formData.value.activityProducer) {
        activitySelected.value = false
        return false
      }
      activitySelected.value = true
      return true
    case 5:
      return formData.value.captcha && formData.value.acceptTerms && formData.value.certifyLegal
    default:
      return true
  }
}

const nextStep = () => {
  if (validateStep(currentStep.value)) {
    if (currentStep.value < 5) {
      currentStep.value++
    }
  }
}

const prevStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

const handleSubmit = () => {
  if (validateStep(5)) {
    console.log('Form submitted:', formData.value)
  }
}

const syncContactEmail = () => {
  if (currentStep.value === 3) {
    formData.value.contactEmail = formData.value.email
  }
}

const isSiretRequired = () => {
  return formData.value.country === 'FR'
}

const getCountryLabel = () => {
  return formData.value.country === 'FR' ? 'Numéro SIRET' : 'Numéro BCE'
}
</script>

<template>
  <div class="modal-overlay" @click="emit('close')">
    <div class="modal-content" @click.stop>
      <button class="close-btn" @click="emit('close')">✕</button>

      <div class="modal-header">
        <h2 class="modal-title">Créer un compte professionnel</h2>
        <p class="modal-subtitle">Rejoignez LocalLink et connectez-vous avec des professionnels locaux</p>
      </div>

      <div class="progress-bar">
        <div class="progress-track">
          <div class="progress-fill" :style="{ width: `${(currentStep - 1) * 25}%` }"></div>
        </div>
        <div class="progress-steps">
          <div v-for="step in 5" :key="step" :class="['step', { active: currentStep >= step }]">
            {{ step }}
          </div>
        </div>
      </div>

      <div class="form-content">
        <!-- Step 1: Account Information -->
        <div v-if="currentStep === 1" class="form-section">
          <div class="section-header">
            <h3 class="section-title">🔐 Informations du compte</h3>
          </div>

          <form class="form-group">
            <div class="form-field">
              <label for="email" class="form-label">Email professionnel</label>
              <input
                id="email"
                v-model="formData.email"
                type="email"
                class="form-input"
                placeholder="contact@entreprise.fr"
                required
              />
            </div>

            <div class="form-field">
              <label for="password" class="form-label">Mot de passe</label>
              <input
                id="password"
                v-model="formData.password"
                type="password"
                class="form-input"
                placeholder="Minimum 8 caractères"
                required
              />
            </div>

            <div class="form-field">
              <label for="confirmPassword" class="form-label">Confirmation du mot de passe</label>
              <input
                id="confirmPassword"
                v-model="formData.confirmPassword"
                type="password"
                class="form-input"
                placeholder="Confirmez votre mot de passe"
                required
                :class="{ 'input-error': !passwordsMatch && formData.confirmPassword }"
              />
              <p v-if="!passwordsMatch && formData.confirmPassword" class="error-message">
                Les mots de passe ne correspondent pas
              </p>
            </div>
          </form>
        </div>

        <!-- Step 2: Company Information -->
        <div v-if="currentStep === 2" class="form-section">
          <div class="section-header">
            <h3 class="section-title">🏢 Informations sur l'entreprise</h3>
          </div>

          <form class="form-group">
            <div class="form-field">
              <label for="companyName" class="form-label">Nom de l'entreprise</label>
              <input
                id="companyName"
                v-model="formData.companyName"
                type="text"
                class="form-input"
                placeholder="Votre entreprise"
                required
              />
            </div>

            <div class="form-row">
              <div class="form-field">
                <label for="country" class="form-label">Pays</label>
                <select id="country" v-model="formData.country" class="form-input">
                  <option value="FR">France</option>
                  <option value="BE">Belgique</option>
                </select>
              </div>

              <div class="form-field">
                <label :for="isSiretRequired() ? 'siret' : 'bce'" class="form-label">
                  {{ getCountryLabel() }}
                  <span class="required">*</span>
                </label>
                <input
                  :id="isSiretRequired() ? 'siret' : 'bce'"
                  v-model="formData.siret"
                  type="text"
                  class="form-input"
                  :placeholder="isSiretRequired() ? 'Ex: 12345678901234' : 'Ex: 0123456789'"
                />
              </div>
            </div>

            <div class="form-field">
              <label for="address" class="form-label">Adresse du siège</label>
              <input
                id="address"
                v-model="formData.address"
                type="text"
                class="form-input"
                placeholder="Rue, avenue, boulevard..."
                required
              />
            </div>

            <div class="form-row">
              <div class="form-field">
                <label for="postalCode" class="form-label">Code postal</label>
                <input
                  id="postalCode"
                  v-model="formData.postalCode"
                  type="text"
                  class="form-input"
                  placeholder="Code postal"
                  required
                />
              </div>

              <div class="form-field">
                <label for="city" class="form-label">Ville</label>
                <input
                  id="city"
                  v-model="formData.city"
                  type="text"
                  class="form-input"
                  placeholder="Ville"
                  required
                />
              </div>
            </div>

            <div class="form-field">
              <label for="phone" class="form-label">Téléphone professionnel</label>
              <input
                id="phone"
                v-model="formData.phone"
                type="tel"
                class="form-input"
                placeholder="+33 1 23 45 67 89"
                required
              />
            </div>

            <div class="form-field">
              <label for="website" class="form-label">Site web (optionnel)</label>
              <input
                id="website"
                v-model="formData.website"
                type="url"
                class="form-input"
                placeholder="https://www.exemple.fr"
              />
            </div>
          </form>
        </div>

        <!-- Step 3: Contact Person -->
        <div v-if="currentStep === 3" class="form-section">
          <div class="section-header">
            <h3 class="section-title">👤 Personne de contact</h3>
          </div>

          <form class="form-group">
            <div class="form-row">
              <div class="form-field">
                <label for="contactFirstName" class="form-label">Prénom</label>
                <input
                  id="contactFirstName"
                  v-model="formData.contactFirstName"
                  type="text"
                  class="form-input"
                  placeholder="Jean"
                  required
                />
              </div>

              <div class="form-field">
                <label for="contactLastName" class="form-label">Nom</label>
                <input
                  id="contactLastName"
                  v-model="formData.contactLastName"
                  type="text"
                  class="form-input"
                  placeholder="Dupont"
                  required
                />
              </div>
            </div>

            <div class="form-field">
              <label for="contactEmail" class="form-label">Email pro du contact</label>
              <div class="input-with-action">
                <input
                  id="contactEmail"
                  v-model="formData.contactEmail"
                  type="email"
                  class="form-input"
                  placeholder="contact@entreprise.fr"
                />
                <button type="button" class="sync-btn" @click="syncContactEmail" title="Utiliser l'email du compte">
                  🔄
                </button>
              </div>
              <p class="helper-text">Cliquez sur 🔄 pour utiliser l'email du compte</p>
            </div>

            <div class="form-field">
              <label for="contactPhone" class="form-label">Téléphone direct (optionnel)</label>
              <input
                id="contactPhone"
                v-model="formData.contactPhone"
                type="tel"
                class="form-input"
                placeholder="+33 6 12 34 56 78"
              />
            </div>
          </form>
        </div>

        <!-- Step 4: Activity Type -->
        <div v-if="currentStep === 4" class="form-section">
          <div class="section-header">
            <h3 class="section-title">📌 Type d'activité</h3>
            <p class="section-subtitle">Votre entreprise souhaite :</p>
          </div>

          <div class="checkboxes-group">
            <label class="checkbox-item">
              <input
                v-model="formData.activityBuyer"
                type="checkbox"
                class="checkbox-input"
              />
              <span class="checkbox-label">
                <span class="checkbox-icon">🛒</span>
                <span class="checkbox-text">Chercher des producteurs</span>
              </span>
            </label>

            <label class="checkbox-item">
              <input
                v-model="formData.activityProducer"
                type="checkbox"
                class="checkbox-input"
              />
              <span class="checkbox-label">
                <span class="checkbox-icon">🌱</span>
                <span class="checkbox-text">Présenter ses propres produits (devenir producteur)</span>
              </span>
            </label>
          </div>

          <p v-if="!activitySelected && formData.activityBuyer === false && formData.activityProducer === false" class="error-message">
            Veuillez sélectionner au moins une activité
          </p>
        </div>

        <!-- Step 5: Verification -->
        <div v-if="currentStep === 5" class="form-section">
          <div class="section-header">
            <h3 class="section-title">🔐 Vérification</h3>
          </div>

          <div class="verification-group">
            <div class="captcha-placeholder">
              <label class="checkbox-item">
                <input
                  v-model="formData.captcha"
                  type="checkbox"
                  class="checkbox-input"
                />
                <span class="checkbox-label">
                  <span class="checkbox-text">Je suis un humain</span>
                </span>
              </label>
              <p class="helper-text">Captcha reCAPTCHA v3</p>
            </div>

            <label class="checkbox-item">
              <input
                v-model="formData.acceptTerms"
                type="checkbox"
                class="checkbox-input"
              />
              <span class="checkbox-label">
                <span class="checkbox-text">
                  J'accepte les <a href="#" class="link">CGU</a> et la <a href="#" class="link">politique de confidentialité</a>
                </span>
              </span>
            </label>

            <label class="checkbox-item">
              <input
                v-model="formData.certifyLegal"
                type="checkbox"
                class="checkbox-input"
              />
              <span class="checkbox-label">
                <span class="checkbox-text">
                  Je certifie être une entreprise légalement enregistrée
                </span>
              </span>
            </label>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button v-if="currentStep > 1" class="btn-secondary" @click="prevStep">
          ← Précédent
        </button>
        <button
          v-if="currentStep < 5"
          class="btn-primary"
          @click="nextStep"
        >
          Suivant →
        </button>
        <button
          v-if="currentStep === 5"
          class="btn-primary"
          @click="handleSubmit"
        >
          Créer mon compte
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
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
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  position: relative;
}

.close-btn {
  position: absolute;
  top: 16px;
  right: 16px;
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

.modal-header {
  padding: 32px 32px 0;
  border-bottom: 1px solid #e5e7eb;
}

.modal-title {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.modal-subtitle {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.progress-bar {
  padding: 24px 32px;
  border-bottom: 1px solid #e5e7eb;
}

.progress-track {
  height: 4px;
  background: #e5e7eb;
  border-radius: 2px;
  margin-bottom: 16px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: #059669;
  transition: width 0.3s ease;
}

.progress-steps {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}

.step {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #f3f4f6;
  border: 2px solid #d1d5db;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 14px;
  color: #6b7280;
  transition: all 0.3s;
}

.step.active {
  background: #059669;
  border-color: #059669;
  color: white;
}

.form-content {
  padding: 32px;
  min-height: 300px;
}

.form-section {
  animation: fadeIn 0.3s ease;
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

.section-header {
  margin-bottom: 24px;
}

.section-title {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.section-subtitle {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}

.required {
  color: #ef4444;
}

.form-input,
select {
  padding: 12px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.2s;
}

.form-input:focus,
select:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

.form-input.input-error {
  border-color: #ef4444;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
}

.error-message {
  font-size: 13px;
  color: #ef4444;
  margin: 0;
}

.helper-text {
  font-size: 12px;
  color: #9ca3af;
  margin: 0;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.input-with-action {
  display: flex;
  gap: 8px;
}

.input-with-action .form-input {
  flex: 1;
}

.sync-btn {
  padding: 12px 14px;
  background: #f3f4f6;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.2s;
}

.sync-btn:hover {
  background: #e5e7eb;
}

.checkboxes-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.checkbox-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  cursor: pointer;
  padding: 12px;
  border-radius: 8px;
  transition: background 0.2s;
}

.checkbox-item:hover {
  background: #f3f4f6;
}

.checkbox-input {
  width: 20px;
  height: 20px;
  margin-top: 2px;
  cursor: pointer;
  accent-color: #059669;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.checkbox-icon {
  font-size: 20px;
}

.checkbox-text {
  font-size: 14px;
  color: #374151;
  line-height: 1.5;
}

.link {
  color: #059669;
  text-decoration: none;
  font-weight: 600;
}

.link:hover {
  text-decoration: underline;
}

.verification-group {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.captcha-placeholder {
  padding: 16px;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}

.modal-footer {
  display: flex;
  gap: 12px;
  padding: 24px 32px;
  border-top: 1px solid #e5e7eb;
  background: #f9fafb;
}

.btn-primary,
.btn-secondary {
  flex: 1;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #059669;
  color: white;
}

.btn-primary:hover {
  background: #047857;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);
}

.btn-secondary {
  background: white;
  color: #374151;
  border: 1px solid #d1d5db;
}

.btn-secondary:hover {
  background: #f3f4f6;
  border-color: #9ca3af;
}

@media (max-width: 640px) {
  .modal-content {
    max-height: 100vh;
    border-radius: 0;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .modal-header {
    padding: 20px 16px 0;
  }

  .modal-title {
    font-size: 22px;
  }

  .form-content {
    padding: 20px 16px;
  }

  .modal-footer {
    padding: 16px;
    flex-direction: column;
  }

  .close-btn {
    top: 12px;
    right: 12px;
  }
}
</style>
