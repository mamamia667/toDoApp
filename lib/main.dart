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
      debugShowCheckedModeBanner: false,
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
  String searchQuery = '';
  String selectedPriority = 'moyenne';
  DateTime? selecteDate;
  bool isFormDisplayed = false;

  // Pour la modification
  final TextEditingController editTaskController = TextEditingController();
  String editPriority = 'moyenne';
  DateTime? editDate;

  void addTask() {
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
        priority: editPriority,
        dueDate: selecteDate,
      ));
    });
    newTask.clear();
    editPriority = 'moyenne';
    selecteDate = null;
    isFormDisplayed = false;
  }

  void exitAddTask() {
    setState(() {
      newTask.clear();
      selectedPriority = 'moyenne';
      selecteDate = null;
      isFormDisplayed = false;
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

  Color getPriorityColor(String priority, bool isCompleted) {
    if (isCompleted) {
      return Colors.grey;
    }
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

  void showSearchBar(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = searchController.text;
              });
              Navigator.pop(context);
            },
            child: Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Trier par'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Nom (A à Z)'),
                leading: Icon(Icons.sort_by_alpha),
                onTap: () {
                  setState(() {
                    tasks.sort((a, b) =>
                        a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Nom (Z à A)'),
                leading: Transform.flip(
                  flipX: true,
                  child: const Icon(Icons.sort_by_alpha),
                ),
                onTap: () {
                  setState(() {
                    tasks.sort((a, b) =>
                        b.nom.toLowerCase().compareTo(a.nom.toLowerCase()));
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Task> searchTasks() {
    if (searchQuery.isEmpty) {
      return tasks;
    } else {
      return tasks
          .where((task) =>
              task.nom.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  void modifyTask(String id, String newName, String newPriority,
      DateTime? newDate) {
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
        content: Text(tasks.firstWhere((task) => task.id == id).isCompleted
            ? "Tâche terminée"
            : "Tâche réactivée"),
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
                Text(editDate == null
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
                editDate,
              );
              Navigator.pop(context);
            },
            child: Text('MODIFIER'),
          ),
        ],
      ),
    );
  }

  Widget buildPriorityChip(String label, Color color) {
    return FilterChip(
      label: Text(label),
      selected: editPriority == label,
      onSelected: (selected) {
        setState(() {
          editPriority = label;
        });
      },
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: editPriority == label ? color : Colors.black,
        fontWeight:
            editPriority == label ? FontWeight.bold : FontWeight.normal,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      Text(
                        'Priorité',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
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
                      Text(
                        'Date d\'échéance',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  selecteDate == null
                                      ? 'Aucune date sélectionnée'
                                      : '${selecteDate!.day}/${selecteDate!.month}/${selecteDate!.year}',
                                  style: TextStyle(
                                    color: selecteDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                DateTime today = DateTime.now();
                                DateTime todayMidnight = DateTime(
                                    today.year, today.month, today.day);
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: todayMidnight,
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
                                onPressed: () =>
                                    setState(() => selecteDate = null),
                              ),
                          ],
                        ),
                      ),
                      Divider(height: 20),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.search_rounded, color: Colors.lightBlue),
                onPressed: () => showSearchBar(context),
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, color: Colors.lightBlue),
                onPressed: () => showSortOptions(context),
              ),
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
            ],
          ),
          Expanded(
            child: searchTasks().isEmpty
                ? Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? "Ajouter une tâche vous n'en avez aucune"
                          : "Aucun résultat pour '$searchQuery'",
                    ),
                  )
                : ListView.builder(
                    itemCount: searchTasks().length,
                    itemBuilder: (context, index) {
                      Task task = searchTasks()[index];
                      return Dismissible(
                        key: Key(task.id),
                        // Désactiver le glissement startToEnd pour les tâches terminées
                        direction: task.isCompleted
                            ? DismissDirection.endToStart
                            : DismissDirection.horizontal,
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
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            toggleTaskCompletion(task.id);
                            return false;
                          } else {
                            return true;
                          }
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            deleteTask(task.id);
                          }
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: getPriorityColor(
                                task.priority, task.isCompleted),
                            radius: 8,
                          ),
                          title: Text(
                            task.nom,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.none
                                  : null,
                              color: task.isCompleted
                                  ? Colors.grey
                                  : Colors.black,
                              fontWeight: task.isCompleted
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.isCompleted ? 'terminée' : task.priority,
                                style: TextStyle(
                                  color: getPriorityColor(
                                      task.priority, task.isCompleted),
                                ),
                              ),
                              if (task.dueDate != null && !task.isCompleted)
                                Text(
                                  'Date: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                                  style: TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          // Désactiver l'édition si la tâche est terminée
                          trailing: task.isCompleted
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.edit, color: Colors.lightBlue),
                                  onPressed: () => showEditDialog(task),
                                ),
                          onTap: task.isCompleted
                              ? null
                              : () => showEditDialog(task),
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
            isFormDisplayed = true;
          });
        },
        tooltip: 'Ajouter une tâche',
        child: const Icon(Icons.add),
      ),
    );
  }
}