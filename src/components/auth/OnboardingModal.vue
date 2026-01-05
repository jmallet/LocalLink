<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { loadProfile } from '../../stores/auth'
import type { UserType } from '../../types/database'

const router = useRouter()

const emit = defineEmits<{
  complete: [userType: UserType]
  close: []
}>()

const selectedType = ref<UserType>('PRO')
const step = ref<'account-creation' | 'siret-check' | 'company-confirm' | 'company-form' | 'usage-selection'>('account-creation')
const loading = ref(false)
const error = ref('')

// Account credentials (for PRO)
const accountForm = ref({
  email: '',
  password: '',
  confirmPassword: ''
})

// SIRET verification
const siret = ref('')
const existingCompany = ref<any>(null)
const siretStatus = ref<'not-checked' | 'new' | 'claimed' | 'available'>('not-checked')

// Company form (minimal)
const companyForm = ref({
  name: '',
  city: '',
  postal_code: ''
})

// Usage selection
const usageForm = ref({
  is_acheteur_pro: false,
  is_producteur: false
})

async function proceedToSiret() {
  if (!accountForm.value.email || !accountForm.value.password) {
    error.value = 'Veuillez remplir tous les champs'
    return
  }

  if (accountForm.value.password !== accountForm.value.confirmPassword) {
    error.value = 'Les mots de passe ne correspondent pas'
    return
  }

  if (accountForm.value.password.length < 6) {
    error.value = 'Le mot de passe doit contenir au moins 6 caractères'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const { data: emailExists, error: rpcError } = await supabase
      .rpc('check_email_exists', { email_to_check: accountForm.value.email })

    if (rpcError) throw rpcError

    if (emailExists) {
      error.value = 'Cet email est déjà utilisé. Veuillez vous connecter ou utiliser un autre email.'
      return
    }

    step.value = 'siret-check'
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de la vérification'
  } finally {
    loading.value = false
  }
}

async function checkSiret() {
  if (!siret.value || siret.value.length !== 14) {
    error.value = 'Le SIRET doit contenir 14 chiffres'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const { data, error: queryError } = await supabase
      .from('companies')
      .select('*')
      .eq('siret', siret.value)
      .maybeSingle()

    if (queryError) throw queryError

    if (!data) {
      siretStatus.value = 'new'
      step.value = 'company-form'
    } else if (data.is_claimed) {
      siretStatus.value = 'claimed'
      error.value = 'Cette entreprise est déjà enregistrée sur la plateforme. Veuillez contacter le support à support@localproconnect.fr'
    } else {
      siretStatus.value = 'available'
      existingCompany.value = data
      step.value = 'company-confirm'
    }
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de la vérification'
  } finally {
    loading.value = false
  }
}

function confirmExistingCompany() {
  step.value = 'usage-selection'
}

async function createCompany() {
  if (!companyForm.value.name || !companyForm.value.city) {
    error.value = 'Veuillez remplir tous les champs obligatoires'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const { data: newCompany, error: companyError } = await supabase
      .from('companies')
      .insert({
        name: companyForm.value.name,
        siret: siret.value,
        siren: siret.value.substring(0, 9),
        postal_code: companyForm.value.postal_code,
        city: companyForm.value.city,
        source: 'MANUAL',
        is_claimed: false
      })
      .select()
      .single()

    if (companyError) throw companyError

    existingCompany.value = newCompany
    step.value = 'usage-selection'
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de la création'
  } finally {
    loading.value = false
  }
}

