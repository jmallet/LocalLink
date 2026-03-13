<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()
</script>

<template>
  <div class="about-page">
    <section class="hero">
      <div class="container">
        <h1 class="hero-title">À propos de Porte à Pro</h1>
        <p class="hero-subtitle">
          Nous mettons en relation particuliers et professionnels locaux
          pour un service de proximité et de qualité
        </p>
      </div>
    </section>

    <section class="mission">
      <div class="container">
        <div class="mission-content">
          <div class="mission-text">
            <h2 class="section-title">Notre mission</h2>
            <p>
              Porte à Pro est née d'un constat simple : trouver le bon professionnel près de chez soi
              peut être compliqué et chronophage. Nous simplifions cette recherche.
            </p>
            <p>
              Notre plateforme met en relation particuliers et professionnels locaux vérifiés.
              Déposez votre demande en 2 minutes et recevez des devis de pros qualifiés de votre quartier,
              ou parcourez directement notre annuaire pour trouver le professionnel qu'il vous faut.
            </p>
            <p>
              En favorisant les échanges de proximité, nous contribuons à dynamiser l'économie locale,
              créer de l'emploi dans les territoires et tisser des liens durables entre habitants
              et professionnels d'un même quartier.
            </p>
          </div>
          <div class="mission-image">
            <img
              src="https://images.pexels.com/photos/3184398/pexels-photo-3184398.jpeg"
              alt="Équipe Porte à Pro"
            />
          </div>
        </div>
      </div>
    </section>

    <section class="values">
      <div class="container">
        <h2 class="section-title-center">Nos valeurs</h2>

        <div class="values-grid">
          <div class="value-card">
            <span class="value-icon">🌱</span>
            <h3>Circuit court</h3>
            <p>
              Nous croyons au pouvoir des échanges locaux pour créer une économie
              plus durable et résiliente.
            </p>
          </div>

          <div class="value-card">
            <span class="value-icon">🤝</span>
            <h3>Confiance</h3>
            <p>
              Toutes les entreprises sont vérifiées. Nous garantissons la qualité
              et la fiabilité de notre réseau.
            </p>
          </div>

          <div class="value-card">
            <span class="value-icon">⚡</span>
            <h3>Simplicité</h3>
            <p>
              Nous rendons la mise en relation simple et rapide. Trouvez vos partenaires
              en quelques clics.
            </p>
          </div>

          <div class="value-card">
            <span class="value-icon">💪</span>
            <h3>Économie locale</h3>
            <p>
              Chaque transaction sur notre plateforme renforce le tissu économique
              des territoires.
            </p>
          </div>
        </div>
      </div>
    </section>

    <section class="how-it-works">
      <div class="container">
        <h2 class="section-title-center">Comment ça marche ?</h2>

        <div class="steps-grid">
          <div class="step">
            <div class="step-number">1</div>
            <h3>Déposez votre demande</h3>
            <p>
              En 2 minutes, décrivez votre besoin et recevez des devis
              de professionnels locaux vérifiés.
            </p>
          </div>

          <div class="step">
            <div class="step-number">2</div>
            <h3>Parcourez l'annuaire</h3>
            <p>
              Explorez notre annuaire de professionnels du quartier.
              Filtrez par catégorie et localisation.
            </p>
          </div>

          <div class="step">
            <div class="step-number">3</div>
            <h3>Comparez les devis</h3>
            <p>
              Recevez plusieurs propositions et choisissez le professionnel
              qui correspond le mieux à vos besoins.
            </p>
          </div>

          <div class="step">
            <div class="step-number">4</div>
            <h3>Profitez du service</h3>
            <p>
              Bénéficiez d'un service de proximité et de qualité.
              Faites appel aux meilleurs pros de votre quartier.
            </p>
          </div>
        </div>
      </div>
    </section>

    <section class="stats">
      <div class="container">
        <div class="stats-grid">
          <div class="stat">
            <div class="stat-number">340</div>
            <div class="stat-label">Pros locaux actifs</div>
          </div>
          <div class="stat">
            <div class="stat-number">1240</div>
            <div class="stat-label">Demandes ce mois</div>
          </div>
          <div class="stat">
            <div class="stat-number">4.8★</div>
            <div class="stat-label">Satisfaction moyenne</div>
          </div>
          <div class="stat">
            <div class="stat-number">100%</div>
            <div class="stat-label">Professionnels vérifiés</div>
          </div>
        </div>
      </div>
    </section>

    <section class="cta">
      <div class="container">
        <div class="cta-card">
          <h2>Prêt à rejoindre Porte à Pro ?</h2>
          <p>
            Trouvez le bon professionnel près de chez vous ou développez votre activité
            en tant que pro local. Rejoignez-nous gratuitement.
          </p>
          <button class="btn-cta" @click="router.push({ name: 'login' })">
            Créer mon compte gratuitement
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.about-page {
  min-height: 100vh;
  background: #f9fafb;
}

