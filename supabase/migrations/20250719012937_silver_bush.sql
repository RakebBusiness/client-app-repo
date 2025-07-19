/*
  # Database Functions and Triggers

  1. Functions
    - Update rating averages
    - Calculate ride pricing
    - Handle ride status changes
    - Update timestamps

  2. Triggers
    - Auto-update timestamps
    - Recalculate ratings after reviews
    - Update ride counts
*/

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_motos_updated_at BEFORE UPDATE ON motos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_motards_updated_at BEFORE UPDATE ON motards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rides_updated_at BEFORE UPDATE ON rides
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate ride price based on distance and time
CREATE OR REPLACE FUNCTION calculate_ride_price(
    distance_km decimal,
    duration_minutes integer,
    base_price decimal DEFAULT 100.00,
    price_per_km decimal DEFAULT 25.00,
    price_per_minute decimal DEFAULT 5.00
)
RETURNS decimal AS $$
BEGIN
    RETURN base_price + (distance_km * price_per_km) + (duration_minutes * price_per_minute);
END;
$$ LANGUAGE plpgsql;

-- Function to update user ratings after a review
CREATE OR REPLACE FUNCTION update_user_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Update client rating if review is for a client
    IF NEW.reviewee_id IN (SELECT id FROM clients) THEN
        UPDATE clients 
        SET rating_average = (
            SELECT ROUND(AVG(rating::decimal), 2)
            FROM reviews 
            WHERE reviewee_id = NEW.reviewee_id
        )
        WHERE id = NEW.reviewee_id;
    END IF;
    
    -- Update motard rating if review is for a motard
    IF NEW.reviewee_id IN (SELECT id FROM motards) THEN
        UPDATE motards 
        SET rating_average = (
            SELECT ROUND(AVG(rating::decimal), 2)
            FROM reviews 
            WHERE reviewee_id = NEW.reviewee_id
        )
        WHERE id = NEW.reviewee_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update ratings after review insert/update
CREATE TRIGGER update_rating_after_review
    AFTER INSERT OR UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_user_rating();

-- Function to update ride counts
CREATE OR REPLACE FUNCTION update_ride_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Only count completed rides
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        -- Update client ride count
        UPDATE clients 
        SET total_rides = total_rides + 1
        WHERE id = NEW.client_id;
        
        -- Update motard ride count
        UPDATE motards 
        SET total_rides = total_rides + 1
        WHERE id = NEW.motard_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update ride counts
CREATE TRIGGER update_ride_counts_trigger
    AFTER UPDATE ON rides
    FOR EACH ROW EXECUTE FUNCTION update_ride_counts();

-- Function to handle ride status changes
CREATE OR REPLACE FUNCTION handle_ride_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Set timestamps based on status changes
    IF NEW.status = 'in_progress' AND (OLD.status IS NULL OR OLD.status != 'in_progress') THEN
        NEW.started_at = now();
    ELSIF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        NEW.completed_at = now();
        -- Calculate final price if not set
        IF NEW.price_final IS NULL AND NEW.distance_km IS NOT NULL AND NEW.duration_minutes IS NOT NULL THEN
            NEW.price_final = calculate_ride_price(NEW.distance_km, NEW.duration_minutes);
        END IF;
    ELSIF NEW.status = 'cancelled' AND (OLD.status IS NULL OR OLD.status != 'cancelled') THEN
        NEW.cancelled_at = now();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for ride status changes
CREATE TRIGGER handle_ride_status_change_trigger
    BEFORE UPDATE ON rides
    FOR EACH ROW EXECUTE FUNCTION handle_ride_status_change();

-- Function to get nearby motards
CREATE OR REPLACE FUNCTION get_nearby_motards(
    client_location point,
    radius_km decimal DEFAULT 5.0
)
RETURNS TABLE (
    id uuid,
    nom_complet varchar,
    num_tel varchar,
    rating_average decimal,
    current_location point,
    distance_km decimal
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.nom_complet,
        m.num_tel,
        m.rating_average,
        m.current_location,
        ROUND((m.current_location <-> client_location) * 111.32, 2) as distance_km
    FROM motards m
    WHERE 
        m.status = 'online'
        AND m.statut_bloque = false
        AND m.is_verified = true
        AND m.current_location IS NOT NULL
        AND (m.current_location <-> client_location) * 111.32 <= radius_km
    ORDER BY distance_km ASC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Function to apply promotion discount
CREATE OR REPLACE FUNCTION apply_promotion_discount(
    promotion_code varchar,
    ride_amount decimal,
    client_id_param uuid
)
RETURNS decimal AS $$
DECLARE
    promo_record promotions%ROWTYPE;
    discount_amount decimal := 0;
BEGIN
    -- Get promotion details
    SELECT * INTO promo_record
    FROM promotions
    WHERE code = promotion_code
    AND is_active = true
    AND valid_from <= now()
    AND (valid_until IS NULL OR valid_until >= now())
    AND (usage_limit IS NULL OR usage_count < usage_limit);
    
    -- Check if promotion exists and is valid
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Check if client already used this promotion
    IF EXISTS (
        SELECT 1 FROM user_promotions 
        WHERE client_id = client_id_param 
        AND promotion_id = promo_record.id
    ) THEN
        RETURN 0;
    END IF;
    
    -- Check minimum ride amount
    IF ride_amount < promo_record.min_ride_amount THEN
        RETURN 0;
    END IF;
    
    -- Calculate discount
    IF promo_record.discount_type = 'percentage' THEN
        discount_amount := ride_amount * (promo_record.discount_value / 100);
        IF promo_record.max_discount IS NOT NULL THEN
            discount_amount := LEAST(discount_amount, promo_record.max_discount);
        END IF;
    ELSIF promo_record.discount_type = 'fixed_amount' THEN
        discount_amount := promo_record.discount_value;
    ELSIF promo_record.discount_type = 'free_ride' THEN
        discount_amount := ride_amount;
    END IF;
    
    -- Ensure discount doesn't exceed ride amount
    discount_amount := LEAST(discount_amount, ride_amount);
    
    RETURN discount_amount;
END;
$$ LANGUAGE plpgsql;