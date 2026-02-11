import 'package:pursenal/core/enums/project_status.dart';
import 'package:pursenal/core/models/domain/budget.dart';
import 'package:pursenal/core/models/domain/profile.dart';
import 'package:pursenal/core/models/domain/project.dart';

abstract class ProjectsRepository {
  Future<int> insertProject({
    required String name,
    ProjectStatus projectStatus = ProjectStatus.pending,
    required Profile profile,
    Budget? budget,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> updateProject({
    required int id,
    required String name,
    required Profile profile,
    ProjectStatus projectStatus = ProjectStatus.pending,
    Budget? budget,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> updateProjectStatus({
    required int id,
    required String name,
    required Profile profile,
    ProjectStatus projectStatus = ProjectStatus.pending,
    Budget? budget,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<int> delete(int id);
  Future<int> deleteProject(int id, {bool deleteTransactions = false});
  Future<Project> getById(int id);
  Future<List<Project>> getAllProjects(int profile);
  Future<Project?> getProjectByID(int id);
}
