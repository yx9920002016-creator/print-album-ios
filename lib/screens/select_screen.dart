import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/photo_scorer.dart';
import '../utils/responsive_helper.dart';
import '../models/photo_model.dart';

class SelectScreen extends StatelessWidget {
  const SelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isWeb = state.allPhotos.isNotEmpty && state.allPhotos.first.mockColor != null;

    return Scaffold(
      body: Column(
        children: [
          // 顶部渐变头部
          _buildHeader(context, state),
          // 内容区
          Expanded(
            child: state.isLoadingPhotos
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryColor),
                        SizedBox(height: context.rw(16)),
                        Text('正在加载照片...',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: context.rw(14))),
                      ],
                    ),
                  )
                : state.loadError != null
                    ? _buildErrorState(context, state)
                    : state.allPhotos.isEmpty
                        ? _buildEmptyState(context, state)
                        : _buildPhotoGrid(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    final count = state.selectedPhotos.length;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.gradientHeader,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.rw(28))),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + context.rw(12),
        left: context.rw(20),
        right: context.rw(20),
        bottom: context.rw(16),
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.rw(8)),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(context.rw(12)),
                ),
                child: Icon(Icons.photo_library_rounded, color: Colors.white, size: context.rw(22)),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Text(
                  '选择照片',
                  style: TextStyle(
                    fontSize: context.rw(22),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rw(10)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.rw(25)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryDark.withAlpha(50),
                        blurRadius: context.rw(12),
                        offset: Offset(0, context.rw(4)),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => _showCreateDialog(context, state),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryColor),
                        SizedBox(width: context.rw(6)),
                        Text(
                          '已选$count张 →',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: context.rw(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (count > 0) ...[
            SizedBox(height: context.rw(12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderChip(context, '全选', Icons.select_all_rounded, state),
                SizedBox(width: context.rw(8)),
                _buildHeaderChip(context, '清空', Icons.close_rounded, state),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderChip(BuildContext context, String label, IconData icon, AppState state) {
    return GestureDetector(
      onTap: () => label == '全选' ? state.toggleSelectAllYear() : state.clearSelection(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.rw(14), vertical: context.rw(7)),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(context.rw(16)),
          border: Border.all(color: Colors.white.withAlpha(60), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.rw(14), color: Colors.white),
            SizedBox(width: context.rw(5)),
            Text(label, style: TextStyle(color: Colors.white, fontSize: context.rw(13), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppState state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.rw(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.rw(20)),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: context.rw(48), color: Colors.red.shade300),
            ),
            SizedBox(height: context.rw(16)),
            Text(state.loadError!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
            SizedBox(height: context.rw(16)),
            ElevatedButton.icon(
              onPressed: () => state.loadPhotosFromGallery(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.rw(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.rw(24)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF0F3), Color(0xFFF5F0FF)],
                ),
                borderRadius: BorderRadius.circular(context.rw(32)),
              ),
              child: Icon(Icons.photo_library_outlined, size: context.rw(72), color: AppTheme.primaryLight),
            ),
            SizedBox(height: context.rw(20)),
            Text('还没有加载照片',
                style: TextStyle(fontSize: context.rw(20), fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            SizedBox(height: context.rw(8)),
            Text('请允许访问相册来开始制作',
                style: TextStyle(fontSize: context.rw(14), color: AppTheme.textSecondary)),
            SizedBox(height: context.rw(28)),
            ElevatedButton.icon(
              onPressed: () => state.loadPhotosFromGallery(),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('  加载相册照片  '),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: context.rw(28), vertical: context.rw(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, AppState state) {
    final years = state.sortedYears;
    final currentPhotos = state.selectedYear != null
        ? state.photosByYear[state.selectedYear] ?? []
        : state.allPhotos;

    return Column(
      children: [
        // 年份导航
        _buildYearBar(context, state, years),
        // 照片网格
        Expanded(
          child: currentPhotos.isEmpty
              ? const Center(
                  child: Text('该年份暂无照片', style: TextStyle(color: AppTheme.textSecondary)))
              : GridView.builder(
                  padding: EdgeInsets.all(context.rw(8)),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: context.rw(8),
                    mainAxisSpacing: context.rw(8),
                  ),
                  itemCount: currentPhotos.length,
                  itemBuilder: (context, index) {
                    return _buildPhotoTile(context, state, currentPhotos[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildYearBar(BuildContext context, AppState state, List<int> years) {
    if (years.isEmpty) return const SizedBox.shrink();
    return Container(
      height: context.rw(52),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withAlpha(8), blurRadius: context.rw(4), offset: Offset(0, context.rw(2))),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.rw(8)),
        itemCount: years.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = state.selectedYear == null;
            return _buildYearChip(context, isSelected, state, null, state.allPhotos.length);
          }
          final year = years[index - 1];
          final isSelected = year == state.selectedYear;
          final count = state.photosByYear[year]?.length ?? 0;
          return _buildYearChip(context, isSelected, state, year, count);
        },
      ),
    );
  }

  Widget _buildYearChip(BuildContext context, bool isSelected, AppState state, int? year, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rw(4), vertical: context.rw(8)),
      child: GestureDetector(
        onTap: () => state.selectYear(year),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rw(8)),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: AppTheme.gradientPrimary)
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(context.rw(20)),
            boxShadow: isSelected
                ? [BoxShadow(color: AppTheme.primaryColor.withAlpha(40), blurRadius: context.rw(8), offset: Offset(0, context.rw(3)))]
                : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: context.rw(4), offset: Offset(0, context.rw(1)))],
          ),
          child: Text(
            year != null ? '$year年 ($count)' : '全部 ($count)',
            style: TextStyle(
              fontSize: context.rw(13),
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(BuildContext context, AppState state, PhotoModel photo) {
    final isSelected = state.selectedPhotos.contains(photo);
    return GestureDetector(
      onTap: () => state.togglePhotoSelection(photo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.rw(14)),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withAlpha(40)
                  : Colors.black.withAlpha(10),
              blurRadius: context.rw(6),
              offset: Offset(0, context.rw(2)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.rw(14)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 照片缩略图
              photo.mockColor != null
                  ? Container(
                      color: photo.mockColor,
                      child: Center(
                        child: Text(
                          photo.title ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rw(12),
                            fontWeight: FontWeight.bold,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFF0F3),
                        child: Icon(Icons.broken_image_rounded,
                            color: AppTheme.primaryLight, size: context.rw(28)),
                      ),
                    ),

              // 选中状态遮罩
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(context.rw(14)),
                    border: Border.all(color: AppTheme.primaryColor, width: 3),
                  ),
                ),
              ),

              // 选中标记（心形）
              if (isSelected)
                Positioned(
                  top: context.rw(6), right: context.rw(6),
                  child: Container(
                    padding: EdgeInsets.all(context.rw(5)),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite_rounded, size: context.rw(16), color: Colors.white),
                  ),
                ),

              // 评分星星
              Positioned(
                bottom: context.rw(4), left: context.rw(4),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.rw(6), vertical: context.rw(2)),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(context.rw(8)),
                  ),
                  child: Text(
                    PhotoScorer.starText(photo.rating),
                    style: TextStyle(fontSize: context.rw(9), color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: '我的相册');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.rw(28))),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.rw(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示条
              Center(
                child: Container(
                  width: context.rw(40), height: context.rw(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(context.rw(2)),
                  ),
                ),
              ),
              SizedBox(height: context.rw(20)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.rw(10)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppTheme.gradientPrimary),
                      borderRadius: BorderRadius.circular(context.rw(14)),
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: context.rw(22)),
                  ),
                  SizedBox(width: context.rw(12)),
                  Text(
                    '创建排版项目',
                    style: TextStyle(fontSize: context.rw(22), fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              SizedBox(height: context.rw(8)),
              Text(
                '已选择 ${state.selectedPhotos.length} 张照片',
                style: TextStyle(fontSize: context.rw(14), color: AppTheme.textSecondary),
              ),
              SizedBox(height: context.rw(20)),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '相册名称',
                  hintText: '给相册起个可爱的名字吧~',
                  prefixIcon: Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                ),
              ),
              SizedBox(height: context.rw(24)),
              SizedBox(
                width: double.infinity,
                height: context.rw(52),
                child: ElevatedButton(
                  onPressed: () {
                    state.createProjectFromSelected(
                      controller.text.trim().isEmpty ? '我的相册' : controller.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: AppTheme.primaryColor.withAlpha(60),
                  ),
                  child: Text('✨  开始排版', style: TextStyle(fontSize: context.rw(17), fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: context.rw(8)),
            ],
          ),
        ),
      ),
    );
  }
}
