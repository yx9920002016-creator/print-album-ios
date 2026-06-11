import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../models/photo_model.dart';
import '../models/album_project.dart';
import '../models/layout_page.dart';
import '../services/photo_service.dart';
import '../services/project_service.dart';
import '../services/export_service.dart';
import '../services/undo_manager.dart';
import '../theme/app_theme.dart';

class AppState extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();
  final ProjectService _projectService = ProjectService();
  final ExportService _exportService = ExportService();

  // ===== 照片选择 =====
  List<PhotoModel> _allPhotos = [];
  List<PhotoModel> _selectedPhotos = [];
  Map<int, List<PhotoModel>> _photosByYear = {};
  List<int> _sortedYears = [];
  int? _selectedYear;
  bool _isLoadingPhotos = false;
  String? _loadError;

  List<PhotoModel> get allPhotos => _allPhotos;
  List<PhotoModel> get selectedPhotos => _selectedPhotos;
  Map<int, List<PhotoModel>> get photosByYear => _photosByYear;
  List<int> get sortedYears => _sortedYears;
  int? get selectedYear => _selectedYear;
  bool get isLoadingPhotos => _isLoadingPhotos;
  String? get loadError => _loadError;

  // ===== 排版 =====
  AlbumProject? _currentProject;
  int _currentPageIndex = 0;
  int _currentThemeIndex = 0;
  bool _showGrid = true;

  AlbumProject? get currentProject => _currentProject;
  LayoutPage? get currentPage {
    if (_currentProject == null || _currentProject!.pages.isEmpty) return null;
    return _currentProject!.pages[_currentPageIndex];
  }
  int get currentPageIndex => _currentPageIndex;
  int get pageCount => _currentProject?.pages.length ?? 0;
  int get currentThemeIndex => _currentThemeIndex;
  bool get showGrid => _showGrid;
  AlbumTheme get currentTheme => AppTheme.albumThemes[_currentThemeIndex];
  ExportService get exportService => _exportService;

  // ===== 撤销/重做 =====
  final UndoManager _undoManager = UndoManager();
  bool get canUndo => currentPage != null && _undoManager.canUndo(currentPage!.id);
  bool get canRedo => currentPage != null && _undoManager.canRedo(currentPage!.id);

  /// 手动保存快照（连续手势操作前由 LayoutScreen 调用）
  void saveUndoSnapshot() {
    final page = currentPage;
    if (page != null) _undoManager.saveSnapshot(page);
  }

  void undo() {
    final page = currentPage;
    if (page == null) return;
    final restored = _undoManager.undo(page);
    if (restored != null) {
      _replaceCurrentPage(restored);
      notifyListeners();
    }
  }

  void redo() {
    final page = currentPage;
    if (page == null) return;
    final restored = _undoManager.redo(page);
    if (restored != null) {
      _replaceCurrentPage(restored);
      notifyListeners();
    }
  }

  void _replaceCurrentPage(LayoutPage newPage) {
    if (_currentProject == null) return;
    _currentProject!.pages[_currentPageIndex] = newPage;
  }

  void _saveUndoSnapshot() {
    final page = currentPage;
    if (page != null) _undoManager.saveSnapshot(page);
    _scheduleAutoSave();
  }

  // ===== 自动保存 =====

  Timer? _autoSaveTimer;

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      saveProject();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // ===== 照片操作 =====

  Future<void> loadPhotosFromGallery() async {
    _isLoadingPhotos = true;
    _loadError = null;
    notifyListeners();
    try {
      if (kIsWeb) {
        // Web 端使用模拟数据
        _allPhotos = PhotoService.generateMockPhotos(count: 42);
      } else {
        final photos = await _photoService.loadPhotos();
        _allPhotos = photos;
      }
      _photosByYear = _groupByYear(_allPhotos);
      _sortedYears = _photosByYear.keys.toList()..sort((a, b) => b.compareTo(a));
      if (_sortedYears.isNotEmpty) _selectedYear = _sortedYears.first;
    } catch (e) {
      _loadError = '加载照片失败: $e';
    }
    _isLoadingPhotos = false;
    notifyListeners();
  }

  void togglePhotoSelection(PhotoModel photo) {
    if (_selectedPhotos.contains(photo)) {
      _selectedPhotos.remove(photo);
    } else {
      _selectedPhotos.add(photo);
    }
    notifyListeners();
  }

  void toggleSelectAllYear() {
    if (_selectedYear == null) return;
    final yearPhotos = _photosByYear[_selectedYear] ?? [];
    if (_selectedPhotos.toSet().containsAll(yearPhotos.toSet())) {
      _selectedPhotos.removeWhere((p) => yearPhotos.contains(p));
    } else {
      for (final p in yearPhotos) {
        if (!_selectedPhotos.contains(p)) _selectedPhotos.add(p);
      }
    }
    notifyListeners();
  }

  void selectYear(int? year) {
    _selectedYear = year;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPhotos.clear();
    notifyListeners();
  }

  // ===== 项目操作 =====

  void createProjectFromSelected(String name) {
    final project = _projectService.createProject(name);
    project.projectPhotos = List.from(_selectedPhotos);
    _distributePhotosToProject(project, _selectedPhotos);
    _currentProject = project;
    _currentPageIndex = 0;
    notifyListeners();
  }

  /// 将某张照片添加到当前页面
  void addPhotoToCurrentPage(PhotoModel photo) {
    final page = currentPage;
    if (page == null) return;
    // 检查是否已存在
    final exists = page.elements.any((e) => e.photo.id == photo.id);
    if (exists) return;

    _saveUndoSnapshot();

    final margin = 40.0;
    final photoW = (page.pageWidth - margin * 2) / 2;
    final photoH = photoW / photo.aspectRatio;
    // 找到一个不重叠的位置（简单往下堆叠）
    double y = margin;
    for (final el in page.elements) {
      if (el.y + el.height > y) y = el.y + el.height + 20;
    }
    // 如果超出页面底部，就放在中间
    if (y + photoH > page.pageHeight - margin) {
      y = margin;
    }

    page.addElement(LayoutElement(
      id: 'elem_${page.elements.length}_${DateTime.now().millisecondsSinceEpoch}',
      photo: photo,
      x: margin,
      y: y,
      width: photoW,
      height: photoH,
    ));
    notifyListeners();
  }

  /// 智能分页排版：照片溢出页面时自动建新页
  void _distributePhotosToProject(AlbumProject project, List<PhotoModel> photos) {
    if (photos.isEmpty) return;
    final pageW = project.currentPage.pageWidth;
    final pageH = project.currentPage.pageHeight;
    final margin = 40.0, gap = 20.0;
    final cols = photos.length <= 2 ? photos.length : 3;
    final photoW = (pageW - margin * 2 - gap * (cols - 1)) / cols;

    LayoutPage currentPage = project.currentPage;
    double x = margin, y = margin, maxRowH = 0;

    for (final photo in photos) {
      final photoH = photoW / photo.aspectRatio;

      // 判断是否需要换行
      if (x + photoW > pageW - margin) {
        x = margin;
        y += maxRowH + gap;
        maxRowH = 0;
      }

      // 判断当前页是否还能放下这张照片
      if (y + photoH > pageH - margin) {
        // 新建一页
        project.addPage();
        currentPage = project.currentPage;
        x = margin;
        y = margin;
        maxRowH = 0;
      }

      currentPage.addElement(LayoutElement(
        id: 'elem_${currentPage.elements.length}_${DateTime.now().millisecondsSinceEpoch}',
        photo: photo,
        x: x,
        y: y,
        width: photoW,
        height: photoH,
      ));
      x += photoW + gap;
      if (photoH > maxRowH) maxRowH = photoH;
    }
  }

  void updateElementScale(String elementId, double newScale) {
    final el = currentPage?.elements.firstWhere((e) => e.id == elementId);
    if (el != null) {
      el.scale = newScale.clamp(0.2, 5.0);
      notifyListeners();
    }
  }

  void updateElementRotation(String elementId, double newRotation) {
    final el = currentPage?.elements.firstWhere((e) => e.id == elementId);
    if (el != null) {
      el.rotation = newRotation;
      notifyListeners();
    }
  }

  void addPage() {
    _currentProject?.addPage();
    _currentPageIndex = (_currentProject?.pages.length ?? 1) - 1;
    notifyListeners();
  }

  void removeCurrentPage() {
    _currentProject?.removePage(_currentPageIndex);
    if (_currentPageIndex >= (_currentProject?.pages.length ?? 0)) {
      _currentPageIndex = (_currentProject?.pages.length ?? 1) - 1;
    }
    notifyListeners();
  }

  void duplicateCurrentPage() {
    final project = _currentProject;
    final page = currentPage;
    if (project == null || page == null) return;
    final json = page.toJson();
    final newPage = LayoutPage.fromJson({
      ...json,
      'id': 'page_${project.pages.length}_${DateTime.now().millisecondsSinceEpoch}',
    });
    project.addPage();
    _currentPageIndex = project.pages.length - 1;
    _replaceCurrentPage(newPage);
    notifyListeners();
  }

  void goToPage(int index) {
    _currentProject?.goToPage(index);
    _currentPageIndex = index;
    notifyListeners();
  }

  void previousPage() { if (_currentPageIndex > 0) { _currentPageIndex--; notifyListeners(); } }
  void nextPage() { if (_currentPageIndex < pageCount - 1) { _currentPageIndex++; notifyListeners(); } }

  void updateElementPosition(String elementId, double x, double y) {
    final el = currentPage?.elements.firstWhere((e) => e.id == elementId);
    if (el != null) { el.x = x; el.y = y; notifyListeners(); }
  }

  void updateElementSize(String elementId, double w, double h) {
    final el = currentPage?.elements.firstWhere((e) => e.id == elementId);
    if (el != null) { el.width = w; el.height = h; notifyListeners(); }
  }

  void removeElement(String elementId) {
    _saveUndoSnapshot();
    currentPage?.removeElement(elementId);
    notifyListeners();
  }

  void bringElementToFront(String elementId) {
    _saveUndoSnapshot();
    currentPage?.bringToFront(elementId);
    notifyListeners();
  }

  void sendElementToBack(String elementId) {
    _saveUndoSnapshot();
    currentPage?.sendToBack(elementId);
    notifyListeners();
  }

  void toggleElementLock(String elementId) {
    final el = currentPage?.elements.firstWhere((e) => e.id == elementId);
    if (el != null) {
      el.locked = !el.locked;
      notifyListeners();
    }
  }

  // ===== 复制/粘贴 =====

  LayoutElement? _copiedElement;

  void copyElement(String elementId) {
    final el = currentPage?.elements.firstWhere((e) => e.id == elementId);
    if (el != null) {
      _copiedElement = LayoutElement(
        id: '',
        photo: el.photo,
        width: el.width,
        height: el.height,
        x: el.x + 40,
        y: el.y + 40,
        rotation: el.rotation,
        scale: el.scale,
        borderStyle: el.borderStyle,
        borderWidth: el.borderWidth,
        borderColor: el.borderColor,
        cornerRadius: el.cornerRadius,
      );
    }
  }

  void pasteElement() {
    if (_copiedElement == null) return;
    final page = currentPage;
    if (page == null) return;
    _saveUndoSnapshot();
    // 确保 id 唯一
    final newElement = LayoutElement(
      id: 'elem_${page.elements.length}_${DateTime.now().millisecondsSinceEpoch}',
      photo: _copiedElement!.photo,
      width: _copiedElement!.width,
      height: _copiedElement!.height,
      x: _copiedElement!.x,
      y: _copiedElement!.y,
      rotation: _copiedElement!.rotation,
      scale: _copiedElement!.scale,
      borderStyle: _copiedElement!.borderStyle,
      borderWidth: _copiedElement!.borderWidth,
      borderColor: _copiedElement!.borderColor,
      cornerRadius: _copiedElement!.cornerRadius,
    );
    page.addElement(newElement);
    notifyListeners();
  }

  void toggleGrid() { _showGrid = !_showGrid; notifyListeners(); }

  void setTheme(int index) {
    if (index >= 0 && index < AppTheme.albumThemes.length) {
      _currentThemeIndex = index;
      notifyListeners();
    }
  }

  Future<void> saveProject() async {
    if (_currentProject != null) await _projectService.saveProject(_currentProject!);
  }

  Future<void> loadProject(String projectId) async {
    final projects = await _projectService.loadProjects();
    _currentProject = projects.firstWhere((p) => p.id == projectId);
    _currentPageIndex = _currentProject!.currentPageIndex;
    notifyListeners();
  }

  Future<List<AlbumProject>> loadAllProjects() async {
    return _projectService.loadProjects();
  }

  // ===== 文字叠加 =====

  void addTextOverlay(String text) {
    final page = currentPage;
    if (page == null) return;
    _saveUndoSnapshot();
    page.textOverlays.add(TextOverlay(
      id: 'text_${page.textOverlays.length}_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      x: page.pageWidth * 0.1,
      y: page.pageHeight * 0.1,
    ));
    notifyListeners();
  }

  void updateTextOverlay(String id, String newText) {
    _saveUndoSnapshot();
    final overlay = currentPage?.textOverlays.firstWhere((t) => t.id == id);
    if (overlay != null) {
      overlay.text = newText;
      notifyListeners();
    }
  }

  void updateTextOverlayPosition(String id, double x, double y) {
    final overlay = currentPage?.textOverlays.firstWhere((t) => t.id == id);
    if (overlay != null) {
      overlay.x = x;
      overlay.y = y;
      notifyListeners();
    }
  }

  void updateTextStyle(String id, {double? fontSize, int? color, bool? bold, bool? italic}) {
    _saveUndoSnapshot();
    final overlay = currentPage?.textOverlays.firstWhere((t) => t.id == id);
    if (overlay != null) {
      if (fontSize != null) overlay.fontSize = fontSize;
      if (color != null) overlay.color = color;
      if (bold != null) overlay.bold = bold;
      if (italic != null) overlay.italic = italic;
      notifyListeners();
    }
  }

  void updateTextOverlayScale(String id, double newScale) {
    final overlay = currentPage?.textOverlays.firstWhere((t) => t.id == id);
    if (overlay != null) {
      overlay.scale = newScale.clamp(0.2, 5.0);
      notifyListeners();
    }
  }

  void updateTextOverlayRotation(String id, double newRotation) {
    final overlay = currentPage?.textOverlays.firstWhere((t) => t.id == id);
    if (overlay != null) {
      overlay.rotation = newRotation;
      notifyListeners();
    }
  }

  void removeTextOverlay(String id) {
    _saveUndoSnapshot();
    currentPage?.textOverlays.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ===== 照片边框 =====

  void setElementBorder(String elementId, PhotoBorderStyle style) {
    _saveUndoSnapshot();
    final el = currentPage?.elements.firstWhere((e) => e.id == elementId);
    if (el != null) {
      el.borderStyle = style;
      switch (style) {
        case PhotoBorderStyle.none:
          el.borderWidth = 0;
          el.cornerRadius = 0;
          break;
        case PhotoBorderStyle.white:
          el.borderWidth = 8;
          el.borderColor = 0xFFFFFFFF;
          el.cornerRadius = 0;
          break;
        case PhotoBorderStyle.polaroid:
          el.borderWidth = 20;
          el.borderColor = 0xFFFFFFFF;
          el.cornerRadius = 4;
          break;
        case PhotoBorderStyle.rounded:
          el.borderWidth = 6;
          el.borderColor = 0xFFFFFFFF;
          el.cornerRadius = 24;
          break;
        case PhotoBorderStyle.vintage:
          el.borderWidth = 4;
          el.borderColor = 0xFF8B7355;
          el.cornerRadius = 2;
          break;
        case PhotoBorderStyle.shadow:
          el.borderWidth = 0;
          el.cornerRadius = 12;
          break;
      }
      notifyListeners();
    }
  }

  // ===== 页面装饰 =====

  void addDecoration(String type) {
    _saveUndoSnapshot();
    final page = currentPage;
    if (page == null) return;
    page.decorations.add(PageDecoration(
      id: 'dec_${page.decorations.length}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
    ));
    notifyListeners();
  }

  void removeDecoration(String id) {
    _saveUndoSnapshot();
    currentPage?.decorations.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void clearDecorations() {
    _saveUndoSnapshot();
    currentPage?.decorations.clear();
    notifyListeners();
  }

  // ===== 辅助 =====

  Map<int, List<PhotoModel>> _groupByYear(List<PhotoModel> photos) {
    final groups = <int, List<PhotoModel>>{};
    for (final p in photos) {
      final year = p.createdDate?.year ?? DateTime.now().year;
      groups.putIfAbsent(year, () => []).add(p);
    }
    return groups;
  }
}
