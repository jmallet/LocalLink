export interface Company {
  id: string
  user_id?: string
  email?: string
  company_name: string
  siret_bce: string
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
  category: string
  tags: string[]
  logo_url?: string
  images: string[]
  verified: boolean
  claimed: boolean
  claimed_at?: string
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
  buyer_company_id?: string
  individual_id?: string
  title: string
  description: string
  category: string
  quantity?: string
  deadline?: string
  budget_range?: string
  status: 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'sent'
  approved_by_admin: boolean
  approved_at?: string
  created_at: string
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
