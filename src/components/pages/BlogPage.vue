<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import type { BlogPost } from '../../types/database'

const router = useRouter()

const posts = ref<BlogPost[]>([])
const loading = ref(true)

onMounted(async () => {
  await loadPosts()
})

async function loadPosts() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('blog_posts')
      .select('*')
      .eq('published', true)
      .order('published_at', { ascending: false })

    if (error) throw error
    posts.value = data || []
  } catch (error) {
    console.error('Error loading posts:', error)
  } finally {
    loading.value = false
  }
}

function handlePostClick(post: BlogPost) {
  router.push({ name: 'blog-post', params: { slug: post.slug } })
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}
</script>

<template>
  <div class="blog-page">
    <section class="page-header">
      <div class="container">
        <h1 class="page-title">Blog LocalLink</h1>
        <p class="page-subtitle">
          Actualités, conseils et ressources pour développer votre réseau B2B local
        </p>
      </div>
    </section>

    <section class="blog-content">
      <div class="container">
        <div v-if="loading" class="loading-container">
          <div class="spinner"></div>
          <p>Chargement des articles...</p>
        </div>

        <div v-else-if="posts.length > 0" class="posts-grid">
          <article
            v-for="post in posts"
            :key="post.id"
            class="post-card"
            @click="handlePostClick(post)"
          >
            <div v-if="post.cover_image" class="post-image">
              <img :src="post.cover_image" :alt="post.title" />
            </div>
            <div class="post-content">
              <div class="post-meta">
                <span class="post-author">{{ post.author }}</span>
                <span class="post-date">{{ formatDate(post.published_at!) }}</span>
              </div>
              <h2 class="post-title">{{ post.title }}</h2>
              <p class="post-excerpt">{{ post.excerpt }}</p>
              <button class="btn-read-more">
                Lire l'article →
              </button>
            </div>
          </article>
        </div>

        <div v-else class="empty-state">
          <span class="empty-icon">📝</span>
          <h3>Aucun article disponible</h3>
          <p>Revenez bientôt pour découvrir nos nouveaux contenus</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.blog-page {
  min-height: 100vh;
  background: #f9fafb;
}

.page-header {
  background: white;
  padding: 64px 24px;
  border-bottom: 1px solid #e5e7eb;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.page-title {
  font-size: 48px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
  text-align: center;
}

.page-subtitle {
  font-size: 20px;
  color: #6b7280;
  margin: 0;
  text-align: center;
  max-width: 700px;
  margin: 0 auto;
}

.blog-content {
  padding: 48px 24px 80px;
}

.posts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 32px;
}

.post-card {
  background: white;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
  cursor: pointer;
}

.post-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.post-image {
  width: 100%;
  height: 240px;
  overflow: hidden;
  background: #f3f4f6;
}

.post-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.post-content {
  padding: 24px;
}

.post-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  font-size: 14px;
  color: #6b7280;
}

.post-author {
  font-weight: 600;
  color: #059669;
}

.post-title {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
  line-height: 1.3;
}

.post-excerpt {
  font-size: 15px;
  color: #6b7280;
  line-height: 1.6;
  margin: 0 0 20px 0;
}

.btn-read-more {
  background: transparent;
  color: #059669;
  border: none;
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  padding: 0;
  transition: all 0.2s;
}

.btn-read-more:hover {
  color: #047857;
}

.loading-container,
.empty-state {
  text-align: center;
  padding: 80px 24px;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #e5e7eb;
  border-top-color: #059669;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 24px;
}

.empty-state h3 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 12px 0;
}

.empty-state p {
  font-size: 16px;
  color: #6b7280;
  margin: 0;
}

@media (max-width: 768px) {
  .page-header {
    padding: 48px 24px;
  }

  .page-title {
    font-size: 36px;
  }

  .page-subtitle {
    font-size: 18px;
  }

  .posts-grid {
    grid-template-columns: 1fr;
  }

  .blog-content {
    padding: 32px 16px 80px;
  }
}
</style>
