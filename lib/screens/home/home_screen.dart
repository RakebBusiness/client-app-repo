import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../profile/profile_screen.dart';
import '../trips/trips_screen.dart';
import '../promotions/promotions_screen.dart';
import '../booking/ride_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController mapController = MapController();
  
  // Default location (Algiers, Algeria)
  LatLng _currentPosition = const LatLng(36.7538, 3.0588);
  LatLng _userLocation = const LatLng(36.7538, 3.0588);
  bool _mapLoaded = false;
  bool _locationLoaded = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _checkMapTiles();
    _getCurrentLocation();
  }

  Future<void> _checkMapTiles() async {
    try {
      final response = await http.get(
        Uri.parse('https://tile.openstreetmap.org/14/8239/6057.png'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _mapLoaded = true;
        });
      }
    } catch (e) {
      print('Map tiles check failed: $e');
      // Still show map even if check fails
      setState(() {
        _mapLoaded = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog('Location services are disabled. Please enable location services.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog('Location permissions are denied. Please grant location access.');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog('Location permissions are permanently denied. Please enable them in settings.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _currentPosition = _userLocation;
        _locationLoaded = true;
        _isLoadingLocation = false;
      });

      // Move map to user location
      mapController.move(_userLocation, 16.0);

    } catch (e) {
      print('Error getting location: $e');
      _showLocationDialog('Failed to get your location. Using default location.');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (message.contains('settings'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _moveToCurrentLocation() async {
    if (_locationLoaded) {
      mapController.move(_userLocation, 16.0);
    } else {
      await _getCurrentLocation();
    }
  }

  void _showNavigationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF32C156)),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Color(0xFF32C156)),
              title: const Text('My Trips'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TripsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Color(0xFF32C156)),
              title: const Text('Promotions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PromotionsScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // OpenStreetMap with Flutter Map
          _mapLoaded
              ? FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 14.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rakib.app',
                      maxZoom: 18,
                      additionalOptions: const {
                        'id': 'openstreetmap',
                      },
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation,
                          width: 40,
                          height: 40,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF32C156),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (_isLoadingLocation)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF32C156),
                        ),
                        SizedBox(height: 16),
                        Text(
                          _isLoadingLocation ? 'Getting your location...' : 'Loading map...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
          
          // Top overlay with menu button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF32C156)),
                onPressed: _showNavigationMenu,
                iconSize: 24,
              ),
            ),
          ),

          // App title
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Rakeb',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF32C156),
                  ),
                ),
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF32C156)),
                    onPressed: () {
                      mapController.move(
                        mapController.camera.center,
                        mapController.camera.zoom + 1,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove, color: Color(0xFF32C156)),
                    onPressed: () {
                      mapController.move(
                        mapController.camera.center,
                        mapController.camera.zoom - 1,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // My location button
          Positioned(
            right: 16,
            bottom: 120,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFF32C156)),
                onPressed: () {
                  _moveToCurrentLocation();
                },
                iconSize: 24,
              ),
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32C156),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RideBookingScreen(
                              currentLocation: _userLocation,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Book a Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}