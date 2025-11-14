<template>
  <section class="about-page">
    <div class="about-container">
      <div class="about-header">
        <h1 class="about-title">À propos de LocalLink</h1>
        <p class="about-subtitle">
          La plateforme qui connecte les professionnels locaux
        </p>
      </div>

      <div class="about-content">
        <div class="mission-section">
          <h2>Notre mission</h2>
          <p>
            LocalLink est née d'une conviction simple : les entreprises locales ont besoin de se connecter entre elles pour prospérer. Notre plateforme facilite les rencontres B2B entre professionnels de la même région, qu'il s'agisse de restaurants cherchant des producteurs locaux, de traiteurs recherchant des fournisseurs de qualité, ou de commerces souhaitant développer leurs partenariats.
          </p>
        </div>

        <div class="values-section">
          <h2>Nos valeurs</h2>
          <div class="values-grid">
            <div class="value-card">
              <div class="value-icon">🤝</div>
              <h3>Proximité</h3>
              <p>Nous favorisons les échanges entre entreprises d'un même territoire pour créer un écosystème local dynamique.</p>
            </div>
            <div class="value-card">
              <div class="value-icon">✓</div>
              <h3>Confiance</h3>
              <p>Tous nos professionnels sont vérifiés pour garantir des partenariats fiables et sécurisés.</p>
            </div>
            <div class="value-card">
              <div class="value-icon">🌱</div>
              <h3>Durabilité</h3>
              <p>En privilégiant les circuits courts, nous contribuons à une économie plus responsable et durable.</p>
            </div>
          </div>
        </div>

        <div class="story-section">
          <h2>Comment ça marche ?</h2>
          <div class="steps">
            <div class="step">
              <div class="step-number">1</div>
              <div class="step-content">
                <h3>Créez votre profil</h3>
                <p>Inscrivez votre entreprise et décrivez vos besoins ou vos services.</p>
              </div>
            </div>
            <div class="step">
              <div class="step-number">2</div>
              <div class="step-content">
                <h3>Découvrez des partenaires</h3>
                <p>Explorez les entreprises locales qui correspondent à vos critères.</p>
              </div>
            </div>
            <div class="step">
              <div class="step-number">3</div>
              <div class="step-content">
                <h3>Connectez-vous</h3>
                <p>Entrez en contact directement via notre plateforme sécurisée.</p>
              </div>
            </div>
          </div>
        </div>

        <div class="contact-section">
          <h2>Nous contacter</h2>
          <p>
            Vous avez des questions ou souhaitez en savoir plus ? N'hésitez pas à nous contacter.
          </p>
          <div class="contact-info">
            <div class="contact-item">
              <span class="contact-icon">📧</span>
              <span>contact@locallink.fr</span>
            </div>
            <div class="contact-item">
              <span class="contact-icon">📞</span>
              <span>01 23 45 67 89</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.about-page {
  min-height: calc(100vh - 72px);
  background: #f9fafb;
  padding: 80px 24px;
}

.about-container {
  max-width: 1200px;
  margin: 0 auto;
}

.about-header {
  text-align: center;
  margin-bottom: 64px;
}

.about-title {
  font-size: 48px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
}

.about-subtitle {
  font-size: 20px;
  color: #6b7280;
  margin: 0;
}

.about-content {
  display: flex;
  flex-direction: column;
  gap: 64px;
}

.mission-section,
.story-section,
.contact-section {
  background: white;
  padding: 48px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.mission-section h2,
.values-section h2,
.story-section h2,
.contact-section h2 {
  font-size: 32px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 24px 0;
}

.mission-section p,
.story-section p,
.contact-section p {
  font-size: 18px;
  line-height: 1.8;
  color: #4b5563;
  margin: 0;
}

.values-section {
  background: white;
  padding: 48px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.values-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
  margin-top: 32px;
}

.value-card {
  text-align: center;
}

.value-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.value-card h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.value-card p {
  font-size: 16px;
  line-height: 1.6;
  color: #6b7280;
  margin: 0;
}

.steps {
  display: flex;
  flex-direction: column;
  gap: 32px;
  margin-top: 32px;
}

.step {
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

.step-number {
  width: 56px;
  height: 56px;
  background: #059669;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: 700;
  flex-shrink: 0;
}

.step-content h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 8px 0;
}

.step-content p {
  font-size: 16px;
  line-height: 1.6;
  color: #6b7280;
  margin: 0;
}

.contact-info {
  display: flex;
  gap: 32px;
  margin-top: 24px;
}

.contact-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 16px;
  color: #374151;
}

.contact-icon {
  font-size: 24px;
}

@media (max-width: 968px) {
  .about-page {
    padding: 48px 24px;
  }

  .about-title {
    font-size: 36px;
  }

  .about-subtitle {
    font-size: 18px;
  }

  .mission-section,
  .values-section,
  .story-section,
  .contact-section {
    padding: 32px 24px;
  }

  .values-grid {
    grid-template-columns: 1fr;
    gap: 32px;
  }

  .contact-info {
    flex-direction: column;
    gap: 16px;
  }
}
</style>
