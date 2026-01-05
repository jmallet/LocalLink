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
const loading = ref(false)
const error = ref('')

async function handleSubmit() {
  if (!selectedType.value || !user.value) return

  loading.value = true
  error.value = ''

  try {
    const { error: updateError } = await supabase
      .from('users')
      .update({ user_type: selectedType.value })
      .eq('id', user.value.id)

    if (updateError) throw updateError

    await loadProfile()
    emit('complete', selectedType.value)
  } catch (err: any) {
    error.value = err.message || 'Une erreur est survenue'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-card">
      <div class="modal-header">
        <h2>Bienvenue sur LocalLink</h2>
        <p>Pour commencer, dites-nous qui vous êtes</p>
      </div>

      <div class="options-container">
        <button
          class="option-card"
          :class="{ selected: selectedType === 'PARTICULIER' }"
          @click="selectedType = 'PARTICULIER'"
        >
          <span class="option-icon">👤</span>
          <h3>Particulier</h3>
          <p>Je recherche des produits ou services locaux pour mes besoins personnels</p>
        </button>

        <button
          class="option-card"
          :class="{ selected: selectedType === 'PRO' }"
          @click="selectedType = 'PRO'"
        >
          <span class="option-icon">🏢</span>
          <h3>Professionnel</h3>
          <p>Je représente une entreprise (acheteur, fournisseur ou les deux)</p>
        </button>
      </div>

      <div v-if="error" class="error-message">
        {{ error }}
      </div>

      <div class="modal-actions">
        <button
          class="btn-primary"
          :disabled="!selectedType || loading"
          @click="handleSubmit"
        >
          {{ loading ? 'Enregistrement...' : 'Continuer' }}
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
  background: rgba(0, 0, 0, 0.7);
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
  max-width: 600px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
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

.option-card:hover {
  border-color: #059669;
  background: #f0fdf4;
}

.option-card.selected {
  border-color: #059669;
  background: #d1fae5;
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.2);
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

.error-message {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  margin-bottom: 16px;
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
}
</style>