async function finalizeRegistration() {
  if (!existingCompany.value) return

  loading.value = true
  error.value = ''

  try {
    const { data: authData, error: signUpError } = await supabase.auth.signUp({
      email: accountForm.value.email,
      password: accountForm.value.password
    })

    if (signUpError) throw signUpError
    if (!authData.user) throw new Error('Échec de création du compte')

    const { error: profileError } = await supabase
      .from('profiles')
      .update({ user_type: 'PRO' })
      .eq('user_id', authData.user.id)

    if (profileError) throw profileError

    const { error: linkError } = await supabase
      .from('company_users')
      .insert({
        user_id: authData.user.id,
        company_id: existingCompany.value.id,
        is_acheteur_pro: usageForm.value.is_acheteur_pro || false,
        is_producteur: usageForm.value.is_producteur || false,
        verified: true,
        verified_at: new Date().toISOString()
      })

    if (linkError) throw linkError

    const { error: claimError } = await supabase
      .from('companies')
      .update({
        is_claimed: true,
        claimed_at: new Date().toISOString()
      })
      .eq('id', existingCompany.value.id)

    if (claimError) throw claimError

    await loadProfile()
    router.push({ name: 'dashboard-pro' })
    emit('complete', 'PRO')
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de la finalisation'
  } finally {
    loading.value = false
  }
}

function goBack() {
  if (step.value === 'account-creation') {
    emit('close')
  } else if (step.value === 'siret-check') {
    step.value = 'account-creation'
    siret.value = ''
    error.value = ''
    siretStatus.value = 'not-checked'
  } else if (step.value === 'company-confirm') {
    step.value = 'siret-check'
    existingCompany.value = null
    error.value = ''
  } else if (step.value === 'company-form') {
    step.value = 'siret-check'
    companyForm.value = { name: '', city: '', postal_code: '' }
    error.value = ''
  } else if (step.value === 'usage-selection') {
    if (siretStatus.value === 'available') {
      step.value = 'company-confirm'
    } else {
      step.value = 'company-form'
    }
    error.value = ''
  }
}
</script>

