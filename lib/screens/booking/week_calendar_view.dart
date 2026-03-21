// lib/screens/booking/week_calendar_view.dart
//
// CAMBIOS vs versión anterior (commit 3 – blocked slots):
//
//  • Nuevos parámetros opcionales: blockedSlotRepo, workerId
//  • StreamSubscription _blockedSub suscrita a streamForWeek()
//  • _blockedSlots se re-renderiza como franjas negras semitransparentes
//    en la cuadrícula (Positioned dentro del Stack existente)
//  • Long-press en celda vacía → abre BlockSlotDialog (si repo != null)
//  • Tap normal sigue funcionando igual
//  • Todo lo demás (appointments, header, paginación) 100% sin tocar

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/repositories/blocked_slot_repo.dart';
import 'package:salon_app/screens/booking/block_slot_dialog.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/utils/date_labels.dart';
import 'package:salon_app/utils/pending_confirmation_utils.dart';
import 'package:salon_app/utils/localization_helper.dart';

typedef TapAppt = void Function(String id, Map<String, dynamic> data);
typedef TapEmpty = void Function(DateTime day, TimeOfDay tod);
typedef WeekChanged = void Function(DateTime newWeekStartMonday);
typedef SelectDay = void Function(DateTime day);

class WeekCalendarView extends StatefulWidget {
  const WeekCalendarView({
    super.key,
    required this.weekStartMonday,
    required this.selectedDay,
    required this.onSelectDay,
    required this.stream,
    required this.serviceColorById,
    required this.startHour,
    required this.endHour,
    required this.onWeekChanged,
    required this.onTapAppointment,
    required this.onTapEmpty,
    // ── Blocked slots (opt-in) ──────────────────────────────────────────────
    // Pasar estos dos params activa el soporte de franjas bloqueadas.
    // Sin ellos el widget funciona exactamente igual que antes.
    this.blockedSlotRepo,
    this.workerId,
  });

  final DateTime weekStartMonday;
  final DateTime selectedDay;
  final SelectDay onSelectDay;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Map<String, Color> serviceColorById;
  final int startHour;
  final int endHour;
  final WeekChanged onWeekChanged;
  final TapAppt onTapAppointment;
  final TapEmpty onTapEmpty;

  /// Repo de franjas bloqueadas. Si es null, no se renderizan bloques.
  final BlockedSlotRepo? blockedSlotRepo;

  /// workerId del worker cuya agenda se está viendo.
  final String? workerId;

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  late final PageController _page;
  late DateTime _anchorWeekStartMonday;
  late DateTime _visibleWeekStartMonday;
  late DateTime _selectedLocalDay;

  static const int _kWeekCenter = 10000;

  // Layout (idéntico al original)
  static const double _outerPad  = 0;
  static const double _gutterW   = 20;
  static const double _gutterGap = 4;
  static const double _hourRowH  = 56;
  static const double _topPad    = 6;

  // ── Blocked slots state ─────────────────────────────────────────────────────
  List<BlockedSlot> _blockedSlots = const [];
  StreamSubscription<List<BlockedSlot>>? _blockedSub;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  DateTime _weekStartForIndex(int index) {
    final deltaWeeks = index - _kWeekCenter;
    return _anchorWeekStartMonday.add(Duration(days: deltaWeeks * 7));
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _yyyymmdd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  List<String> _weekDateKeys(DateTime weekStart) =>
      List.generate(7, (i) => _yyyymmdd(weekStart.add(Duration(days: i))));

  // ── Blocked slots subscription ───────────────────────────────────────────────

  void _subscribeBlocked(DateTime weekStart) {
    _blockedSub?.cancel();
    _blockedSub = null;

    final repo = widget.blockedSlotRepo;
    final wid  = widget.workerId;
    if (repo == null || wid == null || wid.isEmpty) return;

    _blockedSub = repo
        .streamForWeek(wid, _weekDateKeys(weekStart))
        .listen((slots) {
      if (!mounted) return;
      setState(() => _blockedSlots = slots);
    });
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _anchorWeekStartMonday  = _dayOnly(widget.weekStartMonday);
    _visibleWeekStartMonday = _anchorWeekStartMonday;
    _selectedLocalDay       = _dayOnly(widget.selectedDay);
    _page = PageController(initialPage: _kWeekCenter);
    _subscribeBlocked(_anchorWeekStartMonday);
  }

  @override
  void dispose() {
    _blockedSub?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WeekCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldWs = _dayOnly(oldWidget.weekStartMonday);
    final newWs = _dayOnly(widget.weekStartMonday);

    if (oldWs != newWs) {
      _anchorWeekStartMonday  = newWs;
      _visibleWeekStartMonday = newWs;
      _subscribeBlocked(newWs);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _page.jumpToPage(_kWeekCenter);
      });
    }

