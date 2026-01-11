import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/provider/user_provider.dart';

class SelectedAddon {
  final String addonId;
  final String name;
  final String mode; // 'full' | 'per_pair' | 'fixed'
  final int pairs;
  final double unitPrice;
  final double totalPrice;

  SelectedAddon({
    required this.addonId,
    required this.name,
    required this.mode,
    required this.pairs,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class AddOnsScreen extends StatefulWidget {
  final String workerId;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final double basePrice;

  const AddOnsScreen({
    super.key,
    required this.workerId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.basePrice,
  });

  @override
  State<AddOnsScreen> createState() => _AddOnsScreenState();
}

class _AddOnsScreenState extends State<AddOnsScreen> {
  final List<SelectedAddon> _selectedAddons = [];

  double get addonsTotal =>
      _selectedAddons.fold(0.0, (sum, a) => sum + a.totalPrice);

  double get total => widget.basePrice + addonsTotal;

  void _addOrReplaceAddon(SelectedAddon addon) {
    setState(() {
      _selectedAddons.removeWhere((a) => a.addonId == addon.addonId);
      _selectedAddons.add(addon);
    });
  }

  void _removeAddon(String addonId) {
    setState(() {
      _selectedAddons.removeWhere((a) => a.addonId == addonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: const Color(0xff721c80),
      ),
      body: Column(
        children: [
          // Resumen de precios
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Base: €${widget.basePrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedAddons.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Add-ons: €${addonsTotal.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  "Total: €${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff721c80),
                  ),
                ),
              ],
            ),
          ),

          // Lista de addons
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('addons')
                  .where(
                    'appliesToCategories',
                    arrayContains: widget.serviceCategory,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.purple,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error addons: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child:
                        Text('No hay decoraciones disponibles'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final addonId = doc.id;
                    final nameKey =
                        doc['name'] as String? ?? '';
                    final name =
                        trServiceOrAddon(context, nameKey);
                    final selected = _selectedAddons
                        .any((a) => a.addonId == addonId);

                    return ListTile(
                      title: Text(name),
                      subtitle:
                          Text(_subtitleFromAddonDoc(doc)),
                      trailing: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: selected
                            ? const Color(0xff721c80)
                            : Colors.grey,
                      ),
                      onTap: () =>
                          _openAddonConfig(context, doc, name),
                      onLongPress: selected
                          ? () => _removeAddon(addonId)
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Botón confirmar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 12),
            child: GestureDetector(
              onTap: () async {
                // 1) Asegurar que hay usuario logeado
                final user = context
                        .read<UserProvider>()
                        .user ??
                    FirebaseAuth.instance.currentUser;

                if (user == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Inicia sesión para poder agendar una cita'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('appointments')
                      .add({
                    // Datos de usuario
                    'userId': user.uid,
                    'userName': user.displayName ?? '',
                    'userEmail': user.email ?? '',

                    // Datos del worker y servicio
                    'workerId': widget.workerId,
                    'serviceId': widget.serviceId,
                    'serviceName': widget.serviceName,
                    'serviceCategory':
                        widget.serviceCategory,

                    // Precios
                    'basePrice': widget.basePrice,
                    'addons': _selectedAddons
                        .map((a) => {
                              'addonId': a.addonId,
                              'name': a.name,
                              'mode': a.mode,
                              'pairs': a.pairs,
                              'unitPrice': a.unitPrice,
                              'totalPrice': a.totalPrice,
                            })
                        .toList(),
                    'addonsTotal': addonsTotal,
                    'total': total,

                    // Estado y tiempos
                    'status': 'booked',
                    // TODO: cuando tengas selector de hora/fecha real:
                    // 'appointmentDate': selectedDateTime,
                    'createdAt':
                        FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text('Cita creada con éxito ✅'),
                    ),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                          'Error al guardar la cita: $e'),
                    ),
                  );
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff721c80),
                      Color.fromARGB(
                          255, 196, 103, 169),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Confirm appointment",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
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

  String _subtitleFromAddonDoc(
      QueryDocumentSnapshot doc) {
    final pricingModel =
        doc['pricingModel'] as String? ?? 'fixed';
    if (pricingModel == 'per_pair_or_full') {
      final perPair = (doc['pricePerPair'] as num?)
              ?.toDouble() ??
          0;
      final full =
          (doc['fullHandPrice'] as num?)?.toDouble() ??
              0;
      return 'Mano completa: €$full · Por par: €$perPair';
    } else if (pricingModel == 'per_pair') {
      final perPair = (doc['pricePerPair'] as num?)
              ?.toDouble() ??
          0;
      return '€$perPair por par de dedos';
    } else {
      final fixed =
          (doc['price'] as num?)?.toDouble() ?? 0;
      return 'Precio fijo: €$fixed';
    }
  }

  Future<void> _openAddonConfig(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String name,
  ) async {
    final pricingModel =
        doc['pricingModel'] as String? ?? 'fixed';

    if (pricingModel == 'per_pair_or_full') {
      await _configPerPairOrFull(context, doc, name);
    } else if (pricingModel == 'per_pair') {
      await _configPerPairOnly(context, doc, name);
    } else {
      await _configFixed(context, doc, name);
    }
  }

  Future<void> _configFixed(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String name,
  ) async {
    final price =
        (doc['price'] as num?)?.toDouble() ?? 0;
    final addon = SelectedAddon(
      addonId: doc.id,
      name: name,
      mode: 'fixed',
      pairs: 0,
      unitPrice: price,
      totalPrice: price,
    );
    _addOrReplaceAddon(addon);
  }

  Future<void> _configPerPairOnly(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String name,
  ) async {
    final perPair = (doc['pricePerPair'] as num?)
            ?.toDouble() ??
        0;
    final maxPairs =
        (doc['maxPairs'] as num?)?.toInt() ?? 5;
    int tempPairs = 1;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final totalPrice = tempPairs * perPair;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Selecciona número de pares de dedos",
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: tempPairs > 1
                            ? () {
                                setStateModal(() {
                                  tempPairs--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$tempPairs',
                        style: const TextStyle(
                            fontSize: 18),
                      ),
                      IconButton(
                        onPressed: tempPairs < maxPairs
                            ? () {
                                setStateModal(() {
                                  tempPairs++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: €${totalPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xff721c80),
                    ),
                    onPressed: () {
                      final addon = SelectedAddon(
                        addonId: doc.id,
                        name: name,
                        mode: 'per_pair',
                        pairs: tempPairs,
                        unitPrice: perPair,
                        totalPrice: totalPrice,
                      );
                      _addOrReplaceAddon(addon);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _configPerPairOrFull(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String name,
  ) async {
    final perPair = (doc['pricePerPair'] as num?)
            ?.toDouble() ??
        0;
    final full =
        (doc['fullHandPrice'] as num?)?.toDouble() ??
            0;
    final maxPairs =
        (doc['maxPairs'] as num?)?.toInt() ?? 5;

    String mode = 'full';
    int tempPairs = maxPairs;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final totalPrice = (mode == 'full')
                ? full
                : (tempPairs * perPair);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'full',
                        groupValue: mode,
                        onChanged: (value) {
                          setStateModal(() {
                            mode = value!;
                            tempPairs = maxPairs;
                          });
                        },
                      ),
                      const Text('Mano completa'),
                      const SizedBox(width: 8),
                      Text(
                        '€${full.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'per_pair',
                        groupValue: mode,
                        onChanged: (value) {
                          setStateModal(() {
                            mode = value!;
                            tempPairs = 1;
                          });
                        },
                      ),
                      const Text('Por par de dedos'),
                      const SizedBox(width: 8),
                      Text(
                        '€${perPair.toStringAsFixed(2)}/par',
                      ),
                    ],
                  ),
                  if (mode == 'per_pair') ...[
                    const SizedBox(height: 8),
                    const Text(
                        "Selecciona número de pares de dedos"),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: tempPairs > 1
                              ? () {
                                  setStateModal(() {
                                    tempPairs--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '$tempPairs',
                          style: const TextStyle(
                              fontSize: 18),
                        ),
                        IconButton(
                          onPressed: tempPairs < maxPairs
                              ? () {
                                  setStateModal(() {
                                    tempPairs++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Total: €${totalPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xff721c80),
                    ),
                    onPressed: () {
                      final addon = SelectedAddon(
                        addonId: doc.id,
                        name: name,
                        mode: mode,
                        pairs: mode == 'full'
                            ? maxPairs
                            : tempPairs,
                        unitPrice: mode == 'full'
                            ? full
                            : perPair,
                        totalPrice: totalPrice,
                      );
                      _addOrReplaceAddon(addon);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
