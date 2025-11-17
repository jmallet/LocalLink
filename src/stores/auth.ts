import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'
import type { User, Session } from '@supabase/supabase-js'
import type { Company } from '../types/database'

export const user = ref<User | null>(null)
export const session = ref<Session | null>(null)
export const company = ref<Company | null>(null)
export const loading = ref(true)

export const isAuthenticated = computed(() => !!user.value)
export const isProducer = computed(() => company.value?.is_producer && company.value?.producer_active)
export const isVerified = computed(() => company.value?.verified)

export async function initAuth() {
  loading.value = true

  try {
    const { data: { session: currentSession } } = await supabase.auth.getSession()
    session.value = currentSession
    user.value = currentSession?.user || null

    if (user.value) {
      await loadCompany()
    }

    supabase.auth.onAuthStateChange((_event, newSession) => {
      (async () => {
        session.value = newSession
        user.value = newSession?.user || null

        if (user.value) {
          await loadCompany()
        } else {
          company.value = null
        }
      })()
    })
  } catch (error) {
    console.error('Auth initialization error:', error)
  } finally {
    loading.value = false
  }
}

export async function loadCompany() {
  if (!user.value) return

  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('user_id', user.value.id)
      .maybeSingle()

    if (error) throw error
    company.value = data
  } catch (error) {
    console.error('Error loading company:', error)
  }
}

export async function signUp(email: string, password: string) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
  })
  return { data, error }
}

export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })
  return { data, error }
}

export async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (!error) {
    user.value = null
    session.value = null
    company.value = null
  }
  return { error }
}
