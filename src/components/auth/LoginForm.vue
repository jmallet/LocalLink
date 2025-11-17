<script setup lang="ts">
import { ref } from 'vue'
import { signIn, signUp } from '../../stores/auth'
import { navigateTo } from '../../router'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const isSignup = ref(false)
const loading = ref(false)
const error = ref('')

const formData = ref({
  email: '',
  password: '',
  confirmPassword: ''
})

const handleSubmit = async () => {
  error.value = ''
  loading.value = true

  try {
    if (isSignup.value) {
      if (formData.value.password !== formData.value.confirmPassword) {
        error.value = 'Les mots de passe ne correspondent pas'
        return
      }

      const { error: signUpError } = await signUp(formData.value.email, formData.value.password)
      if (signUpError) throw signUpError

      navigateTo({ name: 'dashboard' })
      emit('close')
    } else {
      const { error: signInError } = await signIn(formData.value.email, formData.value.password)
      if (signInError) throw signInError

      navigateTo({ name: 'dashboard' })
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
  error.value = ''
}
</script>

<template>
  <div class="modal-overlay" @click="emit('close')">
    <div class="modal-content" @click.stop>
      <button class="close-btn" @click="emit('close')">✕</button>

      <div class="modal-header">
        <h2 class="modal-title">{{ isSignup ? 'Créer un compte' : 'Connexion' }}</h2>
        <p class="modal-subtitle">
          {{ isSignup ? 'Rejoignez LocalLink et connectez-vous avec des professionnels locaux' : 'Connectez-vous à votre compte' }}
        </p>
      </div>

      <form @submit.prevent="handleSubmit" class="form">
        <div v-if="error" class="error-banner">
          {{ error }}
        </div>

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

        <div v-if="isSignup" class="form-field">
          <label for="confirmPassword" class="form-label">Confirmer le mot de passe</label>
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
</style>
