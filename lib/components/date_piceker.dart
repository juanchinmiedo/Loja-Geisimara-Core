import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime>? onDateChange;

  const CustomDatePicker({
    Key? key,
    this.initialDate,
    this.onDateChange,
  }) : super(key: key);

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _today;
  late DateTime _selectedDate;

  final DatePickerController _controller = DatePickerController();

  @override
  void initState() {
    super.initState();

    _today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final init = widget.initialDate ?? _today;

    // nunca permitir antes de hoy
    _selectedDate = init.isBefore(_today) ? _today : init;
  }

  void _goToPreviousMonth() {
    final candidateFirstOfPrevMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month - 1,
      1,
    );

    DateTime newDate;
    if (candidateFirstOfPrevMonth.isBefore(_today)) {
      newDate = _today;
    } else {
      newDate = candidateFirstOfPrevMonth;
    }

    if (newDate.isAtSameMomentAs(_selectedDate)) return;

    setState(() => _selectedDate = newDate);
    _controller.setDateAndAnimate(newDate);
    widget.onDateChange?.call(newDate);
  }

  void _goToNextMonth() {
    final newDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);

    setState(() => _selectedDate = newDate);
    _controller.setDateAndAnimate(newDate);
    widget.onDateChange?.call(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: _goToPreviousMonth,
                child: Icon(
                  Icons.arrow_back_ios,
                  color: _selectedDate.isAtSameMomentAs(_today)
                      ? Colors.white24
                      : Colors.white60,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                "${setMonth(_selectedDate.month)}, ${_selectedDate.year}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _goToNextMonth,
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white60,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: DatePicker(
              _today,
              controller: _controller,
              height: 100,
              initialSelectedDate: _selectedDate,
              deactivatedColor: Colors.white,
              selectionColor: Colors.white,
              selectedTextColor: const Color(0xff721c80),
              dateTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              dayTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              monthTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              onDateChange: (date) {
                setState(() => _selectedDate = date);
                widget.onDateChange?.call(date);
              },
            ),
          ),
        ),
      ],
    );
  }

  String setMonth(int monthNo) {
    switch (monthNo) {
      case 1:
        return "Jan";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "May";
      case 6:
        return "June";
      case 7:
        return "Jul";
      case 8:
        return "Aug";
      case 9:
        return "Sep";
      case 10:
        return "Oct";
      case 11:
        return "Nov";
      case 12:
        return "Dec";
      default:
        return "";
    }
  }
}
