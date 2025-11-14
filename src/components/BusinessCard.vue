<script setup lang="ts">
import type { Business } from '../types'

defineProps<{
  business: Business
}>()

const emit = defineEmits<{
  (e: 'contact', business: Business): void
}>()

const handleContact = (business: Business) => {
  emit('contact', business)
}
</script>

<template>
  <div class="business-card">
    <div class="card-image">
      <img :src="business.image" :alt="business.name" />
      <div v-if="business.verified" class="verified-badge">
        <span>✓</span> Vérifié
      </div>
    </div>

    <div class="card-content">
      <div class="card-header">
        <h3 class="business-name">{{ business.name }}</h3>
        <div class="distance">📍 {{ business.distance }} km</div>
      </div>

      <p class="business-description">{{ business.description }}</p>

      <div class="business-tags">
        <span v-for="tag in business.tags" :key="tag" class="tag">
          {{ tag }}
        </span>
      </div>

      <div class="card-footer">
        <div class="location-info">
          <span class="location-icon">📍</span>
          <span>{{ business.location }}</span>
        </div>
        <button @click="handleContact(business)" class="contact-btn">
          Contacter
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.business-card {
  background: white;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
  border: 1px solid #e5e7eb;
}

.business-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.12);
}

.card-image {
  position: relative;
  width: 100%;
  height: 200px;
  overflow: hidden;
}

.card-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s;
}

.business-card:hover .card-image img {
  transform: scale(1.05);
}

.verified-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  background: #059669;
  color: white;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 4px;
}

.card-content {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.business-name {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0;
  line-height: 1.3;
}

.distance {
  background: #f3f4f6;
  padding: 4px 10px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #374151;
  white-space: nowrap;
}

.business-description {
  font-size: 14px;
  line-height: 1.6;
  color: #6b7280;
  margin: 0;
}

.business-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag {
  background: #f0fdf4;
  color: #059669;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding-top: 8px;
  border-top: 1px solid #e5e7eb;
}

.location-info {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #6b7280;
}

.location-icon {
  font-size: 14px;
}

.contact-btn {
  background: #059669;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.contact-btn:hover {
  background: #047857;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);
}

@media (max-width: 480px) {
  .card-footer {
    flex-direction: column;
    align-items: stretch;
  }

  .contact-btn {
    width: 100%;
  }
}
</style>
