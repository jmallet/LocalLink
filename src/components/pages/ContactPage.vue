<script setup lang="ts">
import { ref } from 'vue'

const formData = ref({
  name: '',
  email: '',
  company: '',
  subject: '',
  message: ''
})

const loading = ref(false)
const submitted = ref(false)
const error = ref('')

async function handleSubmit() {
  error.value = ''
  loading.value = true

  try {
    await new Promise(resolve => setTimeout(resolve, 1000))

    submitted.value = true
    formData.value = {
      name: '',
      email: '',
      company: '',
      subject: '',
      message: ''
    }
  } catch (err: any) {
    error.value = 'Une erreur est survenue. Veuillez réessayer.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="contact-page">
    <section class="page-header">
      <div class="container">
        <h1 class="page-title">Contactez-nous</h1>
        <p class="page-subtitle">
          Une question ? Un problème ? Notre équipe est là pour vous aider
        </p>
      </div>
    </section>

    <section class="contact-content">
      <div class="container">
        <div class="contact-grid">
          <div class="contact-info">
            <h2>Informations de contact</h2>

            <div class="info-item">
              <span class="info-icon">📧</span>
              <div>
                <h3>Email</h3>
                <a href="mailto:contact@locallink.fr">contact@locallink.fr</a>
              </div>
            </div>

            <div class="info-item">
              <span class="info-icon">📞</span>
              <div>
                <h3>Téléphone</h3>
                <a href="tel:+33478123456">+33 4 78 12 34 56</a>
              </div>
            </div>

            <div class="info-item">
              <span class="info-icon">📍</span>
              <div>
                <h3>Adresse</h3>
                <p>123 Avenue de l'Innovation<br>69001 Lyon, France</p>
              </div>
            </div>

            <div class="info-item">
              <span class="info-icon">🕐</span>
              <div>
                <h3>Horaires</h3>
                <p>Lundi - Vendredi<br>9h00 - 18h00</p>
              </div>
            </div>

            <div class="social-links">
              <h3>Suivez-nous</h3>
              <div class="social-icons">
                <a href="#" class="social-icon" aria-label="LinkedIn">in</a>
                <a href="#" class="social-icon" aria-label="Twitter">𝕏</a>
                <a href="#" class="social-icon" aria-label="Facebook">f</a>
              </div>
            </div>
          </div>

          <div class="contact-form-container">
            <div v-if="submitted" class="success-message">
              <span class="success-icon">✓</span>
              <h3>Message envoyé !</h3>
              <p>Merci pour votre message. Nous vous répondrons dans les plus brefs délais.</p>
              <button class="btn-secondary" @click="submitted = false">
                Envoyer un autre message
              </button>
            </div>

            <form v-else @submit.prevent="handleSubmit" class="contact-form">
              <div v-if="error" class="error-banner">
                {{ error }}
              </div>

              <div class="form-row">
                <div class="form-field">
                  <label for="name" class="form-label">Nom complet *</label>
                  <input
                    id="name"
                    v-model="formData.name"
                    type="text"
                    class="form-input"
                    placeholder="Jean Dupont"
                    required
                  />
                </div>

                <div class="form-field">
                  <label for="email" class="form-label">Email *</label>
                  <input
                    id="email"
                    v-model="formData.email"
                    type="email"
                    class="form-input"
                    placeholder="jean.dupont@entreprise.fr"
                    required
                  />
                </div>
              </div>

              <div class="form-field">
                <label for="company" class="form-label">Entreprise</label>
                <input
                  id="company"
                  v-model="formData.company"
                  type="text"
                  class="form-input"
                  placeholder="Nom de votre entreprise"
                />
              </div>

              <div class="form-field">
                <label for="subject" class="form-label">Sujet *</label>
                <select
                  id="subject"
                  v-model="formData.subject"
                  class="form-select"
                  required
                >
                  <option value="">Sélectionnez un sujet</option>
                  <option value="general">Question générale</option>
                  <option value="technical">Problème technique</option>
                  <option value="account">Mon compte</option>
                  <option value="partnership">Partenariat</option>
                  <option value="other">Autre</option>
                </select>
              </div>

              <div class="form-field">
                <label for="message" class="form-label">Message *</label>
                <textarea
                  id="message"
                  v-model="formData.message"
                  class="form-textarea"
                  placeholder="Décrivez votre demande..."
                  rows="6"
                  required
                ></textarea>
              </div>

              <button type="submit" class="btn-submit" :disabled="loading">
                {{ loading ? 'Envoi en cours...' : 'Envoyer le message' }}
              </button>
            </form>
          </div>
        </div>
      </div>
    </section>

    <section class="faq">
      <div class="container">
        <h2 class="section-title">Questions fréquentes</h2>

        <div class="faq-grid">
          <div class="faq-item">
            <h3>Comment puis-je m'inscrire ?</h3>
            <p>
              Cliquez sur "Créer un compte" dans le menu principal. Vous devrez fournir
              votre SIRET pour vérifier que vous êtes bien une entreprise.
            </p>
          </div>

          <div class="faq-item">
            <h3>L'inscription est-elle gratuite ?</h3>
            <p>
              Oui, l'inscription et la navigation sur la plateforme sont entièrement gratuites.
              Seules les demandes de devis débloquées sont payantes (10€ par demande).
            </p>
          </div>

          <div class="faq-item">
            <h3>Comment fonctionne la mise en avant ?</h3>
            <p>
              Les producteurs peuvent payer pour apparaître en haut des résultats de recherche.
              Les tarifs varient selon la zone géographique (locale, régionale, nationale).
            </p>
          </div>

          <div class="faq-item">
            <h3>Puis-je modifier mes informations ?</h3>
            <p>
              Oui, une fois connecté, accédez à votre dashboard pour modifier votre profil,
              vos produits/services et toutes vos informations.
            </p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.contact-page {
  min-height: 100vh;
  background: #f9fafb;
}

.page-header {
  background: white;
  padding: 64px 24px;
  border-bottom: 1px solid #e5e7eb;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.page-title {
  font-size: 48px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
  text-align: center;
}

.page-subtitle {
  font-size: 20px;
  color: #6b7280;
  margin: 0;
  text-align: center;
}

.contact-content {
  padding: 64px 24px;
}

.contact-grid {
  display: grid;
  grid-template-columns: 1fr 1.5fr;
  gap: 48px;
}

.contact-info h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 32px 0;
}

.info-item {
  display: flex;
  gap: 16px;
  margin-bottom: 32px;
}

.info-icon {
  font-size: 32px;
  flex-shrink: 0;
}

.info-item h3 {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 4px 0;
}

.info-item p,
.info-item a {
  font-size: 15px;
  color: #6b7280;
  margin: 0;
  text-decoration: none;
  line-height: 1.6;
}

.info-item a:hover {
  color: #059669;
}

.social-links {
  margin-top: 40px;
}

.social-links h3 {
  font-size: 16px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 16px 0;
}

.social-icons {
  display: flex;
  gap: 12px;
}

.social-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #e5e7eb;
  color: #374151;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  text-decoration: none;
  transition: all 0.2s;
}