    // Si cambia el workerId, re-suscribir
    if (oldWidget.workerId != widget.workerId) {
      _subscribeBlocked(_visibleWeekStartMonday);
    }

    final oldSel = _dayOnly(oldWidget.selectedDay);
    final newSel = _dayOnly(widget.selectedDay);
    if (oldSel != newSel) {
      if (!mounted) return;
      setState(() => _selectedLocalDay = newSel);
    }
  }

  // ── Long-press → BlockSlotDialog ─────────────────────────────────────────────

  Future<void> _openBlockDialog(DateTime day, int tappedMin) async {
    final repo = widget.blockedSlotRepo;
    final wid  = widget.workerId;
    if (repo == null || wid == null || wid.isEmpty) return;

    await showDialog(
      context: context,
      builder: (_) => BlockSlotDialog(
        workerId: wid,
        date: day,
        repo: repo,
        initialStartMin: tappedMin,
        initialEndMin: (tappedMin + 60).clamp(0, 21 * 60),
      ),
    );
    // El stream se actualiza solo; no hace falta setState manual
  }

  // ── Select day ───────────────────────────────────────────────────────────────

  void _selectDayInstant(DateTime day) {
    final d = _dayOnly(day);
    if (!mounted) return;
    setState(() => _selectedLocalDay = d);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_sameDay(_selectedLocalDay, d)) return;
      widget.onSelectDay(d);
    });
  }

  // ── Time label ───────────────────────────────────────────────────────────────

  Widget _timeLabel(BuildContext context, int hour) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        hour.toString(),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Blocked slot Positioned widgets ─────────────────────────────────────────
  //
  // Apariencia: fondo negro semitransparente con bordes sutiles.
  // Tap: ignorado (no se puede crear cita encima).
  // Long-press: abre BlockSlotDialog para gestionar el bloque.

  List<Widget> _buildBlockedSlotWidgets({
    required DateTime weekStart,
    required double colW,
    required double rowH,
  }) {
    final baseMin = widget.startHour * 60;
    final out     = <Widget>[];

    for (final slot in _blockedSlots) {
      // Buscar en qué día de la semana cae
      int dayIndex = -1;
      for (int i = 0; i < 7; i++) {
        final d = weekStart.add(Duration(days: i));
        if (_yyyymmdd(d) == slot.date) {
          dayIndex = i;
          break;
        }
      }
      if (dayIndex < 0) continue;

      final topPx = ((slot.startMin - baseMin) / 60.0) * rowH;
      final heightPx =
          ((slot.endMin - slot.startMin) / 60.0) * rowH;
      if (heightPx <= 0) continue;

      final left = dayIndex * colW;

      out.add(
        Positioned(
          left:   left + 1,
          top:    topPx + 1,
          width:  colW - 2,
          height: heightPx.clamp(6.0, double.infinity) - 2,
          child: GestureDetector(
            // Absorbe el tap para que no cree cita encima del bloque
            onTap: () {},
            onLongPress: () {
              final day = weekStart.add(Duration(days: dayIndex));
              _openBlockDialog(day, slot.startMin);
            },
            child: Container(
              decoration: BoxDecoration(
                // Negro semitransparente — se ve claramente como "no disponible"
                color: Colors.black.withOpacity(0.30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.black.withOpacity(0.50),
                  width: 1,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: slot.reason.isNotEmpty
                  ? Text(
                      slot.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : const Icon(
                      Icons.block,
                      size: 10,
                      color: Colors.white54,
                    ),
            ),
          ),
        ),
      );
    }

    return out;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalHours = widget.endHour - widget.startHour;
    final gridHeight = totalHours * _hourRowH;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        final double maxH = math
            .min(MediaQuery.of(context).size.height * 0.70, 640)
            .toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _outerPad),
          child: SizedBox(
            height: maxH,
            child: Column(
              children: [
                _WeekHeaderRow(
                  gutterWidth: _gutterW + _gutterGap,
                  weekStartMonday: _visibleWeekStartMonday,
                  selectedDay: _selectedLocalDay,
                  onSelectDay: _selectDayInstant,
                ),
                const SizedBox(height: _topPad),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    onPageChanged: (idx) {
                      final ws = _weekStartForIndex(idx);
                      if (mounted) {
                        setState(() => _visibleWeekStartMonday = ws);
                      }
                      _subscribeBlocked(ws);
                      widget.onWeekChanged(ws);
                    },
                    itemBuilder: (context, index) {
                      final weekStart = _weekStartForIndex(index);

                      return LayoutBuilder(
                        builder: (context, c) {
                          final fullW = c.maxWidth;
                          final gridW = fullW - (_gutterW + _gutterGap);

                          const minColW      = 46.0;
                          const desiredGridW = minColW * 7;

                          final effectiveGridW =
                              math.max(gridW, desiredGridW);
                          final colW = effectiveGridW / 7.0;

                          final positionedBlocks =
                              _buildAppointmentBlocksWithOverlap(
                            weekStart: weekStart,
                            weekDocs: docs,
                            colW: colW,
                            rowH: _hourRowH,
                          );

                          // Bloques bloqueados para esta semana
                          final blockedWidgets = _buildBlockedSlotWidgets(
                            weekStart: weekStart,
                            colW: colW,
                            rowH: _hourRowH,
                          );

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 90),
                              child: SizedBox(
                                height: gridHeight,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Gutter de horas
                                    SizedBox(
                                      width: _gutterW,
                                      child: Column(
                                        children:
                                            List.generate(totalHours, (i) {
                                          final hour =
                                              widget.startHour + i;
                                          return SizedBox(
                                            height: _hourRowH,
                                            child: _timeLabel(
                                                context, hour),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: _gutterGap),

                                    // Grid principal
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics:
                                            const BouncingScrollPhysics(),
                                        child: SizedBox(
                                          width: effectiveGridW,
                                          child: Stack(
                                            children: [
                                              // 1) Fondo cuadrícula
                                              _GridBackground(
                                                totalHours: totalHours,
                                                rowH: _hourRowH,
                                                colW: colW,
                                              ),

                                              // 2) Franjas bloqueadas
                                              //    (debajo del tap layer pero
                                              //    encima del fondo)
                                              ...blockedWidgets,

                                              // 3) Tap layer (vacío)
                                              //    Solo activa si la celda
                                              //    NO está bloqueada.
                                              //    Long-press en bloqueado
                                              //    lo gestiona el propio widget.
                                              Positioned.fill(
                                                child: _EmptyTapLayer(
                                                  weekStart: weekStart,
                                                  colW: colW,
                                                  rowH: _hourRowH,
                                                  startHour: widget.startHour,
                                                  blockedSlots: _blockedSlots,
                                                  onLongPress: (day, tappedMin) =>
                                                      _openBlockDialog(
                                                          day, tappedMin),
                                                  onTap: (day, tod) async {
                                                    final now = DateTime.now();
                                                    final today = DateTime(
                                                        now.year,
                                                        now.month,
                                                        now.day);
                                                    final dd = DateTime(
                                                        day.year,
                                                        day.month,
                                                        day.day);
                                                    if (dd.isBefore(today)) {
                                                      return;
                                                    }
                                                    widget.onTapEmpty(
                                                        day, tod);
                                                  },
                                                ),
                                              ),

                                              // 4) Appointments (encima de todo)
                                              ...positionedBlocks,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Appointment blocks (idéntico al original) ────────────────────────────────

  List<Widget> _buildAppointmentBlocksWithOverlap({
    required DateTime weekStart,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> weekDocs,
    required double colW,
    required double rowH,
  }) {
    final perDay  = List.generate(7, (_) => <_Evt>[]);
    final baseMin = widget.startHour * 60;

    for (final d in weekDocs) {
      final data = d.data();
      final ts   = data['appointmentDate'];
      if (ts is! Timestamp) continue;

      final start    = ts.toDate();
      final dayIndex = _dayIndexFromDate(start, weekStart);
      if (dayIndex < 0 || dayIndex > 6) continue;

      final dur     = data['durationMin'] is num
          ? (data['durationMin'] as num).toInt()
          : 0;
      final safeDur = dur <= 0 ? 30 : dur;
      final end     = start.add(Duration(minutes: safeDur));

      perDay[dayIndex].add(_Evt(
        id:          d.id,
        data:        data,
        startMin:    start.hour * 60 + start.minute,
        endMin:      end.hour * 60 + end.minute,
        durationMin: safeDur,
        serviceId:   (data['serviceId']   ?? '').toString(),
        serviceName: _resolveServiceName(context, data),
        clientName:  (data['clientName']  ?? 'Client').toString(),
      ));
    }

    final out = <Widget>[];

    for (int day = 0; day < 7; day++) {
      final events = perDay[day];
      if (events.isEmpty) continue;

      events.sort((a, b) => a.startMin.compareTo(b.startMin));

      final clusters   = <List<_Evt>>[];
      List<_Evt> current = [];
      int currentEnd   = -1;

      for (final e in events) {
        if (current.isEmpty) {
          current    = [e];
          currentEnd = e.endMin;
          continue;
        }
        if (e.startMin < (currentEnd - 1)) {
          current.add(e);
          currentEnd = math.max(currentEnd, e.endMin);
        } else {
          clusters.add(current);
          current    = [e];
          currentEnd = e.endMin;
        }
      }
      if (current.isNotEmpty) clusters.add(current);

      for (final cl in clusters) {
        final colEnd = <int>[];
        int maxCols  = 0;

        for (final e in cl) {
          int col = -1;
          for (int i = 0; i < colEnd.length; i++) {
            if (colEnd[i] <= e.startMin + 1) {
              col = i;
              break;
            }
          }
          if (col == -1) {
            col = colEnd.length;
            colEnd.add(e.endMin);
          } else {
            colEnd[col] = e.endMin;
          }
          e.colIndex = col;
          maxCols    = math.max(maxCols, colEnd.length);
        }

        for (final e in cl) e.clusterCols = math.max(1, maxCols);
      }

      for (final e in events) {
        final y     = (((e.startMin - baseMin) / 60.0) * rowH);
        final h     = (((e.durationMin) / 60.0) * rowH).clamp(24.0, 9999.0);
        final slotW = colW / e.clusterCols;
        final xBase = day * colW;
        final x     = xBase + (e.colIndex * slotW);

        final isPending = PendingConfirmationUtils.isPending(e.data);
        final color     = isPending
            ? PendingConfirmationUtils.pendingColor
            : (widget.serviceColorById[e.serviceId] ??
                const Color(0xff721c80));

        out.add(Positioned(
          left:   x + 2,
          top:    y + 2,
          width:  slotW - 4,
          height: h - 4,
          child: _ApptBlock(
            color:     color,
            isPending: isPending,
            title:     e.serviceName.isNotEmpty ? e.serviceName : e.clientName,
            subtitle:  e.serviceName.isNotEmpty ? e.clientName : '',
            onTap:     () => widget.onTapAppointment(e.id, e.data),
          ),
        ));
      }
    }

    return out;
  }

  int _dayIndexFromDate(DateTime d, DateTime weekStart) {
    final x  = _dayOnly(d);
    final ws = _dayOnly(weekStart);
    return x.difference(ws).inDays;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers internos (todos idénticos al original salvo _EmptyTapLayer)
// ═══════════════════════════════════════════════════════════════════════════════

String _resolveServiceName(BuildContext context, Map<String, dynamic> data) {
  final key = (data['serviceNameKey'] ?? '').toString().trim();
  if (key.isNotEmpty) return trServiceOrAddon(context, key);
  // Fallback: si no hay key (docs antiguos) usamos el nombre guardado
  return (data['serviceName'] ?? '').toString();
}

class _Evt {
  _Evt({
    required this.id,
    required this.data,
    required this.startMin,
    required this.endMin,
    required this.durationMin,
    required this.serviceId,
    required this.serviceName,
    required this.clientName,
  });
  final String id;
  final Map<String, dynamic> data;
  final int startMin;
  final int endMin;
  final int durationMin;
  final String serviceId;
  final String serviceName;
  final String clientName;
  int colIndex   = 0;
  int clusterCols = 1;
}

// ── Week header (idéntico) ────────────────────────────────────────────────────

class _WeekHeaderRow extends StatelessWidget {
  const _WeekHeaderRow({
    required this.gutterWidth,
    required this.weekStartMonday,
    required this.selectedDay,
    required this.onSelectDay,
  });

  final double gutterWidth;
  final DateTime weekStartMonday;
  final DateTime selectedDay;
  final void Function(DateTime) onSelectDay;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final s = S.of(context);
    final monthLabel = monthsL10n(weekStartMonday.month, s);
    final yearLabel  = weekStartMonday.year.toString();

    return Row(
      children: [
        SizedBox(
          width: gutterWidth,
          child: Padding(
            padding: const EdgeInsets.only(left: 2, right: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(monthLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(yearLabel,
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(7, (i) {
              final d        = _dayOnly(weekStartMonday.add(Duration(days: i)));
              final isToday  = _sameDay(d, today);
              final isPast   = d.isBefore(today);
              final isSelected = !isPast && _sameDay(d, selectedDay);

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) =>
                      onSelectDay(isPast ? today : d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekL10n(d.weekday, s),
                          style: TextStyle(
                              fontSize: 10,
                              color: isPast
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xff721c80).withOpacity(0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xff721c80)
                                        .withOpacity(0.95),
                                    width: 1.6)
                                : null,
                          ),
                          child: Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isPast
                                  ? Colors.grey[400]
                                  : (isToday
                                      ? const Color(0xff721c80)
                                      : const Color.fromARGB(
                                          255, 35, 35, 35)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Grid background (idéntico) ────────────────────────────────────────────────

class _GridBackground extends StatelessWidget {
  const _GridBackground({
    required this.totalHours,
    required this.rowH,
    required this.colW,
  });
  final int totalHours;
  final double rowH;
  final double colW;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        totalHours: totalHours,
        rowH: rowH,
        colW: colW,
        line: Colors.black.withOpacity(0.06),
      ),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.totalHours,
    required this.rowH,
    required this.colW,
    required this.line,
  });
  final int totalHours;
  final double rowH;
  final double colW;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (int i = 0; i <= 7; i++) {
      final x = i * colW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (int i = 0; i <= totalHours; i++) {
      final y = i * rowH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Empty tap layer (MODIFICADO: añade long-press + respeta bloques) ──────────

// ── Empty tap layer ───────────────────────────────────────────────────────────
//
// PROBLEMA ANTERIOR: onTapDown disparaba inmediatamente al tocar la pantalla,
// incluso cuando el usuario solo quería hacer scroll vertical. Cualquier
// deslizamiento mínimo también cancelaba el onLongPressStart antes de que
// pudiera disparar, haciendo el long-press imposible de usar con comodidad.
//
// SOLUCIÓN: StatefulWidget con lógica manual de gestos:
//
//  - onPointerDown  → guarda posición inicial + programa timer de long-press
//  - onPointerMove  → si el dedo se mueve más de [_kMoveThreshold] píxeles,
//                     cancela el timer → no es long-press ni tap
//  - onPointerUp    → si no hubo movimiento excesivo Y el timer no disparó
//                     todavía → es un TAP normal
//  - Timer (500ms)  → si el dedo sigue quieto tras 500ms → LONG PRESS
//
// Resultado:
//   • Scroll vertical/horizontal → sin acción (movimiento cancela todo)
//   • Tap rápido                 → abre crear cita
//   • Mantener quieto ~0.5s     → abre BlockSlotDialog

class _EmptyTapLayer extends StatefulWidget {
  const _EmptyTapLayer({
    required this.weekStart,
    required this.colW,
    required this.rowH,
    required this.startHour,
    required this.blockedSlots,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime weekStart;
  final double colW;
  final double rowH;
  final int startHour;
  final List<BlockedSlot> blockedSlots;
  final void Function(DateTime day, TimeOfDay tod) onTap;
  final void Function(DateTime day, int tappedMin) onLongPress;

  @override
  State<_EmptyTapLayer> createState() => _EmptyTapLayerState();
}

class _EmptyTapLayerState extends State<_EmptyTapLayer> {
  // Cuántos píxeles de movimiento se permiten antes de cancelar el gesto
  static const double _kMoveThreshold = 10.0;
  // Duración para considerar un toque como long-press
  static const Duration _kLongPressDuration = Duration(milliseconds: 500);

  Offset? _downPosition;   // posición donde se apoyó el dedo
  Timer?  _longPressTimer; // timer que dispara el long-press
  bool    _longPressFired = false; // evita que onPointerUp también dispare

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  // ── Resolver posición → día + minuto ────────────────────────────────────────

  String _yyyymmdd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  bool _isBlocked(DateTime day, int tappedMin) {
    final key = _yyyymmdd(day);
    return widget.blockedSlots.any((s) =>
        s.date == key && tappedMin >= s.startMin && tappedMin < s.endMin);
  }

  ({DateTime day, int tappedMin, TimeOfDay tod}) _resolve(Offset local) {
    final dayIndex = (local.dx / widget.colW).floor().clamp(0, 6);
    final day = DateTime(
      widget.weekStart.year,
      widget.weekStart.month,
      widget.weekStart.day + dayIndex,
    );
    final hourIndex = (local.dy / widget.rowH).floor();
    final hour      = widget.startHour + hourIndex;
    final offsetY   = local.dy % widget.rowH;
    final minute    = offsetY < (widget.rowH / 2) ? 0 : 30;
    return (
      day: day,
      tappedMin: hour * 60 + minute,
      tod: TimeOfDay(hour: hour, minute: minute),
    );
  }

  // ── Pointer handlers ─────────────────────────────────────────────────────────

  void _onDown(PointerDownEvent event) {
    _longPressTimer?.cancel();
    _downPosition   = event.localPosition;
    _longPressFired = false;

    _longPressTimer = Timer(_kLongPressDuration, () {
      // Solo dispara si el dedo sigue quieto (no se canceló por movimiento)
      if (!mounted || _downPosition == null) return;
      _longPressFired = true;
      final r = _resolve(_downPosition!);
      widget.onLongPress(r.day, r.tappedMin);
    });
  }

  void _onMove(PointerMoveEvent event) {
    if (_downPosition == null) return;
    final delta = (event.localPosition - _downPosition!).distance;
    if (delta > _kMoveThreshold) {
      // El dedo se movió demasiado → cancelar todo (es scroll)
      _longPressTimer?.cancel();
      _downPosition = null;
    }
  }

  void _onUp(PointerUpEvent event) {
    _longPressTimer?.cancel();

    // Si el long-press ya disparó, o el dedo se movió → ignorar
    if (_longPressFired || _downPosition == null) {
      _downPosition = null;
      return;
    }

    final r = _resolve(_downPosition!);
    _downPosition = null;

    // Celda bloqueada: el bloque tiene su propio handler
    if (_isBlocked(r.day, r.tappedMin)) return;

    widget.onTap(r.day, r.tod);
  }

  void _onCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
    _downPosition = null;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown:   _onDown,
      onPointerMove:   _onMove,
      onPointerUp:     _onUp,
      onPointerCancel: _onCancel,
      child: const SizedBox.expand(),
    );
  }
}

// ── Appointment block (idéntico al original) ──────────────────────────────────

class _ApptBlock extends StatelessWidget {
  const _ApptBlock({
    required this.color,
    required this.isPending,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final Color color;
  final bool isPending;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;

    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight;

      final bool compact45 = h < 44;
      final bool compact30 = h < 34;
      final bool compact15 = h < 24;

      final client  = subtitle.trim();
      final service = title.trim();
      final clientOrService = client.isNotEmpty ? client : service;

      String firstWord(String s) {
        final t   = s.trim();
        if (t.isEmpty) return '';
        final idx = t.indexOf(' ');
        return idx == -1 ? t : t.substring(0, idx);
      }

      if (compact15) {
        final t = client.isNotEmpty ? firstWord(client) : service;
        return _OneLineMiniBlock(
            color: color,
            text: isPending ? '⏳ $t' : t,
            fontSize: 8.2,
            onTap: onTap);
      }

      if (compact30) {
        return _OneLineMiniBlock(
            color: color,
            text: isPending ? '⏳ $clientOrService' : clientOrService,
            fontSize: 9.0,
            onTap: onTap);
      }

      if (compact45) {
        final showClient  = client.isNotEmpty;
        final double titleSize = (h < 38) ? 9.2 : 9.8;
        final double subSize   = (h < 38) ? 8.4 : 8.8;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPending ? '⏳ $service' : service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: textColor,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        height: 1.05),
                  ),
                  if (showClient) ...[
                    const SizedBox(height: 2),
                    Text(
                      client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: textColor,
                          fontSize: subSize,
                          fontWeight: FontWeight.w700,
                          height: 1.05),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }

      final showSubtitle = subtitle.isNotEmpty && h >= 42;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: DefaultTextStyle(
              style: const TextStyle(color: textColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPending ? '⏳ $title' : title,
                    maxLines: showSubtitle ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        height: 1.05),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          height: 1.05),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _OneLineMiniBlock extends StatelessWidget {
  const _OneLineMiniBlock({
    required this.color,
    required this.text,
    required this.fontSize,
    required this.onTap,
  });
  final Color color;
  final String text;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                height: 1.0),
          ),
        ),
      ),
    );
  }
}
