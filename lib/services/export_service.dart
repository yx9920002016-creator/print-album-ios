import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/album_project.dart';
import '../models/layout_page.dart';

/// 导出服务 - 生成 PDF 并分享
class ExportService {
  /// 导出为 PDF 文件
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
                  // 背景色
                  pw.Container(
                    width: pageFormat.width,
                    height: pageFormat.height,
                    color: _intToPdfColor(page.backgroundColor),
                  ),
                  // 照片元素
                  ...page.elements.map((element) {
                    return pw.Positioned(
                      left: _scaleX(element.x, page, pageFormat.width),
                      top: _scaleY(element.y, page, pageFormat.height),
                      child: pw.Container(
                        width: _scaleX(element.width, page, pageFormat.width),
                        height: _scaleY(element.height, page, pageFormat.height),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 2,
                          ),
                        ),
                        child: _buildPdfImage(element),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      }

      final outputDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${project.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  /// 导出单页为图片
  Future<String?> exportPageAsImage(LayoutPage page, {double scale = 2.0}) async {
    try {
      // 创建离屏渲染
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(page.pageWidth, page.pageHeight);

      // 绘制背景
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Color(page.backgroundColor),
      );

      // 绘制每个元素
      for (final element in page.elements) {
        final file = File(element.photo.path);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(
            imageBytes,
            targetWidth: (element.width * scale).toInt(),
            targetHeight: (element.height * scale).toInt(),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;

          canvas.save();
          if (element.rotation != 0) {
            final centerX = element.x + element.width / 2;
            final centerY = element.y + element.height / 2;
            canvas.translate(centerX, centerY);
            canvas.rotate(element.rotation * 3.14159 / 180);
            canvas.translate(-centerX, -centerY);
          }
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(element.x, element.y, element.width, element.height),
            Paint(),
          );
          canvas.restore();
          image.dispose();
        }
      }

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

  // ========== 辅助方法 ==========

  PdfColor _intToPdfColor(int color) {
    return PdfColor.fromInt(color);
  }

  double _scaleX(double value, LayoutPage page, double targetWidth) {
    return value * targetWidth / page.pageWidth;
  }

  double _scaleY(double value, LayoutPage page, double targetHeight) {
    return value * targetHeight / page.pageHeight;
  }

  pw.Widget _buildPdfImage(LayoutElement element) {
    // PDF 中嵌入图片
    try {
      final file = File(element.photo.path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        return pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
      }
    } catch (_) {}
    return pw.Container(color: PdfColors.grey300);
  }
}
