import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;


class CustomBackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRideStarted = false;
  bool _isFetchingLocation = false;
  String _currentLocation = '';
  Position? _currentPosition;

  // Fetches the user's current location and converts it to an address.
  Future<void> _startRide() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      // 1. Check if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Location services are disabled. Please enable them.')));
        setState(() => _isFetchingLocation = false);
        return;
      }

      // 2. Check for and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')));
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied. Please enable them in settings.')));
        setState(() => _isFetchingLocation = false);
        return;
      }

      // 3. Get the current position if permissions are granted
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String address = '';

      // 4. Try to convert coordinates to a placemark (address)
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = '${place.name}, ${place.locality}, ${place.postalCode}';
        } else {
          address =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
        }
      } on PlatformException catch (_) {
        // If geocoding fails (e.g., no internet), fall back to coordinates.
        address =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not fetch address. Showing coordinates instead.')));
      }

      // 5. Update the state with the new location address
      setState(() {
        _currentLocation = address;
        _currentPosition = position;
        _isFetchingLocation = false;
        _isRideStarted = true;
      });
    } catch (e) {
      // Handle any other errors that might occur
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  // Calls the backend to find the nearest driver.
  Future<void> _callDriver() async {
    if (_currentPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not determine location. Please try again.')),
      );
      return;
    }

    // This is the URL your backend team will give you.
    final url = Uri.parse('https://your-backend-api.com/find-driver');

    // Show loading feedback
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacting the nearest driver...')),
    );

    try {
      // 3. Send the location data to the backend.
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // You might also need an authorization token here in a real app
          // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
        },
        body: jsonEncode({
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          // You would also send a user ID here
          // 'userId': 'some_user_id_from_login',
        }),
      );
      if (!mounted) return;
      // 4. Handle the response from the backend.
      if (response.statusCode == 200) {
        // Success! The backend has received the request.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A driver is on the way!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // The backend returned an error.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding a driver: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // An error occurred with the network request.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to the server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4FF),
      body: Stack(
        children: [
          ClipPath(
            clipper: CustomBackgroundClipper(),
            child: Container(
              color: const Color(0xFF6A5AE0),
              height: 300,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ride Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isFetchingLocation) {
      return _buildLoadingIndicator();
    } else if (!_isRideStarted) {
      return _buildStartRideCard();
    } else {
      return _buildCallDriverCard();
    }
  }

  // Widget for the loading indicator
  Widget _buildLoadingIndicator() {
    return const Column(
      key: ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A5AE0)),
        ),
        SizedBox(height: 20),
        Text(
          'Fetching your location...',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  // Widget for the "Start My Ride" card.
  Widget _buildStartRideCard() {
    return Column(
      key: const ValueKey('startRide'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.drive_eta_outlined,
            size: 80, color: const Color(0xFF6A5AE0).withOpacity(0.8)),
        const SizedBox(height: 24),
        const Text(
          'Ready for your next journey?',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap the button below to find a ride.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF8A7AEC), Color(0xFF6A5AE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A5AE0).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: _startRide,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('START MY RIDE',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20)
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget for the card displaying location and the "Call Driver" button.
  Widget _buildCallDriverCard() {
    return Column(
      key: const ValueKey('callDriver'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Your Current Location:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.green),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _currentLocation,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _callDriver,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              shadowColor: const Color(0xFF00C853).withOpacity(0.4)),
          icon: const Icon(Icons.call_outlined),
          label: const Text('CALL THE NEAREST DRIVER',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
