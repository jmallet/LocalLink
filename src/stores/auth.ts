import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'
import type { User as SupabaseUser, Session } from '@supabase/supabase-js'
import type { Profile, Company, CompanyUser } from '../types/database'

export const user = ref<SupabaseUser | null>(null)
export const session = ref<Session | null>(null)
export const profile = ref<Profile | null>(null)
export const companies = ref<Company[]>([])
export const currentCompany = ref<Company | null>(null)
export const companyUsers = ref<CompanyUser[]>([])
export const loading = ref(true)
export const needsOnboarding = ref(false)

export const isAuthenticated = computed(() => !!user.value)
export const isParticulier = computed(() => profile.value?.user_type === 'PARTICULIER')
export const isPro = computed(() => profile.value?.user_type === 'PRO')
export const isAdmin = computed(() => profile.value?.user_type === 'ADMIN')

export const currentCompanyUser = computed(() => {
  if (!currentCompany.value) return null
  return companyUsers.value.find(cu => cu.company_id === currentCompany.value!.id)
})

export const isAcheteurPro = computed(() => currentCompanyUser.value?.is_acheteur_pro || false)
export const isProducteur = computed(() => currentCompanyUser.value?.is_producteur || false)

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
          clearProfile()
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
    const { data: existingProfile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', user.value.id)
      .maybeSingle()

    if (!existingProfile && !profileError) {
      const { data: newProfile } = await supabase
        .from('profiles')
        .insert({
          user_id: user.value.id,
          user_type: 'PRO'
        })
        .select()
        .single()

      profile.value = newProfile
      needsOnboarding.value = true
    } else {
      profile.value = existingProfile
    }

    if (profile.value?.user_type === 'PRO') {
      const { data: companyUsersData } = await supabase
        .from('company_users')
        .select('*')
        .eq('user_id', user.value.id)

      companyUsers.value = companyUsersData || []

      if (companyUsers.value.length > 0) {
        const companyIds = companyUsers.value.map(cu => cu.company_id)
        const { data: companiesData } = await supabase
          .from('companies')
          .select('*')
          .in('id', companyIds)

        companies.value = companiesData || []

        if (companies.value.length > 0 && !currentCompany.value) {
          currentCompany.value = companies.value[0]
        }
      }

      if (existingProfile && companyUsers.value.length === 0) {
        needsOnboarding.value = true
      } else {
        needsOnboarding.value = false
      }
    } else if (profile.value?.user_type === 'PARTICULIER' || profile.value?.user_type === 'ADMIN') {
      needsOnboarding.value = false
    }
  } catch (error) {
    console.error('Error loading profile:', error)
  }
}

export async function loadCompanies() {
  if (!user.value || !isPro.value) return

  try {
    const { data: companyUsersData } = await supabase
      .from('company_users')
      .select('*')
      .eq('user_id', user.value.id)

    companyUsers.value = companyUsersData || []

    if (companyUsers.value.length > 0) {
      const companyIds = companyUsers.value.map(cu => cu.company_id)
      const { data: companiesData, error } = await supabase
        .from('companies')
        .select('*')
        .in('id', companyIds)

      if (error) throw error
      companies.value = companiesData || []

      if (currentCompany.value) {
        const updatedCurrent = companies.value.find(c => c.id === currentCompany.value!.id)
        currentCompany.value = updatedCurrent || companies.value[0] || null
      } else if (companies.value.length > 0) {
        currentCompany.value = companies.value[0]
      }
    }
  } catch (error) {
    console.error('Error loading companies:', error)
  }
}

export function setCurrentCompany(companyId: string) {
  const company = companies.value.find(c => c.id === companyId)
  if (company) {
    currentCompany.value = company
  }
}

export function clearProfile() {
  profile.value = null
  companies.value = []
  currentCompany.value = null
  companyUsers.value = []
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
    clearProfile()
  }
  return { error }
}

export async function refreshProfile() {
  if (!user.value) return
  await loadProfile()
}
