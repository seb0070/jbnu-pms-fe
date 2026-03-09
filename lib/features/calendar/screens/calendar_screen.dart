import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/network/dio_client.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFE8E6FF);
  static const _bgColor = Color(0xFFF5F5F0);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGray = Color(0xFFAAAAAA);
  static const _dotGray = Color(0xFFCCCCCC);

  // ✅ DioClient - baseUrl + 토큰 자동 주입. _getToken(), SharedPreferences 제거
  final Dio _dio = DioClient.create();

  Map<String, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      DateTime.now().day,
    );
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);
    try {
      final res = await _dio.get(
        '/calendar',
        queryParameters: {
          'year': _focusedMonth.year,
          'month': _focusedMonth.month,
        },
      );
      final List items = res.data['data'] ?? [];
      final Map<String, List<Map<String, dynamic>>> events = {};
      for (final item in items) {
        final dueDate = item['dueDate'] as String?;
        if (dueDate == null) continue;
        final date = DateTime.tryParse(dueDate);
        if (date == null) continue;
        final key = _dateKey(date);
        events.putIfAbsent(key, () => []).add(Map<String, dynamic>.from(item));
      }
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    int weekdayOffset = first.weekday - 1;
    final days = <DateTime>[];
    for (int i = weekdayOffset - 1; i >= 0; i--) {
      days.add(first.subtract(Duration(days: i + 1)));
    }
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int i = 0; i < daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }
    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    return days;
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_focusedMonth);
    final selectedKey = _dateKey(_selectedDay);
    final selectedEvents = _events[selectedKey] ?? [];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 18,
                          color: _textDark,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const Expanded(
                        child: Text(
                          '캘린더',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: _purple,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _navButton(Icons.chevron_left, () {
                                      setState(() {
                                        _focusedMonth = DateTime(
                                          _focusedMonth.year,
                                          _focusedMonth.month - 1,
                                        );
                                        _selectedDay = DateTime(
                                          _focusedMonth.year,
                                          _focusedMonth.month,
                                          1,
                                        );
                                      });
                                      _loadCalendar();
                                    }),
                                    Column(
                                      children: [
                                        Text(
                                          _monthName(_focusedMonth.month),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: _textDark,
                                          ),
                                        ),
                                        Text(
                                          '${_focusedMonth.year}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _textGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _navButton(Icons.chevron_right, () {
                                      setState(() {
                                        _focusedMonth = DateTime(
                                          _focusedMonth.year,
                                          _focusedMonth.month + 1,
                                        );
                                        _selectedDay = DateTime(
                                          _focusedMonth.year,
                                          _focusedMonth.month,
                                          1,
                                        );
                                      });
                                      _loadCalendar();
                                    }),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children:
                                      [
                                            'Mon',
                                            'Tue',
                                            'Wed',
                                            'Thu',
                                            'Fri',
                                            'Sat',
                                            'Sun',
                                          ]
                                          .map(
                                            (d) => Expanded(
                                              child: Center(
                                                child: Text(
                                                  d,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: _textGray,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        childAspectRatio: 1.1,
                                      ),
                                  itemCount: days.length,
                                  itemBuilder: (ctx, i) {
                                    final day = days[i];
                                    final isCurrentMonth =
                                        day.month == _focusedMonth.month;
                                    final isSelected =
                                        day.year == _selectedDay.year &&
                                        day.month == _selectedDay.month &&
                                        day.day == _selectedDay.day;
                                    final key = _dateKey(day);
                                    final dots = (_events[key] ?? [])
                                        .map(
                                          (e) =>
                                              e['type'] == 'TASK' &&
                                              (e['assignedToMe'] as bool? ??
                                                  false),
                                        )
                                        .toList();

                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedDay = day),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: isSelected
                                                ? const BoxDecoration(
                                                    color: _purple,
                                                    shape: BoxShape.circle,
                                                  )
                                                : null,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                                color: isSelected
                                                    ? Colors.white
                                                    : isCurrentMonth
                                                    ? _textDark
                                                    : _textGray,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          if (dots.isNotEmpty)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: dots
                                                  .take(3)
                                                  .map(
                                                    (isMine) => Container(
                                                      width: 5,
                                                      height: 5,
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isMine
                                                            ? _purple
                                                            : _dotGray,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedEvents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              '이 날의 일정이 없어요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Column(
                              children: selectedEvents
                                  .map((e) => _buildEventCard(e))
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFFAAAAAA)),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isMyTask =
        event['type'] == 'TASK' && (event['assignedToMe'] as bool? ?? false);
    final isProject = event['type'] == 'PROJECT';
    final spaceName = event['spaceName'] as String? ?? '';
    final projectName = event['projectName'] as String? ?? '';
    final path = isProject ? '$spaceName >' : '$spaceName > $projectName >';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (isMyTask)
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isMyTask ? 12 : 16, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SvgPicture.asset(
                          isProject
                              ? 'lib/assets/icons/project.svg'
                              : 'lib/assets/icons/task.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${event['title'] ?? ''} · ${isProject ? '프로젝트 마감일' : '작업 마감일'}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
