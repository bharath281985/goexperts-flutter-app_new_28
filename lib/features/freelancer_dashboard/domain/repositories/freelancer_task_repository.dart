import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../entities/freelancer_task.dart';

abstract class FreelancerTaskRepository {
  Future<Result<Paginated<FreelancerTask>>> getTasks(QueryParams params);
  Future<Result<FreelancerTask>> getTask(String id);
  Future<Result<bool>> updateTaskStatus(String id, String status);
  Future<Result<List<TaskComment>>> getComments(String taskId);
  Future<Result<List<TaskAttachment>>> getAttachments(String taskId);
  Future<Result<List<TaskTimeLog>>> getTimeLogs(String taskId);
  Future<Result<bool>> addComment(String taskId, String text);
  Future<Result<bool>> addAttachment(String taskId, String filePath);
  Future<Result<bool>> startTimer(String taskId);
  Future<Result<bool>> stopTimer(String taskId);
  Future<Result<bool>> logTime(
    String taskId, {
    required double hours,
    String? description,
    String? date,
  });
  Future<Result<FreelancerTask>> createTask(Map<String, dynamic> data);
}
