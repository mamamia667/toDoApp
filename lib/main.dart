import 'package:flutter/material.dart';
import 'package:to_do_app/models/tasks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ma Todo List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ListScreen(title: 'Ma Todo List'),
    );
  }
}

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.title});

  final String title;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Task> tasks = []; 
  final TextEditingController newTask = TextEditingController();
  String selectedPriority = 'moyenne';
  DateTime? selecteDate;
  bool isFormDisplayed = false;
  
  // fonction pour la modification
  final TextEditingController editTaskController = TextEditingController();
  String editPriority = 'moyenne';
  DateTime? editDate;

  void addTask(){
    if (newTask.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Le nom de la tâche est requis"),
          backgroundColor: Colors.red,
        ),
      );
      return; 
    }
    setState(() {
      tasks.add(Task(
        id: DateTime.now().toString(), 
        nom: newTask.text, 
        priority: selectedPriority, 
        dueDate: selecteDate
      ));
    });
    newTask.clear();
    selectedPriority = 'moyenne';
    selecteDate = null;
    isFormDisplayed = false;
  }
  
  void exitAddTask() {    
    setState(() {
      newTask.clear();
      selectedPriority = 'moyenne';
      selecteDate = null;
      isFormDisplayed = false;  // Cache le formulaire
    });
  }
  
  void deleteTask(String id) {
    setState(() {
      tasks.removeWhere((task) => task.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Tâche supprimée"),
        backgroundColor: Colors.green,
      ),
    );
  }
  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'Relax':
        return Colors.lightBlue;
      case 'moyenne':
        return Colors.yellow;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void modifyTask(String id, String newName, String newPriority, DateTime? newDate) {
    int index = tasks.indexWhere((task) => task.id == id);
    
    if (index != -1) {
      Task modifiedTask = Task(
        id: tasks[index].id,           
        nom: newName,
        dueDate: newDate,             
        priority: newPriority,
        isCompleted: tasks[index].isCompleted, 
      );
      
      setState(() {
        tasks[index] = modifiedTask;  
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tâche mise à jour"), 
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void toggleTaskCompletion(String id) {
    setState(() {
      int index = tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        tasks[index].isCompleted = !tasks[index].isCompleted;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Tâche mise à jour"),
        backgroundColor: Colors.lightBlue,
      ),
    );
  }
  
  void showEditDialog(Task task) {
    editTaskController.text = task.nom;
    editPriority = task.priority;
    editDate = task.dueDate;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        constraints: BoxConstraints(maxWidth: 500),
        title: Text('Modifier la tâche'), 
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: editTaskController,
            decoration: InputDecoration(
             labelText: 'Nom de la tâche',
              border: OutlineInputBorder(),
            ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,  
              runSpacing: 4,
              children: [
                //Text('Priorité: '),
                  buildPriorityChip('Relax', Colors.lightBlue),  
                  SizedBox(width: 8),
                  buildPriorityChip('moyenne', Colors.yellow),   
                  SizedBox(width: 8), 
                  buildPriorityChip('Urgent', Colors.red),  
                ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text ( editDate == null 
                  ? 'Pas de date' 
                  : 'Date: ${editDate!.day}/${editDate!.month}'),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: editDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => editDate = picked);
                      }
                    },
                    child: Text('Choisir'),
                 ),
                  
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              modifyTask(
                task.id, 
                editTaskController.text, 
                editPriority, 
                editDate
              );
              Navigator.pop(context);
            },
            child: Text('MODIFIER'),
          ),
        ],
      ),
    );
  }

  // Fonction pour construire les chips de priorité
  Widget buildPriorityChip(String label, Color color) {
    return FilterChip(
      label: Text(label),
      selected: editPriority == label,
      onSelected: (selected) {
        setState(() {editPriority = label;});
      },
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: editPriority == label ? color : Colors.black,
        fontWeight: editPriority == label ? FontWeight.bold : FontWeight.normal,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 , vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Formulaire d'ajout

          if (isFormDisplayed)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Center(
                        child: Text(
                          'Ma todo List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      Divider(height: 20),
                      
                      // Champ nom
                      TextField(
                        controller: newTask,
                        decoration: InputDecoration(
                          labelText: 'Nom de la tâche',
                          hintText: 'Ex: Apprendre Flutter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.task),
                        ),
                      ),
                      Divider(height: 20),
                      
                      // Section Priorité
                      Text(
                        'Priorité',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Divider(height: 20),
                      Row(
                        
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildPriorityChip('Relax', Colors.lightBlue),
                          buildPriorityChip('moyenne', Colors.yellow),
                          buildPriorityChip('Urgent', Colors.red),
                        ],
                      ),
                      Divider(height: 20),
                      
                      // Section Date
                      Text(
                        'Date d\'échéance',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Divider(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  selecteDate == null 
                                    ? 'Aucune date sélectionnée' 
                                    : '${selecteDate!.day}/${selecteDate!.month}/${selecteDate!.year}',
                                  style: TextStyle(
                                    color: selecteDate == null ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                DateTime today = DateTime.now();
                                DateTime todayMidnight = DateTime(today.year, today.month, today.day); 
                                DateTime? picked = await showDatePicker(
                                  
                                  context: context,
                                  initialDate:todayMidnight,
                                  firstDate: todayMidnight,
                                  lastDate: DateTime(2070),
                                );
                                if (picked != null) {
                                  setState(() => selecteDate = picked);
                                }
                              },
                              icon: Icon(Icons.calendar_today, size: 16),
                              label: Text('Choisir'),
                            ),
                            if (selecteDate != null)
                              IconButton(
                                icon: Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() => selecteDate = null),
                              ), 
                          ],
                        ),
                      ),
                      Divider(height: 20),
                      
                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: addTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'AJOUTER',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: exitAddTask,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'ANNULER',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Affichage des tâches 
          Expanded(
            child: tasks.isEmpty 
              ? Center(child: Text("Ajouter une tâche vous n'en avez aucune"))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    Task task = tasks[index];
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.horizontal,
                      
                      // Fond pour glissement à DROITE
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Terminer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Fond pour glissement à GAUCHE
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Supprimer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action après glissement
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          // marquer comme terminé
                          toggleTaskCompletion(task.id);
                          setState(() {
                          tasks.removeAt(index);
                        });
                        } else {
                          //suppression
                          deleteTask(task.id);
                        }
                      },
                      
                      // La tâche elle-même
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: task.isCompleted 
                              ? Colors.green 
                              : getPriorityColor(task.priority),
                          radius: 8,
                        ),
                        title: Text(
                          task.nom,
                          style: TextStyle(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? Colors.grey : Colors.black,
                            fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.priority,
                              style: TextStyle(
                                color: getPriorityColor(task.priority),
                                
                              ),
                            ),
                            if (task.dueDate != null)
                              Text(
                                'Date: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                                style: TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.lightBlue),
                          onPressed: () => showEditDialog(task),
                        ),
                        onTap: () => showEditDialog(task),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),     
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          
          setState(() {
            isFormDisplayed = true;  //affichage du formulaire
          });  
        },
        tooltip: 'Ajouter une tâche',
        child: const Icon(Icons.add),
      ),
    );
  }
}