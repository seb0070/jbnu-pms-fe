import 'package:flutter/material.dart';
import '../services/project_service.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final int spaceId;
  const ProjectListScreen({super.key, required this.spaceId});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectService _projectService = ProjectService();
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  static const _purple = Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectService.getProjects(widget.spaceId);
      setState(() {
        _projects = projects;
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
                      const Expanded(
                        child: Text(
                          '프로젝트',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
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
                        : _projects.isEmpty
                        ? const Center(child: Text('프로젝트가 없어요'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _projects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final project = _projects[index];
                              final progress =
                                  (project['progress'] as num?)?.toDouble() ??
                                  0.0;
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProjectDetailScreen(
                                      projectId: project['id'],
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      if ((project['description'] ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          project['description'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: const Color(
                                            0xFFEEEEEE,
                                          ),
                                          color: _purple,
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${progress.toInt()}% 완료',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
}