.hero {
  background: linear-gradient(135deg, #ea580c 0%, #dc2626 100%);
  color: white;
  padding: 80px 24px;
  text-align: center;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.hero-title {
  font-size: 56px;
  font-weight: 800;
  margin: 0 0 24px 0;
}

.hero-subtitle {
  font-size: 24px;
  line-height: 1.6;
  margin: 0;
  opacity: 0.95;
  max-width: 800px;
  margin: 0 auto;
}

.mission {
  padding: 80px 24px;
  background: white;
}

.mission-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 60px;
  align-items: center;
}

.mission-text {
  font-size: 18px;
  line-height: 1.8;
  color: #374151;
}

.section-title {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 24px 0;
}

.section-title-center {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 48px 0;
  text-align: center;
}

.mission-text p {
  margin-bottom: 20px;
}

.mission-image {
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.mission-image img {
  width: 100%;
  height: auto;
  display: block;
}

.values {
  padding: 80px 24px;
  background: #f9fafb;
}

.values-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 32px;
}

.value-card {
  background: white;
  padding: 32px;
  border-radius: 16px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
}

.value-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.value-icon {
  font-size: 48px;
  display: block;
  margin-bottom: 16px;
}

.value-card h3 {
  font-size: 22px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.value-card p {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
}

.how-it-works {
  padding: 80px 24px;
  background: white;
}

.steps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 32px;
}

.step {
  text-align: center;
}

.step-number {
  width: 64px;
  height: 64px;
  background: #ea580c;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: 700;
  margin: 0 auto 20px;
}

.step h3 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.step p {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0;
}

.stats {
  padding: 80px 24px;
  background: linear-gradient(135deg, #ea580c 0%, #dc2626 100%);
  color: white;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 48px;
}

.stat {
  text-align: center;
}

.stat-number {
  font-size: 56px;
  font-weight: 800;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 18px;
  opacity: 0.95;
}

.cta {
  padding: 80px 24px;
  background: #f9fafb;
}

.cta-card {
  background: white;
  padding: 64px;
  border-radius: 24px;
  text-align: center;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.cta-card h2 {
  font-size: 36px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
}

.cta-card p {
  font-size: 18px;
  color: #6b7280;
  margin: 0 0 32px 0;
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
}

.btn-cta {
  padding: 16px 32px;
  background: #ea580c;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cta:hover {
  background: #dc2626;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(234, 88, 12, 0.3);
}

@media (max-width: 768px) {
  .hero {
    padding: 60px 24px;
  }

  .hero-title {
    font-size: 36px;
  }

  .hero-subtitle {
    font-size: 18px;
  }

  .mission-content {
    grid-template-columns: 1fr;
    gap: 40px;
  }

  .mission-text {
    font-size: 16px;
  }

  .section-title,
  .section-title-center {
    font-size: 28px;
  }

  .values,
  .how-it-works,
  .stats,
  .cta {
    padding: 48px 16px;
  }

  .cta-card {
    padding: 40px 24px;
  }

  .cta-card h2 {
    font-size: 28px;
  }

  .stats-grid {
    gap: 32px;
  }

  .stat-number {
    font-size: 42px;
  }
}
</style>
