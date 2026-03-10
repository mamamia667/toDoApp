class Task {
  int id;
  String nom;
  String priority;
  DateTime? dueDate;
  bool isCompleted;

  Task({
    required this.id,
    required this.nom,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
  });

  // Convertir le JSON de Laravel en objet Task
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id:          json['id'],
      nom:         json['nom'],
      priority:    json['priority'],
      dueDate:     json['due_date'] != null
      ? DateTime.parse(json['due_date'])
      : null,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  // Convertir un objet Task en JSON pour envoyer à Laravel
  Map<String, dynamic> toJson() {
    return {
      'nom':          nom,
      'priority':     priority,
      'due_date':     dueDate?.toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}