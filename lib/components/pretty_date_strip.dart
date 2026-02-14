import 'package:flutter/material.dart';
import 'package:salon_app/utils/date_labels.dart';

class PrettyDateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChange;
  final int forwardDays;

  const PrettyDateStrip({
    super.key,
    required this.selectedDate,
    required this.onChange,
    this.forwardDays = 365 * 2,
  });

  @override
  State<PrettyDateStrip> createState() => _PrettyDateStripState();
}

class _PrettyDateStripState extends State<PrettyDateStrip> {
  late final DateTime _today;
  late DateTime _sel;

  final ScrollController _sc = ScrollController();

  static const double _itemW = 56;
  static const double _itemH = 66;
  static const double _gap = 8;
  static const double _padX = 12;

  static const double _radius = 12; // ✅ menos redondeado

  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    _today = _d(DateTime.now());
    _sel = _clamp(widget.selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToDateLeft(_sel, animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant PrettyDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    final next = _clamp(widget.selectedDate);
    if (_same(next, _sel)) return;

    setState(() => _sel = next);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToDateLeft(next, animate: true);
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  DateTime _clamp(DateTime x) {
    final dx = _d(x);
    return dx.isBefore(_today) ? _today : dx;
  }

  int _indexOf(DateTime date) => _d(date).difference(_today).inDays.clamp(0, widget.forwardDays);

  double _offsetForIndexLeft(int index) => _padX + index * (_itemW + _gap);

  void _scrollToDateLeft(DateTime date, {required bool animate}) {
    if (!_sc.hasClients) return;

    final i = _indexOf(date);
    final target = _offsetForIndexLeft(i);

    final maxOff = _sc.position.maxScrollExtent;
    final off = target.clamp(0.0, maxOff);

    if (!animate) {
      _sc.jumpTo(off);
    } else {
      _sc.animateTo(off, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  void _pick(DateTime date) {
    final safe = _clamp(date);
    if (_same(safe, _sel)) return;

    setState(() => _sel = safe);
    widget.onChange(safe);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToDateLeft(safe, animate: true);
    });
  }

  void _prevMonth() => _pick(DateTime(_sel.year, _sel.month - 1, 1));
  void _nextMonth() => _pick(DateTime(_sel.year, _sel.month + 1, 1));

  @override
  Widget build(BuildContext context) {
    final isAtToday = _same(_sel, _today);
    final monthLabel = months(_sel.month);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, left: 4, right: 4, bottom: 18),
          child: Row(
            children: [
              GestureDetector(
                onTap: isAtToday ? null : _prevMonth,
                child: Icon(Icons.arrow_back_ios, color: isAtToday ? Colors.white24 : Colors.white60, size: 20),
              ),
              const Spacer(),
              Text(
                "$monthLabel, ${_sel.year}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _nextMonth,
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 20),
              ),
            ],
          ),
        ),

        SizedBox(
          height: _itemH + 10,
          child: ListView.builder(
            controller: _sc,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _padX),
            itemCount: widget.forwardDays + 1,
            itemBuilder: (context, idx) {
              final d = _today.add(Duration(days: idx));
              final selected = _same(d, _sel);

              final mon = months(d.month);   // MES arriba
              final dow = week(d.weekday);   // DOW abajo

              // ✅ no seleccionado: sin borde (solo fondo leve)
              final bg = selected ? Colors.white : Colors.transparent;
              // colores texto
              final main = selected ? const Color(0xff721c80) : Colors.white;
              final sub = selected ? const Color(0xff721c80).withOpacity(0.85) : Colors.white70;

              return Padding(
                padding: EdgeInsets.only(right: idx == widget.forwardDays ? 0 : _gap),
                child: InkWell(
                  onTap: () => _pick(d),
                  borderRadius: BorderRadius.circular(_radius),
                  child: Container(
                    width: _itemW,
                    height: _itemH,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(_radius),

                      // ✅ borde SOLO si está seleccionado
                      border: selected ? Border.all(color: Colors.white, width: 2) : null,

                      // ✅ sombra SOLO si está seleccionado
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                blurRadius: 14,
                                offset: Offset(0, 6),
                                color: Colors.black26,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6), // ↓ menos padding
                      child: FittedBox(
                        fit: BoxFit.scaleDown, // ✅ si no cabe, reduce
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mon,
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                              style: TextStyle(
                                fontSize: 9.5,          // ↓ un poco
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                height: 1.0,            // ✅ compacta
                                color: sub,
                              ),
                            ),
                            const SizedBox(height: 3),  // ↓ menos espacio
                            Text(
                              "${d.day}",
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                              style: TextStyle(
                                fontSize: 15.5,         // ✅ número más bajo
                                fontWeight: FontWeight.w600,
                                height: 0.95,           // ✅ baja “altura” visual del número
                                color: main,
                              ),
                            ),
                            const SizedBox(height: 3),  // ↓ menos espacio
                            Text(
                              dow,
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.35,
                                height: 1.0,
                                color: sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
