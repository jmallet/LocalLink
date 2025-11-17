<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { isAuthenticated, user } from '../../stores/auth'
import { currentRoute, navigateTo } from '../../router'
import type { Company, ProductService } from '../../types/database'

const company = ref<Company | null>(null)
const userCompany = ref<Company | null>(null)
const products = ref<ProductService[]>([])
const loading = ref(true)
const showContactModal = ref(false)
const sending = ref(false)
const message = ref({ type: '', text: '' })

const quoteFormData = ref({
  title: '',
  description: '',
  budget: null as number | null,
  delivery_date: ''
})

const companyId = computed(() => currentRoute.value.params?.id || '')

onMounted(async () => {
  await loadCompanyData()
})

async function loadCompanyData() {
  loading.value = true
  try {
    const { data: companyData, error: companyError } = await supabase
      .from('companies')
      .select('*')
      .eq('id', companyId.value)
      .maybeSingle()

    if (companyError) throw companyError
    company.value = companyData

    if (companyData) {
      const { data: productsData, error: productsError } = await supabase
        .from('products_services')
        .select('*')
        .eq('company_id', companyData.id)
        .eq('available', true)

      if (productsError) throw productsError
      products.value = productsData || []
    }

    if (isAuthenticated.value && user.value) {
      const { data: userData } = await supabase
        .from('companies')
        .select('*')
        .eq('user_id', user.value.id)
        .maybeSingle()

      userCompany.value = userData
    }
  } catch (error) {
    console.error('Error loading company:', error)
  } finally {
    loading.value = false
  }
}

function handleContact() {
  if (!isAuthenticated.value) {
    navigateTo({ name: 'login' })
  } else {
    message.value = { type: '', text: '' }
    quoteFormData.value = {
      title: '',
      description: '',
      budget: null,
      delivery_date: ''
    }
    showContactModal.value = true
  }
}

async function sendQuoteRequest() {
  if (!userCompany.value || !company.value) {
    message.value = {
      type: 'error',
      text: 'Vous devez avoir un profil entreprise pour envoyer une demande de devis.'
    }
    return
  }

  sending.value = true
  message.value = { type: '', text: '' }

  try {
    const { data: quoteData, error: quoteError } = await supabase
      .from('quote_requests')
      .insert({
        company_id: userCompany.value.id,
        title: quoteFormData.value.title,
        description: quoteFormData.value.description,
        budget: quoteFormData.value.budget,
        delivery_date: quoteFormData.value.delivery_date || null,
        status: 'pending'
      })
      .select()
      .single()

    if (quoteError) throw quoteError

    const { error: recipientError } = await supabase
      .from('quote_recipients')
      .insert({
        quote_id: quoteData.id,
        company_id: company.value.id,
        status: 'pending'
      })

    if (recipientError) throw recipientError

    message.value = {
      type: 'success',
      text: 'Votre demande de devis a été envoyée avec succès !'
    }

    setTimeout(() => {
      showContactModal.value = false
    }, 2000)
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue lors de l\'envoi'
    }
  } finally {
    sending.value = false
  }
}
</script>

