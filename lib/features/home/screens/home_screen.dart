import 'package:flutter/material.dart';
import '../../space/services/space_service.dart';
// import '../../space/screens/space_list_screen.dart';
// import '../../space/screens/space_create_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpaceService _spaceService = SpaceService();
  List<Map<String, dynamic>> _spaces = [];
  Map<String, dynamic>? _selectedSpace;
  bool _isLoading = true;
  bool _dropdownOpen = false;

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      final spaces = await _spaceService.getSpaces();
      setState(() {
        _spaces = spaces;
        if (spaces.isNotEmpty && _selectedSpace == null) {
          _selectedSpace = spaces.first;
        }
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
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // 메인 콘텐츠
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : _buildBody(),
                ),
              ],
            ),
          ),
          // 드롭다운 오버레이
          if (_dropdownOpen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 48,
              left: 0,
              right: 0,
              child: _buildDropdown(),
            ),
          // 드롭다운 닫기용 배경 터치
          if (_dropdownOpen)
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 48,
              child: GestureDetector(
                onTap: () => setState(() => _dropdownOpen = false),
                behavior: HitTestBehavior.translucent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedSpace?['name'] ?? '스페이스 없음',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _dropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF1A1A2E),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFFFBFBEF),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_spaces.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Text(
                  '스페이스가 없어요',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              )
            else
              ..._spaces.map((space) => _buildSpaceItem(space)),
            const Divider(height: 1, color: Color(0xFFE0E0D0)),
            // 스페이스 관리
            InkWell(
              onTap: () {
                setState(() => _dropdownOpen = false);
                // TODO: SpaceListScreen 구현 후 주석 해제
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => const SpaceListScreen()),
                // ).then((_) => _loadSpaces());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.settings_outlined, color: _purple, size: 16),
                    SizedBox(width: 8),
                    Text(
                      '스페이스 관리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _purple,
                      ),
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

  Widget _buildSpaceItem(Map<String, dynamic> space) {
    final isSelected = _selectedSpace?['id'] == space['id'];
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSpace = space;
          _dropdownOpen = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                space['name'] ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _purple : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: _purple, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedSpace == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // TODO: SpaceCreateScreen 연결
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => const SpaceCreateScreen()),
                // ).then((_) => _loadSpaces());
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.add_rounded, color: _purple, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '스페이스가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '새 스페이스를 만들어 시작해보세요',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('긴급 작업', Icons.warning_amber_rounded, Colors.red),
          const SizedBox(height: 8),
          _buildPlaceholderCard('프로젝트/태스크 구현 후 표시됩니다'),
          const SizedBox(height: 20),
          _buildSectionHeader('진행중인 작업', Icons.pending_outlined, Colors.orange),
          const SizedBox(height: 8),
          _buildPlaceholderCard('프로젝트/태스크 구현 후 표시됩니다'),
          const SizedBox(height: 20),
          _buildSectionHeader('최근 프로젝트', Icons.folder_outlined, _purple),
          const SizedBox(height: 8),
          _buildPlaceholderCard('프로젝트/태스크 구현 후 표시됩니다'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}
