import 'package:drift/drift.dart';
import 'package:pursenal/app/extensions/drift_models.dart';
import 'package:pursenal/core/abstracts/projects_repository.dart';
import 'package:pursenal/core/db/app_drift_database.dart';
import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';
import 'package:pursenal/utils/app_logger.dart';

class ProjectsDriftRepository implements ProjectsRepository {
  ProjectsDriftRepository(this.db);
  final AppDriftDatabase db;

  @override
  Future<int> insertProject({
    required String name,
    ProjectStatus projectStatus = ProjectStatus.pending,
    required Profile profile,
    Budget? budget,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final project = DriftProjectsCompanion.insert(
        status: projectStatus,
        name: name,
        description: Value(description),
        profile: profile.dbID,
        startDate: Value(startDate),
        endDate: Value(endDate),
        budget: Value(budget?.dbID),
      );

      final p = await db.insertProject(project);
      return p;
    } catch (e) {
      AppLogger.instance.error("Failed to insert project. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateProject({
    required int id,
    required String name,
    required Profile profile,
    ProjectStatus projectStatus = ProjectStatus.pending,
    Budget? budget,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      db.deleteFilePathByParentID(id);
      final project = DriftProjectsCompanion(
          id: Value(id),
          status: Value(projectStatus),
          name: Value(name),
          profile: Value(profile.dbID),
          description: Value(description),
          startDate: Value(startDate),
          endDate: Value(endDate),
          budget: Value(budget?.dbID),
          updateDate: Value(DateTime.now()));

      return await db.updateProject(project);
    } catch (e) {
      AppLogger.instance.error("Failed to update project. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<bool> updateProjectStatus({
    required int id,
    required String name,
    required Profile profile,
    ProjectStatus projectStatus = ProjectStatus.pending,
    Budget? budget,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final project = DriftProjectsCompanion(
          id: Value(id),
          status: Value(projectStatus),
          name: Value(name),
          profile: Value(profile.dbID),
          description: Value(description),
          startDate: Value(startDate),
          endDate: Value(endDate),
          budget: Value(budget?.dbID),
          updateDate: Value(DateTime.now()));

      return await db.updateProject(project);
    } catch (e) {
      AppLogger.instance.error("Failed to update project. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      return await db.deleteProject(id);
    } catch (e) {
      AppLogger.instance.error("Failed to delete project. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<int> deleteProject(int id, {bool deleteTransactions = false}) async {
    try {
      if (deleteTransactions) {
        await db.deleteTransactionsByProject(id);
      }
      return await db.deleteProject(id);
    } catch (e) {
      AppLogger.instance.error("Failed to delete project. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Project> getById(int id) async {
    try {
      final photoPaths =
          (await db.getFilePathByParentId(id)).map((p) => p.path).toList();
      return (await db.getProjectById(id)).toDomain(photoPaths: photoPaths);
    } catch (e) {
      AppLogger.instance.error("Failed to get project. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<List<Project>> getAllProjects(int profile) async {
    try {
      return (await db.getProjectsByProfile(profile))
          .map((p) => p.toDomain(photoPaths: []))
          .toList();
    } catch (e) {
      AppLogger.instance.error("Failed to get project. ${e.toString()}");
      rethrow;
    }
  }

  @override
  Future<Project?> getProjectByID(int id) async {
    try {
      final p = await db.getProjectByID(id);

      return p?.item1.toDomain(photoPaths: p.item2);
    } catch (e) {
      AppLogger.instance.error("Failed to get project plan. ${e.toString()}");
      rethrow;
    }
  }
}
