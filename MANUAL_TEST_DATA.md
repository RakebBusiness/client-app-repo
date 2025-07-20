# 🏍️ Manual Test Data Setup for Lakhdaria Area

Since the app can't create test data automatically due to RLS policies, you need to manually add some test riders to your Supabase database.

## 📋 **Step-by-Step Instructions:**

### **1. Open Supabase Dashboard**
- Go to [supabase.com](https://supabase.com)
- Open your project dashboard
- Navigate to **SQL Editor**

### **2. Run This SQL Query**
Copy and paste this SQL into the SQL Editor and click **RUN**:

```sql
-- Insert test motorcycles first
INSERT INTO motos (matricule, modele, couleur, type, is_active) VALUES
('LAK-001-25', 'Yamaha NMAX 155', 'Noir', 'Scooter', true),
('LAK-002-25', 'Honda PCX 150', 'Blanc', 'Scooter', true),
('LAK-003-25', 'Suzuki Burgman 200', 'Gris', 'Scooter', true),
('LAK-004-25', 'Piaggio Vespa 300', 'Rouge', 'Scooter', true),
('LAK-005-25', 'Kymco Agility 125', 'Bleu', 'Scooter', true),
('LAK-006-25', 'SYM Symphony 150', 'Vert', 'Scooter', true)
ON CONFLICT (matricule) DO NOTHING;

-- Insert test riders in Lakhdaria area (36.5644° N, 3.5892° E)
INSERT INTO motards (
  nom_complet, num_tel, email, date_naissance, 
  status, is_verified, rating_average, total_rides,
  current_location, matricule_moto, statut_bloque
) VALUES
('Ahmed Benali', '+213661234567', 'ahmed.benali@test.com', '1990-05-15', 
 'online', true, 4.8, 156, 
 'POINT(3.5992 36.5694)', 'LAK-001-25', false),

('Karim Meziane', '+213662345678', 'karim.meziane@test.com', '1988-08-22', 
 'online', true, 4.6, 203, 
 'POINT(3.5742 36.5564)', 'LAK-002-25', false),

('Yacine Boumediene', '+213663456789', 'yacine.boumediene@test.com', '1992-12-10', 
 'online', true, 4.9, 89, 
 'POINT(3.6092 36.5544)', 'LAK-003-25', false),

('Sofiane Khelifi', '+213664567890', 'sofiane.khelifi@test.com', '1985-03-18', 
 'online', true, 4.7, 312, 
 'POINT(3.5812 36.5764)', 'LAK-004-25', false),

('Nabil Saidi', '+213665678901', 'nabil.saidi@test.com', '1991-07-25', 
 'online', true, 4.5, 178, 
 'POINT(3.6142 36.5794)', 'LAK-005-25', false),

('Djamel Brahimi', '+213666789012', 'djamel.brahimi@test.com', '1987-11-08', 
 'online', true, 4.4, 245, 
 'POINT(3.5692 36.5724)', 'LAK-006-25', false)
ON CONFLICT (num_tel) DO NOTHING;
```

### **3. Verify Data Creation**
After running the SQL, check the tables:

**Check Motorcycles:**
```sql
SELECT * FROM motos WHERE matricule LIKE 'LAK-%';
```

**Check Riders:**
```sql
SELECT nom_complet, status, rating_average, current_location 
FROM motards 
WHERE status = 'online' AND statut_bloque = false;
```

### **4. Test the App**
```bash
flutter run
```

You should now see:
- ✅ **6 blue rider markers** on the map around Lakhdaria
- ✅ **Rider count badge** showing "6"
- ✅ **Tap markers** to see rider details
- ✅ **Distance calculations** working properly

## 🗺️ **Test Rider Locations:**

1. **Ahmed Benali** - 4.8⭐ (~1km northeast of Lakhdaria)
2. **Karim Meziane** - 4.6⭐ (~2km southwest of Lakhdaria)
3. **Yacine Boumediene** - 4.9⭐ (~2.5km southeast of Lakhdaria)
4. **Sofiane Khelifi** - 4.7⭐ (~1.5km northwest of Lakhdaria)
5. **Nabil Saidi** - 4.5⭐ (~3km northeast of Lakhdaria)
6. **Djamel Brahimi** - 4.4⭐ (~2.2km northwest of Lakhdaria)

## 🔧 **If Still No Riders Appear:**

1. **Check RLS Policies** - Make sure you can read from `motards` table
2. **Check Console Logs** - Look for "Found X riders in database"
3. **Tap Refresh Button** - The circular arrow button on the map
4. **Grant Location Permission** - Allow GPS access when prompted

The app should now successfully display real rider data from Supabase! 🚀