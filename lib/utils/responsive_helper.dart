import 'package:flutter/widgets.dart';

/// 响应式布局辅助工具
///
/// 以 iPhone 14 (390x844) 为参考设计尺寸，所有固定值按屏幕宽度等比缩放。
/// 这样 iPhone SE → iPhone 16 Pro Max → iPad Pro 12.9" 全部能完美适配。
class ResponsiveHelper {
  /// 参考设计宽度（iPhone 14 竖屏）
  static const double _refWidth = 390.0;

  /// 当前屏幕宽度相对于参考宽度的缩放比
  static double scaleW(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width / _refWidth;
  }

  /// 将参考尺寸值按屏幕宽度等比缩放
  static double rw(BuildContext context, double size) {
    return size * scaleW(context);
  }
}

/// 便捷扩展方法，直接在 BuildContext 上调用
extension ResponsiveContextX on BuildContext {
  /// 屏幕宽度缩放比
  double get scaleW => ResponsiveHelper.scaleW(this);

  /// 等比缩放尺寸
  double rw(double size) => ResponsiveHelper.rw(this, size);
}
