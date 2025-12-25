import 'package:flutter/material.dart';
import '../services/config_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ConfigService _config = ConfigService();

  // Schedule data: day (0-6) -> set of blocked hours (0-23)
  final Map<int, Set<int>> _schedule = {};

  static const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<int> _hours = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23];

  static const Color _colorBlocked = Color(0xFFE53935);
  static const Color _colorAllowed = Color(0xFF43A047);
  static const Color _colorHeader = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    await _config.init();
    setState(() {
      for (int day = 0; day < 7; day++) {
        _schedule[day] = Set<int>.from(_config.weeklySchedule[day] ?? {});
      }
    });
  }

  void _toggleCell(int day, int hour) {
    setState(() {
      _schedule.putIfAbsent(day, () => {});
      if (_schedule[day]!.contains(hour)) {
        _schedule[day]!.remove(hour);
      } else {
        _schedule[day]!.add(hour);
      }
    });
  }

  void _toggleRange(int day, int startHour) {
    final blocked = _schedule[day]?.contains(startHour) ?? false;
    setState(() {
      _schedule.putIfAbsent(day, () => {});
      for (int hour = startHour; hour <= 23; hour++) {
        if (blocked) {
          _schedule[day]!.remove(hour);
        } else {
          _schedule[day]!.add(hour);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          blocked
              ? 'Unblocked $startHour:00 - 23:00 on ${_days[day]}'
              : 'Blocked $startHour:00 - 23:00 on ${_days[day]}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _blockAll() {
    setState(() {
      for (int day = 0; day < 7; day++) {
        _schedule[day] = Set<int>.from(_hours);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All times blocked')),
    );
  }

  void _allowAll() {
    setState(() {
      for (int day = 0; day < 7; day++) {
        _schedule[day] = {};
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All times allowed')),
    );
  }

  void _blockWeekdays() {
    setState(() {
      for (int day = 0; day < 5; day++) {
        _schedule[day] = {9, 10, 11, 12, 13, 14, 15, 16, 17};
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekdays 9-5 blocked')),
    );
  }

  Future<void> _save() async {
    final scheduleMap = <int, Set<int>>{};
    for (var entry in _schedule.entries) {
      scheduleMap[entry.key] = entry.value;
    }
    await _config.setWeeklySchedule(scheduleMap);
    await _config.setScheduleEnabled(true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
      ),
      body: Column(
        children: [
          // Quick action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _blockAll,
                  child: const Text('Block All'),
                ),
                ElevatedButton(
                  onPressed: _allowAll,
                  child: const Text('Allow All'),
                ),
                ElevatedButton(
                  onPressed: _blockWeekdays,
                  child: const Text('Weekdays 9-5'),
                ),
              ],
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 16, height: 16, color: _colorBlocked),
                const SizedBox(width: 4),
                const Text('Blocked'),
                const SizedBox(width: 16),
                Container(width: 16, height: 16, color: _colorAllowed),
                const SizedBox(width: 4),
                const Text('Allowed'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Schedule grid
          Expanded(
            child: SingleChildScrollView(
              child: _buildGrid(),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _colorHeader,
                ),
                child: const Text('Save Schedule', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade700, width: 1),
      defaultColumnWidth: const FlexColumnWidth(),
      children: [
        // Header row
        TableRow(
          children: [
            _buildHeaderCell(''),
            ..._days.map((day) => _buildHeaderCell(day)),
          ],
        ),
        // Hour rows
        ..._hours.map((hour) => TableRow(
          children: [
            _buildHeaderCell('${hour.toString().padLeft(2, '0')}:00'),
            ...List.generate(7, (day) => _buildTimeCell(day, hour)),
          ],
        )),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      color: _colorHeader,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeCell(int day, int hour) {
    final isBlocked = _schedule[day]?.contains(hour) ?? false;
    return GestureDetector(
      onTap: () => _toggleCell(day, hour),
      onLongPress: () => _toggleRange(day, hour),
      child: Container(
        height: 32,
        color: isBlocked ? _colorBlocked : _colorAllowed,
      ),
    );
  }
}
