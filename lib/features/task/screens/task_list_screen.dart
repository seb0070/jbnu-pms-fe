import 'package:flutter/material.dart';
import '../../../features/project/services/project_service.dart';
import 'task_create_screen.dart';

class TaskListScreen extends StatefulWidget {
  final int projectId;
  final String projectName;
  const TaskListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ProjectService _projectService = ProjectService();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _projectService.getTasks(widget.projectId);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Color(0xFF1A1A2E),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.projectName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Color(0xFF1A1A2E),
                          size: 24,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TaskCreateScreen(projectId: widget.projectId),
                            ),
                          );
                          if (result == true) _loadTasks();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _purple),
                          )
                        : _tasks.isEmpty
                        ? const Center(
                            child: Text(
                              '작업이 없어요',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _tasks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) =>
                                _buildTaskItem(_tasks[index]),
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

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final title = task['title'] as String? ?? '';
    final priority = task['priority'] as String? ?? 'MEDIUM';
    final status = task['status'] as String? ?? 'NOT_STARTED';
    final dueDate = task['dueDate'] as String?;
    final assignees = (task['assignees'] as List?) ?? [];

    // 우선순위
    Color priorityColor;
    String priorityLabel;
    switch (priority) {
      case 'HIGH':
        priorityColor = const Color(0xFFF95555);
        priorityLabel = 'High';
        break;
      case 'LOW':
        priorityColor = const Color(0xFF19B36E);
        priorityLabel = 'Low';
        break;
      default:
        priorityColor = const Color(0xFFF79009);
        priorityLabel = 'Medium';
    }

    // 상태
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'IN_PROGRESS':
        statusColor = _purple;
        statusLabel = '진행중';
        break;
      case 'DONE':
        statusColor = Colors.green;
        statusLabel = '완료';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = '시작전';
    }

    // 마감일 D-day 계산
    String dueDateLabel = '-';
    Color dueDateColor = Colors.grey;
    if (dueDate != null) {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      final diff = due
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (diff < 0) {
        dueDateLabel = 'D+${diff.abs()}';
        dueDateColor = Colors.red;
      } else if (diff == 0) {
        dueDateLabel = 'D-day';
        dueDateColor = Colors.red;
      } else if (diff <= 30) {
        dueDateLabel = 'D-$diff';
        dueDateColor = diff <= 7 ? Colors.orange : Colors.grey;
      } else {
        dueDateLabel = '${due.month}/${due.day}';
        dueDateColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 윗줄: 작업 이름
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                // 아랫줄: 상태, 우선순위, 마감일
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priorityLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: dueDateColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      dueDateLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: dueDateColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 담당자 아바타
          if (assignees.isEmpty)
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFEEEEEE),
              child: Icon(Icons.person, size: 16, color: Colors.grey),
            )
          else
            SizedBox(
              width: assignees.take(3).length * 22.0,
              height: 28,
              child: Stack(
                children: assignees.take(3).toList().asMap().entries.map((e) {
                  final assignee = e.value as Map<String, dynamic>;
                  final name = assignee['name'] as String? ?? '?';
                  final profileImage = assignee['profileImage'] as String?;
                  return Positioned(
                    left: e.key * 16.0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: _lightPurple,
                      backgroundImage: profileImage != null
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage == null
                          ? Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
