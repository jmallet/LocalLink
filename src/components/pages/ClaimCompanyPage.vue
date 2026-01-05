<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import { user, loadCompanies } from '../../stores/auth'
import type { Company } from '../../types/database'

const router = useRouter()

const siret = ref('')
const foundCompany = ref<Company | null>(null)
const notFound = ref(false)
const searching = ref(false)
const claiming = ref(false)
const error = ref('')

const isProducteur = ref(false)
const isAcheteurPro = ref(true)

const newCompanyData = ref({
  name: '',
  address: '',
  postal_code: '',
  city: ''
})

async function searchBySiret() {
  if (siret.value.length !== 14) {
    error.value = 'Le SIRET doit contenir exactement 14 chiffres'
    return
  }

  searching.value = true
  error.value = ''
  foundCompany.value = null
  notFound.value = false

  try {
    const { data, error: searchError } = await supabase
      .from('companies')
      .select('*')
      .eq('siret', siret.value)
      .maybeSingle()

    if (searchError) throw searchError

    if (data) {
      foundCompany.value = data
    } else {
      notFound.value = true
      newCompanyData.value.name = ''
    }
  } catch (err: any) {
    error.value = err.message || 'Erreur lors de la recherche'
  } finally {
    searching.value = false
  }
}

async function claimExistingCompany() {
  if (!foundCompany.value || !user.value) return

  if (foundCompany.value.is_claimed) {
    error.value = 'Cette société est déjà rattachée. Contactez le support.'
    return
  }

  claiming.value = true
  error.value = ''

  try {
    const { error: insertError } = await supabase
      .from('company_users')
      .insert({
        user_id: user.value.id,
        company_id: foundCompany.value.id,
        is_acheteur_pro: isAcheteurPro.value,
        is_producteur: isProducteur.value,
        verified: false
      })

    if (insertError) throw insertError

    const { error: updateError } = await supabase
      .from('companies')
      .update({
        is_claimed: true,
        claimed_at: new Date().toISOString()
      })
      .eq('id', foundCompany.value.id)

    if (updateError) throw updateError

    if (isProducteur.value) {
      const { error: profileError } = await supabase
        .from('producer_profiles')
        .insert({
          company_id: foundCompany.value.id,
          is_active: false
        })

      if (profileError && profileError.code !== '23505') {
        console.error('Error creating producer profile:', profileError)
      }
    }

    await loadCompanies()
    router.push({ name: 'dashboard-pro' })
  } catch (err: any) {
    error.value = err.message || 'Erreur lors du rattachement'
  } finally {
    claiming.value = false
  }
}

async function createAndClaimCompany() {
  if (!user.value) return

  if (!newCompanyData.value.name || !newCompanyData.value.address || !newCompanyData.value.postal_code || !newCompanyData.value.city) {
    error.value = 'Veuillez remplir tous les champs obligatoires'
    return
  }

  claiming.value = true
  error.value = ''

  try {
    const { data: newCompany, error: createError } = await supabase
      .from('companies')
      .insert({
        name: newCompanyData.value.name,
        siret: siret.value,
        siren: siret.value.substring(0, 9),
        address: newCompanyData.value.address,
        postal_code: newCompanyData.value.postal_code,
        city: newCompanyData.value.city,
        source: 'MANUAL',
        is_claimed: true,
        claimed_at: new Date().toISOString()
      })
      .select()
      .single()

    if (createError) throw createError

    const { error: linkError } = await supabase
      .from('company_users')
      .insert({
        user_id: user.value.id,
        company_id: newCompany.id,
        is_acheteur_pro: isAcheteurPro.value,
        is_producteur: isProducteur.value,
        verified: false
      })

    if (linkError) throw linkError

    if (isProducteur.value) {
      await supabase
        .from('producer_profiles')
        .insert({
          company_id: newCompany.id,
          is_active: false
        })
    }

    await loadCompanies()
    router.push({ name: 'dashboard-pro' })
  } catch (err: any) {
    error.value = err.message || 'Erreur lors de la création'
  } finally {
    claiming.value = false
  }
}
</script>

