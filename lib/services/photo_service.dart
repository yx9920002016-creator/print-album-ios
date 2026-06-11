import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo_model.dart';
import '../utils/date_extractor.dart';
import '../utils/photo_scorer.dart';
import 'package:uuid/uuid.dart';

/// 照片服务 - 负责从 iOS 相册读取照片
class PhotoService {
  static const _uuid = Uuid();
  bool _initialized = false;

  /// 初始化权限
  Future<bool> requestPermission() async {
    final perm = await PhotoManager.requestPermissionExtend();
    _initialized = perm.isAuth || perm.hasAccess;
    return _initialized;
  }

  /// 获取所有相册
  Future<List<AssetPathEntity>> getAlbums() async {
    if (!_initialized) await requestPermission();
    return PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );
  }

  /// 从相册加载照片列表
  Future<List<PhotoModel>> loadPhotos({
    AssetPathEntity? album,
    int pageSize = 100,
    int page = 0,
  }) async {
    if (!_initialized) {
      final ok = await requestPermission();
      if (!ok) return [];
    }

    final pathList = album ?? (await getAlbums()).first;
    final count = await pathList.assetCountAsync;
    if (count == 0) return [];

    final assets = await pathList.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    final photos = <PhotoModel>[];
    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) continue;

      final photo = PhotoModel(
        id: _uuid.v4(),
        path: file.path,
        assetId: asset.id,
        width: asset.width,
        height: asset.height,
        fileSize: await _getFileSize(file),
        createdDate: asset.createDateTime,
        modifiedDate: asset.modifiedDateTime,
        rating: _initialRating(asset),
      );
      photos.add(photo);
    }

    // 智能评分
    return PhotoScorer.scoreAll(photos);
  }

  /// 获取缩略图路径（用于快速预览）
  Future<String?> getThumbnail(String assetId, {int width = 300, int height = 300}) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;

    final data = await asset.thumbnailDataWithOption(
      ThumbnailOption(size: ThumbnailSize(width, height), quality: 80),
    );
    if (data == null) return null;

    // 写入临时文件
    final tempDir = await getTemporaryDirectory();
    final thumbPath = '${tempDir.path}/thumb_$assetId.jpg';
    await File(thumbPath).writeAsBytes(data);
    return thumbPath;
  }

  /// 获取原图文件
  Future<File?> getOriginalFile(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    return asset.file;
  }

  /// 复制照片到 App 临时目录
  Future<String?> copyToTemp(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;

    final file = await asset.file;
    if (file == null) return null;

    final tempDir = await getTemporaryDirectory();
    final destPath = '${tempDir.path}/${assetId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await file.copy(destPath);
    return destPath;
  }

  /// 获取文件大小
  Future<int> _getFileSize(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  /// 初始评分（基于基本元数据）
  double _initialRating(AssetEntity asset) {
    final megapixels = (asset.width * asset.height) / 1000000;
    if (megapixels >= 12) return 4.5;
    if (megapixels >= 8) return 4.0;
    if (megapixels >= 5) return 3.5;
    if (megapixels >= 2) return 3.0;
    return 2.5;
  }

  // ========== Web 端模拟数据 ==========

  /// 生成模拟照片数据（用于 Web/桌面端测试）
  static List<PhotoModel> generateMockPhotos({int count = 42}) {
    final rng = Random(42); // 固定种子保证可复现
    final now = DateTime.now();
    final colors = [
      Colors.red.shade300, Colors.orange.shade300, Colors.yellow.shade300,
      Colors.green.shade300, Colors.teal.shade300, Colors.blue.shade300,
      Colors.indigo.shade300, Colors.purple.shade300, Colors.pink.shade300,
      Colors.brown.shade300, Colors.cyan.shade300, Colors.lime.shade300,
      Colors.deepOrange.shade300, Colors.lightBlue.shade300,
      Colors.deepPurple.shade300, Colors.amber.shade300,
    ];
    final titles = [
      '春日野餐', '海边漫步', '落叶小径', '雪地玩耍', '生日派对',
      '公园嬉戏', '洗澡时光', '美食分享', '散步记录', '睡觉日常',
      '新玩具', '美容护理', '看医生', '朋友聚会', '搬家纪念',
      '第一次出门', '迎接仪式', '探索世界', '追蝴蝶', '晒太阳',
      '躲猫猫', '爬楼梯', '滑滑梯', '荡秋千', '玩球',
      '穿衣服', '万圣节', '圣诞节', '春节红包', '端午粽子',
      '中秋赏月', '万圣南瓜', '圣诞装饰', '新年烟花', '情人节',
      '儿童节', '七夕鹊桥', '万圣节糖果', '感恩大餐', '元旦日出',
      '跨年派对', '纪念日'
    ];

    final photos = <PhotoModel>[];
    for (var i = 0; i < count; i++) {
      // 生成 2020-2026 年之间的随机日期
      final year = 2020 + rng.nextInt(7);
      final month = 1 + rng.nextInt(12);
      final day = 1 + rng.nextInt(28);
      final createdDate = DateTime(year, month, day, rng.nextInt(24), rng.nextInt(60));

      // 随机宽高比
      final w = 2000 + rng.nextInt(2000);
      final h = 1500 + rng.nextInt(2000);

      // 随机评分
      final rating = 2.0 + rng.nextDouble() * 3.0;

      photos.add(PhotoModel(
        id: 'mock_$i',
        path: '',
        width: w,
        height: h,
        fileSize: 500000 + rng.nextInt(3000000),
        createdDate: createdDate,
        modifiedDate: createdDate,
        rating: rating.clamp(1.0, 5.0),
        mockColor: colors[i % colors.length],
        title: titles[i % titles.length],
      ));
    }

    return PhotoScorer.scoreAll(photos);
  }
}
