import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check if user has admin privileges or use service role
  Future<bool> _hasAdminAccess() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Check if user is in admins table
      final admin = await _supabase
          .from('admins')
          .select('id')
          .eq('num_tel', user.phone ?? '')
          .maybeSingle();
      
      return admin != null;
    } catch (e) {
      return false;
    }
  }

  // Create test motorcycles for Lakhdaria area
  Future<void> createTestMotorcycles() async {
    try {
      // Skip if no admin access - motorcycles need admin permissions
      if (!await _hasAdminAccess()) {
        print('⚠️ Skipping motorcycle creation - requires admin access');
        return;
      }
      
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
      // Skip if no admin access - motards need admin permissions  
      if (!await _hasAdminAccess()) {
        print('⚠️ Skipping rider creation - requires admin access');
        return;
      }
      
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
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('⚠️ No authenticated user - cannot create client profile');
        return;
      }
      
      // Check if client already exists
      final existingClient = await _supabase
          .from('clients')
          .select('id')
          .eq('num_tel', user.phone ?? '')
          .maybeSingle();
      
      if (existingClient != null) {
        print('✅ Client profile already exists');
        return;
      }
      
      final testClient = {
        'nom_complet': user.userMetadata?['display_name'] ?? 'User Lakhdaria',
        'num_tel': user.phone ?? '',
        'email': user.email ?? '',
        'adresse_principale': 'Lakhdaria, Bouira',
        'status_bloque': false,
        'total_rides': 0,
        'rating_average': 0.0,
      };

      await _supabase.from('clients').insert(testClient);
      print('✅ Test client created successfully!');
    } catch (e) {
      print('❌ Error creating test client: $e');
    }
  }

  // Initialize all test data
  Future<void> initializeTestData() async {
    print('🚀 Initializing test data for Lakhdaria area...');
    
    // Create client profile first (this works with current user)
    await createTestClient();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Try to create motorcycles and riders (requires admin access)
    await createTestMotorcycles();
    await Future.delayed(const Duration(milliseconds: 300));
    await createTestRiders();
    
    print('✅ Test data initialization completed!');
  }

  // Check if test data exists
  Future<bool> testDataExists() async {
    try {
      // Check for any riders in the area instead of specific phone number
      final riders = await _supabase
          .from('motards')
          .select('id')
          .limit(1);
      
      return riders.isNotEmpty;
    } catch (e) {
      print('Error checking test data: $e');
      return false;
    }
  }

  // Clean test data (for resetting)
  Future<void> cleanTestData() async {
    try {
      if (!await _hasAdminAccess()) {
        print('⚠️ Admin access required to clean test data');
        return;
      }
      
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
          .eq('num_tel', _supabase.auth.currentUser?.phone ?? '');
      
      print('✅ Test data cleaned successfully!');
    } catch (e) {
      print('❌ Error cleaning test data: $e');
    }
  }
  
  // Create a simple test admin for development
  Future<void> createTestAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // This might fail due to RLS, but worth trying
      final testAdmin = {
        'nom_complet': 'Test Admin',
        'num_tel': user.phone ?? '',
        'email': user.email ?? 'admin@test.com',
        'password_hash': 'test_hash', // In real app, this should be properly hashed
        'type': 'SuperAdmin',
        'is_active': true,
      };
      
      await _supabase.from('admins').insert(testAdmin);
      print('✅ Test admin created!');
    } catch (e) {
      print('❌ Could not create admin (expected): $e');
    }
  }
}