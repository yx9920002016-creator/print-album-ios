import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album_project.dart';
import 'package:uuid/uuid.dart';

/// 项目服务 - 保存/加载排版项目
class ProjectService {
  static const _uuid = Uuid();
  static const _projectsKey = 'album_projects';
  static const _currentProjectKey = 'current_project_id';

  /// 创建新项目
  AlbumProject createProject(String name) {
    return AlbumProject(
      id: _uuid.v4(),
      name: name,
    );
  }

  /// 保存所有项目
  Future<void> saveProjects(List<AlbumProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = projects.map((p) => p.toJson()).toList();
    await prefs.setString(_projectsKey, jsonEncode(jsonList));
  }

  /// 加载所有项目
  Future<List<AlbumProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_projectsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final jsonList = jsonDecode(jsonStr) as List<dynamic>;
      return jsonList
          .map((e) => AlbumProject.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存单个项目
  Future<void> saveProject(AlbumProject project) async {
    final projects = await loadProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.add(project);
    }
    await saveProjects(projects);
  }

  /// 删除项目
  Future<void> deleteProject(String projectId) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
  }

  /// 保存当前打开的项目 ID
  Future<void> setCurrentProjectId(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProjectKey, projectId);
  }

  /// 获取当前打开的项目 ID
  Future<String?> getCurrentProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentProjectKey);
  }
}
