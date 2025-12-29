import { createRouter, createWebHistory } from 'vue-router'
import { isAuthenticated, isAdmin, loading as authLoading, user } from '../stores/auth'
import { supabase } from '../lib/supabase'
import HomePage from '../components/pages/HomePage.vue'
import ProsLocauxPage from '../components/pages/ProsLocauxPage.vue'
import CompanyDetailPage from '../components/pages/CompanyDetailPage.vue'
import BlogPage from '../components/pages/BlogPage.vue'
import BlogPostPage from '../components/pages/BlogPostPage.vue'
import AboutPage from '../components/pages/AboutPage.vue'
import ContactPage from '../components/pages/ContactPage.vue'
import DashboardPage from '../components/pages/DashboardPage.vue'
import ProfilePage from '../components/pages/ProfilePage.vue'
import ProductsPage from '../components/pages/ProductsPage.vue'
import QuotesPage from '../components/pages/QuotesPage.vue'
import VisibilityPage from '../components/pages/VisibilityPage.vue'
import AdminPage from '../components/pages/AdminPage.vue'
import IndividualProfilePage from '../components/pages/IndividualProfilePage.vue'
import IndividualQuotesListPage from '../components/pages/IndividualQuotesListPage.vue'
import IndividualNewQuotePage from '../components/pages/IndividualNewQuotePage.vue'
import IndividualQuoteDetailPage from '../components/pages/IndividualQuoteDetailPage.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomePage,
      meta: {
        title: 'LocalLink - Trouvez les meilleurs professionnels locaux',
        description: 'Découvrez et contactez facilement les entreprises de confiance près de chez vous. LocalLink met en relation acheteurs et professionnels locaux qualifiés.'
      }
    },
    {
      path: '/pros-locaux',
      name: 'pros-locaux',
      component: ProsLocauxPage,
      meta: {
        title: 'Tous les professionnels locaux - LocalLink',
        description: 'Parcourez notre liste complète de professionnels locaux qualifiés. Filtrez par catégorie et ville pour trouver le prestataire idéal.'
      }
    },
    {
      path: '/entreprise/:id',
      name: 'company-detail',
      component: CompanyDetailPage,
      meta: {
        title: 'Détails de l\'entreprise - LocalLink',
        description: 'Découvrez les produits, services et informations complètes de cette entreprise locale.'
      }
    },
    {
      path: '/blog',
      name: 'blog',
      component: BlogPage,
      meta: {
        title: 'Blog - Actualités et conseils - LocalLink',
        description: 'Retrouvez nos derniers articles, conseils et actualités sur les professionnels locaux et les meilleures pratiques.'
      }
    },
    {
      path: '/blog/:slug',
      name: 'blog-post',
      component: BlogPostPage,
      meta: {
        title: 'Article - LocalLink',
        description: 'Lisez nos articles détaillés et conseils d\'experts.'
      }
    },
    {
      path: '/a-propos',
      name: 'about',
      component: AboutPage,
      meta: {
        title: 'À propos - LocalLink',
        description: 'Découvrez LocalLink, la plateforme qui met en relation les acheteurs avec les meilleurs professionnels locaux de confiance.'
      }
    },
    {
      path: '/contact',
      name: 'contact',
      component: ContactPage,
      meta: {
        title: 'Contactez-nous - LocalLink',
        description: 'Une question ? Besoin d\'aide ? Contactez notre équipe via notre formulaire ou consultez notre FAQ.'
      }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: DashboardPage,
      meta: {
        title: 'Tableau de bord - LocalLink',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/profil',
      name: 'dashboard-profile',
      component: ProfilePage,
      meta: {
        title: 'Mon profil - LocalLink',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/produits',
      name: 'dashboard-products',
      component: ProductsPage,
      meta: {
        title: 'Mes produits et services - LocalLink',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/devis',
      name: 'dashboard-quotes',
      component: QuotesPage,
      meta: {
        title: 'Mes demandes de devis - LocalLink',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/visibilite',
      name: 'dashboard-visibility',
      component: VisibilityPage,
      meta: {
        title: 'Ma visibilité - LocalLink',
        requiresAuth: true
      }
    },
    {
      path: '/admin',
      name: 'admin',
      component: AdminPage,
      meta: {
        title: 'Administration - LocalLink',
        requiresAuth: true,
        requiresAdmin: true
      }
    },
    {
      path: '/particulier/profil',
      name: 'individual-profile',
      component: IndividualProfilePage,
      meta: {
        title: 'Mon profil - LocalLink',
        requiresAuth: true,
        requiresIndividual: true
      }
    },
    {
      path: '/particulier/devis',
      name: 'individual-quotes',
      component: IndividualQuotesListPage,
      meta: {
        title: 'Mes demandes de devis - LocalLink',
        requiresAuth: true,
        requiresIndividual: true
      }
    },
    {
      path: '/particulier/nouvelle-demande',
      name: 'individual-new-quote',
      component: IndividualNewQuotePage,
      meta: {
        title: 'Nouvelle demande de devis - LocalLink',
        requiresAuth: true,
        requiresIndividual: true
      }
    },
    {
      path: '/particulier/devis/:id',
      name: 'individual-quote-detail',
      component: IndividualQuoteDetailPage,
      meta: {
        title: 'Détail de la demande - LocalLink',
        requiresAuth: true,
        requiresIndividual: true
      }
    }
  ],
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

router.beforeEach(async (to, _from, next) => {
  if (to.meta.requiresAuth) {
    while (authLoading.value) {
      await new Promise(resolve => setTimeout(resolve, 50))
    }

    if (!isAuthenticated.value) {
      next({ name: 'home' })
      return
    }

    const { data: individualData } = await supabase
      .from('individuals')
      .select('id')
      .eq('user_id', user.value?.id)
      .maybeSingle()

    const { data: companyData } = await supabase
      .from('companies')
      .select('id')
      .eq('user_id', user.value?.id)
      .maybeSingle()

    const isIndividual = !!individualData
    const isCompany = !!companyData

    if (to.name === 'dashboard') {
      if (isIndividual && !isCompany) {
        next({ name: 'individual-profile' })
        return
      }
    }

    if (to.meta.requiresIndividual && !isIndividual) {
      next({ name: 'dashboard' })
      return
    }
  }

  if (to.meta.requiresAdmin && !isAdmin.value) {
    next({ name: 'dashboard' })
  } else {
    if (to.meta.title) {
      document.title = to.meta.title as string
    }
    next()
  }
})

export default router
