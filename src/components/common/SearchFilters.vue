<script setup lang="ts">
import { ref } from 'vue'

const emit = defineEmits<{
  (e: 'update:search', value: string): void
  (e: 'update:category', value: string): void
  (e: 'update:city', value: string): void
}>()

const searchQuery = ref('')
const selectedCategory = ref('all')
const selectedCity = ref('all')

const categories = [
  { value: 'all', label: 'Toutes catégories' },
  { value: 'Agriculture & Alimentation', label: 'Agriculture & Alimentation' },
  { value: 'Construction & Rénovation', label: 'Construction & Rénovation' },
  { value: 'Services aux entreprises', label: 'Services aux entreprises' },
  { value: 'Transport & Logistique', label: 'Transport & Logistique' },
]

const cities = [
  { value: 'all', label: 'Toutes villes' },
  { value: 'Lyon', label: 'Lyon' },
  { value: 'Annecy', label: 'Annecy' },
]

function handleSearch() {
  emit('update:search', searchQuery.value)
}

function handleCategoryChange() {
  emit('update:category', selectedCategory.value)
}

function handleCityChange() {
  emit('update:city', selectedCity.value)
}
</script>

<template>
  <div class="search-filters">
    <div class="filters-container">
      <div class="search-box">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Rechercher une entreprise, un produit..."
          class="search-input"
          @input="handleSearch"
        />
        <span class="search-icon">🔍</span>
      </div>

      <div class="filter-group">
        <select
          v-model="selectedCategory"
          class="filter-select"
          @change="handleCategoryChange"
        >
          <option v-for="cat in categories" :key="cat.value" :value="cat.value">
            {{ cat.label }}
          </option>
        </select>
      </div>

      <div class="filter-group">
        <select
          v-model="selectedCity"
          class="filter-select"
          @change="handleCityChange"
        >
          <option v-for="city in cities" :key="city.value" :value="city.value">
            {{ city.label }}
          </option>
        </select>
      </div>
    </div>
  </div>
</template>

<style scoped>
.search-filters {
  background: white;
  border-bottom: 1px solid #e5e7eb;
  padding: 24px;
}

.filters-container {
  max-width: 1400px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 16px;
  align-items: center;
}

.search-box {
  position: relative;
}

.search-input {
  width: 100%;
  padding: 12px 48px 12px 16px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 15px;
  font-family: inherit;
  transition: all 0.2s;
}

.search-input:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

.search-icon {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 20px;
  pointer-events: none;
}

.filter-group {
  min-width: 200px;
}

.filter-select {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 15px;
  font-family: inherit;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-select:focus {
  outline: none;
  border-color: #059669;
  box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.1);
}

@media (max-width: 768px) {
  .filters-container {
    grid-template-columns: 1fr;
  }

  .search-filters {
    padding: 16px;
  }
}
</style>
