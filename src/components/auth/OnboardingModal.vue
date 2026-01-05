<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../../lib/supabase'
import { user, loadProfile } from '../../stores/auth'
import type { UserType } from '../../types/database'

const emit = defineEmits<{
  complete: [userType: UserType]
  close: []
}>()

const selectedType = ref<UserType | null>(null)
const step = ref<'type-selection' | 'siret-check' | 'company-form'>('type-selection')
const loading = ref(false)
const error = ref('')

// SIRET verification
const siret = ref('')
const existingCompany = ref<any>(null)
const siretStatus = ref<'not-checked' | 'new' | 'claimed' | 'available'>('not-checked')

// Company form
const companyForm = ref({
  name: '',
  siren: '',
  naf_code: '',
  address: '',
  postal_code: '',
  city: '',
  phone: '',
  website: '',
  description: ''
})

function selectType(type: UserType) {
  selectedType.value = type

  if (type === 'PARTICULIER') {
    handleParticulierSubmit()
  } else if (type === 'PRO') {
    step.value = 'siret-check'
  }
}

async function handleParticulierSubmit() {
  if (!user.value) return

  loading.value = true
  error.value = ''

  try {
    const { error: updateError } = await supabase
      .from('profiles')
      .update({ user_type: 'PARTICULIER' })
      .eq('user_id', user.value.id)

    if (updateError) throw updateError

    await loadProfile()
    emit('complete', 'PARTICULIER')
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue'
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
    // Vérifier si le SIRET existe dans la base
    const { data, error: queryError } = await supabase
      .from('companies')
      .select('*')
      .eq('siret', siret.value)
      .maybeSingle()

    if (queryError) throw queryError

    if (!data) {
      // SIRET n'existe pas
      siretStatus.value = 'new'
      companyForm.value.siren = siret.value.substring(0, 9)
      step.value = 'company-form'
    } else if (data.is_claimed) {
      // SIRET existe et est déjà réclamé
      siretStatus.value = 'claimed'
      error.value = 'Cette entreprise est déjà enregistrée sur la plateforme. Veuillez contacter le support à support@localproconnect.fr'
    } else {
      // SIRET existe et n'est pas réclamé
      siretStatus.value = 'available'
      existingCompany.value = data
      await associateWithExistingCompany(data.id)
    }
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de la vérification'
  } finally {
    loading.value = false
  }
}

async function associateWithExistingCompany(companyId: string) {
  if (!user.value) return

  loading.value = true
  error.value = ''

  try {
    // Mettre à jour le profil en PRO
    const { error: profileError } = await supabase
      .from('profiles')
      .update({ user_type: 'PRO' })
      .eq('user_id', user.value.id)

    if (profileError) throw profileError

    // Associer l'utilisateur à l'entreprise
    const { error: linkError } = await supabase
      .from('company_users')
      .insert({
        user_id: user.value.id,
        company_id: companyId,
        is_acheteur_pro: true,
        is_producteur: false,
        verified: true,
        verified_at: new Date().toISOString()
      })

    if (linkError) throw linkError

    // Marquer l'entreprise comme réclamée
    const { error: claimError } = await supabase
      .from('companies')
      .update({
        is_claimed: true,
        claimed_at: new Date().toISOString()
      })
      .eq('id', companyId)

    if (claimError) throw claimError

    await loadProfile()
    emit('complete', 'PRO')
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de l\'association'
  } finally {
    loading.value = false
  }
}

async function createCompanyAndAssociate() {
  if (!user.value) return

  loading.value = true
  error.value = ''

  try {
    // Créer l'entreprise
    const { data: newCompany, error: companyError } = await supabase
      .from('companies')
      .insert({
        name: companyForm.value.name,
        siret: siret.value,
        siren: companyForm.value.siren,
        naf_code: companyForm.value.naf_code,
        address: companyForm.value.address,
        postal_code: companyForm.value.postal_code,
        city: companyForm.value.city,
        phone: companyForm.value.phone,
        website: companyForm.value.website,
        description: companyForm.value.description,
        source: 'MANUAL',
        is_claimed: true,
        claimed_at: new Date().toISOString()
      })
      .select()
      .single()

    if (companyError) throw companyError

    // Mettre à jour le profil en PRO
    const { error: profileError } = await supabase
      .from('profiles')
      .update({ user_type: 'PRO' })
      .eq('user_id', user.value.id)

    if (profileError) throw profileError

    // Associer l'utilisateur à l'entreprise
    const { error: linkError } = await supabase
      .from('company_users')
      .insert({
        user_id: user.value.id,
        company_id: newCompany.id,
        is_acheteur_pro: true,
        is_producteur: false,
        verified: true,
        verified_at: new Date().toISOString()
      })

    if (linkError) throw linkError

    await loadProfile()
    emit('complete', 'PRO')
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue lors de la création'
  } finally {
    loading.value = false
  }
}

