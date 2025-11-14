<template>
  <section class="hero">
    <div class="hero-container">
      <div class="hero-content">
        <h1 class="hero-title">
          Connectez-vous avec des<br />
          <span class="highlight">entreprises locales</span>
        </h1>
        <p class="hero-description">
          LocalLink facilite les partenariats B2B entre entreprises locales.
          Trouvez des fournisseurs, producteurs et prestataires de confiance près de chez vous.
        </p>
        <div class="hero-stats">
          <div class="stat">
            <div class="stat-number">500+</div>
            <div class="stat-label">Entreprises</div>
          </div>
          <div class="stat">
            <div class="stat-number">1200+</div>
            <div class="stat-label">Connexions</div>
          </div>
          <div class="stat">
            <div class="stat-number">95%</div>
            <div class="stat-label">Satisfaction</div>
          </div>
        </div>
      </div>
      <div class="hero-image">
        <img src="https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg?auto=compress&cs=tinysrgb&w=1200" alt="Entreprises locales" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.hero {
  background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%);
  padding: 80px 24px;
}

.hero-container {
  max-width: 1400px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 64px;
  align-items: center;
}

.hero-content {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.hero-title {
  font-size: 52px;
  font-weight: 800;
  line-height: 1.2;
  color: #111827;
  margin: 0;
}

.highlight {
  color: #059669;
  position: relative;
}

.hero-description {
  font-size: 18px;
  line-height: 1.8;
  color: #4b5563;
  margin: 0;
}

.hero-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
  padding-top: 16px;
}

.stat {
  text-align: left;
}

.stat-number {
  font-size: 36px;
  font-weight: 800;
  color: #059669;
  line-height: 1;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #6b7280;
  font-weight: 500;
}

.hero-image {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.12);
}

.hero-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

@media (max-width: 968px) {
  .hero {
    padding: 48px 24px;
  }

  .hero-container {
    grid-template-columns: 1fr;
    gap: 40px;
  }

  .hero-title {
    font-size: 36px;
  }

  .hero-description {
    font-size: 16px;
  }

  .hero-stats {
    gap: 24px;
  }

  .stat-number {
    font-size: 28px;
  }
}
</style>
