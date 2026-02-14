import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/utils/date_labels.dart';

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

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {

  late final PageController _page;
  late DateTime _anchorWeekStartMonday;
  late DateTime _visibleWeekStartMonday;

  // ✅ selección local para marcar borde INSTANTÁNEO
  late DateTime _selectedLocalDay;

  static const int _kWeekCenter = 10000;

  // Layout
  static const double _outerPad = 0;
  static const double _gutterW = 20; // horas (estrecho)
  static const double _gutterGap = 4;
  static const double _hourRowH = 56;
  static const double _topPad = 6;

  DateTime _weekStartForIndex(int index) {
    final deltaWeeks = index - _kWeekCenter;
    return _anchorWeekStartMonday.add(Duration(days: deltaWeeks * 7));
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    _anchorWeekStartMonday = _dayOnly(widget.weekStartMonday);
    _visibleWeekStartMonday = _anchorWeekStartMonday;
    _selectedLocalDay = _dayOnly(widget.selectedDay);
    _page = PageController(initialPage: _kWeekCenter);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WeekCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldWs = _dayOnly(oldWidget.weekStartMonday);
    final newWs = _dayOnly(widget.weekStartMonday);

    // ✅ si cambia la semana ancla, resetea PageView al centro
    if (oldWs != newWs) {
      _anchorWeekStartMonday = newWs;
      _visibleWeekStartMonday = newWs;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _page.jumpToPage(_kWeekCenter);
      });
    }

    // ✅ si cambia el selectedDay desde fuera, actualiza highlight local
    final oldSel = _dayOnly(oldWidget.selectedDay);
    final newSel = _dayOnly(widget.selectedDay);
    if (oldSel != newSel) {
      if (!mounted) return;
      setState(() {
        _selectedLocalDay = newSel;
      });
    }
  }

  int _dayIndexFromDate(DateTime d, DateTime weekStart) {
    final x = _dayOnly(d);
    final ws = _dayOnly(weekStart);
    return x.difference(ws).inDays; // 0..6
  }

  // snap :00 / :30
  TimeOfDay _snapToHalfHour(double y) {
    final minutesFromStart = (y / _hourRowH) * 60.0;
    final totalMin = (widget.startHour * 60) + minutesFromStart.round();

    int h = (totalMin ~/ 60);
    int m = (totalMin % 60);

    if (m < 15) {
      m = 0;
    } else if (m < 45) {
      m = 30;
    } else {
      m = 0;
      h = (h + 1);
    }

    return TimeOfDay(hour: h, minute: m);
  }

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

  void _selectDayInstant(DateTime day) {
    final d = _dayOnly(day);
    if (!mounted) return;

    // 1) ✅ pinta borde INSTANTE en WeekHeader
    setState(() => _selectedLocalDay = d);

    // 2) ✅ luego notifica al parent (en siguiente frame)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // evita spam si ya cambió otra vez
      if (!_sameDay(_selectedLocalDay, d)) return;
      widget.onSelectDay(d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = (widget.endHour - widget.startHour);
    final gridHeight = totalHours * _hourRowH;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? []);

        final double maxH =
            math.min(MediaQuery.of(context).size.height * 0.70, 640).toDouble();

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
                  onSelectDay: (d) {
                    _selectDayInstant(d);
                  },
                ),
                const SizedBox(height: _topPad),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    onPageChanged: (idx) {
                      final ws = _weekStartForIndex(idx);
                      if (mounted) setState(() => _visibleWeekStartMonday = ws);
                      widget.onWeekChanged(ws);
                    },
                    itemBuilder: (context, index) {
                      final weekStart = _weekStartForIndex(index);

                      return LayoutBuilder(
                        builder: (context, c) {
                          final fullW = c.maxWidth;
                          final gridW = fullW - (_gutterW + _gutterGap);

                          final minColW = 46.0;
                          final desiredGridW = minColW * 7;

                          final effectiveGridW = math.max(gridW, desiredGridW);
                          final colW = effectiveGridW / 7.0;

                          final positionedBlocks =
                              _buildAppointmentBlocksWithOverlap(
                            weekStart: weekStart,
                            weekDocs: docs,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: _gutterW,
                                      child: Column(
                                        children: List.generate(totalHours, (i) {
                                          final hour = widget.startHour + i;
                                          return SizedBox(
                                            height: _hourRowH,
                                            child: _timeLabel(context, hour),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: _gutterGap),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: SizedBox(
                                          width: effectiveGridW,
                                          child: Stack(
                                            children: [
                                              _GridBackground(
                                                totalHours: totalHours,
                                                rowH: _hourRowH,
                                                colW: colW,
                                              ),

                                              Positioned.fill(
                                                child: _EmptyTapLayer(
                                                  weekStart: weekStart,
                                                  colW: colW,
                                                  rowH: _hourRowH,
                                                  snapToHalfHour: _snapToHalfHour,
                                                  onTap: (day, tod) async {
                                                    final now = DateTime.now();
                                                    final today = DateTime(
                                                      now.year,
                                                      now.month,
                                                      now.day,
                                                    );
                                                    final dd = DateTime(
                                                      day.year,
                                                      day.month,
                                                      day.day,
                                                    );
                                                    if (dd.isBefore(today)) {
                                                      // no permite tap en días pasados
                                                      return;
                                                    }

                                                    widget.onTapEmpty(day, tod);
                                                  },
                                                ),
                                              ),

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

  // overlap > 1 min -> columnas
  List<Widget> _buildAppointmentBlocksWithOverlap({
    required DateTime weekStart,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> weekDocs,
    required double colW,
    required double rowH,
  }) {
    final perDay = List.generate(7, (_) => <_Evt>[]);
    final baseMin = widget.startHour * 60;

    for (final d in weekDocs) {
      final data = d.data();
      final ts = data['appointmentDate'];
      if (ts is! Timestamp) continue;

      final start = ts.toDate();
      final dayIndex = _dayIndexFromDate(start, weekStart);
      if (dayIndex < 0 || dayIndex > 6) continue;

      final dur = (data['durationMin'] is num)
          ? (data['durationMin'] as num).toInt()
          : 0;
      final safeDur = dur <= 0 ? 30 : dur;
      final end = start.add(Duration(minutes: safeDur));

      final startMin = start.hour * 60 + start.minute;
      final endMin = end.hour * 60 + end.minute;

      perDay[dayIndex].add(
        _Evt(
          id: d.id,
          data: data,
          startMin: startMin,
          endMin: endMin,
          durationMin: safeDur,
          serviceId: (data['serviceId'] ?? '').toString(),
          serviceName: (data['serviceName'] ?? '').toString(),
          clientName: (data['clientName'] ?? 'Client').toString(),
        ),
      );
    }

    final out = <Widget>[];

    for (int day = 0; day < 7; day++) {
      final events = perDay[day];
      if (events.isEmpty) continue;

      events.sort((a, b) => a.startMin.compareTo(b.startMin));

      final clusters = <List<_Evt>>[];
      List<_Evt> current = [];
      int currentEnd = -1;

      for (final e in events) {
        if (current.isEmpty) {
          current = [e];
          currentEnd = e.endMin;
          continue;
        }

        final overlapsCluster = e.startMin < (currentEnd - 1);

        if (overlapsCluster) {
          current.add(e);
          currentEnd = math.max(currentEnd, e.endMin);
        } else {
          clusters.add(current);
          current = [e];
          currentEnd = e.endMin;
        }
      }
      if (current.isNotEmpty) clusters.add(current);

      for (final cl in clusters) {
        final colEnd = <int>[];
        int maxCols = 0;

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
          maxCols = math.max(maxCols, colEnd.length);
        }

        for (final e in cl) {
          e.clusterCols = math.max(1, maxCols);
        }
      }

      for (final e in events) {
        final y = (((e.startMin - baseMin) / 60.0) * rowH);
        final h = (((e.durationMin) / 60.0) * rowH).clamp(24.0, 9999.0);

        final slotW = colW / e.clusterCols;
        final xBase = day * colW;
        final x = xBase + (e.colIndex * slotW);

        final color =
            widget.serviceColorById[e.serviceId] ?? const Color(0xff721c80);

        out.add(
          Positioned(
            left: x + 2,
            top: y + 2,
            width: slotW - 4,
            height: h - 4,
            child: _ApptBlock(
              color: color,
              title: e.serviceName.isNotEmpty ? e.serviceName : e.clientName,
              subtitle: e.serviceName.isNotEmpty ? e.clientName : '',
              onTap: () => widget.onTapAppointment(e.id, e.data),
            ),
          ),
        );
      }
    }

    return out;
  }
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

  int colIndex = 0;
  int clusterCols = 1;
}

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
  final void Function(DateTime day) onSelectDay;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final monthLabel = months(weekStartMonday.month);
    final yearLabel = weekStartMonday.year.toString();

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
                  child: Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    yearLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(7, (i) {
              final d = _dayOnly(weekStartMonday.add(Duration(days: i)));
              final isToday = _sameDay(d, today);

              final isPast = d.isBefore(today);

              // ✅ no permitimos "selected" en pasado
              final isSelected = !isPast && _sameDay(d, selectedDay);

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  // ✅ si es pasado → manda a hoy
                  onTapDown: (_) {
                    if (isPast) {
                      onSelectDay(today);
                    } else {
                      onSelectDay(d);
                    }
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          week(d.weekday),
                          style: TextStyle(
                            fontSize: 10,
                            color: isPast ? Colors.grey[400] : Colors.grey[700],
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xff721c80).withOpacity(0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xff721c80).withOpacity(0.95),
                                    width: 1.6,
                                  )
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
                                      : const Color.fromARGB(255, 35, 35, 35)),
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
    final line = Colors.black.withOpacity(0.06);

    return CustomPaint(
      painter: _GridPainter(
        totalHours: totalHours,
        rowH: rowH,
        colW: colW,
        line: line,
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

class _EmptyTapLayer extends StatelessWidget {
  const _EmptyTapLayer({
    required this.weekStart,
    required this.colW,
    required this.rowH,
    required this.onTap,
    required this.snapToHalfHour,
  });

  final DateTime weekStart;
  final double colW;
  final double rowH;
  final void Function(DateTime day, TimeOfDay tod) onTap;
  final TimeOfDay Function(double y) snapToHalfHour;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (d) {
        final local = d.localPosition;

        final dayIndex = (local.dx / colW).floor().clamp(0, 6);
        final day = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + dayIndex,
        );

        final tod = snapToHalfHour(local.dy);
        onTap(day, tod);
      },
      child: const SizedBox.expand(),
    );
  }
}

class _ApptBlock extends StatelessWidget {
  const _ApptBlock({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final String title;     // procedimiento (service)
  final String subtitle;  // cliente
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;

    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;

        // umbrales
        final bool compact45 = h < 44; // ~45m o menos
        final bool compact30 = h < 34; // ~30m o menos
        final bool compact15 = h < 24; // ~15m o menos

        // texto preferido: cliente (si existe) para 15/30
        final client = subtitle.trim();
        final service = title.trim();
        final clientOrService = client.isNotEmpty ? client : service;

        // helper opcional: primer nombre
        String firstWord(String s) {
          final t = s.trim();
          if (t.isEmpty) return '';
          final idx = t.indexOf(' ');
          return idx == -1 ? t : t.substring(0, idx);
        }

        // ---------- 15m: cliente (primer nombre) 1 línea ----------
        if (compact15) {
          final t = client.isNotEmpty ? firstWord(client) : service;
          return _OneLineMiniBlock(
            color: color,
            text: t,
            fontSize: 8.2,
            onTap: onTap,
          );
        }

        // ---------- 30m: cliente 1 línea (como 15 pero un pelín mayor) ----------
        if (compact30) {
          // aquí SI dejamos nombre completo con ellipsis (queda mejor)
          return _OneLineMiniBlock(
            color: color,
            text: clientOrService,
            fontSize: 9.0,
            onTap: onTap,
          );
        }

        // ---------- 45m: procedimiento + cliente, responsive (solo baja si hace falta) ----------
        if (compact45) {
          final showClient = client.isNotEmpty;

          // tamaños máximos (como te gusta) y mínimos por si aprieta
          final double titleMax = 9.8;
          final double subMax = 8.8;

          // si está muy cerca del límite, bajamos un poco
          // (esto evita overflow sin “encoger” de más)
          final double titleSize = (h < 38) ? 9.2 : titleMax;
          final double subSize = (h < 38) ? 8.4 : subMax;

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ procedimiento
                    Text(
                      service,
                      maxLines: 1, // 45m: mejor 1 línea para asegurar
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    if (showClient) ...[
                      const SizedBox(height: 2),
                      // ✅ cliente
                      Text(
                        client,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: subSize,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        // ---------- NORMAL (≥ 1h): NO TOCAR ----------
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: DefaultTextStyle(
                style: const TextStyle(color: textColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: showSubtitle ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
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
                          height: 1.05,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bloque mini 1 línea (15m y 30m)
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}