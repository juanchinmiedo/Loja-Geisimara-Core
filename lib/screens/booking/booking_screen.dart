import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/components/date_piceker.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/controller/auth_controller.dart';
import 'package:salon_app/screens/booking/add_ons_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int selectedServiceIndex = 0;
  int selectedWorkerIndex = 0;

  String? _selectedWorkerId;
  List<String> _selectedWorkerServiceIds = [];
  QueryDocumentSnapshot? _selectedServiceDoc;

  bool _authLoading = false;

  ImageProvider _imageProviderFrom(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return const AssetImage('assets/services/placeholder.png');
    }
  }

  T _getField<T>(QueryDocumentSnapshot doc, String key, T fallback) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return fallback;
      final value = data[key];
      if (value == null) return fallback;
      return value is T ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }

  List<String> _getListOfStrings(QueryDocumentSnapshot doc, String key) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      final raw = (data?[key]) as List<dynamic>? ?? const [];
      return raw.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  void onServiceClick(int index, QueryDocumentSnapshot doc) {
    setState(() {
      selectedServiceIndex = index;
      _selectedServiceDoc = doc;
    });
  }

  void onWorkerClick(int index, QueryDocumentSnapshot doc) {
    final svcIds = _getListOfStrings(doc, 'serviceIds');
    setState(() {
      selectedWorkerIndex = index;
      _selectedWorkerId = doc.id;
      _selectedWorkerServiceIds = svcIds;
      selectedServiceIndex = 0;
      _selectedServiceDoc = null;
    });
  }

  Future<void> _signInForBooking() async {
    try {
      setState(() => _authLoading = true);

      final user =
          await Authentication.signInWithGoogle(context: context);
      if (user == null) {
        setState(() => _authLoading = false);
        return;
      }

      // Guardar en Provider
      if (mounted) {
        context.read<UserProvider>().setUser(user);
      }

      // Crear/actualizar doc en users/{uid}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
          'role': 'client',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _authLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usuario actual (de Provider o directamente de FirebaseAuth)
    final currentUser =
        context.watch<UserProvider>().user ??
            FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ───────── Cabecera (SIEMPRE se muestra) ─────────
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff721c80),
                    Color.fromARGB(255, 196, 103, 169),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.only(top: 38, left: 18, right: 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Spacer(),
                        Text(
                          "Book Your Appointment",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                    CustomDatePicker(),
                  ],
                ),
              ),
            ),

            // ───────── Slots (dummy por ahora) ─────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Available Slots",
                    style: TextStyle(
                      color: Color.fromARGB(255, 45, 42, 42),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        shape: StadiumBorder(side: BorderSide()),
                        label: Text("10:00 AM"),
                        backgroundColor: Colors.white,
                      ),
                      Chip(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        shape: StadiumBorder(side: BorderSide()),
                        label: Text(
                          "10:00 AM",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.purple,
                      ),
                      Chip(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        shape: StadiumBorder(side: BorderSide()),
                        label: Text("10:00 AM"),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                  ChipWrapper(),
                  ChipWrapper(),
                  ChipWrapper(),
                ],
              ),
            ),

            // ───────── Si NO hay usuario ⇒ CTA de login ─────────
            if (currentUser == null)
              _buildLoggedOutSection(context)
            else
              _buildLoggedInSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 60,
            color: Color(0xff721c80),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to manage your appointments',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          _authLoading
              ? const CircularProgressIndicator(color: Colors.purple)
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff721c80),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _signInForBooking,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLoggedInSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ───────── Select Specialist ─────────
        Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Specialist",
                style: TextStyle(
                  color: Color.fromARGB(255, 45, 42, 42),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('workers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.purple,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Error workers: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Text("No hay especialistas disponibles");
                  }

                  final docs = snapshot.data!.docs;

                  if (_selectedWorkerId == null) {
                    final first = docs.first;
                    _selectedWorkerId = first.id;
                    _selectedWorkerServiceIds =
                        _getListOfStrings(first, 'serviceIds');
                    selectedWorkerIndex = 0;
                  }

                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final img = _getField<String>(
                          doc,
                          'img',
                          'assets/workers/placeholder.png',
                        );
                        final name = _getField<String>(
                          doc,
                          'name',
                          'Sin nombre',
                        );
                        final isSelected =
                            index == selectedWorkerIndex;

                        return GestureDetector(
                          onTap: () => onWorkerClick(index, doc),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            margin:
                                const EdgeInsets.only(right: 12.0),
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              border: isSelected
                                  ? Border.all(
                                      width: 4,
                                      color: const Color(0xff721c80),
                                    )
                                  : Border.all(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.circular(14),
                              image: DecorationImage(
                                image: _imageProviderFrom(img),
                                fit: BoxFit.cover,
                              ),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 4),
                              color: Colors.black45,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // ───────── Select Services ─────────
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Services",
                style: TextStyle(
                  color: Color.fromARGB(255, 45, 42, 42),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('services')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.purple,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Error servicios: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const _EmptyServicesPlaceholder();
                  }

                  final allServices = snapshot.data!.docs;

                  final filtered =
                      (_selectedWorkerServiceIds.isEmpty)
                          ? <QueryDocumentSnapshot>[]
                          : allServices
                              .where((s) =>
                                  _selectedWorkerServiceIds
                                      .contains(s.id))
                              .toList();

                  if (filtered.isEmpty) {
                    return const SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                            "Este especialista no tiene servicios asignados"),
                      ),
                    );
                  }

                  if (selectedServiceIndex >= filtered.length) {
                    selectedServiceIndex = 0;
                  }
                  _selectedServiceDoc ??= filtered[0];

                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final img = _getField<String>(
                          doc,
                          'img',
                          'assets/services/placeholder.jpg',
                        );
                        final nameKey =
                            _getField<String>(doc, 'name', '');
                        final name = trServiceOrAddon(
                            context, nameKey);
                        final price = _getField<num>(
                            doc, 'price', 0);
                        final isSelected =
                            index == selectedServiceIndex;

                        return GestureDetector(
                          onTap: () => onServiceClick(index, doc),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            margin:
                                const EdgeInsets.only(right: 12.0),
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: isSelected
                                  ? Border.all(
                                      width: 5,
                                      color: const Color(0xff721c80),
                                    )
                                  : Border.all(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      const BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    topRight: Radius.circular(14),
                                  ),
                                  child: Image(
                                    image:
                                        _imageProviderFrom(img),
                                    height: 60,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Color(0xff721c80),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  price == 0
                                      ? ""
                                      : "€${price.toString()}",
                                  style: const TextStyle(
                                    color: Color(0xff721c80),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // ───────── Botón Next → AddOnsScreen ─────────
        GestureDetector(
          onTap: () {
            if (_selectedWorkerId == null ||
                _selectedServiceDoc == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Selecciona un especialista y un servicio'),
                ),
              );
              return;
            }

            final serviceDoc = _selectedServiceDoc!;
            final serviceId = serviceDoc.id;
            final nameKey =
                _getField<String>(serviceDoc, 'name', '');
            final serviceName =
                trServiceOrAddon(context, nameKey);
            final category = _getField<String>(
                serviceDoc, 'category', 'hands');
            final basePrice = _getField<num>(
                    serviceDoc, 'price', 0)
                .toDouble();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddOnsScreen(
                  workerId: _selectedWorkerId!,
                  serviceId: serviceId,
                  serviceName: serviceName,
                  serviceCategory: category,
                  basePrice: basePrice,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(
                left: 18, right: 18, bottom: 20),
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff721c80),
                  Color.fromARGB(255, 196, 103, 169),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                "Next",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChipWrapper extends StatelessWidget {
  const ChipWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: const [
        Chip(
          padding: EdgeInsets.symmetric(horizontal: 14),
          shape: StadiumBorder(side: BorderSide()),
          label: Text("10:00 AM"),
          backgroundColor: Colors.white,
        ),
        Chip(
          padding: EdgeInsets.symmetric(horizontal: 14),
          shape: StadiumBorder(side: BorderSide()),
          label: Text("10:00 AM"),
          backgroundColor: Colors.white,
        ),
        Chip(
          padding: EdgeInsets.symmetric(horizontal: 14),
          shape: StadiumBorder(side: BorderSide()),
          label: Text("10:00 AM"),
          backgroundColor: Colors.white,
        ),
      ],
    );
  }
}

class _EmptyServicesPlaceholder extends StatelessWidget {
  const _EmptyServicesPlaceholder();

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.cut, 'label': 'Services'},
      {'icon': Icons.brush, 'label': 'Care'},
      {'icon': Icons.star, 'label': 'Best'},
    ];
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (context, i) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 10.0,
                      spreadRadius: 0.5,
                      offset: Offset(3, 3),
                    )
                  ],
                ),
                child: Icon(
                  items[i]['icon'] as IconData,
                  color: const Color(0xff721c80),
                ),
              ),
              Text(
                items[i]['label'] as String,
                style:
                    const TextStyle(color: Colors.deepPurple),
              ),
            ],
          );
        },
      ),
    );
  }
}