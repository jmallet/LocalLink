/*
  # Reconstruction complète du schéma MVP LocalProConnect

  ## Vue d'ensemble
  Cette migration supprime toutes les tables existantes et recrée un schéma simplifié
  pour le MVP de LocalProConnect.

  ## Tables créées
    - profiles: profil utilisateur avec user_type
    - companies: annuaire des sociétés
    - company_users: liaison users <-> companies
    - producer_profiles: profil producteur
    - producer_products: produits/services
    - quote_requests: demandes de devis
    - quote_messages: messages
    - lead_accesses: tracking ouvertures
*/

-- ============================================================================
-- 1. SUPPRESSION DES ANCIENNES TABLES
-- ============================================================================

DROP TABLE IF EXISTS quote_messages CASCADE;
DROP TABLE IF EXISTS lead_accesses CASCADE;
DROP TABLE IF EXISTS token_transactions CASCADE;
DROP TABLE IF EXISTS company_tokens CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS visibility_boosts CASCADE;
DROP TABLE IF EXISTS quote_recipients CASCADE;
DROP TABLE IF EXISTS quote_requests CASCADE;
DROP TABLE IF EXISTS producer_products CASCADE;
DROP TABLE IF EXISTS producer_profiles CASCADE;
DROP TABLE IF EXISTS products_services CASCADE;
DROP TABLE IF EXISTS user_companies CASCADE;
DROP TABLE IF EXISTS company_users CASCADE;
DROP TABLE IF EXISTS individuals CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS admin_users CASCADE;
DROP TABLE IF EXISTS blog_posts CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

DROP TYPE IF EXISTS quote_status CASCADE;
DROP TYPE IF EXISTS requester_type CASCADE;
DROP TYPE IF EXISTS company_source CASCADE;
DROP TYPE IF EXISTS user_type CASCADE;

-- ============================================================================
-- 2. CRÉATION DES ENUMS
-- ============================================================================

CREATE TYPE user_type AS ENUM ('PARTICULIER', 'PRO', 'ADMIN');
CREATE TYPE company_source AS ENUM ('INSEE', 'IMPORT', 'MANUAL');
CREATE TYPE requester_type AS ENUM ('PARTICULIER', 'ACHETEUR_PRO');
CREATE TYPE quote_status AS ENUM ('SENT', 'VIEWED', 'RESPONDED', 'CLOSED');

-- ============================================================================
-- 3. TABLE PROFILES
-- ============================================================================

CREATE TABLE profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_type user_type DEFAULT 'PRO',
  first_name text,
  last_name text,
  phone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. TABLE COMPANIES
-- ============================================================================

CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  siret text NOT NULL UNIQUE,
  siren text,
  naf_code text,
  address text,
  postal_code text,
  city text,
  country text DEFAULT 'France',
  latitude numeric,
  longitude numeric,
  description text,
  phone text,
  website text,
  logo_url text,
  source company_source DEFAULT 'MANUAL',
  is_claimed boolean DEFAULT false,
  claimed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. TABLE COMPANY_USERS
-- ============================================================================

CREATE TABLE company_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  is_acheteur_pro boolean DEFAULT true,
  is_producteur boolean DEFAULT false,
  verified boolean DEFAULT false,
  verified_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, company_id)
);

ALTER TABLE company_users ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. TABLE PRODUCER_PROFILES
-- ============================================================================

CREATE TABLE producer_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL UNIQUE REFERENCES companies(id) ON DELETE CASCADE,
  is_active boolean DEFAULT false,
  intervention_radius_km integer,
  delivery_available boolean DEFAULT false,
  minimum_order_amount numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE producer_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 7. TABLE PRODUCER_PRODUCTS
-- ============================================================================

CREATE TABLE producer_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  producer_id uuid NOT NULL REFERENCES producer_profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  category text,
  description text,
  unit text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE producer_products ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 8. TABLE QUOTE_REQUESTS
-- ============================================================================

CREATE TABLE quote_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requester_type requester_type NOT NULL,
  target_company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  volume_estimated text,
  frequency text,
  location text,
  budget_range text,
  status quote_status DEFAULT 'SENT',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 9. TABLE QUOTE_MESSAGES
-- ============================================================================

CREATE TABLE quote_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_request_id uuid NOT NULL REFERENCES quote_requests(id) ON DELETE CASCADE,
  sender_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE quote_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 10. TABLE LEAD_ACCESSES
-- ============================================================================

CREATE TABLE lead_accesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_request_id uuid NOT NULL UNIQUE REFERENCES quote_requests(id) ON DELETE CASCADE,
  producer_company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  opened_at timestamptz DEFAULT now()
);

ALTER TABLE lead_accesses ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 11. POLICIES RLS
-- ============================================================================

