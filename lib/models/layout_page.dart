import 'photo_model.dart';

/// 边框样式
enum PhotoBorderStyle {
  none,       // 无边框
  white,      // 白边
  polaroid,   // 拍立得
  rounded,    // 大圆角
  vintage,    // 复古双线
  shadow,     // 阴影卡片
}

/// 排版元素 - 画布上的一张照片
class LayoutElement {
  final String id;
  final PhotoModel photo;
  double x;
  double y;
  double width;
  double height;
  double rotation;      // 旋转角度（度）
  double scale;         // 缩放比例
  int zIndex;
  PhotoBorderStyle borderStyle;  // 边框样式
  double borderWidth;            // 边框宽度
  int borderColor;               // 边框颜色
  double cornerRadius;           // 圆角大小

  LayoutElement({
    required this.id,
    required this.photo,
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.scale = 1.0,
    this.zIndex = 0,
    this.borderStyle = PhotoBorderStyle.white,
    this.borderWidth = 8,
    this.borderColor = 0xFFFFFFFF,
    this.cornerRadius = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'photo': photo.toJson(),
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'scale': scale,
        'zIndex': zIndex,
        'borderStyle': borderStyle.index,
        'borderWidth': borderWidth,
        'borderColor': borderColor,
        'cornerRadius': cornerRadius,
      };

  factory LayoutElement.fromJson(Map<String, dynamic> json) {
    return LayoutElement(
      id: json['id'] as String,
      photo: PhotoModel.fromJson(json['photo'] as Map<String, dynamic>),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      borderStyle: PhotoBorderStyle.values[json['borderStyle'] as int? ?? 1],
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 8,
      borderColor: (json['borderColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// 页面上的文字覆盖层
class TextOverlay {
  String id;
  String text;
  double x;
  double y;
  double fontSize;
  int color;
  String fontFamily;
  bool bold;
  bool italic;
  double scale;       // 缩放比例（1.0=原大小）
  double rotation;    // 旋转角度（度）

  TextOverlay({
    required this.id,
    required this.text,
    this.x = 100,
    this.y = 100,
    this.fontSize = 48,
    this.color = 0xFF333333,
    this.fontFamily = 'default',
    this.bold = false,
    this.italic = false,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'color': color,
        'fontFamily': fontFamily,
        'bold': bold,
        'italic': italic,
        'scale': scale,
        'rotation': rotation,
      };

  factory TextOverlay.fromJson(Map<String, dynamic> json) {
    return TextOverlay(
      id: json['id'] as String,
      text: json['text'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 48,
      color: (json['color'] as num?)?.toInt() ?? 0xFF333333,
      fontFamily: json['fontFamily'] as String? ?? 'default',
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// 页面装饰（角花、分割线等）
class PageDecoration {
  String id;
  String type;   // 'corner_tl', 'corner_tr', 'corner_bl', 'corner_br', 'divider_top', 'divider_bottom', 'sticker'
  int color;
  double size;

  PageDecoration({
    required this.id,
    required this.type,
    this.color = 0xFF6C63FF,
    this.size = 60,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'color': color,
        'size': size,
      };

  factory PageDecoration.fromJson(Map<String, dynamic> json) {
    return PageDecoration(
      id: json['id'] as String,
      type: json['type'] as String,
      color: (json['color'] as num?)?.toInt() ?? 0xFF6C63FF,
      size: (json['size'] as num?)?.toDouble() ?? 60,
    );
  }
}

/// 排版页面 - 一页画布
class LayoutPage {
  final String id;
  final List<LayoutElement> elements;
  final List<TextOverlay> textOverlays;
  final List<PageDecoration> decorations;
  int backgroundColor;   // ARGB 颜色值
  String? backgroundImagePath;
  double pageWidth;      // 画布宽度（逻辑像素）
  double pageHeight;     // 画布高度（逻辑像素）

  LayoutPage({
    required this.id,
    List<LayoutElement>? elements,
    List<TextOverlay>? textOverlays,
    List<PageDecoration>? decorations,
    this.backgroundColor = 0xFFFFFFFF,
    this.backgroundImagePath,
    this.pageWidth = 2480,   // A4 300dpi 宽度
    this.pageHeight = 3508,  // A4 300dpi 高度
  })  : elements = elements ?? [],
        textOverlays = textOverlays ?? [],
        decorations = decorations ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'elements': elements.map((e) => e.toJson()).toList(),
        'textOverlays': textOverlays.map((t) => t.toJson()).toList(),
        'decorations': decorations.map((d) => d.toJson()).toList(),
        'backgroundColor': backgroundColor,
        'backgroundImagePath': backgroundImagePath,
        'pageWidth': pageWidth,
        'pageHeight': pageHeight,
      };

  factory LayoutPage.fromJson(Map<String, dynamic> json) {
    return LayoutPage(
      id: json['id'] as String,
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => LayoutElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      textOverlays: (json['textOverlays'] as List<dynamic>?)
              ?.map((t) => TextOverlay.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      decorations: (json['decorations'] as List<dynamic>?)
              ?.map((d) => PageDecoration.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      backgroundImagePath: json['backgroundImagePath'] as String?,
      pageWidth: (json['pageWidth'] as num?)?.toDouble() ?? 2480,
      pageHeight: (json['pageHeight'] as num?)?.toDouble() ?? 3508,
    );
  }

  void addElement(LayoutElement element) {
    element.zIndex = elements.length;
    elements.add(element);
  }

  void removeElement(String elementId) {
    elements.removeWhere((e) => e.id == elementId);
  }

  void bringToFront(String elementId) {
    final maxZ = elements.isEmpty
        ? 0
        : elements.map((e) => e.zIndex).reduce((a, b) => a > b ? a : b);
    final element = elements.firstWhere((e) => e.id == elementId);
    element.zIndex = maxZ + 1;
  }
}
