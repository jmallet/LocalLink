/*
  # LocalLink - Sch\u00e9ma initial de la base de donn\u00e9es

  ## Description
  Cr\u00e9ation du sch\u00e9ma complet pour la plateforme LocalLink qui met en relation
  des entreprises locales (acheteurs et producteurs).

  ## Tables cr\u00e9\u00e9es

  ### 1. companies (entreprises)
  Table principale contenant toutes les informations sur les entreprises inscrites.
  - `id` (uuid, primary key)
  - `user_id` (uuid, lien avec auth.users)
  - `email` (text)
  - `company_name` (text)
  - `siret_bce` (text)
  - `address` (text)
  - `postal_code` (text)
  - `city` (text)
  - `country` (text)
  - `phone` (text)
  - `website` (text, optionnel)
  - `contact_first_name` (text)
  - `contact_last_name` (text)
  - `contact_email` (text)
  - `contact_phone` (text, optionnel)
  - `is_buyer` (boolean)
  - `is_producer` (boolean)
  - `producer_active` (boolean)
  - `description` (text)
  - `category` (text)
  - `tags` (text array)
  - `logo_url` (text)
  - `images` (text array)
  - `verified` (boolean)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 2. products_services (produits/services)
  Vitrine des produits et services propos\u00e9s par les producteurs.
  - `id` (uuid, primary key)
  - `company_id` (uuid, foreign key)
  - `name` (text)
  - `description` (text)
  - `category` (text)
  - `price` (numeric, optionnel)
  - `unit` (text, optionnel)
  - `images` (text array)
  - `available` (boolean)
  - `created_at` (timestamptz)

  ### 3. quote_requests (demandes de devis)
  Demandes de devis envoy\u00e9es par les acheteurs aux producteurs.
  - `id` (uuid, primary key)
  - `buyer_company_id` (uuid, foreign key)
  - `title` (text)
  - `description` (text)
  - `category` (text)
  - `quantity` (text)
  - `deadline` (date)
  - `budget_range` (text)
  - `status` (text: draft, pending_approval, approved, rejected, sent)
  - `approved_by_admin` (boolean)
  - `approved_at` (timestamptz)
  - `created_at` (timestamptz)

  ### 4. quote_recipients (destinataires des demandes)
  Producteurs ayant re\u00e7u une demande de devis.
  - `id` (uuid, primary key)
  - `quote_request_id` (uuid, foreign key)
  - `producer_company_id` (uuid, foreign key)
  - `unlocked` (boolean)
  - `unlocked_at` (timestamptz)
  - `payment_id` (text)
  - `created_at` (timestamptz)

  ### 5. visibility_boosts (mises en avant)
  Entreprises ayant pay\u00e9 pour \u00eatre mises en avant.
  - `id` (uuid, primary key)
  - `company_id` (uuid, foreign key)
  - `start_date` (date)
  - `end_date` (date)
  - `zone` (text: local, regional, national)
  - `category` (text)
  - `price` (numeric)
  - `payment_id` (text)
  - `active` (boolean)
  - `created_at` (timestamptz)

  ### 6. payments (paiements)
  Historique de tous les paiements effectu\u00e9s.
  - `id` (uuid, primary key)
  - `company_id` (uuid, foreign key)
  - `type` (text: lead, visibility)
  - `amount` (numeric)
  - `stripe_payment_id` (text)
  - `stripe_session_id` (text)
  - `status` (text: pending, succeeded, failed)
  - `metadata` (jsonb)
  - `created_at` (timestamptz)

  ### 7. blog_posts (articles de blog)
  Articles sur le circuit court et l'approvisionnement local.
  - `id` (uuid, primary key)
  - `title` (text)
  - `slug` (text, unique)
  - `excerpt` (text)
  - `content` (text)
  - `author` (text)
  - `cover_image` (text)
  - `published` (boolean)
  - `published_at` (timestamptz)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ## S\u00e9curit\u00e9 (RLS)
  - Toutes les tables ont RLS activ\u00e9
  - Politiques restrictives par d\u00e9faut
  - Acc\u00e8s bas\u00e9 sur auth.uid() et les r\u00f4les
*/

-- Table companies (entreprises)
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  email text NOT NULL,
  company_name text NOT NULL,
  siret_bce text NOT NULL,
  address text NOT NULL,
  postal_code text NOT NULL,
  city text NOT NULL,
  country text NOT NULL DEFAULT 'FR',
  phone text NOT NULL,
  website text,
  contact_first_name text NOT NULL,
  contact_last_name text NOT NULL,
  contact_email text NOT NULL,
  contact_phone text,
  is_buyer boolean DEFAULT true,
  is_producer boolean DEFAULT false,
  producer_active boolean DEFAULT false,
  description text,
  category text,
  tags text[] DEFAULT '{}',
  logo_url text,
  images text[] DEFAULT '{}',
  verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table products_services (produits/services)
