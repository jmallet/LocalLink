<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import type { BlogPost } from '../../types/database'

const route = useRoute()
const router = useRouter()

const post = ref<BlogPost | null>(null)
const loading = ref(true)

const postSlug = computed(() => route.params?.slug as string || '')

onMounted(async () => {
  await loadPost()
})

async function loadPost() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('blog_posts')
      .select('*')
      .eq('slug', postSlug.value)
      .eq('published', true)
      .maybeSingle()

    if (error) throw error
    post.value = data
  } catch (error) {
    console.error('Error loading post:', error)
  } finally {
    loading.value = false
  }
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
  <div class="blog-post-page">
    <div v-if="loading" class="loading-container">
      <div class="spinner"></div>
      <p>Chargement de l'article...</p>
    </div>

    <article v-else-if="post" class="blog-post">
      <div class="post-header">
        <div class="container">
          <button class="btn-back" @click="router.push({ name: 'blog' })">
            ← Retour au blog
          </button>

          <div class="post-meta">
            <span class="post-author">Par {{ post.author }}</span>
            <span class="post-date">{{ formatDate(post.published_at!) }}</span>
          </div>

          <h1 class="post-title">{{ post.title }}</h1>
        </div>
      </div>

      <div v-if="post.cover_image" class="post-cover">
        <img :src="post.cover_image" :alt="post.title" />
      </div>

      <div class="post-content-wrapper">
        <div class="container">
          <div class="post-content" v-html="post.content"></div>
        </div>
      </div>

      <div class="post-footer">
        <div class="container">
          <button class="btn-back-footer" @click="router.push({ name: 'blog' })">
            ← Retour au blog
          </button>
        </div>
      </div>
    </article>

    <div v-else class="error-container">
      <h2>Article non trouvé</h2>
      <button class="btn-back" @click="router.push({ name: 'blog' })">
        ← Retour au blog
      </button>
    </div>
  </div>
</template>

<style scoped>
.blog-post-page {
  min-height: 100vh;
  background: #f9fafb;
}

.post-header {
  background: white;
  padding: 32px 24px 48px;
  border-bottom: 1px solid #e5e7eb;
}

.container {
  max-width: 800px;
  margin: 0 auto;
}

.btn-back,
.btn-back-footer {
  padding: 8px 16px;
  background: transparent;
  color: #059669;
  border: 1px solid #059669;
  border-radius: 8px;
  font-weight: 600;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 24px;
}

.btn-back:hover,
.btn-back-footer:hover {
  background: #f0fdf4;
}

.post-meta {
  display: flex;
  gap: 16px;
  align-items: center;
  margin-bottom: 16px;
  font-size: 14px;
  color: #6b7280;
}

.post-author {
  font-weight: 600;
  color: #059669;
}

.post-title {
  font-size: 42px;
  font-weight: 800;
  color: #111827;
  line-height: 1.2;
  margin: 0;
}

.post-cover {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
}

.post-cover img {
  width: 100%;
  height: auto;
  max-height: 500px;
  object-fit: cover;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

.post-content-wrapper {
  background: white;
  padding: 48px 24px;
  margin-top: 48px;
}

.post-content {
  font-size: 18px;
  line-height: 1.8;
  color: #374151;
}

.post-content :deep(h1) {
  font-size: 32px;
  font-weight: 700;
  color: #111827;
  margin: 32px 0 16px;
}

.post-content :deep(h2) {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 28px 0 12px;
}

.post-content :deep(h3) {
  font-size: 22px;
  font-weight: 700;
  color: #111827;
  margin: 24px 0 12px;
}

.post-content :deep(p) {
  margin-bottom: 20px;
}

.post-content :deep(ul),
.post-content :deep(ol) {
  margin-bottom: 20px;
  padding-left: 32px;
}

.post-content :deep(li) {
  margin-bottom: 8px;
}

.post-content :deep(strong) {
  font-weight: 700;
  color: #111827;
}

.post-content :deep(a) {
  color: #059669;
  text-decoration: underline;
}

.post-content :deep(a:hover) {
  color: #047857;
}

.post-footer {
  padding: 48px 24px;
}

.loading-container,
.error-container {
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

@media (max-width: 768px) {
  .post-title {
    font-size: 32px;
  }

  .post-content {
    font-size: 16px;
  }

  .post-content :deep(h1) {
    font-size: 28px;
  }

  .post-content :deep(h2) {
    font-size: 24px;
  }

  .post-content :deep(h3) {
    font-size: 20px;
  }
}
</style>