<template>
  <div class="company-detail-page">
    <div v-if="loading" class="loading-container">
      <div class="spinner"></div>
      <p>Chargement...</p>
    </div>

    <div v-else-if="company" class="company-detail">
      <div class="company-header">
        <div class="header-content">
          <button class="btn-back" @click="navigateTo({ name: 'pros-locaux' })">
            ← Retour aux pros locaux
          </button>

          <div class="company-main-info">
            <div class="company-logo">
              <img
                :src="company.logo_url || 'https://images.pexels.com/photos/6802042/pexels-photo-6802042.jpeg'"
                :alt="company.company_name"
              />
            </div>

            <div class="company-details">
              <h1 class="company-name">{{ company.company_name }}</h1>

              <div class="company-meta">
                <span class="category-badge">{{ company.category }}</span>
                <span v-if="company.verified" class="verified-badge">✓ Vérifiée</span>
              </div>

              <div class="company-location">
                <span class="icon">📍</span>
                {{ company.address }}, {{ company.postal_code }} {{ company.city }}
              </div>

              <div class="company-contact-info">
                <span class="icon">📞</span>
                {{ company.phone }}
              </div>

              <div v-if="company.website" class="company-website">
                <span class="icon">🌐</span>
                <a :href="company.website" target="_blank" rel="noopener">
                  {{ company.website }}
                </a>
              </div>

              <div class="company-tags">
                <span v-for="tag in company.tags" :key="tag" class="tag">
                  {{ tag }}
                </span>
              </div>

              <button class="btn-contact" @click="handleContact">
                📧 Demander un devis
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="company-body">
        <div class="container">
          <section class="about-section">
            <h2 class="section-title">À propos</h2>
            <p class="company-description">{{ company.description }}</p>
          </section>

          <section v-if="products.length > 0" class="products-section">
            <h2 class="section-title">
              Produits & Services ({{ products.length }})
            </h2>

            <div class="products-grid">
              <div v-for="product in products" :key="product.id" class="product-card">
                <div v-if="product.images.length > 0" class="product-image">
                  <img :src="product.images[0]" :alt="product.name" />
                </div>
                <div class="product-content">
                  <h3 class="product-name">{{ product.name }}</h3>
                  <p class="product-category">{{ product.category }}</p>
                  <p class="product-description">{{ product.description }}</p>
                  <div class="product-footer">
                    <div v-if="product.price" class="product-price">
                      {{ product.price.toFixed(2) }}€
                      <span v-if="product.unit" class="product-unit">/ {{ product.unit }}</span>
                    </div>
                    <div v-else class="product-price-request">
                      Sur devis
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section class="contact-section">
            <div class="contact-card">
              <h2>Intéressé par cette entreprise ?</h2>
              <p>Envoyez une demande de devis personnalisée</p>
              <button class="btn-contact-large" @click="handleContact">
                Demander un devis
              </button>
            </div>
          </section>
        </div>
      </div>
    </div>

    <div v-else class="error-container">
      <h2>Entreprise non trouvée</h2>
      <button class="btn-back" @click="navigateTo({ name: 'pros-locaux' })">
        ← Retour aux pros locaux
      </button>
    </div>

    <div v-if="showContactModal" class="modal-overlay" @click="showContactModal = false">
      <div class="modal-content quote-modal" @click.stop>
        <button class="close-btn" @click="showContactModal = false">✕</button>

        <div class="modal-header-content">
          <h2>Demander un devis</h2>
          <p>Envoyez une demande à <strong>{{ company?.company_name }}</strong></p>
        </div>

        <div v-if="message.text" class="message-banner" :class="message.type">
          {{ message.text }}
        </div>

        <form @submit.prevent="sendQuoteRequest" class="quote-form">
          <div class="form-field">
            <label for="title" class="form-label">Objet de la demande *</label>
            <input
              id="title"
              v-model="quoteFormData.title"
              type="text"
              class="form-input"
              placeholder="Ex: Devis pour fourniture de matériaux"
              required
            />
          </div>

          <div class="form-field">
            <label for="description" class="form-label">Description détaillée *</label>
            <textarea
              id="description"
              v-model="quoteFormData.description"
              class="form-textarea"
              rows="5"
              placeholder="Décrivez précisément vos besoins, quantités, délais souhaités..."
              required
            ></textarea>
          </div>

          <div class="form-row">
            <div class="form-field">
              <label for="budget" class="form-label">Budget indicatif (€)</label>
              <input
                id="budget"
                v-model.number="quoteFormData.budget"
                type="number"
                step="0.01"
                min="0"
                class="form-input"
                placeholder="Optionnel"
              />
            </div>

            <div class="form-field">
              <label for="delivery_date" class="form-label">Date de livraison souhaitée</label>
              <input
                id="delivery_date"
                v-model="quoteFormData.delivery_date"
                type="date"
                class="form-input"
              />
            </div>
          </div>

          <div class="modal-actions">
            <button type="button" class="btn-cancel" @click="showContactModal = false">
              Annuler
            </button>
            <button type="submit" class="btn-submit" :disabled="sending">
              {{ sending ? 'Envoi...' : 'Envoyer la demande' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.company-detail-page {
  min-height: 100vh;
  background: #f9fafb;
}

.company-header {
  background: white;
  border-bottom: 1px solid #e5e7eb;
}

.header-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px;
}

.btn-back {
  padding: 8px 16px;
  background: transparent;
  color: #059669;
  border: 1px solid #059669;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 24px;
}

.btn-back:hover {
  background: #f0fdf4;
}

.company-main-info {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 32px;
  align-items: start;
}

.company-logo {
  width: 200px;
  height: 200px;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.company-logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.company-name {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
}

.company-meta {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.category-badge {
  display: inline-block;
  background: #e0f2fe;
  color: #075985;
  padding: 6px 16px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
}

.verified-badge {
  display: inline-block;
  background: #d1fae5;
  color: #065f46;
  padding: 6px 16px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
}

.company-location,
.company-contact-info,
.company-website {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  font-size: 15px;
  color: #374151;
}

.icon {
  font-size: 18px;
}

.company-website a {
  color: #059669;
  text-decoration: none;
}

.company-website a:hover {
  text-decoration: underline;
}

.company-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 16px 0;
}

.tag {
  background: #f3f4f6;
  color: #374151;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
}

.btn-contact {
  padding: 14px 28px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: 16px;
}

.btn-contact:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(5, 150, 105, 0.3);
}

.company-body {
  padding: 48px 24px;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
}

.about-section,
.products-section,
.contact-section {
  margin-bottom: 48px;
}

.section-title {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 24px 0;
}

.company-description {
  font-size: 16px;
  line-height: 1.8;
  color: #374151;
  max-width: 800px;
}

.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
}

