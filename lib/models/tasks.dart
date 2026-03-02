class Task {
  String id;           
  String nom;          
  String priority;  
  DateTime? dueDate;
  bool isCompleted = false;
   

  Task({
    required this.id,
    required this.nom,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false
  });
}