import 'dart:io';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/layout_page.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

/// 记录手势开始时的元素状态
class _GestureStart {
  final double scale;
  final double rotation;
  final double x;
  final double y;
  _GestureStart({required this.scale, required this.rotation, required this.x, required this.y});
}

class LayoutScreen extends StatefulWidget {
  const LayoutScreen({super.key});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  final Map<String, _GestureStart> _gestureStarts = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.currentProject == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(context.rw(32)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(context.rw(24)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F3), Color(0xFFF5F0FF)],
                    ),
                    borderRadius: BorderRadius.circular(context.rw(32)),
                  ),
                  child: Icon(Icons.dashboard_customize_rounded, size: context.rw(72), color: AppTheme.primaryLight),
                ),
                SizedBox(height: context.rw(20)),
                Text('还没有排版项目',
                    style: TextStyle(fontSize: context.rw(20), fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                SizedBox(height: context.rw(8)),
                Text('请先在「选片」中选择照片并创建项目',
                    style: TextStyle(fontSize: context.rw(14), color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // 顶部栏
          _buildHeader(state),
          // 画布
          Expanded(child: _buildCanvas(state)),
          // 照片条
          _buildPhotoStrip(state),
          // 底部工具条
          _buildBottomBar(state),
        ],
      ),
    );
  }

  // ===== 顶部栏 =====
  Widget _buildHeader(AppState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.gradientHeader,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.rw(24))),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + context.rw(8),
        left: context.rw(8),
        right: context.rw(8),
        bottom: context.rw(8),
      ),
      child: Row(
        children: [
          // 返回/标题
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: context.rw(8)),
              child: Text(
                state.currentProject!.name,
                style: TextStyle(
                  fontSize: context.rw(19),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // 操作按钮
          _headerIcon(Icons.grid_view_rounded, '网格', state.showGrid, () => state.toggleGrid()),
          _buildThemePopup(state),
          _headerIcon(Icons.add_circle_rounded, '加页', false, () => state.addPage()),
          if (state.pageCount > 1)
            _headerIcon(Icons.delete_outline_rounded, '删页', false,
                () => _confirmDeletePage(state)),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, String tooltip, bool active, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.rw(3)),
          padding: EdgeInsets.all(context.rw(8)),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(context.rw(12)),
          ),
          child: Icon(icon, size: context.rw(20), color: active ? AppTheme.primaryColor : Colors.white),
        ),
      ),
    );
  }

  Widget _buildThemePopup(AppState state) {
    return PopupMenuButton<int>(
      offset: Offset(0, context.rw(44)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.rw(16))),
      color: AppTheme.bgCard,
      child: Container(
        padding: EdgeInsets.all(context.rw(8)),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(context.rw(12)),
        ),
        child: Icon(Icons.palette_rounded, size: context.rw(20), color: Colors.white),
      ),
      tooltip: '选择主题',
      onSelected: (index) => state.setTheme(index),
      itemBuilder: (ctx) => List.generate(AppTheme.albumThemes.length, (index) {
        final t = AppTheme.albumThemes[index];
        return PopupMenuItem(
          value: index,
          height: context.rw(38),
          child: Row(
            children: [
              Container(
                width: context.rw(26), height: context.rw(26),
                decoration: BoxDecoration(
                  color: t.bgColor,
                  borderRadius: BorderRadius.circular(context.rw(8)),
                  border: Border.all(color: t.accentColor.withAlpha(80), width: 1.5),
                ),
              ),
              SizedBox(width: context.rw(10)),
              Text(t.name, style: TextStyle(fontSize: context.rw(14), fontWeight: FontWeight.w500)),
              if (index == state.currentThemeIndex) ...[
                const Spacer(),
                Icon(Icons.check_circle_rounded, size: context.rw(20), color: AppTheme.primaryColor),
              ],
            ],
          ),
        );
      }),
    );
  }

  // ===== 画布 =====
  Widget _buildCanvas(AppState state) {
    final page = state.currentPage;
    if (page == null) return const SizedBox.shrink();

    final theme = state.currentTheme;
    final pagePixelW = page.pageWidth * 0.3;
    final pagePixelH = page.pageHeight * 0.3;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final availW = constraints.maxWidth - context.rw(40);
        final availH = constraints.maxHeight - context.rw(40);
        final scaleX = availW / pagePixelW;
        final scaleY = availH / pagePixelH;
        final initialScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.05, 1.0);

        final controller = TransformationController();
        controller.value = Matrix4.identity()..scale(initialScale);

        return Padding(
          padding: EdgeInsets.all(context.rw(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.rw(20)),
            child: InteractiveViewer(
              minScale: 0.05,
              maxScale: 3.0,
              boundaryMargin: EdgeInsets.all(context.rw(200)),
              transformationController: controller,
              child: Center(
                child: Container(
                  width: pagePixelW,
                  height: pagePixelH,
                  decoration: BoxDecoration(
                    color: theme.bgColor,
                    borderRadius: BorderRadius.circular(context.rw(4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: context.rw(20),
                        offset: Offset(0, context.rw(4)),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (state.showGrid) _buildGrid(page),
                      ...page.elements.map((el) => _buildDraggableElement(state, el)),
                      ...page.textOverlays.map((t) => _buildTextOverlay(state, t)),
                      ...page.decorations.map((d) => _buildDecoration(page, d)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(LayoutPage page) {
    return CustomPaint(
      size: Size(page.pageWidth * 0.3, page.pageHeight * 0.3),
      painter: _GridPainter(gridSize: 40),
    );
  }

  // ===== 照片元素（画布坐标系，不随屏幕缩放） =====
  Widget _buildDraggableElement(AppState state, LayoutElement element) {
    final viewScale = 0.3;
    final borderW = element.borderWidth * viewScale * element.scale;
    final totalW = (element.width * viewScale + borderW * 2) * element.scale;
    final totalH = (element.height * viewScale + borderW * 2) * element.scale;

    BoxDecoration containerDeco;
    List<BoxShadow> shadows = [];
    switch (element.borderStyle) {
      case PhotoBorderStyle.none:
        containerDeco = const BoxDecoration();
        break;
      case PhotoBorderStyle.shadow:
        shadows = [
          BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 12, offset: const Offset(0, 6)),
        ];
        containerDeco = BoxDecoration(borderRadius: BorderRadius.circular(element.cornerRadius * viewScale * element.scale));
        break;
      case PhotoBorderStyle.polaroid:
        shadows = [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 4)),
        ];
        containerDeco = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(element.cornerRadius * viewScale * element.scale),
        );
        break;
      case PhotoBorderStyle.vintage:
        containerDeco = BoxDecoration(
          border: Border.all(color: Color(element.borderColor), width: borderW),
          borderRadius: BorderRadius.circular(element.cornerRadius * viewScale * element.scale),
        );
        break;
      default:
        containerDeco = BoxDecoration(
          border: Border.all(color: Color(element.borderColor), width: borderW),
          borderRadius: BorderRadius.circular(element.cornerRadius * viewScale * element.scale),
        );
    }

    return Positioned(
      left: element.x * viewScale,
      top: element.y * viewScale,
      child: GestureDetector(
        onScaleStart: (_) {
          _gestureStarts[element.id] = _GestureStart(
            scale: element.scale, rotation: element.rotation,
            x: element.x, y: element.y,
          );
        },
        onScaleUpdate: (details) {
          final start = _gestureStarts[element.id];
          if (start == null) return;
          state.updateElementPosition(
            element.id,
            start.x + details.focalPointDelta.dx / viewScale,
            start.y + details.focalPointDelta.dy / viewScale,
          );
          if (details.scale != 1.0) {
            state.updateElementScale(element.id, start.scale * details.scale);
          }
          if (details.rotation != 0.0) {
            state.updateElementRotation(element.id, start.rotation + details.rotation * 180 / pi);
          }
        },
        onScaleEnd: (_) => _gestureStarts.remove(element.id),
        onTap: () => _showElementOptions(state, element),
        child: Transform.rotate(
          angle: element.rotation * pi / 180,
          child: Container(
            width: totalW, height: totalH,
            decoration: containerDeco,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(borderW),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(element.cornerRadius * viewScale * element.scale),
                    child: Container(
                      width: element.width * viewScale * element.scale,
                      height: element.height * viewScale * element.scale,
                      decoration: BoxDecoration(boxShadow: shadows),
                      child: element.photo.mockColor != null
                          ? Container(
                              color: element.photo.mockColor,
                              child: Center(
                                child: Text(element.photo.title ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 10,
                                        shadows: [Shadow(color: Colors.black54, blurRadius: 2)])),
                              ),
                            )
                          : Image.file(
                              File(element.photo.path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image_rounded),
                              ),
                            ),
                    ),
                  ),
                ),
                // 删除按钮（画布坐标系，保持固定大小以便点击）
                Positioned(
                  top: -6, right: -6,
                  child: GestureDetector(
                    onTap: () => state.removeElement(element.id),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.red.withAlpha(40), blurRadius: 6)],
                      ),
                      child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 照片元素选项弹窗 =====
  void _showElementOptions(AppState state, LayoutElement element) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(24))),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.rw(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: context.rw(40), height: context.rw(4),
                    decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(context.rw(2))),
                  ),
                ),
                SizedBox(height: context.rw(16)),
                Text('照片样式', style: TextStyle(fontSize: context.rw(20), fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                SizedBox(height: context.rw(16)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _borderOption(state, element, PhotoBorderStyle.none, '无边框', Icons.crop_free_rounded),
                      _borderOption(state, element, PhotoBorderStyle.white, '白边', Icons.crop_square_rounded),
                      _borderOption(state, element, PhotoBorderStyle.polaroid, '拍立得', Icons.photo_rounded),
                      _borderOption(state, element, PhotoBorderStyle.rounded, '圆角', Icons.rounded_corner_rounded),
                      _borderOption(state, element, PhotoBorderStyle.vintage, '复古', Icons.history_rounded),
                      _borderOption(state, element, PhotoBorderStyle.shadow, '阴影', Icons.layers_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _borderOption(AppState state, LayoutElement element,
      PhotoBorderStyle style, String label, IconData icon) {
    final isSelected = element.borderStyle == style;
    return Padding(
      padding: EdgeInsets.only(right: context.rw(12)),
      child: GestureDetector(
        onTap: () { state.setElementBorder(element.id, style); Navigator.pop(context); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.rw(60), height: context.rw(60),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: AppTheme.gradientPrimary)
                      : null,
                  color: isSelected ? null : const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(context.rw(16)),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppTheme.primaryColor.withAlpha(40), blurRadius: context.rw(8))]
                      : null,
                ),
                child: Icon(icon, size: context.rw(26),
                    color: isSelected ? Colors.white : AppTheme.textSecondary),
              ),
              SizedBox(height: context.rw(6)),
              Text(label,
                  style: TextStyle(
                    fontSize: context.rw(12), fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 文字覆盖层（画布坐标系，不随屏幕缩放） =====
  Widget _buildTextOverlay(AppState state, TextOverlay text) {
    final viewScale = 0.3;
    return Positioned(
      left: text.x * viewScale,
      top: text.y * viewScale,
      child: GestureDetector(
        onScaleStart: (_) {
          _gestureStarts[text.id] = _GestureStart(
            scale: text.scale, rotation: text.rotation,
            x: text.x, y: text.y,
          );
        },
        onScaleUpdate: (details) {
          final start = _gestureStarts[text.id];
          if (start == null) return;
          state.updateTextOverlayPosition(
            text.id,
            start.x + details.focalPointDelta.dx / viewScale,
            start.y + details.focalPointDelta.dy / viewScale,
          );
          if (details.scale != 1.0) {
            state.updateTextOverlayScale(text.id, start.scale * details.scale);
          }
          if (details.rotation != 0.0) {
            state.updateTextOverlayRotation(text.id, start.rotation + details.rotation * 180 / pi);
          }
        },
        onScaleEnd: (_) => _gestureStarts.remove(text.id),
        onLongPress: () => _editTextOverlay(state, text),
        child: Transform.rotate(
          angle: text.rotation * pi / 180,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withAlpha(120), width: 1),
            ),
            child: Transform.scale(
              scale: text.scale,
              child: Text(
                text.text,
                style: TextStyle(
                  fontSize: text.fontSize * viewScale,
                  color: Color(text.color),
                  fontWeight: text.bold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: text.italic ? FontStyle.italic : FontStyle.normal,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== 编辑文字对话框 =====
  void _editTextOverlay(AppState state, TextOverlay text) {
    final controller = TextEditingController(text: text.text);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(24))),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.rw(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: context.rw(40), height: context.rw(4),
                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(context.rw(2)))),
                ),
                SizedBox(height: context.rw(16)),
                Text('编辑文字', style: TextStyle(fontSize: context.rw(20), fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                SizedBox(height: context.rw(16)),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '文字内容',
                    prefixIcon: Icon(Icons.text_fields_rounded, color: AppTheme.primaryColor),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: context.rw(16)),
                Text('字号', style: TextStyle(fontSize: context.rw(14), fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                SizedBox(height: context.rw(8)),
                Row(
                  children: [
                    _textStyleChip(state, text, '大标题', 72),
                    _textStyleChip(state, text, '标题', 48),
                    _textStyleChip(state, text, '正文', 32),
                    _textStyleChip(state, text, '小字', 24),
                  ],
                ),
                SizedBox(height: context.rw(16)),
                Text('颜色', style: TextStyle(fontSize: context.rw(14), fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                SizedBox(height: context.rw(8)),
                Row(
                  children: [
                    _colorChip(state, text, '深', 0xFF3D2C3A),
                    _colorChip(state, text, '白', 0xFFFFFFFF),
                    _colorChip(state, text, '粉', 0xFFFF7EB3),
                    _colorChip(state, text, '紫', 0xFFA78BFA),
                    _colorChip(state, text, '金', 0xFFFFD54F),
                  ],
                ),
                SizedBox(height: context.rw(24)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () { state.removeTextOverlay(text.id); Navigator.pop(ctx); },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: const Text('删除'),
                      ),
                    ),
                    SizedBox(width: context.rw(12)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          state.updateTextOverlay(text.id, controller.text);
                          Navigator.pop(ctx);
                        },
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textStyleChip(AppState state, TextOverlay text, String label, double size) {
    final isSelected = text.fontSize == size;
    return Padding(
      padding: EdgeInsets.only(right: context.rw(8)),
      child: GestureDetector(
        onTap: () => state.updateTextStyle(text.id, fontSize: size),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: context.rw(14), vertical: context.rw(8)),
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(colors: AppTheme.gradientPrimary) : null,
            color: isSelected ? null : const Color(0xFFFFF0F3),
            borderRadius: BorderRadius.circular(context.rw(20)),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: context.rw(13), fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              )),
        ),
      ),
    );
  }

  Widget _colorChip(AppState state, TextOverlay text, String label, int color) {
    final isSelected = text.color == color;
    return Padding(
      padding: EdgeInsets.only(right: context.rw(10)),
      child: GestureDetector(
        onTap: () => state.updateTextStyle(text.id, color: color),
        child: Container(
          width: context.rw(36), height: context.rw(36),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(color),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: Color(color).withAlpha(60), blurRadius: context.rw(8))]
                : null,
          ),
          child: isSelected
              ? Icon(Icons.check_rounded, size: context.rw(16), color: Colors.white)
              : null,
        ),
      ),
    );
  }

  // ===== 装饰元素（画布坐标系，不随屏幕缩放） =====
  Widget _buildDecoration(LayoutPage page, PageDecoration dec) {
    final scale = 0.3;
    final size = dec.size * scale;
    Widget child;
    switch (dec.type) {
      case 'corner_tl':
        child = _cornerDecoration(dec.color, true, true);
        return Positioned(left: 0, top: 0, child: child);
      case 'corner_tr':
        child = _cornerDecoration(dec.color, false, true);
        return Positioned(right: 0, top: 0, child: child);
      case 'corner_bl':
        child = _cornerDecoration(dec.color, true, false);
        return Positioned(left: 0, bottom: 0, child: child);
      case 'corner_br':
        child = _cornerDecoration(dec.color, false, false);
        return Positioned(right: 0, bottom: 0, child: child);
      case 'divider_top':
        child = _dividerDecoration(dec.color, page.pageWidth * scale);
        return Positioned(top: size, left: 20 * scale, right: 20 * scale, child: child);
      case 'divider_bottom':
        child = _dividerDecoration(dec.color, page.pageWidth * scale);
        return Positioned(bottom: size, left: 20 * scale, right: 20 * scale, child: child);
      case 'sticker_heart':
        child = Icon(Icons.favorite_rounded, color: Color(dec.color), size: size);
        return Positioned(left: page.pageWidth * scale * 0.5 - size / 2,
            top: page.pageHeight * scale * 0.5 - size / 2, child: child);
      case 'sticker_star':
        child = Icon(Icons.star_rounded, color: Color(dec.color), size: size);
        return Positioned(left: page.pageWidth * scale * 0.7,
            top: page.pageHeight * scale * 0.3, child: child);
      case 'sticker_paw':
        child = Icon(Icons.pets_rounded, color: Color(dec.color), size: size);
        return Positioned(left: page.pageWidth * scale * 0.2,
            top: page.pageHeight * scale * 0.7, child: child);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _cornerDecoration(int color, bool left, bool top) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: left ? BorderSide(color: Color(color), width: 3) : BorderSide.none,
          top: top ? BorderSide(color: Color(color), width: 3) : BorderSide.none,
          right: !left ? BorderSide(color: Color(color), width: 3) : BorderSide.none,
          bottom: !top ? BorderSide(color: Color(color), width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _dividerDecoration(int color, double width) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(color).withAlpha(200),
            Color(color).withAlpha(60),
            Color(color).withAlpha(200),
          ],
        ),
      ),
    );
  }

  // ===== 底部工具栏 =====
  Widget _buildBottomBar(AppState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(12),
            blurRadius: context.rw(12),
            offset: Offset(0, -context.rw(2)),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(20))),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(8), vertical: context.rw(4)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 编辑工具
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _toolButton(Icons.text_fields_rounded, '文字', () => _showAddTextDialog(state)),
                    _toolButton(Icons.auto_awesome, '装饰', () => _showDecorationPicker(state)),
                    _toolButton(Icons.palette_rounded, '背景', () => _showThemePicker(state)),
                    _toolButton(state.showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                        '网格', () => state.toggleGrid()),
                    _toolButton(Icons.add_rounded, '加页', () => state.addPage()),
                    if (state.pageCount > 1)
                      _toolButton(Icons.delete_outline_rounded, '删页',
                          () => _confirmDeletePage(state)),
                  ],
                ),
              ),
              SizedBox(height: context.rw(6)),
              // 翻页控制
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.rw(12), vertical: context.rw(6)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(context.rw(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pageNavButton(Icons.chevron_left_rounded,
                        state.currentPageIndex > 0, () => state.previousPage()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
                      child: Text(
                        '${state.currentPageIndex + 1} / ${state.pageCount}',
                        style: TextStyle(
                          fontSize: context.rw(15), fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    _pageNavButton(Icons.chevron_right_rounded,
                        state.currentPageIndex < state.pageCount - 1, () => state.nextPage()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rw(5)),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.rw(8)),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(context.rw(12)),
              ),
              child: Icon(icon, size: context.rw(22), color: AppTheme.primaryColor),
            ),
            SizedBox(height: context.rw(3)),
            Text(label, style: TextStyle(fontSize: context.rw(11), fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _pageNavButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(context.rw(4)),
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primaryColor : AppTheme.primaryLight.withAlpha(80),
          borderRadius: BorderRadius.circular(context.rw(20)),
        ),
        child: Icon(icon, size: context.rw(22), color: Colors.white),
      ),
    );
  }

  // ===== 照片缩略图条 =====
  Widget _buildPhotoStrip(AppState state) {
    final photos = state.currentProject?.projectPhotos ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();

    final page = state.currentPage;
    final usedIds = page?.elements.map((e) => e.photo.id).toSet() ?? {};

    return Container(
      height: context.rw(76),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(top: BorderSide(color: AppTheme.primaryLight.withAlpha(60), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: context.rw(42),
            alignment: Alignment.center,
            child: Icon(Icons.photo_library_rounded, size: context.rw(20), color: AppTheme.primaryLight),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(vertical: context.rw(10), horizontal: context.rw(4)),
              itemCount: photos.length,
              separatorBuilder: (_, __) => SizedBox(width: context.rw(8)),
              itemBuilder: (ctx, index) {
                final photo = photos[index];
                final isUsed = usedIds.contains(photo.id);
                return GestureDetector(
                  onTap: () { if (!isUsed) state.addPhotoToCurrentPage(photo); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: context.rw(56), height: context.rw(56),
                    decoration: BoxDecoration(
                      color: photo.mockColor ?? const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(context.rw(14)),
                      border: Border.all(
                        color: isUsed ? AppTheme.primaryColor : AppTheme.primaryLight.withAlpha(60),
                        width: isUsed ? 2.5 : 1,
                      ),
                      boxShadow: isUsed
                          ? [BoxShadow(color: AppTheme.primaryColor.withAlpha(30), blurRadius: context.rw(6))]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(context.rw(12)),
                          child: photo.mockColor == null
                              ? Image.file(File(photo.path), fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.broken_image_rounded, size: context.rw(20)),
                                )
                              : Center(
                                  child: Text(photo.title ?? '',
                                      style: TextStyle(fontSize: context.rw(8), color: Colors.white),
                                      textAlign: TextAlign.center),
                                ),
                        ),
                        if (isUsed)
                          Positioned(
                            top: 2, right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: AppTheme.gradientPrimary),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_rounded, size: context.rw(10), color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== 背景主题选择弹窗 =====
  void _showThemePicker(AppState state) {
    final themes = AppTheme.albumThemes;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(24))),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.rw(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: context.rw(40), height: context.rw(4),
                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(context.rw(2)))),
                ),
                SizedBox(height: context.rw(16)),
                Text('页面背景', style: TextStyle(fontSize: context.rw(20), fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                SizedBox(height: context.rw(16)),
                Wrap(
                  spacing: context.rw(12), runSpacing: context.rw(12),
                  children: List.generate(themes.length, (index) {
                    final t = themes[index];
                    final isSelected = index == state.currentThemeIndex;
                    return GestureDetector(
                      onTap: () { state.setTheme(index); Navigator.pop(ctx); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: context.rw(80), height: context.rw(56),
                        decoration: BoxDecoration(
                          color: t.bgColor,
                          borderRadius: BorderRadius.circular(context.rw(14)),
                          border: Border.all(
                            color: isSelected ? t.accentColor : t.accentColor.withAlpha(40),
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, size: context.rw(18), color: AppTheme.primaryColor)
                            else
                              Icon(Icons.circle_rounded, size: context.rw(8), color: t.accentColor),
                            SizedBox(height: context.rw(2)),
                            Text(t.name, style: TextStyle(fontSize: context.rw(10), fontWeight: FontWeight.w600, color: t.textColor)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 添加文字对话框 =====
  void _showAddTextDialog(AppState state) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(24))),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.rw(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: context.rw(40), height: context.rw(4),
                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(context.rw(2)))),
                ),
                SizedBox(height: context.rw(16)),
                Text('添加文字', style: TextStyle(fontSize: context.rw(20), fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                SizedBox(height: context.rw(16)),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '输入文字内容',
                    hintText: '写点什么吧~',
                    prefixIcon: Icon(Icons.text_fields_rounded, color: AppTheme.primaryColor),
                  ),
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                ),
                SizedBox(height: context.rw(20)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                    ),
                    SizedBox(width: context.rw(12)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            state.addTextOverlay(controller.text);
                          }
                          Navigator.pop(ctx);
                        },
                        child: const Text('添加'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 装饰选择弹窗 =====
  void _showDecorationPicker(AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(24))),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.rw(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: context.rw(40), height: context.rw(4),
                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(context.rw(2)))),
                ),
                SizedBox(height: context.rw(16)),
                Text('页面装饰', style: TextStyle(fontSize: context.rw(20), fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                SizedBox(height: context.rw(16)),
                Wrap(
                  spacing: context.rw(10), runSpacing: context.rw(10),
                  children: [
                    _decoCard('四角边框', Icons.border_style_rounded),
                    _decoCard('爱心贴纸', Icons.favorite_rounded),
                    _decoCard('星星贴纸', Icons.star_rounded),
                    _decoCard('爪印贴纸', Icons.pets_rounded),
                  ],
                ),
                SizedBox(height: context.rw(16)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () { state.clearDecorations(); Navigator.pop(ctx); },
                    icon: Icon(Icons.delete_outline_rounded, size: context.rw(18)),
                    label: const Text('清除全部装饰'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _decoCard(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        final state = context.read<AppState>();
        switch (label) {
          case '四角边框':
            state.addDecoration('corner_tl'); state.addDecoration('corner_tr');
            state.addDecoration('corner_bl'); state.addDecoration('corner_br');
            break;
          case '顶部分割线':
            state.addDecoration('divider_top');
            break;
          case '底部分割线':
            state.addDecoration('divider_bottom');
            break;
          case '爱心贴纸':
            state.addDecoration('sticker_heart');
            break;
          case '星星贴纸':
            state.addDecoration('sticker_star');
            break;
          case '爪印贴纸':
            state.addDecoration('sticker_paw');
            break;
        }
      },
      child: Container(
        width: context.rw(72), height: context.rw(72),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(context.rw(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: context.rw(28), color: AppTheme.primaryColor),
            SizedBox(height: context.rw(4)),
            Text(label, style: TextStyle(fontSize: context.rw(10), fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ===== 通用弹窗 =====
  void _confirmDeletePage(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.rw(24))),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.rw(8)),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(context.rw(12)),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: context.rw(24)),
            ),
            SizedBox(width: context.rw(12)),
            Text('删除当前页', style: TextStyle(fontSize: context.rw(18), fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('确定要删除这一页吗？此操作不可撤销哦~',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { state.removeCurrentPage(); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gridSize;
  _GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryLight.withAlpha(25)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
