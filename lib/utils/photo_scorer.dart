import '../models/photo_model.dart';

/// 智能照片评分器
/// 根据照片尺寸、文件大小、拍摄时间等维度评分
class PhotoScorer {
  /// 评分维度权重
  static const double _resolutionWeight = 0.35;
  static const double _fileSizeWeight = 0.25;
  static const double _aspectRatioWeight = 0.15;
  static const double _dateWeight = 0.15;
  static const double _varietyWeight = 0.10;

  /// 对单张照片评分 (1-5)
  static double score(PhotoModel photo) {
    double score = 0;

    // 1. 分辨率评分 (越高越好)
    final megapixels = (photo.width * photo.height) / 1000000;
    double resolutionScore;
    if (megapixels >= 12) {
      resolutionScore = 5.0;
    } else if (megapixels >= 8) {
      resolutionScore = 4.0;
    } else if (megapixels >= 5) {
      resolutionScore = 3.0;
    } else if (megapixels >= 2) {
      resolutionScore = 2.0;
    } else {
      resolutionScore = 1.0;
    }
    score += resolutionScore * _resolutionWeight;

    // 2. 文件大小评分 (越大通常质量越好)
    final mb = photo.fileSize / (1024 * 1024);
    double fileSizeScore;
    if (mb >= 10) {
      fileSizeScore = 5.0;
    } else if (mb >= 5) {
      fileSizeScore = 4.0;
    } else if (mb >= 2) {
      fileSizeScore = 3.0;
    } else if (mb >= 0.5) {
      fileSizeScore = 2.0;
    } else {
      fileSizeScore = 1.0;
    }
    score += fileSizeScore * _fileSizeWeight;

    // 3. 宽高比评分 (接近 4:3 或 3:2 最佳)
    final ratio = photo.aspectRatio;
    double aspectScore;
    if ((ratio >= 1.3 && ratio <= 1.4) || (ratio >= 1.45 && ratio <= 1.55)) {
      aspectScore = 5.0; // 4:3 或 3:2
    } else if (ratio >= 1.0 && ratio <= 2.0) {
      aspectScore = 4.0;
    } else if (ratio >= 0.75 && ratio <= 3.0) {
      aspectScore = 3.0;
    } else {
      aspectScore = 2.0;
    }
    score += aspectScore * _aspectRatioWeight;

    // 4. 日期评分 (越新越高)
    double dateScore = 3.0;
    if (photo.createdDate != null) {
      final daysSince = DateTime.now().difference(photo.createdDate!).inDays;
      if (daysSince < 30) {
        dateScore = 5.0;
      } else if (daysSince < 180) {
        dateScore = 4.5;
      } else if (daysSince < 365) {
        dateScore = 4.0;
      } else if (daysSince < 730) {
        dateScore = 3.0;
      } else {
        dateScore = 2.0;
      }
    }
    score += dateScore * _dateWeight;

    // 5. 多样性 (横版 vs 竖版，这里给横版略高分)
    final varietyScore = photo.isLandscape ? 4.0 : 3.5;
    score += varietyScore * _varietyWeight;

    return double.parse(score.toStringAsFixed(1));
  }

  /// 批量评分
  static List<PhotoModel> scoreAll(List<PhotoModel> photos) {
    return photos.map((p) {
      if (p.rating == 3.0) {
        // 只有默认评分时才重新计算
        final newRating = score(p);
        return p.copyWith(rating: newRating);
      }
      return p;
    }).toList();
  }

  /// 获取星级文本
  static String starText(double rating) {
    final stars = rating.round();
    return '⭐' * stars + '☆' * (5 - stars);
  }
}