.product-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.2s;
}

.product-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.product-image {
  width: 100%;
  height: 200px;
  overflow: hidden;
  background: #f3f4f6;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-content {
  padding: 20px;
}

.product-name {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.product-category {
  font-size: 13px;
  color: #059669;
  font-weight: 600;
  margin: 0 0 8px 0;
}

.product-description {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.product-footer {
  border-top: 1px solid #e5e7eb;
  padding-top: 12px;
}

.product-price {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
}

.product-unit {
  font-size: 14px;
  font-weight: 500;
  color: #6b7280;
}

.product-price-request {
  font-size: 16px;
  font-weight: 600;
  color: #059669;
}

.contact-card {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  color: white;
  padding: 48px;
  border-radius: 16px;
  text-align: center;
}

.contact-card h2 {
  font-size: 32px;
  margin: 0 0 12px 0;
}

.contact-card p {
  font-size: 18px;
  margin: 0 0 24px 0;
  opacity: 0.95;
}

.btn-contact-large {
  padding: 16px 32px;
  background: white;
  color: #059669;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-contact-large:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(255, 255, 255, 0.3);
}

.loading-container,
.error-container {
  text-align: center;
  padding: 80px 24px;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #e5e7eb;
  border-top-color: #059669;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

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

.modal-header-content {
  margin-bottom: 24px;
}

.modal-header-content h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.modal-header-content p {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.message-banner {
  margin-bottom: 20px;
  padding: 14px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
}

.message-banner.success {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #86efac;
}

.message-banner.error {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

.quote-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
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

.form-input,
.form-textarea {
  padding: 12px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.2s;
}

.form-input:focus,
.form-textarea:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

.form-textarea {
  resize: vertical;
}

.modal-actions {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

.btn-cancel {
  flex: 1;
  padding: 12px 24px;
  background: transparent;
  color: #6b7280;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel:hover {
  background: #f3f4f6;
}

.btn-submit {
  flex: 2;
  padding: 12px 24px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-submit:hover:not(:disabled) {
  background: #047857;
}

.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .company-main-info {
    grid-template-columns: 1fr;
  }

  .company-logo {
    width: 150px;
    height: 150px;
    margin: 0 auto;
  }

  .company-name {
    font-size: 28px;
    text-align: center;
  }

  .company-meta {
    justify-content: center;
  }

  .products-grid {
    grid-template-columns: 1fr;
  }

  .contact-card {
    padding: 32px 24px;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .modal-actions {
    flex-direction: column;
  }
}
</style>
