<script setup lang="ts">
import { ref } from 'vue'
import type { Category } from '../types'

const emit = defineEmits<{
  (e: 'update:search', value: string): void
  (e: 'update:category', value: Category): void
}>()

const searchQuery = ref('')
const selectedCategory = ref<Category>('all')

const categories = [
  { value: 'all', label: 'Toutes', icon: '🏪' },
  { value: 'producer', label: 'Producteurs', icon: '🌾' },
  { value: 'restaurant', label: 'Restaurants', icon: '🍽️' },
  { value: 'caterer', label: 'Traiteurs', icon: '🎉' },
  { value: 'retailer', label: 'Commerçants', icon: '🏬' },
  { value: 'service', label: 'Services', icon: '🚚' }
]

const handleSearch = () => {
  emit('update:search', searchQuery.value)
}

const handleCategoryChange = (category: Category) => {
  selectedCategory.value = category
  emit('update:category', category)
}
</script>

<template>
  <div class="filters-container">
    <div class="search-box">
      <span class="search-icon">🔍</span>
      <input
        v-model="searchQuery"
        @input="handleSearch"
        type="text"
        placeholder="Rechercher une entreprise, un produit..."
        class="search-input"
      />
    </div>

    <div class="category-filters">
      <button
        v-for="category in categories"
        :key="category.value"
        @click="handleCategoryChange(category.value as Category)"
        :class="['category-btn', { active: selectedCategory === category.value }]"
      >
        <span class="category-icon">{{ category.icon }}</span>
        <span>{{ category.label }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.filters-container {
  max-width: 1400px;
  margin: -40px auto 48px;
  padding: 0 24px;
  position: relative;
  z-index: 10;
}

.search-box {
  background: white;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  padding: 16px 24px;
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
  transition: box-shadow 0.2s;
}

.search-box:focus-within {
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.16);
}

.search-icon {
  font-size: 20px;
}

.search-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 16px;
  color: #111827;
  background: transparent;
}

.search-input::placeholder {
  color: #9ca3af;
}

.category-filters {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.category-btn {
  background: white;
  border: 2px solid #e5e7eb;
  padding: 12px 20px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}

.category-btn:hover {
  border-color: #059669;
  background: #f0fdf4;
  transform: translateY(-2px);
}

.category-btn.active {
  background: #059669;
  border-color: #059669;
  color: white;
}

.category-icon {
  font-size: 18px;
}

@media (max-width: 768px) {
  .filters-container {
    margin: -32px auto 32px;
  }

  .search-box {
    padding: 12px 16px;
  }

  .category-filters {
    gap: 8px;
  }

  .category-btn {
    padding: 10px 16px;
    font-size: 13px;
  }
}
</style>