<template>
  <div class="claim-page">
    <div class="container">
      <div class="header">
        <h1>Rattacher mon entreprise</h1>
        <p>Recherchez votre entreprise par son numéro SIRET</p>
      </div>

      <div class="search-section">
        <div class="search-box">
          <input
            v-model="siret"
            type="text"
            placeholder="Entrez votre SIRET (14 chiffres)"
            maxlength="14"
            @keyup.enter="searchBySiret"
          />
          <button
            class="btn-primary"
            :disabled="searching || siret.length !== 14"
            @click="searchBySiret"
          >
            {{ searching ? 'Recherche...' : 'Rechercher' }}
          </button>
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>
      </div>

      <div v-if="foundCompany" class="result-card">
        <div class="result-header">
          <span class="result-icon">✓</span>
          <h2>Société trouvée</h2>
        </div>

        <div class="company-info">
          <div class="info-row">
            <span class="label">Nom :</span>
            <span class="value">{{ foundCompany.name || foundCompany.company_name }}</span>
          </div>
          <div class="info-row">
            <span class="label">SIRET :</span>
            <span class="value">{{ foundCompany.siret || foundCompany.siret_bce }}</span>
          </div>
          <div class="info-row">
            <span class="label">Adresse :</span>
            <span class="value">{{ foundCompany.address }}</span>
          </div>
          <div class="info-row">
            <span class="label">Ville :</span>
            <span class="value">{{ foundCompany.postal_code }} {{ foundCompany.city }}</span>
          </div>
        </div>

        <div class="roles-section">
          <h3>Sélectionnez votre rôle :</h3>
          <div class="checkbox-group">
            <label class="checkbox-label">
              <input type="checkbox" v-model="isAcheteurPro" />
              <span>Je suis acheteur professionnel</span>
            </label>
            <label class="checkbox-label">
              <input type="checkbox" v-model="isProducteur" />
              <span>Je suis producteur / fournisseur</span>
            </label>
          </div>
        </div>

        <button
          class="btn-primary-large"
          :disabled="claiming || (!isAcheteurPro && !isProducteur)"
          @click="claimExistingCompany"
        >
          {{ claiming ? 'Rattachement...' : 'Rattacher cette société à mon compte' }}
        </button>
      </div>

      <div v-if="notFound" class="result-card">
        <div class="result-header not-found">
          <span class="result-icon">✗</span>
          <h2>Société non trouvée</h2>
        </div>

        <p class="not-found-text">
          Aucune société avec ce SIRET n'a été trouvée dans notre base.
          Vous pouvez créer une fiche manuellement :
        </p>

        <div class="form-section">
          <div class="form-group">
            <label>Nom de l'entreprise *</label>
            <input v-model="newCompanyData.name" type="text" placeholder="Ex: Ferme Durand" />
          </div>

          <div class="form-group">
            <label>Adresse *</label>
            <input v-model="newCompanyData.address" type="text" placeholder="Ex: 123 Route des Champs" />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Code postal *</label>
              <input v-model="newCompanyData.postal_code" type="text" placeholder="Ex: 35000" maxlength="5" />
            </div>

            <div class="form-group">
              <label>Ville *</label>
              <input v-model="newCompanyData.city" type="text" placeholder="Ex: Rennes" />
            </div>
          </div>

          <div class="form-group">
            <label>SIRET</label>
            <input :value="siret" type="text" disabled />
          </div>
        </div>

        <div class="roles-section">
          <h3>Sélectionnez votre rôle :</h3>
          <div class="checkbox-group">
            <label class="checkbox-label">
              <input type="checkbox" v-model="isAcheteurPro" />
              <span>Je suis acheteur professionnel</span>
            </label>
            <label class="checkbox-label">
              <input type="checkbox" v-model="isProducteur" />
              <span>Je suis producteur / fournisseur</span>
            </label>
          </div>
        </div>

        <button
          class="btn-primary-large"
          :disabled="claiming || (!isAcheteurPro && !isProducteur)"
          @click="createAndClaimCompany"
        >
          {{ claiming ? 'Création...' : 'Créer et rattacher' }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.claim-page {
  min-height: 100vh;
  background: #f9fafb;
  padding: 40px 24px;
}

.container {
  max-width: 800px;
  margin: 0 auto;
}

.header {
  text-align: center;
  margin-bottom: 40px;
}

.header h1 {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 12px 0;
}

.header p {
  font-size: 18px;
  color: #6b7280;
  margin: 0;
}

.search-section {
  background: white;
  padding: 32px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  margin-bottom: 24px;
}

.search-box {
  display: flex;
  gap: 12px;
}

.search-box input {
  flex: 1;
  padding: 14px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  font-size: 16px;
  transition: border-color 0.2s;
}

.search-box input:focus {
  outline: none;
  border-color: #059669;
}

.btn-primary {
  padding: 14px 28px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-primary:hover:not(:disabled) {
  background: #047857;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.error-message {
  margin-top: 16px;
  padding: 12px 16px;
  background: #fee2e2;
  color: #991b1b;
  border-radius: 8px;
  font-size: 14px;
}

.result-card {
  background: white;
  padding: 32px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.result-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
}

.result-header.not-found .result-icon {
  background: #fee2e2;
  color: #991b1b;
}

.result-icon {
  width: 48px;
  height: 48px;
  background: #d1fae5;
  color: #059669;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: 700;
}

.result-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.company-info {
  background: #f9fafb;
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 24px;
}

.info-row {
  display: flex;
  padding: 8px 0;
  border-bottom: 1px solid #e5e7eb;
}

.info-row:last-child {
  border-bottom: none;
}

.label {
  font-weight: 600;
  color: #6b7280;
  min-width: 120px;
}

.value {
  color: #111827;
}

.not-found-text {
  color: #6b7280;
  line-height: 1.6;
  margin-bottom: 24px;
}

.form-section {
  margin-bottom: 24px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  font-weight: 600;
  color: #374151;
  margin-bottom: 8px;
}

.form-group input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 0.2s;
}

.form-group input:focus {
  outline: none;
  border-color: #059669;
}

.form-group input:disabled {
  background: #f3f4f6;
  cursor: not-allowed;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 16px;
}

.roles-section {
  margin-bottom: 24px;
}

.roles-section h3 {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 16px 0;
}

.checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f9fafb;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.checkbox-label:hover {
  background: #f3f4f6;
}

.checkbox-label input[type="checkbox"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.checkbox-label span {
  font-size: 15px;
  color: #374151;
}

.btn-primary-large {
  width: 100%;
  padding: 16px 32px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary-large:hover:not(:disabled) {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

.btn-primary-large:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .header h1 {
    font-size: 28px;
  }

  .search-box {
    flex-direction: column;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .search-section,
  .result-card {
    padding: 24px;
  }
}
</style>
