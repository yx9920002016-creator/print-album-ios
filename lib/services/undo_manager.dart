import '../models/layout_page.dart';

/// 单个页面的撤销/重做管理器
/// 通过保存 LayoutPage 的 JSON 快照来支持撤销和重做
class PageUndoManager {
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];
  static const int _maxStackSize = 50;

  Map<String, dynamic>? _lastSnapshot;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// 保存当前页面状态快照（在修改前调用）
  void saveSnapshot(LayoutPage page) {
    final snapshot = page.toJson();
    // 去重：相同快照不重复压栈
    if (_lastSnapshot != null && _identicalSnapshots(snapshot, _lastSnapshot!)) {
      return;
    }
    _undoStack.add(snapshot);
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear(); // 新操作清空重做栈
    _lastSnapshot = snapshot;
  }

  /// 撤销：返回上一个状态，或 null 表示无法撤销
  LayoutPage? undo(LayoutPage currentPage) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(currentPage.toJson());
    final snapshot = _undoStack.removeLast();
    _lastSnapshot = _undoStack.isEmpty ? null : _undoStack.last;
    return LayoutPage.fromJson(snapshot);
  }

  /// 重做：返回下一个状态，或 null 表示无法重做
  LayoutPage? redo(LayoutPage currentPage) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(currentPage.toJson());
    final snapshot = _redoStack.removeLast();
    _lastSnapshot = _undoStack.isEmpty ? null : _undoStack.last;
    return LayoutPage.fromJson(snapshot);
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _lastSnapshot = null;
  }

  bool _identicalSnapshots(Map<String, dynamic> a, Map<String, dynamic> b) {
    // 比较关键字段（忽略 id 差异）
    return a['backgroundColor'] == b['backgroundColor'] &&
        _listEquals(a['elements'], b['elements']) &&
        _listEquals(a['textOverlays'], b['textOverlays']) &&
        _listEquals(a['decorations'], b['decorations']);
  }

  bool _listEquals(dynamic a, dynamic b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i].toString() != b[i].toString()) return false;
      }
      return true;
    }
    return a == b;
  }
}

/// 全局撤销/重做管理器，每个页面独立管理
class UndoManager {
  final Map<String, PageUndoManager> _managers = {};

  PageUndoManager _getManager(String pageId) {
    return _managers.putIfAbsent(pageId, () => PageUndoManager());
  }

  bool canUndo(String pageId) => _managers[pageId]?.canUndo ?? false;
  bool canRedo(String pageId) => _managers[pageId]?.canRedo ?? false;

  void saveSnapshot(LayoutPage page) {
    _getManager(page.id).saveSnapshot(page);
  }

  LayoutPage? undo(LayoutPage currentPage) {
    return _getManager(currentPage.id).undo(currentPage);
  }

  LayoutPage? redo(LayoutPage currentPage) {
    return _getManager(currentPage.id).redo(currentPage);
  }

  void clearPage(String pageId) {
    _managers[pageId]?.clear();
  }

  void clearAll() {
    _managers.clear();
  }
}
