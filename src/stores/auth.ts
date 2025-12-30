import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'
import type { User as SupabaseUser, Session } from '@supabase/supabase-js'
import type { Company, Individual, User as AppUser, UserCompany } from '../types/database'

export const user = ref<SupabaseUser | null>(null)
export const session = ref<Session | null>(null)
export const appUser = ref<AppUser | null>(null)
export const companies = ref<Company[]>([])
export const currentCompany = ref<Company | null>(null)
export const userCompanies = ref<UserCompany[]>([])
export const individual = ref<Individual | null>(null)
export const loading = ref(true)

export const isAuthenticated = computed(() => !!user.value)
export const isIndividual = computed(() => !!individual.value)
export const isCompany = computed(() => companies.value.length > 0)
export const isProducer = computed(() => currentCompany.value?.is_producer && currentCompany.value?.producer_active)
export const isVerified = computed(() => currentCompany.value?.verified)
export const isAdmin = computed(() => {
  if (!currentCompany.value) return false
  const userCompany = userCompanies.value.find(uc => uc.company_id === currentCompany.value!.id)
  return userCompany?.role === 'admin'
})
export const isOwner = computed(() => {
  if (!currentCompany.value) return false
  const userCompany = userCompanies.value.find(uc => uc.company_id === currentCompany.value!.id)
  return userCompany?.role === 'owner'
})

// Backward compatibility
export const company = computed({
  get: () => currentCompany.value,
  set: (val) => { currentCompany.value = val }
})

export async function initAuth() {
  loading.value = true

  try {
    const { data: { session: currentSession } } = await supabase.auth.getSession()
    session.value = currentSession
    user.value = currentSession?.user || null

    if (user.value) {
      await loadProfile()
    }

    supabase.auth.onAuthStateChange((_event, newSession) => {
      (async () => {
        session.value = newSession
        user.value = newSession?.user || null

        if (user.value) {
          await loadProfile()
        } else {
          company.value = null
          individual.value = null
        }
      })()
    })
  } catch (error) {
    console.error('Auth initialization error:', error)
  } finally {
    loading.value = false
  }
}

export async function loadProfile() {
  if (!user.value) return

  try {
    // 1. Créer ou récupérer l'utilisateur dans la table users
    const { data: existingUser, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.value.id)
      .maybeSingle()

    if (!existingUser && !userError) {
      const { data: newUser } = await supabase
        .from('users')
        .insert({
          id: user.value.id,
          email: user.value.email!
        })
        .select()
        .single()

      appUser.value = newUser
    } else {
      appUser.value = existingUser
    }

    // 2. Charger les relations user_companies
    const { data: userCompaniesData } = await supabase
      .from('user_companies')
      .select('*')
      .eq('user_id', user.value.id)

    userCompanies.value = userCompaniesData || []

    // 3. Charger les companies associées
    if (userCompanies.value.length > 0) {
      const companyIds = userCompanies.value.map(uc => uc.company_id)
      const { data: companiesData } = await supabase
        .from('companies')
        .select('*')
        .in('id', companyIds)

      companies.value = companiesData || []

      // Définir la company courante (première dans la liste par défaut)
      if (companies.value.length > 0 && !currentCompany.value) {
        currentCompany.value = companies.value[0]
      }
    }

    // 4. Charger le profil individual si existant
    const { data: individualData } = await supabase
      .from('individuals')
      .select('*')
      .eq('user_id', user.value.id)
      .maybeSingle()

    individual.value = individualData
  } catch (error) {
    console.error('Error loading profile:', error)
  }
}

export async function loadCompany() {
  if (!user.value) return

  try {
    // Recharger les user_companies
    const { data: userCompaniesData } = await supabase
      .from('user_companies')
      .select('*')
      .eq('user_id', user.value.id)

    userCompanies.value = userCompaniesData || []

    // Recharger les companies
    if (userCompanies.value.length > 0) {
      const companyIds = userCompanies.value.map(uc => uc.company_id)
      const { data: companiesData, error } = await supabase
        .from('companies')
        .select('*')
        .in('id', companyIds)

      if (error) throw error
      companies.value = companiesData || []

      // Mettre à jour la company courante si elle existe encore
      if (currentCompany.value) {
        const updatedCurrent = companies.value.find(c => c.id === currentCompany.value!.id)
        currentCompany.value = updatedCurrent || companies.value[0] || null
      } else if (companies.value.length > 0) {
        currentCompany.value = companies.value[0]
      }
    }
  } catch (error) {
    console.error('Error loading company:', error)
  }
}

export function setCurrentCompany(companyId: string) {
  const company = companies.value.find(c => c.id === companyId)
  if (company) {
    currentCompany.value = company
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
    appUser.value = null
    companies.value = []
    currentCompany.value = null
    userCompanies.value = []
    individual.value = null
  }
  return { error }
}