<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-card">
      <!-- ÉTAPE 1: Création de compte -->
      <div v-if="step === 'account-creation'">
        <button class="back-button" @click="goBack">← Retour</button>

        <div class="modal-header">
          <h2>Inscription Professionnel</h2>
          <p>Étape 1/4 - Créez votre compte</p>
        </div>

        <div class="form-container">
          <div class="form-group">
            <label for="email">Email professionnel *</label>
            <input
              id="email"
              v-model="accountForm.email"
              type="email"
              placeholder="contact@entreprise.fr"
              :disabled="loading"
              @keyup.enter="proceedToSiret"
            />
          </div>

          <div class="form-group">
            <label for="password">Mot de passe *</label>
            <input
              id="password"
              v-model="accountForm.password"
              type="password"
              placeholder="Minimum 6 caractères"
              :disabled="loading"
              @keyup.enter="proceedToSiret"
            />
          </div>

          <div class="form-group">
            <label for="confirmPassword">Confirmer le mot de passe *</label>
            <input
              id="confirmPassword"
              v-model="accountForm.confirmPassword"
              type="password"
              placeholder="Confirmez votre mot de passe"
              :disabled="loading"
              @keyup.enter="proceedToSiret"
            />
          </div>

          <div v-if="error" class="error-message">
            {{ error }}
          </div>

          <button
            class="btn-primary full-width"
            :disabled="!accountForm.email || !accountForm.password || !accountForm.confirmPassword || loading"
            @click="proceedToSiret"
          >
            {{ loading ? 'Vérification...' : 'Continuer' }}
          </button>
        </div>
      </div>

      <!-- ÉTAPE 2: Vérification SIRET -->
      <div v-else-if="step === 'siret-check'">
        <button class="back-button" @click="goBack">← Retour</button>

        <div class="modal-header">
          <h2>Rattachez votre entreprise</h2>
          <p>Étape 2/4 - Entrez le numéro SIRET de votre entreprise (14 chiffres)</p>
        </div>

        <div class="form-container">
          <div class="form-group">
            <label for="siret">Numéro SIRET *</label>
            <input
              id="siret"
              v-model="siret"
              type="text"
              maxlength="14"
              placeholder="12345678901234"
              :disabled="loading"
              @keyup.enter="checkSiret"
            />
          </div>

          <div class="info-message">
            Nous utilisons le SIRET uniquement pour vérifier votre entreprise. Aucune donnée n'est publiée sans votre validation.
          </div>

          <div v-if="error" class="error-message">
            {{ error }}
          </div>

          <button
            class="btn-primary full-width"
            :disabled="!siret || siret.length !== 14 || loading"
            @click="checkSiret"
          >
            {{ loading ? 'Rechercher mon entreprise' : 'Rechercher mon entreprise' }}
          </button>
        </div>
      </div>

      <!-- ÉTAPE 3A: Confirmation entreprise trouvée -->
      <div v-else-if="step === 'company-confirm'">
        <button class="back-button" @click="goBack">← Retour</button>

        <div class="modal-header">
          <h2>Est-ce votre entreprise ?</h2>
          <p>Étape 3/4 - Confirmez votre entreprise</p>
        </div>

        <div class="company-info-card">
          <h3>{{ existingCompany?.name }}</h3>
          <div class="company-details">
            <p v-if="existingCompany?.city">
              <strong>Ville :</strong> {{ existingCompany.city }}
            </p>
            <p v-if="existingCompany?.naf_code">
              <strong>Activité :</strong> {{ existingCompany.naf_code }}
            </p>
            <p v-if="existingCompany?.address">
              <strong>Adresse :</strong> {{ existingCompany.address }}
            </p>
          </div>
        </div>

        <button
          class="btn-primary full-width"
          @click="confirmExistingCompany"
          :disabled="loading"
        >
          Rattacher cette entreprise
        </button>
      </div>

      <!-- ÉTAPE 3B: Formulaire entreprise -->
      <div v-else-if="step === 'company-form'">
        <button class="back-button" @click="goBack">← Retour</button>

        <div class="modal-header">
          <h2>Informations entreprise</h2>
          <p>Étape 3/4 - Cette entreprise n'est pas encore référencée</p>
        </div>

        <div class="form-container">
          <div class="form-group">
            <label for="siret_display">SIRET</label>
            <input
              id="siret_display"
              :value="siret"
              type="text"
              disabled
              class="disabled-input"
            />
          </div>

          <div class="form-group">
            <label for="name">Nom de l'entreprise *</label>
            <input
              id="name"
              v-model="companyForm.name"
              type="text"
              placeholder="Nom de votre entreprise"
              :disabled="loading"
            />
          </div>

          <div class="form-group">
            <label for="city">Ville *</label>
            <input
              id="city"
              v-model="companyForm.city"
              type="text"
              placeholder="Rennes"
              :disabled="loading"
            />
          </div>

          <div class="form-group">
            <label for="postal_code">Code postal (recommandé)</label>
            <input
              id="postal_code"
              v-model="companyForm.postal_code"
              type="text"
              maxlength="5"
              placeholder="35000"
              :disabled="loading"
            />
          </div>

          <div v-if="error" class="error-message">
            {{ error }}
          </div>

          <button
            class="btn-primary full-width"
            :disabled="!companyForm.name || !companyForm.city || loading"
            @click="createCompany"
          >
            {{ loading ? 'Création...' : 'Créer et rattacher mon entreprise' }}
          </button>
        </div>
      </div>

      <!-- ÉTAPE 4: Sélection usage -->
      <div v-else-if="step === 'usage-selection'">
        <button class="back-button" @click="goBack">← Retour</button>

        <div class="modal-header">
          <h2>Comment souhaitez-vous utiliser LocalProConnect ?</h2>
          <p>Étape 4/4 - Sélectionnez une ou plusieurs options</p>
        </div>

        <div class="form-container">
          <label class="checkbox-card">
            <input
              type="checkbox"
              v-model="usageForm.is_acheteur_pro"
              :disabled="loading"
            />
            <div class="checkbox-content">
              <h3>Trouver des fournisseurs</h3>
              <p>Rechercher et contacter des producteurs locaux pour vos besoins professionnels</p>
            </div>
          </label>

          <label class="checkbox-card">
            <input
              type="checkbox"
              v-model="usageForm.is_producteur"
              :disabled="loading"
            />
            <div class="checkbox-content">
              <h3>Recevoir des demandes de devis</h3>
              <p>Créer votre profil producteur et recevoir des demandes de la part d'acheteurs</p>
            </div>
          </label>

          <div v-if="error" class="error-message">
            {{ error }}
          </div>

          <button
            class="btn-primary full-width"
            @click="finalizeRegistration"
            :disabled="loading"
          >
            {{ loading ? 'Finalisation...' : 'Finaliser mon inscription' }}
          </button>
        </div>
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
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
  overflow-y: auto;
}

