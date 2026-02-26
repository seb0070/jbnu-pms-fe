import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(2021, 9);
  DateTime _selectedDay = DateTime(2021, 9, 2);

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFE8E6FF);
  static const _bgColor = Color(0xFFF5F5F0);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGray = Color(0xFFAAAAAA);
  static const _dotGray = Color(0xFFCCCCCC);

  // 더미 데이터 — 날짜별 dot 개수 (내 담당: purple, 그 외: gray)
  final Map<String, List<bool>> _dotData = {
    '2021-09-02': [true, true, true],
    '2021-09-03': [false, false],
    '2021-09-08': [false],
    '2021-09-10': [true, false, false],
    '2021-09-13': [false, false],
    '2021-09-15': [false, false],
    '2021-09-17': [false],
    '2021-09-20': [true, false],
    '2021-09-22': [true, false, false],
    '2021-09-23': [false],
    '2021-09-29': [true, false, false],
    '2021-09-30': [true, false, false],
    '2021-09-31': [false, false, false],
  };

  // 더미 일정 데이터
  final Map<String, List<Map<String, dynamic>>> _events = {
    '2021-09-02': [
      {
        'time': '10:00-13:00',
        'title': 'Design new UX flow for Michael',
        'subtitle': 'Start from screen 16',
        'isMyTask': true,
        'type': 'TASK',
        'spaceName': 'PMS 개발팀',
        'projectName': 'PMS 앱 개발',
      },
      {
        'time': '14:00-15:00',
        'title': 'Brainstorm with the team',
        'subtitle': 'Define the problem or question that..',
        'isMyTask': false,
        'type': 'TASK',
        'spaceName': 'PMS 개발팀',
        'projectName': 'PMS 앱 개발',
      },
      {
        'time': '19:00-20:00',
        'title': 'Workout with Ella',
        'subtitle': 'We will do the legs and back workout',
        'isMyTask': false,
        'type': 'PROJECT',
        'spaceName': 'PMS 개발팀',
        'projectName': 'PMS 앱 개발',
      },
    ],
  };

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    // 월요일 시작 (1=Mon, 7=Sun)
    int weekdayOffset = first.weekday - 1;
    final days = <DateTime>[];
    // 이전 달 날짜
    for (int i = weekdayOffset - 1; i >= 0; i--) {
      days.add(first.subtract(Duration(days: i + 1)));
    }
    // 이번 달 날짜
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int i = 0; i < daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }
    // 다음 달 날짜 (6주 채우기)
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
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  IconButton(
                    icon: const Icon(Icons.search, size: 22, color: _textDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 캘린더 카드
                    Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Column(
                        children: [
                          // 월 헤더
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _navButton(Icons.chevron_left, () {
                                  setState(() {
                                    _focusedMonth = DateTime(
                                      _focusedMonth.year,
                                      _focusedMonth.month - 1,
                                    );
                                  });
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
                                  });
                                }),
                              ],
                            ),
                          ),

                          // 요일 헤더
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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

                          // 날짜 그리드
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                final dots = _dotData[key] ?? [];

                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDay = day),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                      // dots
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

                    // 이벤트 목록
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
          border: Border.all(color: Color(0xFFEEEEEE)),
        ),
        child: Icon(icon, size: 18, color: Color(0xFFAAAAAA)),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isMyTask = event['isMyTask'] as bool;
    final isProject = event['type'] == 'PROJECT';
    final spaceName = event['spaceName'] as String;
    final projectName = event['projectName'] as String;

    // 경로 표시
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
            // 내 담당 보라색 세로 라인
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
                    // 경로
                    Text(
                      path,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 아이콘 + 제목
                    Row(
                      children: [
                        Text(
                          isProject ? '📁' : '✅',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event['title'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: _textGray,
                        ),
                      ],
                    ),
                    if (event['subtitle'] != null &&
                        (event['subtitle'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event['subtitle'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // 시간
                    if (event['time'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isMyTask ? _purple : _dotGray,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            event['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isMyTask ? _purple : _textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
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
