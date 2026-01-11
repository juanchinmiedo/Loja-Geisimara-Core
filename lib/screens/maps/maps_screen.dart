import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salon_app/generated/l10n.dart'; // 👈 ARB / localización

/// 📍 Coordenadas reales de Galerias Europa (Tondela)
const LatLng kDestination = LatLng(40.51899, -8.08371);

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  GoogleMapController? _map;
  final Map<String, Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // no usamos rutas

  LatLng? _current;
  BitmapDescriptor? _destIcon;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 🔹 Inicializa ubicación y marcador tienda (sin popup)
  Future<void> _bootstrap() async {
    try {
      final ok = await _ensureLocationReady();
      if (!ok) {
        setState(() {
          _error = 'Ativa o GPS e concede permissões de localização.';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _current = LatLng(pos.latitude, pos.longitude);

      _destIcon ??= await _loadMarkerIcon(
        'assets/shop.png', // asegúrate de que existe
        targetPx: 90,
      );

      _markers.clear();
      _markers['destination'] = Marker(
        markerId: const MarkerId('destination'),
        position: kDestination,
        icon: _destIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: "Geisimara Santos Nail Designer"), // 👈 no popup al tocar
        zIndex: 2,
      );

      setState(() => _loading = false);

      if (_map != null) {
        _fitToBounds();
      }
    } catch (e) {
      setState(() {
        _error = 'Erro inicializando mapa: $e';
        _loading = false;
      });
    }
  }

  /// 🔹 Permisos de ubicación
  Future<bool> _ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// 🔹 Cargar icono custom
  Future<BitmapDescriptor> _loadMarkerIcon(
    String assetPath, {
    int targetPx = 96,
  }) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetPx,
    );
    final fi = await codec.getNextFrame();
    final bytes =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }

  /// 🔹 Centra la cámara entre tu ubicación y la tienda
  void _fitToBounds() {
    if (_map == null) return;

    final points = <LatLng>[
      if (_current != null) _current!,
      kDestination,
    ];

    if (points.isEmpty) return;

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _map!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  // 👇 Manteniendo tu lógica pero usando ARB para el mensaje de error
  Future<void> _openInGoogleMaps() async {
    final s = S.of(context);

    final url =
        "https://www.google.com/maps/dir/?api=1&destination=${kDestination.latitude},${kDestination.longitude}";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.openInMapsError), // 👈 ARB
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context); // 👈 para usar openInMaps en el botón

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _current ?? kDestination,
              zoom: 14,
            ),
            onMapCreated: (c) {
              _map = c;
              _fitToBounds();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers.values.toSet(),
            polylines: _polylines, // vacío
          ),

          // 🔹 Botón "Abrir en Google Maps" con texto desde ARB
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: GestureDetector(
                  onTap: _openInGoogleMaps,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff721c80),
                          Color.fromARGB(255, 196, 103, 169),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.openInMaps, // 👈 ARB (en vez de hardcoded)
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
