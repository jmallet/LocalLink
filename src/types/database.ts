export type UserType = 'PARTICULIER' | 'PRO' | 'ADMIN'
export type CompanySource = 'INSEE' | 'IMPORT' | 'MANUAL'
export type RequesterType = 'PARTICULIER' | 'ACHETEUR_PRO'
export type QuoteStatus = 'SENT' | 'VIEWED' | 'RESPONDED' | 'CLOSED'

export interface User {
  id: string
  email: string
  first_name?: string
  last_name?: string
  phone?: string
  user_type: UserType
  created_at: string
  updated_at: string
}

export interface UserCompany {
  id: string
  user_id: string
  company_id: string
  role?: 'owner' | 'admin' | 'member'
  is_acheteur_pro: boolean
  is_producteur: boolean
  verified: boolean
  verified_at?: string
  created_at: string
}

export interface Company {
  id: string
  user_id?: string
  email?: string
  name: string
  company_name?: string
  siret: string
  siret_bce?: string
  siren?: string
  address: string
  postal_code: string
  city: string
  country: string
  phone?: string
  website?: string
  contact_first_name?: string
  contact_last_name?: string
  contact_email?: string
  contact_phone?: string
  is_buyer: boolean
  is_producer: boolean
  producer_active: boolean
  description?: string
  naf_code?: string
  category?: string
  tags: string[]
  logo_url?: string
  images: string[]
  verified: boolean
  is_claimed: boolean
  claimed?: boolean
  claimed_at?: string
  source: CompanySource
  created_at: string
  updated_at: string
}

export interface Individual {
  id: string
  user_id: string
  first_name: string
  last_name: string
  phone?: string
  city?: string
  postal_code?: string
  created_at: string
  updated_at: string
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

export interface ProductService {
  id: string
  company_id: string
  name: string
  description: string
  category: string
  price?: number
  unit?: string
  images: string[]
  available: boolean
  created_at: string
}

export interface QuoteRequest {
  id: string
  requester_id: string
  requester_type: RequesterType
  target_company_id: string
  buyer_company_id?: string
  buyer_individual_id?: string
  individual_id?: string
  title: string
  description?: string
  category?: string
  volume_estimated?: string
  frequency?: string
  location?: string
  quantity?: string
  deadline?: string
  budget_range?: string
  status?: 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'sent'
  new_status?: QuoteStatus
  approved_by_admin?: boolean
  approved_at?: string
  created_at: string
  updated_at?: string
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

export interface QuoteRecipient {
  id: string
  quote_request_id: string
  producer_company_id: string
  unlocked: boolean
  unlocked_at?: string
  payment_id?: string
  created_at: string
}

export interface VisibilityBoost {
  id: string
  company_id: string
  start_date: string
  end_date: string
  zone: 'local' | 'regional' | 'national'
  category?: string
  price: number
  payment_id?: string
  active: boolean
  created_at: string
}

export interface Payment {
  id: string
  company_id: string
  type: 'lead' | 'visibility'
  amount: number
  stripe_payment_id?: string
  stripe_session_id?: string
  status: 'pending' | 'succeeded' | 'failed'
  metadata: Record<string, any>
  created_at: string
}

export interface BlogPost {
  id: string
  title: string
  slug: string
  excerpt: string
  content: string
  author: string
  cover_image?: string
  published: boolean
  published_at?: string
  created_at: string
  updated_at: string
}

export interface CompanyWithProducts extends Company {
  products?: ProductService[]
}

export interface QuoteRequestWithCompany extends QuoteRequest {
  buyer_company?: Company
  individual?: Individual
}

export interface QuoteRecipientWithDetails extends QuoteRecipient {
  quote_request?: QuoteRequest
  producer_company?: Company
}
