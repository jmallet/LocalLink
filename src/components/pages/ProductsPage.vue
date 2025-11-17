<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { user } from '../../stores/auth'
import DashboardLayout from '../dashboard/DashboardLayout.vue'
import type { Company, ProductService } from '../../types/database'

const company = ref<Company | null>(null)
const products = ref<ProductService[]>([])
const loading = ref(true)
const saving = ref(false)
const showForm = ref(false)
const editingProduct = ref<ProductService | null>(null)
const message = ref({ type: '', text: '' })

const formData = ref({
  name: '',
  category: '',
  description: '',
  price: null as number | null,
  unit: '',
  available: true,
  images: [] as string[]
})

const categories = [
  'Alimentation',
  'Matériaux',
  'Services',
  'Équipements',
  'Fournitures',
  'Autre'
]

const newImageUrl = ref('')

const hasCompany = computed(() => !!company.value)

onMounted(async () => {
  await loadData()
})

async function loadData() {
  loading.value = true
  try {
    const { data: companyData } = await supabase
      .from('companies')
      .select('*')
      .eq('user_id', user.value?.id)
      .maybeSingle()

    company.value = companyData

    if (companyData) {
      const { data: productsData } = await supabase
        .from('products_services')
        .select('*')
        .eq('company_id', companyData.id)
        .order('created_at', { ascending: false })

      products.value = productsData || []
    }
  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

function openCreateForm() {
  editingProduct.value = null
  formData.value = {
    name: '',
    category: '',
    description: '',
    price: null,
    unit: '',
    available: true,
    images: []
  }
  showForm.value = true
  message.value = { type: '', text: '' }
}

function openEditForm(product: ProductService) {
  editingProduct.value = product
  formData.value = {
    name: product.name,
    category: product.category,
    description: product.description || '',
    price: product.price || null,
    unit: product.unit || '',
    available: product.available,
    images: [...product.images]
  }
  showForm.value = true
  message.value = { type: '', text: '' }
}

function closeForm() {
  showForm.value = false
  editingProduct.value = null
  message.value = { type: '', text: '' }
}

async function handleSubmit() {
  if (!company.value) return

  message.value = { type: '', text: '' }
  saving.value = true

  try {
    if (editingProduct.value) {
      const { error } = await supabase
        .from('products_services')
        .update({
          name: formData.value.name,
          category: formData.value.category,
          description: formData.value.description,
          price: formData.value.price,
          unit: formData.value.unit,
          available: formData.value.available,
          images: formData.value.images,
          updated_at: new Date().toISOString()
        })
        .eq('id', editingProduct.value.id)

      if (error) throw error

      message.value = {
        type: 'success',
        text: 'Produit mis à jour avec succès !'
      }
    } else {
      const { error } = await supabase
        .from('products_services')
        .insert({
          company_id: company.value.id,
          name: formData.value.name,
          category: formData.value.category,
          description: formData.value.description,
          price: formData.value.price,
          unit: formData.value.unit,
          available: formData.value.available,
          images: formData.value.images
        })

      if (error) throw error

      message.value = {
        type: 'success',
        text: 'Produit créé avec succès !'
      }
    }

    await loadData()
    setTimeout(() => closeForm(), 1500)
  } catch (error: any) {
    message.value = {
      type: 'error',
      text: error.message || 'Une erreur est survenue'
    }
  } finally {
    saving.value = false
  }
}

async function handleDelete(product: ProductService) {
  if (!confirm('Êtes-vous sûr de vouloir supprimer ce produit ?')) return

  try {
    const { error } = await supabase
      .from('products_services')
      .delete()
      .eq('id', product.id)

    if (error) throw error

    await loadData()
  } catch (error) {
    console.error('Error deleting product:', error)
  }
}

function addImage() {
  if (newImageUrl.value && !formData.value.images.includes(newImageUrl.value)) {
    formData.value.images.push(newImageUrl.value)
    newImageUrl.value = ''
  }
}

function removeImage(index: number) {
  formData.value.images.splice(index, 1)
}
</script>

<template>
  <DashboardLayout>
    <div class="products-page">
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Chargement...</p>
      </div>

      <div v-else-if="!hasCompany" class="empty-state">
        <span class="empty-icon">🏢</span>
        <h2>Profil entreprise requis</h2>
        <p>Vous devez d'abord créer votre profil entreprise.</p>
      </div>

      <div v-else class="products-content">
        <div class="products-header">
          <div>
            <h2 class="products-title">Mes produits & services</h2>
            <p class="products-subtitle">{{ products.length }} produit(s)</p>
          </div>
          <button class="btn-create" @click="openCreateForm">
            + Ajouter un produit
          </button>
        </div>

        <div v-if="products.length === 0 && !showForm" class="empty-products">
          <span class="empty-icon">📦</span>
          <h3>Aucun produit</h3>
          <p>Commencez par ajouter vos premiers produits ou services</p>
          <button class="btn-primary" @click="openCreateForm">
            Ajouter mon premier produit
          </button>
        </div>

        <div v-else class="products-grid">
          <div v-for="product in products" :key="product.id" class="product-card">
            <div class="product-image">
              <img
                v-if="product.images.length > 0"
                :src="product.images[0]"
                :alt="product.name"
              />
              <div v-else class="no-image">📦</div>
            </div>
            <div class="product-content">
              <div class="product-header-content">
                <h3 class="product-name">{{ product.name }}</h3>
                <span
                  class="product-status"
                  :class="{ available: product.available, unavailable: !product.available }"
                >
                  {{ product.available ? '🟢 Disponible' : '🔴 Indisponible' }}
                </span>
              </div>
              <p class="product-category">{{ product.category }}</p>
              <p class="product-description">{{ product.description }}</p>
              <div class="product-footer">
                <div v-if="product.price" class="product-price">
                  {{ product.price.toFixed(2) }}€
                  <span v-if="product.unit" class="product-unit">/ {{ product.unit }}</span>
                </div>
                <div v-else class="product-price-request">Sur devis</div>
                <div class="product-actions">
                  <button class="btn-edit" @click="openEditForm(product)">✏️</button>
                  <button class="btn-delete" @click="handleDelete(product)">🗑️</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="showForm" class="modal-overlay" @click="closeForm">
        <div class="modal-content" @click.stop>
          <div class="modal-header">
            <h2>{{ editingProduct ? 'Modifier' : 'Ajouter' }} un produit</h2>
            <button class="close-btn" @click="closeForm">✕</button>
          </div>

          <div v-if="message.text" class="message-banner" :class="message.type">
            {{ message.text }}
          </div>

          <form @submit.prevent="handleSubmit" class="product-form">
            <div class="form-field">
              <label for="name" class="form-label">Nom du produit/service *</label>
              <input
                id="name"
                v-model="formData.name"
                type="text"
                class="form-input"
                required
              />
            </div>

            <div class="form-row">
              <div class="form-field">
                <label for="category" class="form-label">Catégorie *</label>
                <select
                  id="category"
                  v-model="formData.category"
                  class="form-select"
                  required
                >
                  <option value="">Sélectionnez</option>
                  <option v-for="cat in categories" :key="cat" :value="cat">
                    {{ cat }}
                  </option>
                </select>
              </div>

              <div class="form-field">
                <label for="unit" class="form-label">Unité</label>
                <input
                  id="unit"
                  v-model="formData.unit"
                  type="text"
                  class="form-input"
                  placeholder="kg, m², heure..."
                />
              </div>
            </div>

            <div class="form-field">
              <label for="description" class="form-label">Description</label>
              <textarea
                id="description"
                v-model="formData.description"
                class="form-textarea"
                rows="3"
              ></textarea>
            </div>

            <div class="form-field">
              <label for="price" class="form-label">Prix (€)</label>
              <input
                id="price"
                v-model.number="formData.price"
                type="number"
                step="0.01"
                min="0"
                class="form-input"
                placeholder="Laissez vide pour 'Sur devis'"
              />
            </div>

            <div class="form-field">
              <label class="form-label">Images</label>
              <div class="images-container">
                <div v-if="formData.images.length > 0" class="images-list">
                  <div v-for="(img, index) in formData.images" :key="index" class="image-item">
                    <img :src="img" :alt="`Image ${index + 1}`" />
                    <button type="button" @click="removeImage(index)" class="remove-image">✕</button>
                  </div>
                </div>
                <div class="add-image">
                  <input
                    v-model="newImageUrl"
                    type="url"
                    class="form-input"
                    placeholder="URL de l'image..."
                  />
                  <button type="button" @click="addImage" class="btn-add-image">+</button>
                </div>
              </div>
            </div>

            <div class="form-field-checkbox">
              <input
                id="available"
                v-model="formData.available"
                type="checkbox"
                class="form-checkbox"
              />
              <label for="available" class="checkbox-label">
                Produit disponible
              </label>
            </div>

            <div class="form-actions">
              <button type="button" class="btn-cancel" @click="closeForm">
                Annuler
              </button>
              <button type="submit" class="btn-submit" :disabled="saving">
                {{ saving ? 'Enregistrement...' : 'Enregistrer' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.products-page {
  max-width: 1400px;
  margin: 0 auto;
}

.loading-container {
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

.empty-state {
  text-align: center;
  padding: 80px 24px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.empty-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 24px;
}

.empty-state h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

.products-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
}

.products-title {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 4px 0;
}

.products-subtitle {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.btn-create {
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

.btn-create:hover {
  background: #047857;
  transform: translateY(-1px);
}

.empty-products {
  text-align: center;
  padding: 80px 24px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.empty-products h3 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-products p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 24px 0;
}

.btn-primary {
  padding: 14px 28px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #047857;
  transform: translateY(-1px);
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
  display: flex;
  align-items: center;
  justify-content: center;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.no-image {
  font-size: 48px;
}

.product-content {
  padding: 20px;
}

.product-header-content {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 8px;
}

.product-name {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0;
  flex: 1;
}

.product-status {
  font-size: 12px;
  font-weight: 600;
  padding: 4px 8px;
  border-radius: 12px;
}

.product-status.available {
  background: #d1fae5;
  color: #065f46;
}

.product-status.unavailable {
  background: #fee2e2;
  color: #991b1b;
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
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.product-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid #e5e7eb;
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

.product-actions {
  display: flex;
  gap: 8px;
}

.btn-edit,
.btn-delete {
  padding: 8px 12px;
  background: #f3f4f6;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-edit:hover {
  background: #d1fae5;
}

.btn-delete:hover {
  background: #fee2e2;
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
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
}

.modal-header {
  padding: 24px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h2 {
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

.message-banner {
  margin: 16px 24px;
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

.product-form {
  padding: 24px;
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
  margin-bottom: 16px;
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

.images-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.images-list {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.image-item {
  position: relative;
  width: 100px;
  height: 100px;
  border-radius: 8px;
  overflow: hidden;
}

.image-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.remove-image {
  position: absolute;
  top: 4px;
  right: 4px;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  border: none;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
}

.add-image {
  display: flex;
  gap: 8px;
}

.btn-add-image {
  padding: 12px 20px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-add-image:hover {
  background: #047857;
}

.form-field-checkbox {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}

.form-checkbox {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.checkbox-label {
  font-size: 14px;
  color: #374151;
  cursor: pointer;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  padding-top: 16px;
  border-top: 1px solid #e5e7eb;
}

.btn-cancel {
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
  .products-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .btn-create {
    width: 100%;
  }

  .products-grid {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
