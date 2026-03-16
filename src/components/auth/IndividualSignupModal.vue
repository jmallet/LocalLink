<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { loadProfile } from '../../stores/auth'

const router = useRouter()

const emit = defineEmits<{
  close: []
}>()

const loading = ref(false)
const error = ref('')

const formData = ref({
  email: '',
  password: '',
  confirmPassword: ''
})

async function handleSignup() {
  if (!formData.value.email || !formData.value.password) {
    error.value = 'Veuillez remplir tous les champs'
    return
  }

  if (formData.value.password !== formData.value.confirmPassword) {
    error.value = 'Les mots de passe ne correspondent pas'
    return
  }

  if (formData.value.password.length < 6) {
    error.value = 'Le mot de passe doit contenir au moins 6 caractères'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const { data: emailExists, error: rpcError } = await supabase
      .rpc('check_email_exists', { email_to_check: formData.value.email })

    if (rpcError) throw rpcError

    if (emailExists) {
      error.value = 'Cet email est déjà utilisé. Veuillez vous connecter.'
      return
    }

    const { data: authData, error: signUpError } = await supabase.auth.signUp({
      email: formData.value.email,
      password: formData.value.password
    })

    if (signUpError) throw signUpError
    if (!authData.user) throw new Error('Échec de création du compte')

    const { error: profileError } = await supabase
      .from('profiles')
      .update({ user_type: 'PARTICULIER' })
      .eq('user_id', authData.user.id)

    if (profileError) throw profileError

    await loadProfile()
    router.push({ name: 'individual-new-quote' })
    emit('close')
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de l\'inscription'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-card">
      <button class="close-button" @click="$emit('close')">×</button>

      <div class="modal-header">
        <div class="icon">📝</div>
        <h2>Inscription Particulier</h2>
        <p>Créez votre compte pour déposer une demande de devis</p>
      </div>

      <form @submit.prevent="handleSignup" class="form-container">
        <div class="form-group">
          <label for="email">Email *</label>
          <input
            id="email"
            v-model="formData.email"
            type="email"
            placeholder="votre@email.com"
            :disabled="loading"
            required
          />
        </div>

        <div class="form-group">
          <label for="password">Mot de passe *</label>
          <input
            id="password"
            v-model="formData.password"
            type="password"
            placeholder="Minimum 6 caractères"
            :disabled="loading"
            required
          />
        </div>

        <div class="form-group">
          <label for="confirmPassword">Confirmer le mot de passe *</label>
          <input
            id="confirmPassword"
            v-model="formData.confirmPassword"
            type="password"
            placeholder="Confirmez votre mot de passe"
            :disabled="loading"
            required
          />
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>

        <button
          type="submit"
          class="btn-primary"
          :disabled="loading"
        >
          {{ loading ? 'Création du compte...' : 'Créer mon compte' }}
        </button>
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
  background: rgba(0, 0, 0, 0.75);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
}

.modal-card {
  background: white;
  border-radius: 16px;
  padding: 40px;
  max-width: 480px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  position: relative;
}

.close-button {
  position: absolute;
  top: 16px;
  right: 16px;
  background: none;
  border: none;
  font-size: 32px;
  color: #9ca3af;
  cursor: pointer;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  transition: all 0.2s;
}

.close-button:hover {
  background: #f3f4f6;
  color: #374151;
}

.modal-header {
  text-align: center;
  margin-bottom: 32px;
}

.icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.modal-header h2 {
  font-size: 28px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 12px 0;
}

.modal-header p {
  font-size: 15px;
  color: #6b7280;
  margin: 0;
}

.form-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}

.form-group input {
  padding: 14px 16px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 15px;
  transition: all 0.2s;
  font-family: inherit;
}

.form-group input:focus {
  outline: none;
  border-color: #ea580c;
  box-shadow: 0 0 0 3px rgba(234, 88, 12, 0.1);
}

.form-group input:disabled {
  background: #f9fafb;
  cursor: not-allowed;
}

.error-message {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  border: 1px solid #fca5a5;
}

.btn-primary {
  padding: 14px 32px;
  background: #ea580c;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
  width: 100%;
}

.btn-primary:hover:not(:disabled) {
  background: #c2410c;
  transform: translateY(-1px);
  box-shadow: 0 8px 24px rgba(234, 88, 12, 0.3);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .modal-card {
    padding: 32px 24px;
  }

  .modal-header h2 {
    font-size: 24px;
  }

  .icon {
    font-size: 40px;
  }
}
</style>