.modal-card {
  background: white;
  border-radius: 16px;
  padding: 40px;
  max-width: 600px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  position: relative;
  max-height: 90vh;
  overflow-y: auto;
  margin: auto;
}

.back-button {
  background: none;
  border: none;
  color: #059669;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  padding: 8px 0;
  margin-bottom: 16px;
  transition: color 0.2s;
}

.back-button:hover {
  color: #047857;
}

.modal-header {
  text-align: center;
  margin-bottom: 32px;
}

.modal-header h2 {
  font-size: 32px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 12px 0;
}

.modal-header p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.options-container {
  display: grid;
  gap: 16px;
  margin-bottom: 24px;
}

.option-card {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 24px;
  cursor: pointer;
  transition: all 0.2s;
  text-align: left;
  width: 100%;
}

.option-card:hover:not(:disabled) {
  border-color: #059669;
  background: #f0fdf4;
}

.option-card.selected {
  border-color: #059669;
  background: #d1fae5;
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.2);
}

.option-card:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.option-icon {
  font-size: 40px;
  display: block;
  margin-bottom: 12px;
}

.option-card h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.option-card p {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
}

.form-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
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

.form-group input,
.form-group textarea {
  padding: 12px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 0.2s;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #059669;
}

.form-group input:disabled,
.form-group textarea:disabled {
  background: #f9fafb;
  cursor: not-allowed;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.info-message {
  background: #dbeafe;
  color: #1e40af;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 13px;
  line-height: 1.5;
  margin-top: 8px;
}

.error-message {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
}

.company-info-card {
  background: #f9fafb;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
}

.company-info-card h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 16px 0;
}

.company-details p {
  margin: 8px 0;
  font-size: 14px;
  color: #4b5563;
}

.company-details strong {
  color: #111827;
  font-weight: 600;
}

.disabled-input {
  background: #f3f4f6 !important;
  color: #6b7280 !important;
  cursor: not-allowed !important;
}

.checkbox-card {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.2s;
}

.checkbox-card:hover:not(:has(input:disabled)) {
  border-color: #059669;
  background: #f0fdf4;
}

.checkbox-card:has(input:checked) {
  border-color: #059669;
  background: #d1fae5;
}

.checkbox-card input[type="checkbox"] {
  width: 20px;
  height: 20px;
  margin-top: 2px;
  cursor: pointer;
  flex-shrink: 0;
  accent-color: #059669;
}

.checkbox-card input[type="checkbox"]:disabled {
  cursor: not-allowed;
}

.checkbox-content {
  flex: 1;
}

.checkbox-content h3 {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 6px 0;
}

.checkbox-content p {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.5;
  margin: 0;
}

.modal-actions {
  display: flex;
  justify-content: center;
}

.btn-primary {
  padding: 14px 32px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
  min-width: 200px;
}

.btn-primary.full-width {
  width: 100%;
  min-width: auto;
}

.btn-primary:hover:not(:disabled) {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .modal-card {
    padding: 24px;
  }

  .modal-header h2 {
    font-size: 24px;
  }

  .option-icon {
    font-size: 32px;
  }

  .option-card h3 {
    font-size: 18px;
  }

  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
