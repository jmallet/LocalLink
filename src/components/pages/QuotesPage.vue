<script setup lang="ts">
import DashboardLayout from '../dashboard/DashboardLayout.vue'
</script>

<template>
  <DashboardLayout>
    <div class="quotes-page">
      <div class="coming-soon">
        <span class="icon">📋</span>
        <h2>Demandes de devis</h2>
        <p>Cette fonctionnalité sera bientôt disponible.</p>
        <p class="description">
          Vous pourrez consulter toutes les demandes de devis que vous avez reçues
          et y répondre directement.
        </p>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.quotes-page {
  max-width: 1200px;
  margin: 0 auto;
}

.coming-soon {
  background: white;
  padding: 80px 40px;
  border-radius: 16px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.icon {
  font-size: 64px;
  display: block;
  margin-bottom: 24px;
}

.coming-soon h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 16px 0;
}

.coming-soon p {
  font-size: 16px;
  color: #6b7280;
  margin: 0 0 12px 0;
}

.description {
  max-width: 500px;
  margin: 16px auto 0;
  line-height: 1.6;
}
</style>
