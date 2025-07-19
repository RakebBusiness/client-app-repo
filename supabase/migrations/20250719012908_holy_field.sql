/*
  # Row Level Security Policies

  1. Security Policies
    - Clients can only access their own data
    - Motards can only access their own data
    - Admins have appropriate access based on role
    - Public read access for active promotions

  2. Authentication Integration
    - Policies based on auth.uid()
    - Phone number matching for user identification
*/

-- ==========================================
-- CLIENTS POLICIES
-- ==========================================

-- Clients can read their own profile
CREATE POLICY "Clients can read own profile"
  ON clients FOR SELECT
  TO authenticated
  USING (num_tel = (auth.jwt() ->> 'phone'));

-- Clients can update their own profile
CREATE POLICY "Clients can update own profile"
  ON clients FOR UPDATE
  TO authenticated
  USING (num_tel = (auth.jwt() ->> 'phone'));

-- Clients can insert their own profile
CREATE POLICY "Clients can insert own profile"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (num_tel = (auth.jwt() ->> 'phone'));

-- Motards can read client profiles (for rides)
CREATE POLICY "Motards can read client profiles"
  ON clients FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM motards 
      WHERE motards.num_tel = (auth.jwt() ->> 'phone')
      AND motards.statut_bloque = false
    )
  );

-- ==========================================
-- MOTARDS POLICIES
-- ==========================================

-- Motards can read their own profile
CREATE POLICY "Motards can read own profile"
  ON motards FOR SELECT
  TO authenticated
  USING (num_tel = (auth.jwt() ->> 'phone'));

-- Motards can update their own profile
CREATE POLICY "Motards can update own profile"
  ON motards FOR UPDATE
  TO authenticated
  USING (num_tel = (auth.jwt() ->> 'phone'));

-- Motards can insert their own profile
CREATE POLICY "Motards can insert own profile"
  ON motards FOR INSERT
  TO authenticated
  WITH CHECK (num_tel = (auth.jwt() ->> 'phone'));

-- Clients can read active motard profiles (for ride matching)
CREATE POLICY "Clients can read active motards"
  ON motards FOR SELECT
  TO authenticated
  USING (
    statut_bloque = false 
    AND status IN ('online', 'busy')
    AND EXISTS (
      SELECT 1 FROM clients 
      WHERE clients.num_tel = (auth.jwt() ->> 'phone')
      AND clients.status_bloque = false
    )
  );

-- ==========================================
-- MOTOS POLICIES
-- ==========================================

