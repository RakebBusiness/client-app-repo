import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create test motorcycles for Lakhdaria area
  Future<void> createTestMotorcycles() async {
    try {
      final motorcycles = [
        {
          'matricule': 'LAK-001-25',
          'modele': 'Yamaha NMAX 155',
          'couleur': 'Noir',
          'type': 'Scooter',
          'is_active': true,
        },
        {
          'matricule': 'LAK-002-25',
          'modele': 'Honda PCX 150',
          'couleur': 'Blanc',
          'type': 'Scooter',
          'is_active': true,
        },
        {
          'matricule': 'LAK-003-25',
          'modele': 'Suzuki Burgman 200',
          'couleur': 'Gris',
          'type': 'Scooter',
          'is_active': true,
        },
        {
          'matricule': 'LAK-004-25',
          'modele': 'Piaggio Vespa 300',
          'couleur': 'Rouge',
          'type': 'Scooter',
          'is_active': true,
        },
        {
          'matricule': 'LAK-005-25',
          'modele': 'Kymco Agility 125',
          'couleur': 'Bleu',
          'type': 'Scooter',
          'is_active': true,
        },
        {
          'matricule': 'LAK-006-25',
          'modele': 'SYM Symphony 150',
          'couleur': 'Vert',
          'type': 'Scooter',
          'is_active': true,
        },
      ];

      for (var moto in motorcycles) {
        await _supabase.from('motos').upsert(moto);
      }

      print('✅ Test motorcycles created successfully!');
    } catch (e) {
      print('❌ Error creating motorcycles: $e');
    }
  }

  // Create test riders in Lakhdaria area
  Future<void> createTestRiders() async {
    try {
      // Lakhdaria coordinates: 36.5644° N, 3.5892° E
      final testRiders = [
        {
          'nom_complet': 'Ahmed Benali',
          'num_tel': '+213661234567',
          'email': 'ahmed.benali@email.com',
          'date_naissance': '1990-05-15',
          'status': 'online',
          'is_verified': true,
          'rating_average': 4.8,
          'total_rides': 156,
          'current_location': 'POINT(${3.5892 + 0.01} ${36.5644 + 0.005})', // ~1km northeast
          'matricule_moto': 'LAK-001-25',
          'statut_bloque': false,
        },
        {
          'nom_complet': 'Karim Meziane',
          'num_tel': '+213662345678',
          'email': 'karim.meziane@email.com',
          'date_naissance': '1988-08-22',
          'status': 'online',
          'is_verified': true,
          'rating_average': 4.6,
          'total_rides': 203,
          'current_location': 'POINT(${3.5892 - 0.015} ${36.5644 - 0.008})', // ~2km southwest
          'matricule_moto': 'LAK-002-25',
          'statut_bloque': false,
        },
        {
          'nom_complet': 'Yacine Boumediene',
          'num_tel': '+213663456789',
          'email': 'yacine.boumediene@email.com',
          'date_naissance': '1992-12-10',
          'status': 'online',
          'is_verified': true,
          'rating_average': 4.9,
          'total_rides': 89,
          'current_location': 'POINT(${3.5892 + 0.02} ${36.5644 - 0.01})', // ~2.5km southeast
          'matricule_moto': 'LAK-003-25',
          'statut_bloque': false,
        },
        {
          'nom_complet': 'Sofiane Khelifi',
          'num_tel': '+213664567890',
          'email': 'sofiane.khelifi@email.com',
          'date_naissance': '1985-03-18',
          'status': 'online',
          'is_verified': true,
          'rating_average': 4.7,
          'total_rides': 312,
          'current_location': 'POINT(${3.5892 - 0.008} ${36.5644 + 0.012})', // ~1.5km northwest
          'matricule_moto': 'LAK-004-25',
          'statut_bloque': false,
        },
        {
          'nom_complet': 'Nabil Saidi',
          'num_tel': '+213665678901',
          'email': 'nabil.saidi@email.com',
          'date_naissance': '1991-07-25',
          'status': 'online',
          'is_verified': true,
          'rating_average': 4.5,
          'total_rides': 178,
          'current_location': 'POINT(${3.5892 + 0.025} ${36.5644 + 0.015})', // ~3km northeast
          'matricule_moto': 'LAK-005-25',
          'statut_bloque': false,
        },
        {
          'nom_complet': 'Djamel Brahimi',
          'num_tel': '+213666789012',
          'email': 'djamel.brahimi@email.com',
          'date_naissance': '1987-11-08',
          'status': 'online',
          'is_verified': true,
          'rating_average': 4.4,
          'total_rides': 245,
          'current_location': 'POINT(${3.5892 - 0.02} ${36.5644 + 0.008})', // ~2.2km northwest
          'matricule_moto': 'LAK-006-25',
          'statut_bloque': false,
        },
      ];

      for (var rider in testRiders) {
        await _supabase.from('motards').upsert(rider);
      }

      print('✅ Test riders created successfully in Lakhdaria area!');
    } catch (e) {
      print('❌ Error creating test riders: $e');
    }
  }

  // Create a test client (you)
  Future<void> createTestClient() async {
    try {
      final testClient = {
        'nom_complet': 'Test User Lakhdaria',
        'num_tel': '+213555123456',
        'email': 'testuser@lakhdaria.com',
        'adresse_principale': 'Lakhdaria, Bouira',
        'status_bloque': false,
        'total_rides': 0,
        'rating_average': 0.0,
      };

      await _supabase.from('clients').upsert(testClient);
      print('✅ Test client created successfully!');
    } catch (e) {
      print('❌ Error creating test client: $e');
    }
  }

  // Initialize all test data
  Future<void> initializeTestData() async {
    print('🚀 Initializing test data for Lakhdaria area...');
    
    await createTestMotorcycles();
    await Future.delayed(const Duration(milliseconds: 500));
    
    await createTestRiders();
    await Future.delayed(const Duration(milliseconds: 500));
    
    await createTestClient();
    
    print('✅ All test data initialized successfully!');
  }

  // Check if test data exists
  Future<bool> testDataExists() async {
    try {
      final riders = await _supabase
          .from('motards')
          .select('id')
          .eq('num_tel', '+213661234567')
          .maybeSingle();
      
      return riders != null;
    } catch (e) {
      return false;
    }
  }

  // Clean test data (for resetting)
  Future<void> cleanTestData() async {
    try {
      // Delete test riders
      await _supabase
          .from('motards')
          .delete()
          .like('num_tel', '+21366%');
      
      // Delete test motorcycles
      await _supabase
          .from('motos')
          .delete()
          .like('matricule', 'LAK-%');
      
      // Delete test client
      await _supabase
          .from('clients')
          .delete()
          .eq('num_tel', '+213555123456');
      
      print('✅ Test data cleaned successfully!');
    } catch (e) {
      print('❌ Error cleaning test data: $e');
    }
  }
}