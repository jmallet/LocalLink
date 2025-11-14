<script setup lang="ts">
import { ref, watch } from 'vue'
import type { Business } from '../types'

const props = defineProps<{
  business: Business | null
  isOpen: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const message = ref('')
const companyName = ref('')
const contactEmail = ref('')

watch(() => props.isOpen, (newValue) => {
  if (!newValue) {
    message.value = ''
    companyName.value = ''
    contactEmail.value = ''
  }
})

const handleSubmit = () => {
  alert(`Message envoyé à ${props.business?.name}!\n\nCette fonctionnalité sera disponible prochainement.`)
  emit('close')
}

const handleOverlayClick = (event: MouseEvent) => {
  if (event.target === event.currentTarget) {
    emit('close')
  }
}
</script>

<template>
  <Transition name="modal">
    <div v-if="isOpen && business" class="modal-overlay" @click="handleOverlayClick">
      <div class="modal-container">
        <div class="modal-header">
          <h2 class="modal-title">Contacter {{ business.name }}</h2>
          <button @click="emit('close')" class="close-btn">✕</button>
        </div>

        <div class="modal-body">
          <div class="business-info">
            <img :src="business.image" :alt="business.name" class="business-thumb" />
            <div class="business-details">
              <h3>{{ business.name }}</h3>
              <p>{{ business.location }}</p>
              <div class="contact-info">
                <div>📧 {{ business.contact.email }}</div>
                <div>📞 {{ business.contact.phone }}</div>
              </div>
            </div>
          </div>

          <form @submit.prevent="handleSubmit" class="contact-form">
            <div class="form-group">
              <label for="companyName">Votre entreprise</label>
              <input
                id="companyName"
                v-model="companyName"
                type="text"
                placeholder="Nom de votre entreprise"
                required
              />
            </div>

            <div class="form-group">
              <label for="contactEmail">Votre email</label>
              <input
                id="contactEmail"
                v-model="contactEmail"
                type="email"
                placeholder="contact@entreprise.fr"
                required
              />
            </div>

            <div class="form-group">
              <label for="message">Message</label>
              <textarea
                id="message"
                v-model="message"
                placeholder="Décrivez votre besoin..."
                rows="5"
                required
              ></textarea>
            </div>

            <div class="form-actions">
              <button type="button" @click="emit('close')" class="btn-cancel">
                Annuler
              </button>
              <button type="submit" class="btn-submit">
                Envoyer le message
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
  backdrop-filter: blur(4px);
}

.modal-container {
  background: white;
  border-radius: 20px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  padding: 24px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-title {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  color: #6b7280;
  cursor: pointer;
  padding: 4px 8px;
  transition: color 0.2s;
}

.close-btn:hover {
  color: #111827;
}

.modal-body {
  padding: 24px;
}

.business-info {
  display: flex;
  gap: 16px;
  padding: 20px;
  background: #f9fafb;
  border-radius: 12px;
  margin-bottom: 24px;
}

.business-thumb {
  width: 80px;
  height: 80px;
  border-radius: 12px;
  object-fit: cover;
}

.business-details h3 {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.business-details p {
  font-size: 14px;
  color: #6b7280;
  margin: 0 0 12px 0;
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 13px;
  color: #374151;
}

.contact-form {
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

.form-group input,
.form-group textarea {
  padding: 12px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  color: #111827;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #059669;
}

.form-group textarea {
  resize: vertical;
  font-family: inherit;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  padding-top: 8px;
}

.btn-cancel,
.btn-submit {
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.btn-cancel {
  background: #f3f4f6;
  color: #374151;
}

.btn-cancel:hover {
  background: #e5e7eb;
}

.btn-submit {
  background: #059669;
  color: white;
}

.btn-submit:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-container,
.modal-leave-active .modal-container {
  transition: transform 0.3s;
}

.modal-enter-from .modal-container,
.modal-leave-to .modal-container {
  transform: scale(0.9);
}

@media (max-width: 640px) {
  .business-info {
    flex-direction: column;
  }

  .form-actions {
    flex-direction: column;
  }

  .btn-cancel,
  .btn-submit {
    width: 100%;
  }
}
</style>
