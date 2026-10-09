import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RideMapWidget extends StatefulWidget {
  final LatLng? riderLocation;
  final LatLng pickupLocation;
  final LatLng dropLocation;
  final bool isRider;
  
  const RideMapWidget({
    super.key,
    this.riderLocation,
    required this.pickupLocation,
    required this.dropLocation,
    required this.isRider,
  });

  @override
  State<RideMapWidget> createState() => _RideMapWidgetState();
}

class _RideMapWidgetState extends State<RideMapWidget> {
  final MapController _mapController = MapController();
  
  @override
  Widget build(BuildContext context) {
    final center = widget.riderLocation ?? widget.pickupLocation;
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Map tiles (OpenStreetMap - FREE)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.campuslift.app',
        ),
        
        // Markers layer
        MarkerLayer(
          markers: [
            // Pickup marker (GREEN)
            Marker(
              point: widget.pickupLocation,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
            
            // Drop marker (RED)
            Marker(
              point: widget.dropLocation,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
            
            // Rider marker (BLUE) - only if location known
            if (widget.riderLocation != null)
              Marker(
                point: widget.riderLocation!,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.isRider ? Icons.directions_bike : Icons.two_wheeler,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
          ],
        ),
        
        // Route line between pickup and drop
        PolylineLayer(
          polylines: [
            Polyline(
              points: [
                widget.pickupLocation,
                widget.dropLocation,
              ],
              strokeWidth: 4,
              color: Colors.blue.withValues(alpha: 0.7),
            ),
          ],
        ),
      ],
    );
  }
  
  // Auto-center on rider location when it updates
  void centerOnRider() {
    if (widget.riderLocation != null) {
      _mapController.move(widget.riderLocation!, 15);
    }
  }
}
