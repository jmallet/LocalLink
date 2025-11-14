export interface Business {
  id: number
  name: string
  category: string
  description: string
  location: string
  distance: number
  image: string
  tags: string[]
  verified: boolean
  contact: {
    email: string
    phone: string
  }
}

export type Category = 'all' | 'producer' | 'restaurant' | 'caterer' | 'retailer' | 'service'