function goBack() {
  if (step.value === 'siret-check') {
    step.value = 'type-selection'
    selectedType.value = null
    siret.value = ''
    error.value = ''
    siretStatus.value = 'not-checked'
  } else if (step.value === 'company-form') {
    step.value = 'siret-check'
    error.value = ''
  }
}
</script>

<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-card">
      <!-- ÉTAPE 1: Sélection du type -->
      <div v-if="step === 'type-selection'">
        <div class="modal-header">
          <h2>Bienvenue sur LocalLink</h2>
          <p>Pour commencer, dites-nous qui vous êtes</p>
        </div>

        <div class="options-container">
          <button
            class="option-card"
            :class="{ selected: selectedType === 'PARTICULIER' }"
            @click="selectType('PARTICULIER')"
            :disabled="loading"
          >
            <span class="option-icon">👤</span>
            <h3>Particulier</h3>
            <p>Je recherche des produits ou services locaux pour mes besoins personnels</p>
          </button>

          <button
            class="option-card"
            :class="{ selected: selectedType === 'PRO' }"
            @click="selectType('PRO')"
            :disabled="loading"
          >
            <span class="option-icon">🏢</span>
            <h3>Professionnel</h3>
            <p>Je représente une entreprise (acheteur, fournisseur ou les deux)</p>
          </button>
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>
      </div>

      <!-- ÉTAPE 2: Vérification SIRET -->
      <div v-else-if="step === 'siret-check'">
        <button class="back-button" @click="goBack">← Retour</button>

        <div class="modal-header">
          <h2>Votre SIRET</h2>
          <p>Entrez le numéro SIRET de votre entreprise (14 chiffres)</p>
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

          <div v-if="error" class="error-message">
            {{ error }}
          </div>

          <button
            class="btn-primary full-width"
            :disabled="!siret || siret.length !== 14 || loading"
            @click="checkSiret"
          >
            {{ loading ? 'Vérification...' : 'Vérifier' }}
          </button>
        </div>
      </div>

      <!-- ÉTAPE 3: Formulaire entreprise -->
      <div v-else-if="step === 'company-form'">
        <button class="back-button" @click="goBack">← Retour</button>

        <div class="modal-header">
          <h2>Informations entreprise</h2>
          <p>Complétez les informations de votre entreprise</p>
        </div>

        <div class="form-container">
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

          <div class="form-row">
            <div class="form-group">
              <label for="siren">SIREN</label>
              <input
                id="siren"
                v-model="companyForm.siren"
                type="text"
                maxlength="9"
                placeholder="123456789"
                :disabled="loading"
              />
            </div>

            <div class="form-group">
              <label for="naf_code">Code NAF</label>
              <input
                id="naf_code"
                v-model="companyForm.naf_code"
                type="text"
                placeholder="47.11A"
                :disabled="loading"
              />
            </div>
          </div>

          <div class="form-group">
            <label for="address">Adresse *</label>
            <input
              id="address"
              v-model="companyForm.address"
              type="text"
              placeholder="15 Rue de la République"
              :disabled="loading"
            />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="postal_code">Code postal *</label>
              <input
                id="postal_code"
                v-model="companyForm.postal_code"
                type="text"
                maxlength="5"
                placeholder="35000"
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
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="phone">Téléphone</label>
              <input
                id="phone"
                v-model="companyForm.phone"
                type="tel"
                placeholder="02 99 00 00 00"
                :disabled="loading"
              />
            </div>

            <div class="form-group">
              <label for="website">Site web</label>
              <input
                id="website"
                v-model="companyForm.website"
                type="url"
                placeholder="https://..."
                :disabled="loading"
              />
            </div>
          </div>

          <div class="form-group">
            <label for="description">Description</label>
            <textarea
              id="description"
              v-model="companyForm.description"
              rows="3"
              placeholder="Décrivez votre activité..."
              :disabled="loading"
            ></textarea>
          </div>

          <div v-if="error" class="error-message">
            {{ error }}
          </div>

          <button
            class="btn-primary full-width"
            :disabled="!companyForm.name || !companyForm.address || !companyForm.postal_code || !companyForm.city || loading"
            @click="createCompanyAndAssociate"
          >
            {{ loading ? 'Création...' : 'Créer mon entreprise' }}
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

.error-message {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
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
