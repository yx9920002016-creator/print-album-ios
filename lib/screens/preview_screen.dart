import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/layout_page.dart';
import '../theme/app_theme.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.currentProject == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F3), Color(0xFFF5F0FF)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(Icons.preview_rounded, size: 72, color: AppTheme.primaryLight),
                ),
                const SizedBox(height: 20),
                const Text('还没有排版项目',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text('请先创建排版项目再来预览吧',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final theme = state.currentTheme;

    return Scaffold(
      body: Column(
        children: [
          // 顶部渐变头
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.gradientHeader,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 8,
              bottom: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.currentProject!.name,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 导出按钮
                _headerBtn(Icons.save_alt_rounded, '导出 PDF', () => _exportPdf(context, state)),
                _headerBtn(Icons.share_rounded, '分享', () => _sharePdf(context, state)),
              ],
            ),
          ),
          // 页面预览
          Expanded(child: _buildPageViewer(context, state, theme)),
          // 底部页导航
          _buildPageBar(context, state),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPageViewer(BuildContext context, AppState state, AlbumTheme theme) {
    final project = state.currentProject!;
    final page = project.pages[state.currentPageIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final scaleFactor = constraints.maxWidth / page.pageWidth;
            final displayW = page.pageWidth * scaleFactor;
            final displayH = page.pageHeight * scaleFactor;

            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Container(
                width: displayW,
                height: displayH,
                decoration: BoxDecoration(
                  color: theme.bgColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _renderPage(page, scaleFactor),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _renderPage(LayoutPage page, double scaleFactor) {
    return Stack(
      children: [
        // 背景
        Positioned.fill(
          child: Container(color: Color(page.backgroundColor)),
        ),
        // 照片元素（含边框/缩放/旋转）
        ...page.elements.map((el) {
          final borderW = el.borderWidth * scaleFactor * el.scale;
          return Positioned(
            left: el.x * scaleFactor - (el.width * scaleFactor * (el.scale - 1) / 2),
            top: el.y * scaleFactor - (el.height * scaleFactor * (el.scale - 1) / 2),
            child: Transform.rotate(
              angle: el.rotation * 3.14159 / 180,
              child: Container(
                width: (el.width * scaleFactor + borderW * 2) * el.scale,
                height: (el.height * scaleFactor + borderW * 2) * el.scale,
                decoration: BoxDecoration(
                  color: el.borderStyle == PhotoBorderStyle.polaroid ? Colors.white : null,
                  border: el.borderStyle != PhotoBorderStyle.none && el.borderStyle != PhotoBorderStyle.polaroid && el.borderStyle != PhotoBorderStyle.shadow
                      ? Border.all(color: Color(el.borderColor), width: borderW)
                      : null,
                  borderRadius: BorderRadius.circular(el.cornerRadius * scaleFactor * el.scale),
                  boxShadow: el.borderStyle == PhotoBorderStyle.shadow || el.borderStyle == PhotoBorderStyle.polaroid
                      ? [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Padding(
                  padding: EdgeInsets.all(borderW),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(el.cornerRadius * scaleFactor * el.scale),
                    child: el.photo.mockColor != null
                        ? Container(
                            color: el.photo.mockColor,
                            child: Center(
                              child: Text(el.photo.title ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 12,
                                      shadows: [Shadow(color: Colors.black54, blurRadius: 2)])),
                            ),
                          )
                        : Image.file(
                            File(el.photo.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFFFF0F3)),
                          ),
                  ),
                ),
              ),
            ),
          );
        }),
        // 文字覆盖层
        ...page.textOverlays.map((t) {
          return Positioned(
            left: t.x * scaleFactor,
            top: t.y * scaleFactor,
            child: Transform.rotate(
              angle: t.rotation * 3.14159 / 180,
              child: Transform.scale(
                scale: t.scale,
                child: Text(
                  t.text,
                  style: TextStyle(
                    fontSize: t.fontSize * scaleFactor,
                    color: Color(t.color),
                    fontWeight: t.bold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: t.italic ? FontStyle.italic : FontStyle.normal,
                    shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
                  ),
                ),
              ),
            ),
          );
        }),
        // 装饰元素
        ...page.decorations.map((d) {
          final size = d.size * scaleFactor;
          switch (d.type) {
            case 'corner_tl':
              return Positioned(left: 0, top: 0,
                  child: _cornerDecoration(d.color, true, true));
            case 'corner_tr':
              return Positioned(right: 0, top: 0,
                  child: _cornerDecoration(d.color, false, true));
            case 'corner_bl':
              return Positioned(left: 0, bottom: 0,
                  child: _cornerDecoration(d.color, true, false));
            case 'corner_br':
              return Positioned(right: 0, bottom: 0,
                  child: _cornerDecoration(d.color, false, false));
            case 'sticker_heart':
              return Positioned(
                left: page.pageWidth * scaleFactor * 0.5 - size / 2,
                top: page.pageHeight * scaleFactor * 0.5 - size / 2,
                child: Icon(Icons.favorite_rounded, color: Color(d.color), size: size));
            case 'sticker_star':
              return Positioned(
                left: page.pageWidth * scaleFactor * 0.7,
                top: page.pageHeight * scaleFactor * 0.3,
                child: Icon(Icons.star_rounded, color: Color(d.color), size: size));
            case 'sticker_paw':
              return Positioned(
                left: page.pageWidth * scaleFactor * 0.2,
                top: page.pageHeight * scaleFactor * 0.7,
                child: Icon(Icons.pets_rounded, color: Color(d.color), size: size));
            default:
              return const SizedBox.shrink();
          }
        }),
      ],
    );
  }

  Widget _cornerDecoration(int color, bool left, bool top) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: left ? BorderSide(color: Color(color), width: 2) : BorderSide.none,
          top: top ? BorderSide(color: Color(color), width: 2) : BorderSide.none,
          right: !left ? BorderSide(color: Color(color), width: 2) : BorderSide.none,
          bottom: !top ? BorderSide(color: Color(color), width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  // ===== 底部页导航 =====
  Widget _buildPageBar(BuildContext context, AppState state) {
    final project = state.currentProject!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withAlpha(12), blurRadius: 12, offset: const Offset(0, -2)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageNavBtn(Icons.chevron_left_rounded,
                  state.currentPageIndex > 0, () => state.previousPage()),
              const SizedBox(width: 16),
              // 圆点指示器
              Row(
                children: List.generate(project.pageCount, (i) {
                  final isCurrent = i == state.currentPageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isCurrent ? 28 : 8, height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: isCurrent
                          ? const LinearGradient(colors: AppTheme.gradientPrimary)
                          : null,
                      color: isCurrent ? null : AppTheme.primaryLight.withAlpha(80),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              _pageNavBtn(Icons.chevron_right_rounded,
                  state.currentPageIndex < project.pageCount - 1, () => state.nextPage()),
              const SizedBox(width: 20),
              Text('${state.currentPageIndex + 1}/${project.pageCount}',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageNavBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: enabled ? const LinearGradient(colors: AppTheme.gradientPrimary) : null,
          color: enabled ? null : const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22,
            color: enabled ? Colors.white : AppTheme.primaryLight.withAlpha(80)),
      ),
    );
  }

  // ===== 导出 PDF =====
  void _exportPdf(BuildContext context, AppState state) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );

    final path = await state.exportService.exportToPdf(state.currentProject!);
    Navigator.pop(context);

    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF 已导出 ~ $path'),
          action: SnackBarAction(
            label: '分享',
            textColor: AppTheme.accentWarm,
            onPressed: () => _sharePdfFile(context, state, path),
          ),
          backgroundColor: AppTheme.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('导出失败，请重试'),
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _sharePdf(BuildContext context, AppState state) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );

    final path = await state.exportService.exportToPdf(state.currentProject!);
    Navigator.pop(context);

    if (path != null) {
      await state.exportService.sharePdf(path);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('导出失败，请重试'),
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _sharePdfFile(BuildContext context, AppState state, String path) {
    state.exportService.sharePdf(path);
  }
}
