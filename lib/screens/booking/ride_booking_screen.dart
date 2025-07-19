import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class RideBookingScreen extends StatefulWidget {
  final LatLng? currentLocation;

  const RideBookingScreen({super.key, this.currentLocation});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  
  LatLng? _startLocation;
  LatLng? _destinationLocation;
  List<LocationSuggestion> _startSuggestions = [];
  List<LocationSuggestion> _destinationSuggestions = [];
  bool _isSearchingStart = false;
  bool _isSearchingDestination = false;
  bool _showStartSuggestions = false;
  bool _showDestinationSuggestions = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeStartLocation();
  }

  void _initializeStartLocation() async {
    if (widget.currentLocation != null) {
      _startLocation = widget.currentLocation;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          widget.currentLocation!.latitude,
          widget.currentLocation!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          _startController.text = '${placemark.street ?? ''}, ${placemark.locality ?? ''}';
        }
      } catch (e) {
        _startController.text = 'Current Location';
      }
    }
  }

  Future<void> _searchLocation(String query, bool isStart) async {
    if (query.length < 3) {
      setState(() {
        if (isStart) {
          _startSuggestions = [];
          _showStartSuggestions = false;
        } else {
          _destinationSuggestions = [];
          _showDestinationSuggestions = false;
        }
      });
      return;
    }

    setState(() {
      if (isStart) {
        _isSearchingStart = true;
      } else {
        _isSearchingDestination = true;
      }
    });

    try {
      // Using Google Places API for location search
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&location=36.7538,3.0588&radius=50000&key=YOUR_GOOGLE_MAPS_API_KEY'
        ),
        headers: {
          'User-Agent': 'RakibApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        final suggestions = results.map((item) => LocationSuggestion(
          displayName: item['name'] ?? '',
          latitude: item['geometry']['location']['lat'],
          longitude: item['geometry']['location']['lng'],
          address: item['formatted_address'] ?? '',
        )).toList();

        setState(() {
          if (isStart) {
            _startSuggestions = suggestions;
            _showStartSuggestions = suggestions.isNotEmpty;
            _isSearchingStart = false;
          } else {
            _destinationSuggestions = suggestions;
            _showDestinationSuggestions = suggestions.isNotEmpty;
            _isSearchingDestination = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        if (isStart) {
          _isSearchingStart = false;
          _showStartSuggestions = false;
        } else {
          _isSearchingDestination = false;
          _showDestinationSuggestions = false;
        }
      });
    }
  }

  void _selectLocation(LocationSuggestion suggestion, bool isStart) {
    setState(() {
      if (isStart) {
        _startController.text = suggestion.displayName;
        _startLocation = LatLng(suggestion.latitude, suggestion.longitude);
        _showStartSuggestions = false;
        _startFocusNode.unfocus();
        _updateMarkers();
      } else {
        _destinationController.text = suggestion.displayName;
        _destinationLocation = LatLng(suggestion.latitude, suggestion.longitude);
        _showDestinationSuggestions = false;
        _destinationFocusNode.unfocus();
        _updateMarkers();
      }
    });
  }

  void _updateMarkers() {
    Set<Marker> markers = {};
    
    if (_startLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: _startLocation!,
        infoWindow: InfoWindow(title: 'Pickup', snippet: _startController.text),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    
    if (_destinationLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLocation!,
        infoWindow: InfoWindow(title: 'Destination', snippet: _destinationController.text),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _confirmBooking() {
    if (_startLocation != null && _destinationLocation != null) {
      // Calculate distance
      final distance = Geolocator.distanceBetween(
        _startLocation!.latitude,
        _startLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      
      final distanceKm = (distance / 1000).toStringAsFixed(1);
      final estimatedPrice = (distance / 1000 * 50).toInt(); // 50 DA per km

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From: ${_startController.text}'),
              const SizedBox(height: 8),
              Text('To: ${_destinationController.text}'),
              const SizedBox(height: 8),
              Text('Distance: $distanceKm km'),
              const SizedBox(height: 8),
              Text('Estimated Price: $estimatedPrice DA'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride booked successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF32C156),
              ),
              child: const Text('Book Ride', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and destination')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Book a Ride',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF32C156),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Location inputs
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Start location input
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.radio_button_checked,
                              color: Color(0xFF32C156),
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _startController,
                              focusNode: _startFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'Pick up location',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (value) => _searchLocation(value, true),
                              onTap: () {
                                setState(() {
                                  _showDestinationSuggestions = false;
                                });
                              },
                            ),
                          ),
                          if (_isSearchingStart)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF32C156),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Destination input
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _destinationController,
                              focusNode: _destinationFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'Where to?',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (value) => _searchLocation(value, false),
                              onTap: () {
                                setState(() {
                                  _showStartSuggestions = false;
                                });
                              },
                            ),
                          ),
                          if (_isSearchingDestination)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF32C156),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Map preview (if both locations selected)
              if (_startLocation != null && _destinationLocation != null)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: _startLocation!,
                          zoom: 12.0,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        markers: _markers,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                ),
              
              // Book ride button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF32C156),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Confirm Booking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Start location suggestions
          if (_showStartSuggestions)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
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
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _startSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _startSuggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.grey),
                      title: Text(
                        suggestion.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectLocation(suggestion, true),
                    );
                  },
                ),
              ),
            ),
          
          // Destination suggestions
          if (_showDestinationSuggestions)
            Positioned(
              top: 164,
              left: 16,
              right: 16,
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
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _destinationSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _destinationSuggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.grey),
                      title: Text(
                        suggestion.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectLocation(suggestion, false),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _destinationController.dispose();
    _startFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }
}

class LocationSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;
  final String address;

  LocationSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}