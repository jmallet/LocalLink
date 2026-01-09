export type UserType = 'PARTICULIER' | 'PRO' | 'ADMIN'
export type CompanySource = 'INSEE' | 'IMPORT' | 'MANUAL'
export type RequesterType = 'PARTICULIER' | 'ACHETEUR_PRO'
export type QuoteStatus = 'SENT' | 'VIEWED' | 'RESPONDED' | 'CLOSED'

export interface Profile {
  user_id: string
  user_type: UserType
  first_name?: string
  last_name?: string
  phone?: string
  created_at: string
  updated_at: string
}

export interface Company {
  id: string
  name: string
  siret: string
  siren?: string
  naf_code?: string
  address?: string
  postal_code?: string
  city?: string
  country?: string
  latitude?: number
  longitude?: number
  description?: string
  phone?: string
  website?: string
  logo_url?: string
  source: CompanySource
  is_claimed: boolean
  claimed_at?: string
  created_at: string
  updated_at: string
}

export interface CompanyUser {
  id: string
  user_id: string
  company_id: string
  is_acheteur_pro: boolean
  is_producteur: boolean
  verified: boolean
  verified_at?: string
  created_at: string
}

export interface ProducerProfile {
  id: string
  company_id: string
  is_active: boolean
  intervention_radius_km?: number
  delivery_available: boolean
  minimum_order_amount?: number
  created_at: string
  updated_at: string
}

export interface ProducerProduct {
  id: string
  producer_id: string
  name: string
  category?: string
  description?: string
  unit?: string
  created_at: string
}

export interface QuoteRequest {
  id: string
  requester_id: string
  requester_type: RequesterType
  target_company_id: string
  title: string
  description?: string
  volume_estimated?: string
  frequency?: string
  location?: string
  budget_range?: string
  status: QuoteStatus
  admin_approved: boolean
  admin_approved_at?: string
  admin_approved_by?: string
  admin_rejection_reason?: string
  created_at: string
  updated_at: string
}

export interface QuoteMessage {
  id: string
  quote_request_id: string
  sender_user_id: string
  message: string
  created_at: string
}

export interface LeadAccess {
  id: string
  quote_request_id: string
  producer_company_id: string
  opened_at: string
}

export interface QuoteWithCompany extends QuoteRequest {
  target_company?: Company
}

export interface QuoteWithMessages extends QuoteRequest {
  quote_messages?: QuoteMessage[]
  target_company?: Company
}

export interface CompanyWithProfile extends Company {
  producer_profile?: ProducerProfile
  producer_products?: ProducerProduct[]
}
