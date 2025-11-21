<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()
const currentYear = new Date().getFullYear()
</script>

<template>
  <footer class="footer">
    <div class="footer-content">
      <div class="footer-grid">
        <div class="footer-section">
          <div class="footer-brand">
            <span class="logo-icon">🏪</span>
            <span class="logo-text">LocalLink</span>
          </div>
          <p class="footer-description">
            La plateforme qui connecte les entreprises locales pour favoriser
            le circuit court et l'économie régionale.
          </p>
        </div>

        <div class="footer-section">
          <h3 class="footer-title">Navigation</h3>
          <ul class="footer-links">
            <li><a @click.prevent="router.push({ name: 'home' })" href="#">Accueil</a></li>
            <li><a @click.prevent="router.push({ name: 'pros-locaux' })" href="#">Pros locaux</a></li>
            <li><a @click.prevent="router.push({ name: 'about' })" href="#">À propos</a></li>
            <li><a @click.prevent="router.push({ name: 'blog' })" href="#">Blog</a></li>
            <li><a @click.prevent="router.push({ name: 'contact' })" href="#">Contact</a></li>
          </ul>
        </div>

        <div class="footer-section">
          <h3 class="footer-title">Entreprises</h3>
          <ul class="footer-links">
            <li><a @click.prevent="router.push({ name: 'login' })" href="#">Créer un compte</a></li>
            <li><a @click.prevent="router.push({ name: 'login' })" href="#">Se connecter</a></li>
            <li><a @click.prevent="router.push({ name: 'dashboard' })" href="#">Dashboard</a></li>
            <li><a href="#">Tarifs</a></li>
          </ul>
        </div>

        <div class="footer-section">
          <h3 class="footer-title">Légal</h3>
          <ul class="footer-links">
            <li><a href="#">Mentions légales</a></li>
            <li><a href="#">Politique de confidentialité</a></li>
            <li><a href="#">CGU</a></li>
            <li><a href="#">CGV</a></li>
          </ul>
        </div>
      </div>
    </div>

    <div class="footer-bottom">
      <div class="footer-content">
        <div class="footer-bottom-content">
          <p class="copyright">
            © {{ currentYear }} LocalLink. Tous droits réservés.
          </p>
          <div class="social-links">
            <a href="#" class="social-link" aria-label="LinkedIn">in</a>
            <a href="#" class="social-link" aria-label="Twitter">𝕏</a>
            <a href="#" class="social-link" aria-label="Facebook">f</a>
          </div>
        </div>
      </div>
    </div>
  </footer>
</template>

<style scoped>
.footer {
  background: #111827;
  color: #e5e7eb;
  margin-top: auto;
}

.footer-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 24px;
}

.footer-grid {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  gap: 48px;
  padding: 64px 0 48px;
}

.footer-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.footer-brand {
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 700;
  font-size: 24px;
  margin-bottom: 8px;
}

.logo-icon {
  font-size: 28px;
}

.footer-description {
  font-size: 15px;
  line-height: 1.6;
  color: #9ca3af;
  margin: 0;
  max-width: 300px;
}

.footer-title {
  font-size: 16px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 8px 0;
}

.footer-links {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.footer-links a {
  color: #9ca3af;
  text-decoration: none;
  font-size: 14px;
  transition: color 0.2s;
  cursor: pointer;
}

.footer-links a:hover {
  color: #059669;
}

.footer-bottom {
  border-top: 1px solid #374151;
}

.footer-bottom-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 0;
}

.copyright {
  font-size: 14px;
  color: #9ca3af;
  margin: 0;
}

.social-links {
  display: flex;
  gap: 12px;
}

.social-link {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #374151;
  color: #e5e7eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 14px;
  text-decoration: none;
  transition: all 0.2s;
}

.social-link:hover {
  background: #059669;
  color: white;
}

@media (max-width: 1024px) {
  .footer-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 32px;
  }
}

@media (max-width: 640px) {
  .footer-grid {
    grid-template-columns: 1fr;
    gap: 32px;
    padding: 48px 0 32px;
  }

  .footer-bottom-content {
    flex-direction: column;
    gap: 16px;
    text-align: center;
  }
}
</style>
