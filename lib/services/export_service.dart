import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/album_project.dart';
import '../models/layout_page.dart';

/// 导出服务 - 生成 PDF / 图片并分享
class ExportService {
  // ──────────────────────────────────────────────
  //  PDF 导出
  // ──────────────────────────────────────────────

  /// 导出完整相册项目为 PDF
  Future<String?> exportToPdf(AlbumProject project) async {
    try {
      final pdf = pw.Document();
      final pageFormat = PdfPageFormat(
        595.28, // A4 宽度 (points)
        841.89, // A4 高度 (points)
      );

      for (final page in project.pages) {
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (context) {
              return pw.Stack(
                children: [
                  // ── 背景 ──
                  pw.Container(
                    width: pageFormat.width,
                    height: pageFormat.height,
                    color: _intToPdfColor(page.backgroundColor),
                  ),

                  // ── 装饰 (角花 / 分割线 / 贴纸) ──
                  ..._buildPdfDecorations(page, pageFormat.width, pageFormat.height),

                  // ── 照片元素 (完整旋转+缩放+边框) ──
                  ...page.elements.map((e) => _buildPdfPhotoElement(e, page, pageFormat.width, pageFormat.height)),

                  // ── 文字覆盖层 ──
                  ...page.textOverlays.map((t) => _buildPdfTextOverlay(t, page, pageFormat.width, pageFormat.height)),
                ],
              );
            },
          ),
        );
      }

