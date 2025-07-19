/*
  # Sample Data for Testing

  1. Sample Data
    - Test motorcycles
    - Sample promotions
    - Admin users
    - Test clients and motards

  2. Note
    - This is for development/testing only
    - Remove or modify for production
*/

-- Insert sample motorcycles
INSERT INTO motos (matricule, modele, couleur, type) VALUES
('ALG-001-16', 'Yamaha NMAX 155', 'Noir', 'Scooter'),
('ALG-002-16', 'Honda PCX 150', 'Blanc', 'Scooter'),
('ALG-003-16', 'Suzuki Burgman 200', 'Gris', 'Scooter'),
('ALG-004-16', 'Piaggio Vespa 300', 'Rouge', 'Scooter'),
('ALG-005-16', 'Kymco Agility 125', 'Bleu', 'Scooter');

-- Insert sample promotions
INSERT INTO promotions (code, title, description, discount_type, discount_value, min_ride_amount, max_discount, usage_limit, valid_until) VALUES
('WELCOME50', 'Welcome Bonus', 'Get 50% off your first ride', 'percentage', 50.00, 100.00, 200.00, 1000, now() + interval '30 days'),
('WEEKEND20', 'Weekend Special', '20% off on weekend rides', 'percentage', 20.00, 150.00, 100.00, null, now() + interval '90 days'),
('STUDENT30', 'Student Discount', 'Special discount for students', 'percentage', 30.00, 100.00, 150.00, null, now() + interval '365 days'),
('NEWUSER100', 'New User Bonus', 'Free ride up to 100 DA', 'fixed_amount', 100.00, 50.00, 100.00, 500, now() + interval '60 days'),
('LOYALTY10', 'Loyalty Reward', '10% off for regular customers', 'percentage', 10.00, 200.00, 50.00, null, now() + interval '180 days');

-- Insert sample admin (password should be hashed in real application)
INSERT INTO admins (num_tel, nom_complet, email, password_hash, type) VALUES
('+213 555 000 001', 'Ahmed Benali', 'admin@rakib.dz', '$2b$10$example_hash_here', 'SuperAdmin'),
('+213 555 000 002', 'Fatima Khelifi', 'drivers@rakib.dz', '$2b$10$example_hash_here', 'AdminChauffeur'),
('+213 555 000 003', 'Mohamed Saidi', 'stats@rakib.dz', '$2b$10$example_hash_here', 'AdminStatistique');

-- Insert sample clients (for testing)
INSERT INTO clients (num_tel, nom_complet, email, adresse_principale) VALUES
('+213 555 123 456', 'Yacine Boumediene', 'yacine@email.com', 'Bab Ezzouar, Alger'),
('+213 555 234 567', 'Amina Cherif', 'amina@email.com', 'Hydra, Alger'),
('+213 555 345 678', 'Karim Mansouri', 'karim@email.com', 'Kouba, Alger'),
('+213 555 456 789', 'Leila Brahimi', 'leila@email.com', 'El Biar, Alger'),
('+213 555 567 890', 'Omar Zidane', 'omar@email.com', 'Bir Mourad Rais, Alger');

-- Insert sample motards (drivers)
INSERT INTO motards (num_tel, nom_complet, email, matricule_moto, date_naissance, status, is_verified) VALUES
('+213 666 123 456', 'Rachid Hamidi', 'rachid@email.com', 'ALG-001-16', '1990-05-15', 'online', true),
('+213 666 234 567', 'Sofiane Belkacem', 'sofiane@email.com', 'ALG-002-16', '1988-08-22', 'online', true),
('+213 666 345 678', 'Nabil Ouali', 'nabil@email.com', 'ALG-003-16', '1992-12-10', 'offline', true),
('+213 666 456 789', 'Djamel Benaissa', 'djamel@email.com', 'ALG-004-16', '1985-03-18', 'online', true),
('+213 666 567 890', 'Farid Meziane', 'farid@email.com', 'ALG-005-16', '1991-07-25', 'busy', true);

-- Update motards with sample locations (Algiers area)
UPDATE motards SET current_location = point(3.0588, 36.7538) WHERE num_tel = '+213 666 123 456'; -- Algiers Center
UPDATE motards SET current_location = point(3.0892, 36.7755) WHERE num_tel = '+213 666 234 567'; -- Bab Ezzouar
UPDATE motards SET current_location = point(3.0416, 36.7694) WHERE num_tel = '+213 666 345 678'; -- Hydra
UPDATE motards SET current_location = point(3.0267, 36.7528) WHERE num_tel = '+213 666 456 789'; -- Kouba
UPDATE motards SET current_location = point(3.0156, 36.7611) WHERE num_tel = '+213 666 567 890'; -- El Biar

-- Insert sample completed rides (for testing reviews and ratings)
INSERT INTO rides (
    client_id, motard_id, pickup_location, pickup_address, 
    destination_location, destination_address, status, 
    distance_km, duration_minutes, price_final, payment_method
) VALUES
(
    (SELECT id FROM clients WHERE num_tel = '+213 555 123 456'),
    (SELECT id FROM motards WHERE num_tel = '+213 666 123 456'),
    point(3.0588, 36.7538), 'Place des Martyrs, Alger',
    point(3.0892, 36.7755), 'Université USTHB, Bab Ezzouar',
    'completed', 12.5, 25, 412.50, 'cash'
),
(
    (SELECT id FROM clients WHERE num_tel = '+213 555 234 567'),
    (SELECT id FROM motards WHERE num_tel = '+213 666 234 567'),
    point(3.0416, 36.7694), 'Hydra, Alger',
    point(3.0588, 36.7538), 'Centre-ville, Alger',
    'completed', 8.2, 18, 295.00, 'card'
);

-- Insert sample reviews
INSERT INTO reviews (ride_id, reviewer_id, reviewee_id, reviewer_type, rating, comment) VALUES
(
    (SELECT id FROM rides LIMIT 1),
    (SELECT client_id FROM rides LIMIT 1),
    (SELECT motard_id FROM rides LIMIT 1),
    'client', 5, 'Excellent service, très professionnel!'
),
(
    (SELECT id FROM rides LIMIT 1 OFFSET 1),
    (SELECT client_id FROM rides LIMIT 1 OFFSET 1),
    (SELECT motard_id FROM rides LIMIT 1 OFFSET 1),
    'client', 4, 'Bon chauffeur, conduite sécurisée.'
);