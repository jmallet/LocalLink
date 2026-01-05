<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { signIn, signUp } from '../../stores/auth'
import { supabase } from '../../lib/supabase'

const router = useRouter()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'pro-registration'): void
}>()

const isSignup = ref(false)
const signupStep = ref<'type' | 'form'>('type')
const accountType = ref<'individual' | 'company'>('individual')
const loading = ref(false)
const error = ref('')

const formData = ref({
  email: '',
  password: '',
  confirmPassword: '',
  firstName: '',
  lastName: '',
  phone: '',
  city: '',
  postalCode: ''
})

const selectAccountType = (type: 'individual' | 'company') => {
  accountType.value = type
  if (type === 'company') {
    emit('pro-registration')
  } else {
    signupStep.value = 'form'
  }
}

const handleSubmit = async () => {
  error.value = ''
  loading.value = true

  try {
    if (isSignup.value) {
      if (formData.value.password !== formData.value.confirmPassword) {
        error.value = 'Les mots de passe ne correspondent pas'
        return
      }

      const { data, error: signUpError } = await signUp(formData.value.email, formData.value.password)
      if (signUpError) throw signUpError

      if (data.user && accountType.value === 'individual') {
        const { error: profileError } = await supabase
          .from('individuals')
          .insert({
            user_id: data.user.id,
            email: formData.value.email,
            first_name: formData.value.firstName,
            last_name: formData.value.lastName,
            phone: formData.value.phone || null,
            city: formData.value.city || null,
            postal_code: formData.value.postalCode || null
          })

        if (profileError) throw profileError
      }

      router.push({ name: 'dashboard' })
      emit('close')
    } else {
      const { error: signInError } = await signIn(formData.value.email, formData.value.password)
      if (signInError) throw signInError

      router.push({ name: 'dashboard' })
      emit('close')
    }
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue'
  } finally {
    loading.value = false
  }
}

const toggleMode = () => {
  isSignup.value = !isSignup.value
  signupStep.value = 'type'
  error.value = ''
}

const goBack = () => {
  signupStep.value = 'type'
  error.value = ''
}
</script>