      final outputDir = await getApplicationDocumentsDirectory();
      final fileName = '${project.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      print('PDF 导出失败: $e');
      return null;
    }
  }

  /// 分享 PDF 文件
  Future<void> sharePdf(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: '我的成长相册');
  }

  /// 导出所有页面为 PNG 图片，返回文件路径列表
  Future<List<String>?> exportAllPagesAsImages(AlbumProject project, {double scale = 2.0}) async {
    try {
      final paths = <String>[];
      for (int i = 0; i < project.pages.length; i++) {
        final path = await exportPageAsImage(project.pages[i], scale: scale);
        if (path != null) paths.add(path);
      }
      return paths.isEmpty ? null : paths;
    } catch (e) {
      print('多页图片导出失败: $e');
      return null;
    }
  }

  /// 分享多张图片
  Future<void> shareImages(List<String> paths) async {
    final files = paths.map((p) => XFile(p)).toList();
    await Share.shareXFiles(files, text: '我的成长相册');
  }

  // ──────────────────────────────────────────────
  //  图片导出（修复版：含文字、装饰、旋转、缩放）
  // ──────────────────────────────────────────────

  /// 导出单页为 PNG 图片
  Future<String?> exportPageAsImage(LayoutPage page, {double scale = 2.0}) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(page.pageWidth, page.pageHeight);

      // 1. 背景
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Color(page.backgroundColor),
      );

      // 2. 装饰
      _drawDecorationsOnCanvas(canvas, page);

      // 3. 照片元素（含旋转、缩放）
      for (final element in page.elements) {
        final file = File(element.photo.path);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(
            imageBytes,
            targetWidth: (element.width * element.scale * scale).toInt(),
            targetHeight: (element.height * element.scale * scale).toInt(),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;

          canvas.save();

          // 旋转（绕元素中心）
          if (element.rotation != 0) {
            final cx = element.x + (element.width * element.scale) / 2;
            final cy = element.y + (element.height * element.scale) / 2;
            canvas.translate(cx, cy);
            canvas.rotate(element.rotation * pi / 180);
            canvas.translate(-cx, -cy);
          }

          // 绘制边框（如果有）
          if (element.borderStyle != PhotoBorderStyle.none) {
            final borderRect = RRect.fromRectAndRadius(
              Rect.fromLTWH(element.x, element.y,
                  element.width * element.scale, element.height * element.scale),
              Radius.circular(element.borderStyle == PhotoBorderStyle.rounded ? element.cornerRadius : 0),
            );
            final borderPaint = Paint()
              ..color = Color(element.borderColor)
              ..style = PaintingStyle.stroke
              ..strokeWidth = element.borderWidth;
            canvas.drawRRect(borderRect, borderPaint);
          }

          // 圆角裁剪（仅 rounded 风格在图片上也做圆角）
          if (element.borderStyle == PhotoBorderStyle.rounded && element.cornerRadius > 0) {
            canvas.clipRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(element.x, element.y,
                  element.width * element.scale, element.height * element.scale),
              Radius.circular(element.cornerRadius),
            ));
          }

          // 拍立得：底部留白更多
          double drawY = element.y;
          double drawH = element.height * element.scale;
          if (element.borderStyle == PhotoBorderStyle.polaroid) {
            drawH = element.height * element.scale * 0.75;
            drawY = element.y + (element.height * element.scale - drawH) / 4;
          }

          canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(element.x, drawY, element.width * element.scale, drawH),
            Paint(),
          );
          canvas.restore();
          image.dispose();
        }
      }

      // 4. 文字覆盖层
      _drawTextOverlaysOnCanvas(canvas, page);

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        (size.width * scale).toInt(),
        (size.height * scale).toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();

      if (byteData == null) return null;

      final outputDir = await getApplicationDocumentsDirectory();
      final fileName = 'page_${page.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file.path;
    } catch (e) {
      print('图片导出失败: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  //  PDF 元素构建器
  // ──────────────────────────────────────────────

  /// 构建 PDF 照片元素（含旋转、缩放、边框样式）
  pw.Widget _buildPdfPhotoElement(LayoutElement element, LayoutPage page, double pdfW, double pdfH) {
    final scaledW = _scaleX(element.width * element.scale, page, pdfW);
    final scaledH = _scaleY(element.height * element.scale, page, pdfH);
    final posX = _scaleX(element.x, page, pdfW);
    final posY = _scaleY(element.y, page, pdfH);

    // 图片 widget
    pw.Widget imageWidget = _buildPdfImage(element);

    // 圆角裁剪
    if (element.borderStyle == PhotoBorderStyle.rounded && element.cornerRadius > 0) {
      final rad = _scaleX(element.cornerRadius, page, pdfW);
      imageWidget = pw.ClipRRect(
        horizontalRadius: rad,
        verticalRadius: rad,
        child: imageWidget,
      );
    }

    // 拍立得：图片区域缩小
    if (element.borderStyle == PhotoBorderStyle.polaroid) {
      imageWidget = pw.Padding(
        padding: pw.EdgeInsets.only(
          left: scaledW * 0.08,
          top: scaledH * 0.08,
          right: scaledW * 0.08,
          bottom: scaledH * 0.30,
        ),
        child: imageWidget,
      );
    }

    // 边框
    final wDeco = _buildPdfBorderDecoration(element, page, pdfW);

    // 无旋转 → 直接定位
    if (element.rotation == 0) {
      return pw.Positioned(
        left: posX,
        top: posY,
        child: pw.Container(
          width: scaledW,
          height: scaledH,
          decoration: wDeco,
          child: imageWidget,
        ),
      );
    }

    // 有旋转 → 用 Transform.rotate 绕中心旋转
    // PDF 的 Transform.rotate 绕左上角旋转，所以需要偏移到中心
    final rad = element.rotation * pi / 180;
    final halfW = scaledW / 2;
    final halfH = scaledH / 2;
    final centerX = posX + halfW;
    final centerY = posY + halfH;

    // 用多层 Stack 模拟绕中心旋转：
    // 1. 把容器平移到 (centerX, centerY)
    // 2. 绕原点旋转（原点已移到中心）
    // 3. 把内容偏移回 (-halfW, -halfH)
    return pw.Positioned(
      left: centerX,
      top: centerY,
      child: pw.Transform.rotate(
        angle: rad,
        child: pw.Container(
          width: scaledW,
          height: scaledH,
          margin: pw.EdgeInsets.only(left: -halfW, top: -halfH),
          decoration: wDeco,
          child: imageWidget,
        ),
      ),
    );
  }

  /// 构建 PDF 文字覆盖层
  pw.Widget _buildPdfTextOverlay(TextOverlay text, LayoutPage page, double pdfW, double pdfH) {
    final fontSize = _scaleX(text.fontSize * text.scale, page, pdfW);
    final posX = _scaleX(text.x, page, pdfW);
    final posY = _scaleY(text.y, page, pdfH);
    final color = _intToPdfColor(text.color);

    var style = pw.TextStyle(fontSize: fontSize, color: color);
    if (text.bold && text.italic) {
      style = style.copyWith(fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic);
    } else if (text.bold) {
      style = style.copyWith(fontWeight: pw.FontWeight.bold);
    } else if (text.italic) {
      style = style.copyWith(fontStyle: pw.FontStyle.italic);
    }

    final textWidget = pw.Text(text.text, style: style);

    if (text.rotation == 0) {
      return pw.Positioned(left: posX, top: posY, child: textWidget);
    }

    // 有旋转——由于文字没有确切的宽高，简化处理：直接在 Positioned 内旋转
    return pw.Positioned(
      left: posX,
      top: posY,
      child: pw.Transform.rotate(angle: text.rotation * pi / 180, child: textWidget),
    );
  }

  /// 构建 PDF 照片边框
  pw.BoxDecoration _buildPdfBorderDecoration(LayoutElement element, LayoutPage page, double pdfW) {
    if (element.borderStyle == PhotoBorderStyle.none) {
      return const pw.BoxDecoration();
    }

    final borderColor = _intToPdfColor(element.borderColor);
    final bw = _scaleX(element.borderWidth, page, pdfW);

    // 复古双线
    if (element.borderStyle == PhotoBorderStyle.vintage) {
      return pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: bw),
      );
    }

    // 阴影
    if (element.borderStyle == PhotoBorderStyle.shadow) {
      return pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: bw),
      );
    }

    // 圆角
    if (element.borderStyle == PhotoBorderStyle.rounded) {
      final rad = _scaleX(element.cornerRadius, page, pdfW);
      return pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: bw),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(rad)),
      );
    }

    // 默认白边 / 拍立得
    return pw.BoxDecoration(
      border: pw.Border.all(color: borderColor, width: bw),
    );
  }

  /// PDF 中嵌入图片
  pw.Widget _buildPdfImage(LayoutElement element) {
    try {
      final file = File(element.photo.path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        return pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
      }
    } catch (_) {}
    return pw.Container(color: PdfColors.grey300);
  }

  /// 构建 PDF 中所有装饰元素
  List<pw.Widget> _buildPdfDecorations(LayoutPage page, double pdfW, double pdfH) {
    final widgets = <pw.Widget>[];

    for (final dec in page.decorations) {
      final color = _intToPdfColor(dec.color);
      // 简化：直接用 proportional size
      final s = pdfW * 0.035; // 大约 20pt

      switch (dec.type) {
        // ── 四角边框 ──
        case 'corner_tl':
          widgets.add(_buildCornerPdf(color, s, pdfW, pdfH, left: true, top: true));
          break;
        case 'corner_tr':
          widgets.add(_buildCornerPdf(color, s, pdfW, pdfH, left: false, top: true));
          break;
        case 'corner_bl':
          widgets.add(_buildCornerPdf(color, s, pdfW, pdfH, left: true, top: false));
          break;
        case 'corner_br':
          widgets.add(_buildCornerPdf(color, s, pdfW, pdfH, left: false, top: false));
          break;

        // ── 分割线 ──
        case 'divider_top':
          widgets.add(
            pw.Positioned(
              left: pdfW * 0.08,
              right: pdfW * 0.08,
              top: s * 1.2,
              child: pw.Container(height: 2, color: color),
            ),
          );
          break;
        case 'divider_bottom':
          widgets.add(
            pw.Positioned(
              left: pdfW * 0.08,
              right: pdfW * 0.08,
              bottom: s * 1.2,
              child: pw.Container(height: 2, color: color),
            ),
          );
          break;

        // ── 贴纸 ──
        case 'sticker_heart':
          widgets.add(_buildStickerPdf('♥', color, pdfW * 0.50 - s / 2, pdfH * 0.50 - s / 2, s * 1.6));
          break;
        case 'sticker_star':
          widgets.add(_buildStickerPdf('★', color, pdfW * 0.70 - s / 2, pdfH * 0.30 - s / 2, s * 1.6));
          break;
        case 'sticker_paw':
          widgets.add(_buildStickerPdf('🐾', color, pdfW * 0.20 - s / 2, pdfH * 0.70 - s / 2, s * 1.8));
          break;
      }
    }
    return widgets;
  }

  /// PDF 四角 L 形装饰
  pw.Widget _buildCornerPdf(PdfColor color, double size, double pdfW, double pdfH,
      {required bool left, required bool top}) {
    final border = pw.Border(
      left: left ? pw.BorderSide(color: color, width: 3) : pw.BorderSide.none,
      top: top ? pw.BorderSide(color: color, width: 3) : pw.BorderSide.none,
      right: !left ? pw.BorderSide(color: color, width: 3) : pw.BorderSide.none,
      bottom: !top ? pw.BorderSide(color: color, width: 3) : pw.BorderSide.none,
    );

    return pw.Positioned(
      left: left ? 10 : pdfW - size - 10,
      top: top ? 10 : pdfH - size - 10,
      child: pw.Container(width: size, height: size, decoration: pw.BoxDecoration(border: border)),
    );
  }

  /// PDF 贴纸（用 Unicode 字符）
  pw.Widget _buildStickerPdf(String char, PdfColor color, double x, double y, double size) {
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Text(char, style: pw.TextStyle(fontSize: size, color: color)),
    );
  }

  // ──────────────────────────────────────────────
  //  Canvas 绘制辅助 (图片导出用)
  // ──────────────────────────────────────────────

  /// 在 Canvas 上绘制所有装饰
  void _drawDecorationsOnCanvas(Canvas canvas, LayoutPage page) {
    const uiDecoScale = 0.3;

    for (final dec in page.decorations) {
      final paint = Paint()..color = Color(dec.color)..style = PaintingStyle.stroke..strokeWidth = 3;
      final size = dec.size * uiDecoScale;

      switch (dec.type) {
        case 'corner_tl':
          _drawCornerOnCanvas(canvas, Offset(0, 0), size, paint, left: true, top: true);
          break;
        case 'corner_tr':
          _drawCornerOnCanvas(canvas, Offset(page.pageWidth * uiDecoScale - size, 0), size, paint, left: false, top: true);
          break;
        case 'corner_bl':
          _drawCornerOnCanvas(canvas, Offset(0, page.pageHeight * uiDecoScale - size), size, paint, left: true, top: false);
          break;
        case 'corner_br':
          _drawCornerOnCanvas(canvas,
              Offset(page.pageWidth * uiDecoScale - size, page.pageHeight * uiDecoScale - size), size, paint,
              left: false, top: false);
          break;
        case 'divider_top':
          canvas.drawLine(
            Offset(page.pageWidth * uiDecoScale * 0.1, size * 1.5),
            Offset(page.pageWidth * uiDecoScale * 0.9, size * 1.5),
            paint,
          );
          break;
        case 'divider_bottom':
          canvas.drawLine(
            Offset(page.pageWidth * uiDecoScale * 0.1, page.pageHeight * uiDecoScale - size * 1.5),
            Offset(page.pageWidth * uiDecoScale * 0.9, page.pageHeight * uiDecoScale - size * 1.5),
            paint,
          );
          break;
        case 'sticker_heart':
          _drawStickerOnCanvas(canvas, '♥',
              Offset(page.pageWidth * uiDecoScale * 0.5, page.pageHeight * uiDecoScale * 0.5), size * 1.6, dec.color);
          break;
        case 'sticker_star':
          _drawStickerOnCanvas(canvas, '★',
              Offset(page.pageWidth * uiDecoScale * 0.7, page.pageHeight * uiDecoScale * 0.3), size * 1.6, dec.color);
          break;
        case 'sticker_paw':
          _drawStickerOnCanvas(canvas, '🐾',
              Offset(page.pageWidth * uiDecoScale * 0.2, page.pageHeight * uiDecoScale * 0.7), size * 1.8, dec.color);
          break;
      }
    }
  }

  /// 在 Canvas 上绘制 L 形角装饰
  void _drawCornerOnCanvas(Canvas canvas, Offset origin, double size, Paint paint,
      {required bool left, required bool top}) {
    if (top) {
      final pStartH = left ? origin : Offset(origin.dx + size, origin.dy);
      final pEndH = left ? Offset(origin.dx + size, origin.dy) : origin;
      canvas.drawLine(pStartH, pEndH, paint);
    }
    if (left) {
      canvas.drawLine(Offset(origin.dx, origin.dy), Offset(origin.dx, origin.dy + size), paint);
    } else {
      canvas.drawLine(Offset(origin.dx + size, origin.dy), Offset(origin.dx + size, origin.dy + size), paint);
    }
  }

  /// 在 Canvas 上绘制贴纸（文字）
  void _drawStickerOnCanvas(Canvas canvas, String char, Offset center, double fontSize, int color) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      fontSize: fontSize,
    ))
      ..pushStyle(ui.TextStyle(color: Color(color), fontSize: fontSize))
      ..addText(char);
    final paragraph = builder.build()..layout(ui.ParagraphConstraints(width: fontSize * 2));
    canvas.drawParagraph(paragraph, Offset(center.dx - fontSize, center.dy - fontSize / 2));
  }

  /// 在 Canvas 上绘制文字覆盖层
  void _drawTextOverlaysOnCanvas(Canvas canvas, LayoutPage page) {
    for (final text in page.textOverlays) {
      final fontSize = text.fontSize * text.scale;
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        fontSize: fontSize,
        fontWeight: text.bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
        fontStyle: text.italic ? ui.FontStyle.italic : ui.FontStyle.normal,
      ))
        ..pushStyle(ui.TextStyle(color: Color(text.color), fontSize: fontSize))
        ..addText(text.text);
      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: page.pageWidth - text.x));

      canvas.save();

      if (text.rotation != 0) {
        final cx = text.x + paragraph.width / 2;
        final cy = text.y + paragraph.height / 2;
        canvas.translate(cx, cy);
        canvas.rotate(text.rotation * pi / 180);
        canvas.translate(-cx, -cy);
      }

      canvas.drawParagraph(paragraph, Offset(text.x, text.y));
      canvas.restore();
    }
  }

  // ==============================================
  //  坐标映射 & 颜色工具
  // ==============================================

  double _scaleX(double value, LayoutPage page, double targetWidth) {
    return value * targetWidth / page.pageWidth;
  }

  double _scaleY(double value, LayoutPage page, double targetHeight) {
    return value * targetHeight / page.pageHeight;
  }

  PdfColor _intToPdfColor(int color) {
    return PdfColor.fromInt(color);
  }
}