.social-icon:hover {
  background: #059669;
  color: white;
}

.contact-form-container {
  background: white;
  padding: 40px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.success-message {
  text-align: center;
  padding: 40px 20px;
}

.success-icon {
  width: 64px;
  height: 64px;
  background: #d1fae5;
  color: #059669;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 24px;
}

.success-message h3 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.success-message p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-secondary {
  padding: 12px 24px;
  background: transparent;
  color: #059669;
  border: 2px solid #059669;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: #f0fdf4;
}

.contact-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.error-banner {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
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

.form-input,
.form-select,
.form-textarea {
  padding: 12px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.2s;
}

.form-input:focus,
.form-select:focus,
.form-textarea:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

.form-textarea {
  resize: vertical;
}

.btn-submit {
  padding: 14px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
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

.faq {
  padding: 64px 24px;
  background: white;
}

.section-title {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 48px 0;
  text-align: center;
}

.faq-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 32px;
}

.faq-item {
  background: #f9fafb;
  padding: 24px;
  border-radius: 12px;
}

.faq-item h3 {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.faq-item p {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
}

@media (max-width: 768px) {
  .page-header {
    padding: 48px 24px;
  }

  .page-title {
    font-size: 36px;
  }

  .page-subtitle {
    font-size: 18px;
  }

  .contact-grid {
    grid-template-columns: 1fr;
    gap: 32px;
  }

  .contact-form-container {
    padding: 24px;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .contact-content,
  .faq {
    padding: 48px 16px;
  }

  .section-title {
    font-size: 28px;
  }

  .faq-grid {
    grid-template-columns: 1fr;
  }
}
</style>
