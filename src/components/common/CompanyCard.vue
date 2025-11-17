<script setup lang="ts">
import type { Company } from '../../types/database'

defineProps<{
  company: Company
  featured?: boolean
}>()

const emit = defineEmits<{
  (e: 'click'): void
  (e: 'contact'): void
}>()
</script>

<template>
  <div class="company-card" :class="{ featured }" @click="emit('click')">
    <div v-if="featured" class="featured-badge">
      ⭐ Mis en avant
    </div>

    <div class="company-image">
      <img
        :src="company.logo_url || 'https://images.pexels.com/photos/6802042/pexels-photo-6802042.jpeg'"
        :alt="company.company_name"
      />
    </div>

    <div class="company-content">
      <h3 class="company-name">{{ company.company_name }}</h3>

      <div class="company-category">
        <span class="category-badge">{{ company.category }}</span>
      </div>

      <p class="company-description">
        {{ company.description?.substring(0, 120) }}{{ company.description && company.description.length > 120 ? '...' : '' }}
      </p>

      <div class="company-location">
        <span class="location-icon">📍</span>
        {{ company.city }}, {{ company.postal_code }}
      </div>

      <div class="company-tags">
        <span v-for="tag in company.tags.slice(0, 3)" :key="tag" class="tag">
          {{ tag }}
        </span>
      </div>

      <button
        class="btn-contact"
        @click.stop="emit('contact')"
      >
        Contacter
      </button>
    </div>
  </div>
</template>

<style scoped>
.company-card {
  background: white;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
  cursor: pointer;
  position: relative;
}

.company-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.company-card.featured {
  border: 2px solid #fbbf24;
}

.featured-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  background: #fbbf24;
  color: #78350f;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 700;
  z-index: 10;
}

.company-image {
  width: 100%;
  height: 200px;
  overflow: hidden;
  background: #f3f4f6;
}

.company-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.company-content {
  padding: 20px;
}

.company-name {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.company-category {
  margin-bottom: 12px;
}

.category-badge {
  display: inline-block;
  background: #e0f2fe;
  color: #075985;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 13px;
  font-weight: 600;
}

.company-description {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 12px 0;
}

.company-location {
  font-size: 14px;
  color: #6b7280;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.location-icon {
  font-size: 16px;
}

.company-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

.tag {
  background: #f3f4f6;
  color: #374151;
  padding: 4px 10px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
}

.btn-contact {
  width: 100%;
  padding: 12px;
  background: #059669;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-contact:hover {
  background: #047857;
  transform: translateY(-1px);
}
</style>
