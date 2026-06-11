import 'dart:math';
import 'package:flutter/material.dart';
import '../models/layout_page.dart';

/// 吸附辅助线
class SnapGuide {
  final double value;
  final bool isHorizontal; // true=水平线, false=垂直线
  final double start;
  final double end;

  const SnapGuide({
    required this.value,
    required this.isHorizontal,
    required this.start,
    required this.end,
  });
}

/// 吸附结果
class SnapResult {
  final double x;
  final double y;
  final List<SnapGuide> guides;

  const SnapResult({required this.x, required this.y, required this.guides});
  const SnapResult.noSnap(double x, double y)
      : x = x,
        y = y,
        guides = const [];
}

/// 智能对齐吸附计算器
class SnapCalculator {
  static const double snapThreshold = 12.0; // 吸附距离阈值（页面坐标）

  /// 计算吸附后的位置
  static SnapResult snap(
    LayoutPage page,
    LayoutElement movingElement,
    double proposedX,
    double proposedY, {
    double snapThreshold = snapThreshold,
  }) {
    final guides = <SnapGuide>[];
    double snappedX = proposedX;
    double snappedY = proposedY;

    final elemW = movingElement.width * movingElement.scale;
    final elemH = movingElement.height * movingElement.scale;

    // 当前元素的边缘
    final myLeft = proposedX;
    final myRight = proposedX + elemW;
    final myTop = proposedY;
    final myBottom = proposedY + elemH;
    final myCenterX = proposedX + elemW / 2;
    final myCenterY = proposedY + elemH / 2;

    // ── 画布边界 ──
    final canvasLeft = 0.0;
    final canvasRight = page.pageWidth;
    final canvasTop = 0.0;
    final canvasBottom = page.pageHeight;
    final canvasCenterX = page.pageWidth / 2;
    final canvasCenterY = page.pageHeight / 2;

    double closestDX = snapThreshold + 1;
    double closestDY = snapThreshold + 1;

    // 检查画布边界吸附
    _checkSnap(myLeft, canvasLeft, snapThreshold, (v) {
      if ((v - proposedX).abs() < closestDX.abs()) {
        closestDX = v - proposedX;
        guides.add(SnapGuide(value: v, isHorizontal: false, start: canvasTop, end: canvasBottom));
      }
    });

    _checkSnap(myRight, canvasRight, snapThreshold, (v) {
      final dx = v - elemW - proposedX;
      if (dx.abs() < closestDX.abs()) {
        closestDX = dx;
        guides.add(SnapGuide(value: v, isHorizontal: false, start: canvasTop, end: canvasBottom));
      }
    });

    _checkSnap(myTop, canvasTop, snapThreshold, (v) {
      if ((v - proposedY).abs() < closestDY.abs()) {
        closestDY = v - proposedY;
        guides.add(SnapGuide(value: v, isHorizontal: true, start: canvasLeft, end: canvasRight));
      }
    });

    _checkSnap(myBottom, canvasBottom, snapThreshold, (v) {
      final dy = v - elemH - proposedY;
      if (dy.abs() < closestDY.abs()) {
        closestDY = dy;
        guides.add(SnapGuide(value: v, isHorizontal: true, start: canvasLeft, end: canvasRight));
      }
    });

    // 画布中线
    _checkSnap(myCenterX, canvasCenterX, snapThreshold, (v) {
      final dx = v - elemW / 2 - proposedX;
      if (dx.abs() < closestDX.abs()) {
        closestDX = dx;
        guides.add(SnapGuide(value: v, isHorizontal: false, start: canvasTop, end: canvasBottom));
      }
    });

    _checkSnap(myCenterY, canvasCenterY, snapThreshold, (v) {
      final dy = v - elemH / 2 - proposedY;
      if (dy.abs() < closestDY.abs()) {
        closestDY = dy;
        guides.add(SnapGuide(value: v, isHorizontal: true, start: canvasLeft, end: canvasRight));
      }
    });

    // ── 与其他元素对齐 ──
    for (final other in page.elements) {
      if (other.id == movingElement.id) continue;

      final oLeft = other.x;
      final oRight = other.x + other.width * other.scale;
      final oTop = other.y;
      final oBottom = other.y + other.height * other.scale;
      final oCenterX = other.x + other.width * other.scale / 2;
      final oCenterY = other.y + other.height * other.scale / 2;

      // 左边对齐
      _checkSnap(myLeft, oLeft, snapThreshold, (v) {
        final dx = v - proposedX;
        if (dx.abs() < closestDX.abs()) {
          closestDX = dx;
          guides.add(SnapGuide(value: v, isHorizontal: false, start: min(myTop, oTop), end: max(myBottom, oBottom)));
        }
      });
      // 右边对齐
      _checkSnap(myRight, oRight, snapThreshold, (v) {
        final dx = v - elemW - proposedX;
        if (dx.abs() < closestDX.abs()) {
          closestDX = dx;
          guides.add(SnapGuide(value: v, isHorizontal: false, start: min(myTop, oTop), end: max(myBottom, oBottom)));
        }
      });
      // 中心 X 对齐
      _checkSnap(myCenterX, oCenterX, snapThreshold, (v) {
        final dx = v - elemW / 2 - proposedX;
        if (dx.abs() < closestDX.abs()) {
          closestDX = dx;
          guides.add(SnapGuide(value: v, isHorizontal: false, start: min(myTop, oTop), end: max(myBottom, oBottom)));
        }
      });

      // 顶边对齐
      _checkSnap(myTop, oTop, snapThreshold, (v) {
        final dy = v - proposedY;
        if (dy.abs() < closestDY.abs()) {
          closestDY = dy;
          guides.add(SnapGuide(value: v, isHorizontal: true, start: min(myLeft, oLeft), end: max(myRight, oRight)));
        }
      });
      // 底边对齐
      _checkSnap(myBottom, oBottom, snapThreshold, (v) {
        final dy = v - elemH - proposedY;
        if (dy.abs() < closestDY.abs()) {
          closestDY = dy;
          guides.add(SnapGuide(value: v, isHorizontal: true, start: min(myLeft, oLeft), end: max(myRight, oRight)));
        }
      });
      // 中心 Y 对齐
      _checkSnap(myCenterY, oCenterY, snapThreshold, (v) {
        final dy = v - elemH / 2 - proposedY;
        if (dy.abs() < closestDY.abs()) {
          closestDY = dy;
          guides.add(SnapGuide(value: v, isHorizontal: true, start: min(myLeft, oLeft), end: max(myRight, oRight)));
        }
      });
    }

    snappedX = proposedX + closestDX;
    snappedY = proposedY + closestDY;

    // 如果没有吸附，清空辅助线
    if (closestDX.abs() > snapThreshold && closestDY.abs() > snapThreshold) {
      guides.clear();
    }

    return SnapResult(x: snappedX, y: snappedY, guides: guides);
  }

  /// 检查吸附距离并回调
  static void _checkSnap(double myEdge, double targetEdge, double threshold, void Function(double snappedValue) onSnap) {
    final dist = (myEdge - targetEdge).abs();
    if (dist <= threshold) {
      onSnap(targetEdge);
    }
  }
}

/// 在 Canvas 上绘制吸附辅助线
class SnapGuidePainter extends CustomPainter {
  final List<SnapGuide> guides;
  final double viewScale; // 画布显示缩放

  SnapGuidePainter({required this.guides, required this.viewScale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4081)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      final scaledVal = guide.value * viewScale;
      final scaledStart = guide.start * viewScale;
      final scaledEnd = guide.end * viewScale;

      if (guide.isHorizontal) {
        canvas.drawLine(Offset(scaledStart, scaledVal), Offset(scaledEnd, scaledVal), paint);
      } else {
        canvas.drawLine(Offset(scaledVal, scaledStart), Offset(scaledVal, scaledEnd), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SnapGuidePainter oldDelegate) => true;
}
