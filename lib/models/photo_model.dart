import 'dart:ui';

/// 照片数据模型
class PhotoModel {
  final String id;
  final String path;          // 本地文件路径
  final String? assetId;      // 相册资源 ID（iOS PHAsset localIdentifier）
  final int width;
  final int height;
  final int fileSize;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final double rating;        // 1-5 星评分
  final String? locationName;
  final Color? mockColor;     // Web端模拟照片颜色
  final String? title;        // 照片标题（模拟用）

  const PhotoModel({
    required this.id,
    required this.path,
    this.assetId,
    required this.width,
    required this.height,
    required this.fileSize,
    this.createdDate,
    this.modifiedDate,
    this.rating = 3.0,
    this.locationName,
    this.mockColor,
    this.title,
  });

  /// 宽高比
  double get aspectRatio => height > 0 ? width / height : 1.0;

  /// 是否为横版照片
  bool get isLandscape => width > height;

  /// 年份分组
  int get year => createdDate?.year ?? modifiedDate?.year ?? DateTime.now().year;

  /// 月份分组
  int get month => createdDate?.month ?? modifiedDate?.month ?? DateTime.now().month;

  /// 从 JSON 创建
  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      path: json['path'] as String,
      assetId: json['assetId'] as String?,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      fileSize: (json['fileSize'] as num).toInt(),
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
      modifiedDate: json['modifiedDate'] != null
          ? DateTime.parse(json['modifiedDate'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 3.0,
      locationName: json['locationName'] as String?,
      title: json['title'] as String?,
    );
  }

  /// 转为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'assetId': assetId,
        'width': width,
        'height': height,
        'fileSize': fileSize,
        'createdDate': createdDate?.toIso8601String(),
        'modifiedDate': modifiedDate?.toIso8601String(),
        'rating': rating,
        'locationName': locationName,
        'title': title,
      };

  PhotoModel copyWith({
    String? id,
    String? path,
    String? assetId,
    int? width,
    int? height,
    int? fileSize,
    DateTime? createdDate,
    DateTime? modifiedDate,
    double? rating,
    String? locationName,
    Color? mockColor,
    String? title,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      path: path ?? this.path,
      assetId: assetId ?? this.assetId,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      rating: rating ?? this.rating,
      locationName: locationName ?? this.locationName,
      mockColor: mockColor ?? this.mockColor,
      title: title ?? this.title,
    );
  }
}
