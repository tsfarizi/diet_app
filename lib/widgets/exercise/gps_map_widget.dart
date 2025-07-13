import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../models/walking_session_model.dart';
import '../../services/gps_tracking_service.dart';
import '../../utils/gps_utils.dart';

class GPSMapWidget extends StatefulWidget {
  final WalkingSession? session;
  final bool isTracking;
  final double height;
  final bool showUserLocation;
  final bool autoFollow;

  const GPSMapWidget({
    super.key,
    this.session,
    this.isTracking = false,
    this.height = 300,
    this.showUserLocation = true,
    this.autoFollow = true,
  });

  @override
  State<GPSMapWidget> createState() => _GPSMapWidgetState();
}

class _GPSMapWidgetState extends State<GPSMapWidget> {
  final GPSTrackingService _gpsService = GPSTrackingService();
  final MapController _mapController = MapController();
  
  StreamSubscription<LocationPoint>? _locationSubscription;
  LocationPoint? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _isMapReady = false;
  double _currentZoom = 16.0;
  LatLng? _centerPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    if (widget.isTracking) {
      _startLocationTracking();
    }
  }

  void _initializeMap() {
    if (widget.session != null && widget.session!.route.isNotEmpty) {
      _routePoints = widget.session!.route
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      
      if (_routePoints.isNotEmpty) {
        _centerPosition = _routePoints.last;
        
        if (_routePoints.length > 1) {
          final bounds = GPSUtils.getBounds(widget.session!.route);
          _centerPosition = LatLng(
            (bounds['minLat']! + bounds['maxLat']!) / 2,
            (bounds['minLon']! + bounds['maxLon']!) / 2,
          );
          
          final latDiff = bounds['maxLat']! - bounds['minLat']!;
          final lonDiff = bounds['maxLon']! - bounds['maxLon']!;
          final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
          
          if (maxDiff > 0.01) {
            _currentZoom = 13.0;
          } else if (maxDiff > 0.005) {
            _currentZoom = 15.0;
          } else {
            _currentZoom = 17.0;
          }
        }
      }
    }
    
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      final position = await _gpsService.getCurrentPosition();
      if (position != null && mounted) {
        final location = LocationPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
          altitude: position.altitude,
        );
        
        setState(() {
          _currentLocation = location;
          _centerPosition ??= LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _startLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = _gpsService.locationStream?.listen(
      (location) {
        if (mounted) {
          setState(() {
            _currentLocation = location;
            
            if (widget.autoFollow && _isMapReady) {
              _mapController.move(
                LatLng(location.latitude, location.longitude),
                _currentZoom,
              );
            }
          });
        }
      },
      onError: (error) {
        debugPrint('GPS location error: $error');
      },
    );
  }

  @override
  void didUpdateWidget(GPSMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.session != oldWidget.session) {
      _updateRoute();
    }
    
    if (widget.isTracking != oldWidget.isTracking) {
      if (widget.isTracking) {
        _startLocationTracking();
      } else {
        _locationSubscription?.cancel();
      }
    }
  }

  void _updateRoute() {
    if (widget.session != null && widget.session!.route.isNotEmpty) {
      setState(() {
        _routePoints = widget.session!.route
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centerPosition ?? LatLng(-6.2088, 106.8456),
                initialZoom: _currentZoom,
                minZoom: 10.0,
                maxZoom: 20.0,
                interactionOptions: InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  enableScrollWheel: true,
                  rotationWinGestures: MultiFingerGesture.rotate,
                  pinchZoomWinGestures: MultiFingerGesture.pinchZoom,
                ),
                onMapReady: () {
                  setState(() {
                    _isMapReady = true;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dietapp.tracking',
                  maxZoom: 20,
                  tileBuilder: (context, widget, tile) {
                    return ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.grey.withValues(alpha: 0.1),
                        BlendMode.saturation,
                      ),
                      child: widget,
                    );
                  },
                ),
                
                if (_routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                        borderStrokeWidth: 2.0,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),
                
                if (_routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _routePoints.first,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      
                      if (_routePoints.length > 1)
                        Marker(
                          point: _routePoints.last,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                
                if (widget.showUserLocation && _currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isTracking ? Icons.gps_fixed : Icons.gps_off,
                      color: widget.isTracking ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      widget.isTracking ? 'Tracking' : 'Stopped',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (widget.session != null && widget.session!.route.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.session!.route.length} titik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            Positioned(
              bottom: 8,
              right: 8,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: "zoom_in",
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () {
                      _currentZoom = (_currentZoom + 1).clamp(10.0, 20.0);
                      _mapController.move(
                        _mapController.camera.center,
                        _currentZoom,
                      );
                    },
                    child: Icon(Icons.zoom_in),
                  ),
                  SizedBox(height: 4),
                  FloatingActionButton.small(
                    heroTag: "zoom_out",
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () {
                      _currentZoom = (_currentZoom - 1).clamp(10.0, 20.0);
                      _mapController.move(
                        _mapController.camera.center,
                        _currentZoom,
                      );
                    },
                    child: Icon(Icons.zoom_out),
                  ),
                  if (widget.autoFollow && _currentLocation != null) ...[
                    SizedBox(height: 4),
                    FloatingActionButton.small(
                      heroTag: "center_location",
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        if (_currentLocation != null) {
                          _mapController.move(
                            LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
                            _currentZoom,
                          );
                        }
                      },
                      child: Icon(Icons.my_location),
                    ),
                  ],
                  if (_routePoints.length > 1) ...[
                    SizedBox(height: 4),
                    FloatingActionButton.small(
                      heroTag: "fit_route",
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        if (_routePoints.isNotEmpty) {
                          _fitMapToRoute();
                        }
                      },
                      child: Icon(Icons.fit_screen),
                    ),
                  ],
                ],
              ),
            ),
            
            if (_routePoints.isEmpty && !widget.isTracking)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Mulai tracking untuk melihat jalur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Jalur akan digambar secara real-time',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _fitMapToRoute() {
    if (_routePoints.length < 2) return;
    
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;
    
    for (final point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    double zoom = 16.0;
    if (maxDiff > 0.02) {
      zoom = 12.0;
    } else if (maxDiff > 0.01) {
      zoom = 14.0;
    } else if (maxDiff > 0.005) {
      zoom = 15.0;
    }
    
    _currentZoom = zoom;
    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }
}