-- Profiles
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Companies
CREATE POLICY "Anyone can view companies" ON companies FOR SELECT TO authenticated USING (true);
CREATE POLICY "Company users can update" ON companies FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM company_users WHERE company_users.company_id = companies.id AND company_users.user_id = auth.uid())
);
CREATE POLICY "Authenticated can create companies" ON companies FOR INSERT TO authenticated WITH CHECK (true);

-- Company Users
CREATE POLICY "Users view their links" ON company_users FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users create their links" ON company_users FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update their links" ON company_users FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Producer Profiles
CREATE POLICY "Anyone views active profiles" ON producer_profiles FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "Company users manage profile" ON producer_profiles FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM company_users WHERE company_users.company_id = producer_profiles.company_id AND company_users.user_id = auth.uid() AND company_users.is_producteur = true)
);

-- Producer Products
CREATE POLICY "Anyone views products" ON producer_products FOR SELECT TO authenticated USING (true);
CREATE POLICY "Producer manages products" ON producer_products FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM producer_profiles pp JOIN company_users cu ON cu.company_id = pp.company_id WHERE pp.id = producer_products.producer_id AND cu.user_id = auth.uid() AND cu.is_producteur = true)
);

-- Quote Requests
CREATE POLICY "View own or received quotes" ON quote_requests FOR SELECT TO authenticated USING (
  auth.uid() = requester_id OR EXISTS (SELECT 1 FROM company_users WHERE company_users.company_id = quote_requests.target_company_id AND company_users.user_id = auth.uid() AND company_users.is_producteur = true)
);
CREATE POLICY "Create quote requests" ON quote_requests FOR INSERT TO authenticated WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Update quote status" ON quote_requests FOR UPDATE TO authenticated USING (
  auth.uid() = requester_id OR EXISTS (SELECT 1 FROM company_users WHERE company_users.company_id = quote_requests.target_company_id AND company_users.user_id = auth.uid() AND company_users.is_producteur = true)
);

-- Quote Messages
CREATE POLICY "View messages" ON quote_messages FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM quote_requests qr WHERE qr.id = quote_messages.quote_request_id AND (qr.requester_id = auth.uid() OR EXISTS (SELECT 1 FROM company_users cu WHERE cu.company_id = qr.target_company_id AND cu.user_id = auth.uid())))
);
CREATE POLICY "Send messages" ON quote_messages FOR INSERT TO authenticated WITH CHECK (
  auth.uid() = sender_user_id AND EXISTS (SELECT 1 FROM quote_requests qr WHERE qr.id = quote_messages.quote_request_id AND (qr.requester_id = auth.uid() OR EXISTS (SELECT 1 FROM company_users cu WHERE cu.company_id = qr.target_company_id AND cu.user_id = auth.uid())))
);

-- Lead Accesses
CREATE POLICY "View lead accesses" ON lead_accesses FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM company_users WHERE company_users.company_id = lead_accesses.producer_company_id AND company_users.user_id = auth.uid())
);
CREATE POLICY "Create lead accesses" ON lead_accesses FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM company_users WHERE company_users.company_id = lead_accesses.producer_company_id AND company_users.user_id = auth.uid())
);

-- ============================================================================
-- 12. INDEX
-- ============================================================================

CREATE INDEX idx_companies_siret ON companies(siret);
CREATE INDEX idx_companies_is_claimed ON companies(is_claimed);
CREATE INDEX idx_company_users_user_id ON company_users(user_id);
CREATE INDEX idx_company_users_company_id ON company_users(company_id);
CREATE INDEX idx_producer_profiles_company_id ON producer_profiles(company_id);
CREATE INDEX idx_producer_profiles_is_active ON producer_profiles(is_active);
CREATE INDEX idx_quote_requests_requester_id ON quote_requests(requester_id);
CREATE INDEX idx_quote_requests_target_company_id ON quote_requests(target_company_id);
CREATE INDEX idx_quote_messages_quote_request_id ON quote_messages(quote_request_id);

-- ============================================================================
-- 13. DONNÉES DE DÉMO
-- ============================================================================

INSERT INTO companies (name, siret, siren, address, postal_code, city, description, source) VALUES
('Ferme Bio du Val', '12345678901234', '123456789', '15 Route des Champs', '35000', 'Rennes', 'Production de légumes biologiques locaux', 'IMPORT'),
('Boulangerie Artisanale', '98765432109876', '987654321', '23 Rue du Pain', '35200', 'Rennes', 'Pain artisanal au levain naturel', 'IMPORT'),
('Fromagerie Bretonne', '11122233344455', '111222333', '8 Avenue du Lait', '35400', 'Saint-Malo', 'Fromages artisanaux de Bretagne', 'IMPORT')
ON CONFLICT (siret) DO NOTHING;
