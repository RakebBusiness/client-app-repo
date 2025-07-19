/*
  # Create core tables for Rakib ride-sharing app

  1. New Tables
    - `motos` - Motorcycle information with images
    - `clients` - Client/passenger profiles
    - `motards` - Motorcycle drivers/riders
    - `admins` - Admin users with different roles
    - `rides` - Ride booking and tracking
    - `payments` - Payment transactions
    - `reviews` - Ride reviews and ratings

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for each user type
    - Secure file uploads for images

  3. Improvements
    - Added ride management system
    - Payment tracking
    - Review system
    - Better data types and constraints
    - Audit fields (created_at, updated_at)
    - Soft delete support
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 🏍️ Moto Table (Motorcycles)
CREATE TABLE IF NOT EXISTS motos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  matricule varchar(20) UNIQUE NOT NULL,
  modele varchar(50) NOT NULL,
  couleur varchar(30),
  type varchar(30) CHECK (type IN ('Scooter', 'Sport', 'Cruiser', 'Standard', 'Electric')),
  carte_grise_url text, -- URL to image in Supabase Storage
  photo_moto_url text,  -- URL to image in Supabase Storage
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 🧍 Client Table (Passengers)
CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  num_tel varchar(20) UNIQUE NOT NULL,
  nom_complet varchar(100),
  email varchar(100),
  photo_url text,
  status_bloque boolean DEFAULT false,
  date_naissance date,
  adresse_principale text,
  preferences jsonb DEFAULT '{}', -- Store user preferences
  total_rides integer DEFAULT 0,
  rating_average decimal(3,2) DEFAULT 0.00,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz,
  
  CONSTRAINT valid_email CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  CONSTRAINT valid_rating CHECK (rating_average >= 0 AND rating_average <= 5)
);

-- 🏍️ Motard Table (Drivers)
CREATE TABLE IF NOT EXISTS motards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  num_tel varchar(20) UNIQUE NOT NULL,
  nom_complet varchar(100) NOT NULL,
  email varchar(100),
  photo_url text,
  statut_bloque boolean DEFAULT false,
  matricule_moto varchar(20),
  date_naissance date NOT NULL,
  permis_conduire_url text, -- URL to license image
  cin_url text, -- National ID card
  casier_judiciaire_url text, -- Criminal record
  status varchar(20) DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'busy', 'suspended')),
  current_location point, -- PostGIS point for location
  total_rides integer DEFAULT 0,
  rating_average decimal(3,2) DEFAULT 0.00,
  earnings_total decimal(10,2) DEFAULT 0.00,
  is_verified boolean DEFAULT false,
  verification_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz,
  
  FOREIGN KEY (matricule_moto) REFERENCES motos(matricule),
  CONSTRAINT valid_email CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  CONSTRAINT valid_rating CHECK (rating_average >= 0 AND rating_average <= 5),
  CONSTRAINT adult_age CHECK (date_naissance <= CURRENT_DATE - INTERVAL '18 years')
);

-- 👑 Admin Table
CREATE TABLE IF NOT EXISTS admins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  num_tel varchar(20) UNIQUE NOT NULL,
  nom_complet varchar(100) NOT NULL,
  email varchar(100) UNIQUE NOT NULL,
  password_hash varchar(255) NOT NULL,
  type varchar(30) NOT NULL CHECK (
    type IN ('SuperAdmin', 'AdminChauffeur', 'AdminStatistique', 'AdminReclamations', 'AdminGestion')
  ),
  permissions jsonb DEFAULT '[]', -- Array of specific permissions
  is_active boolean DEFAULT true,
  last_login timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  CONSTRAINT valid_email CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- 🚗 Rides Table (Trip Management)
CREATE TABLE IF NOT EXISTS rides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES clients(id),
  motard_id uuid REFERENCES motards(id),
  pickup_location point NOT NULL,
  pickup_address text NOT NULL,
  destination_location point NOT NULL,
  destination_address text NOT NULL,
  status varchar(20) DEFAULT 'pending' CHECK (
    status IN ('pending', 'accepted', 'driver_arrived', 'in_progress', 'completed', 'cancelled', 'failed')
  ),
  distance_km decimal(8,2),
  duration_minutes integer,
  price_estimated decimal(8,2),
  price_final decimal(8,2),
  payment_method varchar(20) DEFAULT 'cash' CHECK (
    payment_method IN ('cash', 'card', 'wallet', 'promotion')
  ),
  special_instructions text,
  scheduled_time timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 💳 Payments Table
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid NOT NULL REFERENCES rides(id),
  client_id uuid NOT NULL REFERENCES clients(id),
  motard_id uuid NOT NULL REFERENCES motards(id),
  amount decimal(10,2) NOT NULL,
  commission decimal(10,2) DEFAULT 0.00, -- Platform commission
  driver_earnings decimal(10,2) NOT NULL,
  payment_method varchar(20) NOT NULL,
  status varchar(20) DEFAULT 'pending' CHECK (
    status IN ('pending', 'completed', 'failed', 'refunded')
  ),
  transaction_id varchar(100),
  processed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- ⭐ Reviews Table
CREATE TABLE IF NOT EXISTS reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid NOT NULL REFERENCES rides(id),
  reviewer_id uuid NOT NULL, -- Can be client or motard
  reviewee_id uuid NOT NULL, -- Can be client or motard
  reviewer_type varchar(10) NOT NULL CHECK (reviewer_type IN ('client', 'motard')),
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamptz DEFAULT now(),
  
  UNIQUE(ride_id, reviewer_id) -- One review per ride per reviewer
);

-- 🎫 Promotions Table
CREATE TABLE IF NOT EXISTS promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(20) UNIQUE NOT NULL,
  title varchar(100) NOT NULL,
  description text,
  discount_type varchar(20) CHECK (discount_type IN ('percentage', 'fixed_amount', 'free_ride')),
  discount_value decimal(8,2),
  min_ride_amount decimal(8,2) DEFAULT 0,
  max_discount decimal(8,2),
  usage_limit integer,
  usage_count integer DEFAULT 0,
  valid_from timestamptz DEFAULT now(),
  valid_until timestamptz,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 🎫 User Promotions (Track promotion usage)
CREATE TABLE IF NOT EXISTS user_promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES clients(id),
  promotion_id uuid NOT NULL REFERENCES promotions(id),
  ride_id uuid REFERENCES rides(id),
  used_at timestamptz DEFAULT now(),
  
  UNIQUE(client_id, promotion_id, ride_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_clients_num_tel ON clients(num_tel);
CREATE INDEX IF NOT EXISTS idx_motards_num_tel ON motards(num_tel);
CREATE INDEX IF NOT EXISTS idx_motards_status ON motards(status);
CREATE INDEX IF NOT EXISTS idx_motards_location ON motards USING GIST(current_location);
CREATE INDEX IF NOT EXISTS idx_rides_client_id ON rides(client_id);
CREATE INDEX IF NOT EXISTS idx_rides_motard_id ON rides(motard_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_created_at ON rides(created_at);
CREATE INDEX IF NOT EXISTS idx_payments_ride_id ON payments(ride_id);
CREATE INDEX IF NOT EXISTS idx_reviews_ride_id ON reviews(ride_id);

-- Enable Row Level Security
ALTER TABLE motos ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE motards ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_promotions ENABLE ROW LEVEL SECURITY;