import 'layout_page.dart';
import 'photo_model.dart';

/// 相册项目 - 整个排版工程
class AlbumProject {
  final String id;
  String name;
  final List<LayoutPage> pages;
  int currentPageIndex;
  final DateTime createdDate;
  DateTime modifiedDate;
  List<PhotoModel> projectPhotos; // 项目关联的所有原始照片

  AlbumProject({
    required this.id,
    required this.name,
    List<LayoutPage>? pages,
    this.currentPageIndex = 0,
    DateTime? createdDate,
    DateTime? modifiedDate,
    List<PhotoModel>? projectPhotos,
  })  : pages = pages ?? [LayoutPage(id: 'page_1')],
        projectPhotos = projectPhotos ?? [],
        createdDate = createdDate ?? DateTime.now(),
        modifiedDate = modifiedDate ?? DateTime.now();

  LayoutPage get currentPage => pages[currentPageIndex];
  int get pageCount => pages.length;

  void addPage() {
    pages.add(LayoutPage(id: 'page_${pages.length + 1}'));
    currentPageIndex = pages.length - 1;
    modifiedDate = DateTime.now();
  }

  void removePage(int index) {
    if (pages.length > 1) {
      pages.removeAt(index);
      if (currentPageIndex >= pages.length) {
        currentPageIndex = pages.length - 1;
      }
      modifiedDate = DateTime.now();
    }
  }

  void goToPage(int index) {
    if (index >= 0 && index < pages.length) {
      currentPageIndex = index;
    }
  }

  void nextPage() {
    if (currentPageIndex < pages.length - 1) {
      currentPageIndex++;
    }
  }

  void previousPage() {
    if (currentPageIndex > 0) {
      currentPageIndex--;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pages': pages.map((p) => p.toJson()).toList(),
        'currentPageIndex': currentPageIndex,
        'createdDate': createdDate.toIso8601String(),
        'modifiedDate': modifiedDate.toIso8601String(),
        'projectPhotos': projectPhotos.map((p) => p.toJson()).toList(),
      };

  factory AlbumProject.fromJson(Map<String, dynamic> json) {
    return AlbumProject(
      id: json['id'] as String,
      name: json['name'] as String,
      pages: (json['pages'] as List<dynamic>?)
              ?.map((p) => LayoutPage.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [LayoutPage(id: 'page_1')],
      currentPageIndex: (json['currentPageIndex'] as num?)?.toInt() ?? 0,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : DateTime.now(),
      modifiedDate: json['modifiedDate'] != null
          ? DateTime.parse(json['modifiedDate'] as String)
          : DateTime.now(),
      projectPhotos: (json['projectPhotos'] as List<dynamic>?)
              ?.map((p) => PhotoModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
