import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadStatus { downloading, done, failed }

class DownloadItem {
  final String fileName;
  final String url;
  DownloadStatus status;
  double progress;
  String? savedPath;

  DownloadItem({
    required this.fileName,
    required this.url,
    this.status = DownloadStatus.downloading,
    this.progress = 0.0,
    this.savedPath,
  });
}

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final List<DownloadItem> items = [];
  final List<VoidCallback> _listeners = [];
  final Dio _dio = Dio();
  OverlayEntry? _overlayEntry;

  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in _listeners) l();
  }

  Future<void> download({
    required BuildContext context,
    required String fileName,
    required String downloadUrl,
  }) async {
    final item = DownloadItem(fileName: fileName, url: downloadUrl);
    items.add(item);
    _showOverlay(context);
    _notify();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';

      await _dio.download(
        downloadUrl,
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            item.progress = received / total;
            _notify();
          }
        },
      );
      item.status = DownloadStatus.done;
      item.savedPath = savePath;
    } catch (e) {
      item.status = DownloadStatus.failed;
    }
    _notify();
  }

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _notify();
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (_) =>
          _DownloadSheetOverlay(manager: this, onClose: _closeOverlay),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _notify();
  }
}

class _DownloadSheetOverlay extends StatefulWidget {
  final DownloadManager manager;
  final VoidCallback onClose;
  const _DownloadSheetOverlay({required this.manager, required this.onClose});

  @override
  State<_DownloadSheetOverlay> createState() => _DownloadSheetOverlayState();
}

class _DownloadSheetOverlayState extends State<_DownloadSheetOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  static const _purple = Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    widget.manager.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.manager.removeListener(_onUpdate);
    _animController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _close() {
    _animController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // 외부 터치로 닫기
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // 바텀시트
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: GestureDetector(
              onTap: () {}, // 시트 내부 터치는 닫히지 않게
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 핸들
                      const SizedBox(height: 10),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 헤더
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Text(
                              '다운로드',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _close,
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      // 목록
                      ...widget.manager.items.map(_buildItem),
                      SizedBox(height: bottomPadding + 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(DownloadItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_fileIcon(item.fileName), color: _purple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (item.status == DownloadStatus.downloading)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.progress > 0 ? item.progress : null,
                      backgroundColor: Colors.grey[100],
                      color: _purple,
                      minHeight: 3,
                    ),
                  )
                else if (item.status == DownloadStatus.done)
                  Text(
                    '다운로드 완료',
                    style: TextStyle(fontSize: 11, color: Colors.green[500]),
                  )
                else
                  Text(
                    '다운로드 실패',
                    style: TextStyle(fontSize: 11, color: Colors.red[400]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (item.status == DownloadStatus.downloading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _purple),
            )
          else if (item.status == DownloadStatus.done)
            GestureDetector(
              onTap: () => OpenFilex.open(item.savedPath!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '열기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Icon(Icons.error_outline, color: Colors.red[300], size: 20),
        ],
      ),
    );
  }

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