<template>
  <div class="modal-overlay" @click="emit('close')">
    <div class="modal-content" @click.stop>
      <button class="close-btn" @click="emit('close')">✕</button>

      <div v-if="isSignup && signupStep === 'type'" class="account-type-selection">
        <div class="modal-header">
          <h2 class="modal-title">Créer un compte</h2>
          <p class="modal-subtitle">Choisissez votre type de compte</p>
        </div>

        <div class="account-types">
          <button type="button" class="account-type-card" @click="selectAccountType('individual')">
            <div class="account-type-icon">👤</div>
            <h3>Particulier</h3>
            <p>Je souhaite faire des demandes de devis</p>
          </button>

          <button type="button" class="account-type-card" @click="selectAccountType('company')">
            <div class="account-type-icon">🏢</div>
            <h3>Entreprise</h3>
            <p>Je souhaite proposer mes services et recevoir des demandes</p>
          </button>
        </div>

        <p class="toggle-text">
          Vous avez déjà un compte ?
          <button type="button" @click="toggleMode" class="toggle-btn">
            Se connecter
          </button>
        </p>
      </div>

      <div v-else>
        <div class="modal-header">
          <button v-if="isSignup && signupStep === 'form'" type="button" class="back-btn" @click="goBack">← Retour</button>
          <h2 class="modal-title">
            {{ isSignup ? (accountType === 'individual' ? 'Inscription Particulier' : 'Inscription Entreprise') : 'Connexion' }}
          </h2>
          <p class="modal-subtitle">
            {{ isSignup ? 'Créez votre compte pour accéder à toutes les fonctionnalités' : 'Connectez-vous à votre compte' }}
          </p>
        </div>

        <form @submit.prevent="handleSubmit" class="form">
          <div v-if="error" class="error-banner">
            {{ error }}
          </div>

          <div v-if="isSignup && accountType === 'individual'">
            <div class="form-row">
              <div class="form-field">
                <label for="firstName" class="form-label">Prénom *</label>
                <input
                  id="firstName"
                  v-model="formData.firstName"
                  type="text"
                  class="form-input"
                  placeholder="Jean"
                  required
                />
              </div>

              <div class="form-field">
                <label for="lastName" class="form-label">Nom *</label>
                <input
                  id="lastName"
                  v-model="formData.lastName"
                  type="text"
                  class="form-input"
                  placeholder="Dupont"
                  required
                />
              </div>
            </div>

            <div class="form-field">
              <label for="phone" class="form-label">Téléphone</label>
              <input
                id="phone"
                v-model="formData.phone"
                type="tel"
                class="form-input"
                placeholder="06 12 34 56 78"
              />
            </div>

            <div class="form-row">
              <div class="form-field">
                <label for="city" class="form-label">Ville</label>
                <input
                  id="city"
                  v-model="formData.city"
                  type="text"
                  class="form-input"
                  placeholder="Paris"
                />
              </div>

              <div class="form-field">
                <label for="postalCode" class="form-label">Code postal</label>
                <input
                  id="postalCode"
                  v-model="formData.postalCode"
                  type="text"
                  class="form-input"
                  placeholder="75001"
                />
              </div>
            </div>
          </div>

          <div class="form-field">
            <label for="email" class="form-label">Email {{ isSignup && accountType === 'company' ? 'professionnel' : '' }} *</label>
            <input
              id="email"
              v-model="formData.email"
              type="email"
              class="form-input"
              :placeholder="accountType === 'company' ? 'contact@entreprise.fr' : 'votre@email.fr'"
              required
            />
          </div>

          <div class="form-field">
            <label for="password" class="form-label">Mot de passe *</label>
            <input
              id="password"
              v-model="formData.password"
              type="password"
              class="form-input"
              placeholder="Minimum 8 caractères"
              required
            />
          </div>

          <div v-if="isSignup" class="form-field">
            <label for="confirmPassword" class="form-label">Confirmer le mot de passe *</label>
            <input
              id="confirmPassword"
              v-model="formData.confirmPassword"
              type="password"
              class="form-input"
              placeholder="Confirmez votre mot de passe"
              required
            />
          </div>

          <button type="submit" class="btn-submit" :disabled="loading">
            {{ loading ? 'Chargement...' : (isSignup ? 'Créer mon compte' : 'Se connecter') }}
          </button>

          <p class="toggle-text">
            {{ isSignup ? 'Vous avez déjà un compte ?' : 'Vous n\'avez pas de compte ?' }}
            <button type="button" @click="toggleMode" class="toggle-btn">
              {{ isSignup ? 'Se connecter' : 'Créer un compte' }}
            </button>
          </p>
        </form>
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
  max-width: 480px;
  position: relative;
  padding: 32px;
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
  margin-bottom: 24px;
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

.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.error-banner {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
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

.form-input {
  padding: 12px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.2s;
}

.form-input:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

.btn-submit {
  padding: 12px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: 8px;
}

.btn-submit:hover:not(:disabled) {
  background: #047857;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);
}

.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.toggle-text {
  text-align: center;
  font-size: 14px;
  color: #6b7280;
  margin-top: 8px;
}

.toggle-btn {
  background: none;
  border: none;
  color: #059669;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
  margin-left: 4px;
}

.toggle-btn:hover {
  text-decoration: underline;
}

.account-types {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 24px;
}

.account-type-card {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 24px;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.account-type-card:hover {
  border-color: #059669;
  background: #f0fdf4;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.2);
}

.account-type-icon {
  font-size: 48px;
  margin-bottom: 8px;
}

.account-type-card h3 {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.account-type-card p {
  font-size: 13px;
  color: #6b7280;
  margin: 0;
  line-height: 1.5;
}

.back-btn {
  background: none;
  border: none;
  color: #059669;
  font-weight: 600;
  cursor: pointer;
  padding: 8px 0;
  margin-bottom: 8px;
  font-size: 14px;
  display: flex;
  align-items: center;
  gap: 4px;
  transition: all 0.2s;
}

.back-btn:hover {
  color: #047857;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

@media (max-width: 640px) {
  .account-types {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
