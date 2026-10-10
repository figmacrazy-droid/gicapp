import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color accentGold = Color(0xFFD39706);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    final list = await DataService.getCalendarEvents();
    setState(() {
      _events = list;
    });
  }

  bool _isEventDay(DateTime day) {
    return _events.any((e) => isSameDay(e.date, day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'التقويم والأحداث الأكاديمية',
          style: TextStyle(
            color: navyDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2028, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: const BoxDecoration(color: navyDark, shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: accentGold, shape: BoxShape.circle),
                  markerDecoration: const BoxDecoration(color: accentGold, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_isEventDay(day)) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: accentGold, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('الأيام باللون الذهبي تمثل الفعاليات والأحداث المرفوعة من النظام',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentGold.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navyDark),
                              ),
                              Text(
                                '${event.date.year}/${event.date.month}/${event.date.day}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentGold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event.description,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
