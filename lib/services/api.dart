import 'package:dio/dio.dart';
import '../models/tasks.dart';

class ApiService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000/api', 
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  //  Récupérer toutes les tâches
  Future<List<Task>> getTasks() async {
    try {
      final response = await dio.get('/tasks');
      final List data = response.data['data'];
      return data.map((e) => Task.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur serveur');
    }
  }

  //  Ajouter une tâche
  Future<Task> createTask(Task task) async {
    try {
      final response = await dio.post('/tasks', data: task.toJson());
      return Task.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur serveur');
    }
  }

  // Modifier une tâche
  Future<Task> updateTask(Task task) async {
    try {
      final response = await dio.put('/tasks/${task.id}', data: task.toJson());
      return Task.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur serveur');
    }
  }

  // Supprimer une tâche
  Future<void> deleteTask(int id) async {
    try {
      await dio.delete('/tasks/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur serveur');
    }
  }
}