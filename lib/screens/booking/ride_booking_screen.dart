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
  bool _isMapSelectionMode = false;
  bool _isSelectingStart = false;
  Set<Marker> _markers = {};
  Timer? _searchTimer;

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
      _updateMarkers();
    }
  }

  void _onSearchChanged(String query, bool isStart) {
    // Cancel previous timer
    _searchTimer?.cancel();
    
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

    // Debounce search requests
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(query, isStart);
    });
  }

  Future<void> _searchLocation(String query, bool isStart) async {
    setState(() {
      if (isStart) {
        _isSearchingStart = true;
      } else {
        _isSearchingDestination = true;
      }
    });

    try {
      // Using Google Places API for location search with bias towards Algeria
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?'
          'query=${Uri.encodeComponent(query)}&'
          'location=36.7538,3.0588&'
          'radius=100000&'
          'region=dz&'
          'key=YOUR_GOOGLE_MAPS_API_KEY'
        ),
        headers: {
          'User-Agent': 'RakibApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        
        // Reference location for distance calculation
        LatLng referenceLocation;
        if (isStart) {
          // For start location, use current location if available
          referenceLocation = widget.currentLocation ?? const LatLng(36.7538, 3.0588);
        } else {
          // For destination, use start location if available, otherwise current location
          referenceLocation = _startLocation ?? widget.currentLocation ?? const LatLng(36.7538, 3.0588);
        }

        final suggestions = await Future.wait(
          results.take(8).map((item) async {
            final lat = item['geometry']['location']['lat'];
            final lng = item['geometry']['location']['lng'];
            final location = LatLng(lat, lng);
            
            // Calculate distance from reference point
            final distance = Geolocator.distanceBetween(
              referenceLocation.latitude,
              referenceLocation.longitude,
              lat,
              lng,
            );

            // Get more detailed address information
            String detailedAddress = item['formatted_address'] ?? '';
            String businessStatus = '';
            double? rating;
            
            if (item['business_status'] != null) {
              businessStatus = item['business_status'];
            }
            
            if (item['rating'] != null) {
              rating = item['rating'].toDouble();
            }

            return LocationSuggestion(
              displayName: item['name'] ?? '',
              latitude: lat,
              longitude: lng,
              address: detailedAddress,
              distance: distance,
              businessStatus: businessStatus,
              rating: rating,
              types: List<String>.from(item['types'] ?? []),
            );
          }).toList(),
        );

        // Sort by distance
        suggestions.sort((a, b) => a.distance.compareTo(b.distance));

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
      } else {
        throw Exception('Failed to search locations');
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        if (isStart) {
          _isSearchingStart = false;
          _showStartSuggestions = false;
          _startSuggestions = [];
        } else {
          _isSearchingDestination = false;
          _showDestinationSuggestions = false;
          _destinationSuggestions = [];
        }
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search locations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectLocation(LocationSuggestion suggestion, bool isStart) {
    setState(() {
      if (isStart) {
        _startController.text = suggestion.displayName;
        _startLocation = LatLng(suggestion.latitude, suggestion.longitude);
        _showStartSuggestions = false;
        _startFocusNode.unfocus();
      } else {
        _destinationController.text = suggestion.displayName;
        _destinationLocation = LatLng(suggestion.latitude, suggestion.longitude);
        _showDestinationSuggestions = false;
        _destinationFocusNode.unfocus();
      }
      _updateMarkers();
      _fitMarkersInView();
    });
  }

  void _onMapTap(LatLng position) async {
    if (!_isMapSelectionMode) return;

    try {
      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      String address = 'Selected Location';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        address = '${placemark.street ?? ''}, ${placemark.locality ?? ''}'.trim();
        if (address == ', ') {
          address = '${placemark.name ?? 'Selected Location'}';
        }
      }

      setState(() {
        if (_isSelectingStart) {
          _startLocation = position;
          _startController.text = address;
        } else {
          _destinationLocation = position;
          _destinationController.text = address;
          _destinationFocusNode.unfocus();
        }
        _isMapSelectionMode = false;
        _updateMarkers();
      });

      if (_startLocation != null && _destinationLocation != null) {
        _fitMarkersInView();
      }

      // Hide any existing snackbars first
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSelectingStart ? 'Pickup location set!' : 'Destination set!'),
          backgroundColor: const Color(0xFF32C156),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error getting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get address for selected location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startMapSelection(bool isStart) {
    setState(() {
      // Clear any existing suggestions
      _showStartSuggestions = false;
      _showDestinationSuggestions = false;
      
      _isMapSelectionMode = true;
      _isSelectingStart = isStart;
      _showStartSuggestions = false;
      _showDestinationSuggestions = false;
    });
    
    // Unfocus text fields
    _startFocusNode.unfocus();
    _destinationFocusNode.unfocus();
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isStart ? 'Tap on the map to set pickup location' : 'Tap on the map to set destination'),
        backgroundColor: const Color(0xFF32C156),
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            setState(() {
              _isMapSelectionMode = false;
            });
          },
        ),
      ),
    );
  }

  void _cancelMapSelection() {
    setState(() {
      _isMapSelectionMode = false;
      _isSelectingStart = false;
    });
    
    // Hide any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    FocusScope.of(context).unfocus();
  }

  void _updateMarkers() {
    Set<Marker> markers = {};
    
    if (_startLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: _startLocation!,
        infoWindow: InfoWindow(title: 'Pickup Location', snippet: _startController.text),
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

  Future<void> _fitMarkersInView() async {
    if (_startLocation != null && _destinationLocation != null) {
      final GoogleMapController controller = await _controller.future;
      
      // Calculate bounds
      double minLat = _startLocation!.latitude < _destinationLocation!.latitude 
          ? _startLocation!.latitude : _destinationLocation!.latitude;
      double maxLat = _startLocation!.latitude > _destinationLocation!.latitude 
          ? _startLocation!.latitude : _destinationLocation!.latitude;
      double minLng = _startLocation!.longitude < _destinationLocation!.longitude 
          ? _startLocation!.longitude : _destinationLocation!.longitude;
      double maxLng = _startLocation!.longitude > _destinationLocation!.longitude 
          ? _startLocation!.longitude : _destinationLocation!.longitude;

      // Add padding
      double latPadding = (maxLat - minLat) * 0.2;
      double lngPadding = (maxLng - minLng) * 0.2;

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat - latPadding, minLng - lngPadding),
        northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      );

      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  IconData _getLocationIcon(List<String> types) {
    if (types.contains('restaurant') || types.contains('food')) {
      return Icons.restaurant;
    } else if (types.contains('hospital') || types.contains('pharmacy')) {
      return Icons.local_hospital;
    } else if (types.contains('school') || types.contains('university')) {
      return Icons.school;
    } else if (types.contains('shopping_mall') || types.contains('store')) {
      return Icons.shopping_bag;
    } else if (types.contains('gas_station')) {
      return Icons.local_gas_station;
    } else if (types.contains('bank') || types.contains('atm')) {
      return Icons.account_balance;
    } else if (types.contains('mosque') || types.contains('church')) {
      return Icons.place;
    } else if (types.contains('airport')) {
      return Icons.flight;
    } else if (types.contains('bus_station') || types.contains('transit_station')) {
      return Icons.directions_bus;
    } else {
      return Icons.location_on;
    }
  }

  void _confirmBooking() {
    if (_startLocation != null && _destinationLocation != null) {
      // Calculate distance and estimated time
      final distance = Geolocator.distanceBetween(
        _startLocation!.latitude,
        _startLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      
      final distanceKm = (distance / 1000);
      final estimatedTimeMinutes = (distanceKm * 3).round(); // Assuming 20km/h average speed
      final basePrice = 100; // Base price in DA
      final pricePerKm = 50; // Price per km in DA
      final estimatedPrice = (basePrice + (distanceKm * pricePerKm)).round();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio_button_checked, color: Color(0xFF32C156), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('From: ${_startController.text}', style: const TextStyle(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('To: ${_destinationController.text}', style: const TextStyle(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Distance:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('${distanceKm.toStringAsFixed(1)} km'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Time:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('$estimatedTimeMinutes min'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Price:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF32C156))),
                        Text('$estimatedPrice DA', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF32C156))),
                      ],
                    ),
                  ],
                ),
              ),
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
                  const SnackBar(
                    content: Text('Ride booked successfully! Looking for nearby drivers...'),
                    backgroundColor: Color(0xFF32C156),
                  ),
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
        const SnackBar(content: Text('Please select both pickup and destination locations')),
      );
    }
  }

  Widget _buildSuggestionTile(LocationSuggestion suggestion, bool isStart) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF32C156).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getLocationIcon(suggestion.types),
            color: const Color(0xFF32C156),
            size: 20,
          ),
        ),
        title: Text(
          suggestion.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32C156).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatDistance(suggestion.distance),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF32C156),
                    ),
                  ),
                ),
                if (suggestion.rating != null) ...[
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        suggestion.rating!.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => _selectLocation(suggestion, isStart),
      ),
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required Color iconColor,
    required bool isStart,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => _onSearchChanged(value, isStart),
                  onTap: () {
                    setState(() {
                      _isMapSelectionMode = false;
                      if (isStart) {
                        _showDestinationSuggestions = false;
                      } else {
                        _showStartSuggestions = false;
                      }
                    });
                  },
                ),
              ),
              if (isLoading)
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
          // "Or choose from map" button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: TextButton.icon(
              onPressed: () => _startMapSelection(isStart),
              icon: Icon(
                Icons.map,
                size: 16,
                color: Color(0xFF32C156),
              ),
              label: const Text(
                'or choose from map',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF32C156),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                    _buildLocationInput(
                      controller: _startController,
                      focusNode: _startFocusNode,
                      hintText: 'Pick up location',
                      icon: Icons.radio_button_checked,
                      iconColor: const Color(0xFF32C156),
                      isStart: true,
                      isLoading: _isSearchingStart,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Destination input
                    _buildLocationInput(
                      controller: _destinationController,
                      focusNode: _destinationFocusNode,
                      hintText: 'Where to?',
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      isStart: false,
                      isLoading: _isSearchingDestination,
                    ),
                  ],
                ),
              ),
              
              // Map preview
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: widget.currentLocation ?? const LatLng(36.7538, 3.0588),
                            zoom: 12.0,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                          markers: _markers,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                          compassEnabled: true,
                          onTap: _onMapTap,
                        ),
                        // Map selection overlay
                        if (_isMapSelectionMode)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSelectingStart ? Icons.radio_button_checked : Icons.location_on,
                                      color: _isSelectingStart ? const Color(0xFF32C156) : Colors.red,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isSelectingStart ? 'Select Pickup Location' : 'Select Destination',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap anywhere on the map',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _cancelMapSelection,
                                        setState(() {
                                          _isMapSelectionMode = false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                      ),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
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
              top: 140,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
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
                    return _buildSuggestionTile(suggestion, true);
                  },
                ),
              ),
            ),
          
          // Destination suggestions
          if (_showDestinationSuggestions)
            Positioned(
              top: 240,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
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
                    return _buildSuggestionTile(suggestion, false);
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
    _searchTimer?.cancel();
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
  final double distance; // Distance in meters
  final String businessStatus;
  final double? rating;
  final List<String> types;

  LocationSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.distance,
    this.businessStatus = '',
    this.rating,
    this.types = const [],
  });
}