-- Motards can read their own moto
CREATE POLICY "Motards can read own moto"
  ON motos FOR SELECT
  TO authenticated
  USING (
    matricule IN (
      SELECT matricule_moto FROM motards 
      WHERE motards.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- Motards can update their own moto
CREATE POLICY "Motards can update own moto"
  ON motos FOR UPDATE
  TO authenticated
  USING (
    matricule IN (
      SELECT matricule_moto FROM motards 
      WHERE motards.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- ==========================================
-- RIDES POLICIES
-- ==========================================

-- Clients can read their own rides
CREATE POLICY "Clients can read own rides"
  ON rides FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT id FROM clients 
      WHERE clients.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- Motards can read their assigned rides
CREATE POLICY "Motards can read assigned rides"
  ON rides FOR SELECT
  TO authenticated
  USING (
    motard_id IN (
      SELECT id FROM motards 
      WHERE motards.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- Clients can create rides
CREATE POLICY "Clients can create rides"
  ON rides FOR INSERT
  TO authenticated
  WITH CHECK (
    client_id IN (
      SELECT id FROM clients 
      WHERE clients.num_tel = (auth.jwt() ->> 'phone')
      AND clients.status_bloque = false
    )
  );

-- Motards can update rides (accept, start, complete)
CREATE POLICY "Motards can update assigned rides"
  ON rides FOR UPDATE
  TO authenticated
  USING (
    motard_id IN (
      SELECT id FROM motards 
      WHERE motards.num_tel = (auth.jwt() ->> 'phone')
      AND motards.statut_bloque = false
    )
  );

-- Clients can update their rides (cancel)
CREATE POLICY "Clients can update own rides"
  ON rides FOR UPDATE
  TO authenticated
  USING (
    client_id IN (
      SELECT id FROM clients 
      WHERE clients.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- ==========================================
-- PAYMENTS POLICIES
-- ==========================================

-- Users can read their own payments
CREATE POLICY "Users can read own payments"
  ON payments FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT id FROM clients 
      WHERE clients.num_tel = (auth.jwt() ->> 'phone')
    )
    OR
    motard_id IN (
      SELECT id FROM motards 
      WHERE motards.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- System can insert payments (via service role)
CREATE POLICY "Service role can manage payments"
  ON payments FOR ALL
  TO service_role
  USING (true);

-- ==========================================
-- REVIEWS POLICIES
-- ==========================================

-- Users can read reviews for their rides
CREATE POLICY "Users can read ride reviews"
  ON reviews FOR SELECT
  TO authenticated
  USING (
    ride_id IN (
      SELECT id FROM rides 
      WHERE client_id IN (
        SELECT id FROM clients 
        WHERE clients.num_tel = (auth.jwt() ->> 'phone')
      )
      OR motard_id IN (
        SELECT id FROM motards 
        WHERE motards.num_tel = (auth.jwt() ->> 'phone')
      )
    )
  );

-- Users can create reviews for their completed rides
CREATE POLICY "Users can create reviews"
  ON reviews FOR INSERT
  TO authenticated
  WITH CHECK (
    ride_id IN (
      SELECT id FROM rides 
      WHERE status = 'completed'
      AND (
        client_id IN (
          SELECT id FROM clients 
          WHERE clients.num_tel = (auth.jwt() ->> 'phone')
        )
        OR motard_id IN (
          SELECT id FROM motards 
          WHERE motards.num_tel = (auth.jwt() ->> 'phone')
        )
      )
    )
  );

-- ==========================================
-- PROMOTIONS POLICIES
-- ==========================================

-- Everyone can read active promotions
CREATE POLICY "Anyone can read active promotions"
  ON promotions FOR SELECT
  TO authenticated
  USING (is_active = true AND valid_until > now());

-- ==========================================
-- USER PROMOTIONS POLICIES
-- ==========================================

-- Clients can read their own promotion usage
CREATE POLICY "Clients can read own promotions"
  ON user_promotions FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT id FROM clients 
      WHERE clients.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- Clients can use promotions
CREATE POLICY "Clients can use promotions"
  ON user_promotions FOR INSERT
  TO authenticated
  WITH CHECK (
    client_id IN (
      SELECT id FROM clients 
      WHERE clients.num_tel = (auth.jwt() ->> 'phone')
    )
  );

-- ==========================================
-- ADMIN POLICIES
-- ==========================================

-- Admins can read all data based on their role
CREATE POLICY "Admins can read based on role"
  ON clients FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admins 
      WHERE admins.num_tel = (auth.jwt() ->> 'phone')
      AND admins.is_active = true
    )
  );

CREATE POLICY "Admins can manage motards"
  ON motards FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admins 
      WHERE admins.num_tel = (auth.jwt() ->> 'phone')
      AND admins.is_active = true
      AND admins.type IN ('SuperAdmin', 'AdminChauffeur', 'AdminGestion')
    )
  );

CREATE POLICY "Admins can manage motos"
  ON motos FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admins 
      WHERE admins.num_tel = (auth.jwt() ->> 'phone')
      AND admins.is_active = true
      AND admins.type IN ('SuperAdmin', 'AdminChauffeur', 'AdminGestion')
    )
  );

CREATE POLICY "Admins can read all rides"
  ON rides FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admins 
      WHERE admins.num_tel = (auth.jwt() ->> 'phone')
      AND admins.is_active = true
    )
  );

CREATE POLICY "Admins can manage promotions"
  ON promotions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admins 
      WHERE admins.num_tel = (auth.jwt() ->> 'phone')
      AND admins.is_active = true
      AND admins.type IN ('SuperAdmin', 'AdminGestion')
    )
  );