CREATE TABLE IF NOT EXISTS products_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  description text NOT NULL,
  category text NOT NULL,
  price numeric(10,2),
  unit text,
  images text[] DEFAULT '{}',
  available boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Table quote_requests (demandes de devis)
CREATE TABLE IF NOT EXISTS quote_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  category text NOT NULL,
  quantity text,
  deadline date,
  budget_range text,
  status text DEFAULT 'pending_approval' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'sent')),
  approved_by_admin boolean DEFAULT false,
  approved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Table quote_recipients (destinataires des demandes)
CREATE TABLE IF NOT EXISTS quote_recipients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_request_id uuid REFERENCES quote_requests(id) ON DELETE CASCADE NOT NULL,
  producer_company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  unlocked boolean DEFAULT false,
  unlocked_at timestamptz,
  payment_id text,
  created_at timestamptz DEFAULT now()
);

-- Table visibility_boosts (mises en avant)
CREATE TABLE IF NOT EXISTS visibility_boosts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  zone text DEFAULT 'local' CHECK (zone IN ('local', 'regional', 'national')),
  category text,
  price numeric(10,2) NOT NULL,
  payment_id text,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Table payments (paiements)
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  type text NOT NULL CHECK (type IN ('lead', 'visibility')),
  amount numeric(10,2) NOT NULL,
  stripe_payment_id text,
  stripe_session_id text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'succeeded', 'failed')),
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Table blog_posts (articles de blog)
CREATE TABLE IF NOT EXISTS blog_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  excerpt text NOT NULL,
  content text NOT NULL,
  author text NOT NULL,
  cover_image text,
  published boolean DEFAULT false,
  published_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes pour am\u00e9liorer les performances
CREATE INDEX IF NOT EXISTS idx_companies_user_id ON companies(user_id);
CREATE INDEX IF NOT EXISTS idx_companies_producer_active ON companies(producer_active);
CREATE INDEX IF NOT EXISTS idx_companies_category ON companies(category);
CREATE INDEX IF NOT EXISTS idx_products_company_id ON products_services(company_id);
CREATE INDEX IF NOT EXISTS idx_quote_requests_buyer ON quote_requests(buyer_company_id);
CREATE INDEX IF NOT EXISTS idx_quote_recipients_producer ON quote_recipients(producer_company_id);
CREATE INDEX IF NOT EXISTS idx_visibility_boosts_active ON visibility_boosts(company_id, active, end_date);
CREATE INDEX IF NOT EXISTS idx_blog_posts_published ON blog_posts(published, published_at);

-- Activer RLS sur toutes les tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE products_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE visibility_boosts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour companies
CREATE POLICY "Companies are viewable by everyone when producer_active"
  ON companies FOR SELECT
  USING (producer_active = true);

CREATE POLICY "Users can view their own company"
  ON companies FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own company"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own company"
  ON companies FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Politiques RLS pour products_services
CREATE POLICY "Products are viewable by everyone"
  ON products_services FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = products_services.company_id
      AND companies.producer_active = true
    )
  );

CREATE POLICY "Companies can manage their own products"
  ON products_services FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = products_services.company_id
      AND companies.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = products_services.company_id
      AND companies.user_id = auth.uid()
    )
  );

-- Politiques RLS pour quote_requests
CREATE POLICY "Users can view their own quote requests"
  ON quote_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = quote_requests.buyer_company_id
      AND companies.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create quote requests"
  ON quote_requests FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = quote_requests.buyer_company_id
      AND companies.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own quote requests"
  ON quote_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = quote_requests.buyer_company_id
      AND companies.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = quote_requests.buyer_company_id
      AND companies.user_id = auth.uid()
    )
  );

-- Politiques RLS pour quote_recipients
CREATE POLICY "Producers can view their received quotes"
  ON quote_recipients FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = quote_recipients.producer_company_id
      AND companies.user_id = auth.uid()
    )
  );

CREATE POLICY "System can insert quote recipients"
  ON quote_recipients FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Producers can update their quote recipients"
  ON quote_recipients FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = quote_recipients.producer_company_id
      AND companies.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = quote_recipients.producer_company_id
      AND companies.user_id = auth.uid()
    )
  );

-- Politiques RLS pour visibility_boosts
CREATE POLICY "Everyone can view active visibility boosts"
  ON visibility_boosts FOR SELECT
  USING (active = true AND end_date >= CURRENT_DATE);

CREATE POLICY "Companies can view their own visibility boosts"
  ON visibility_boosts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = visibility_boosts.company_id
      AND companies.user_id = auth.uid()
    )
  );

-- Politiques RLS pour payments
CREATE POLICY "Users can view their own payments"
  ON payments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE companies.id = payments.company_id
      AND companies.user_id = auth.uid()
    )
  );

CREATE POLICY "System can insert payments"
  ON payments FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Politiques RLS pour blog_posts
CREATE POLICY "Everyone can view published blog posts"
  ON blog_posts FOR SELECT
  USING (published = true);
