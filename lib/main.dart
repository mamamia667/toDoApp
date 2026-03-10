import 'dart:async';
import 'package:flutter/material.dart';
import 'package:to_do_app/models/tasks.dart';
import 'services/api.dart';

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
  State<ListScreen> createState() => ListScreenState();
}


class TimerState {
  Timer? timer;
  int remainingSeconds;
  bool isPaused = false;

  TimerState(this.remainingSeconds);

  void dispose() {
    timer?.cancel();
  }
}

class ListScreenState extends State<ListScreen> {
  //Sauvegarde à modifier
  List<Task> tasks = [];
  final ApiService apiService = ApiService();
  final TextEditingController newTask = TextEditingController();
  String searchQuery = '';
  String selectedPriority = 'moyenne';
  DateTime? selecteDate;
  bool isFormDisplayed = false;


  //iniatialisation
  @override
  void initState() {
      super.initState();
      loadTasks();
  }
  //récupère les tâches
  Future<void> loadTasks() async {
      try {
          final tasks = await apiService.getTasks();
          setState(() {
              this.tasks = tasks;
          });
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
              ),
          );
      }
  }


  
  // Pour la modification
  final TextEditingController editTaskController = TextEditingController();
  String editPriority = 'moyenne';
  DateTime? editDate;

  
  final Map<String, TimerState> timerControllers = {};

  @override
  void dispose() {
    for (var state in timerControllers.values) {
      state.dispose();
    }
    super.dispose();
  }
    //Ajouter une tâche avec API 
  Future<void> addTask() async {
    if (newTask.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Le nom de la tâche est requis"),
                backgroundColor: Colors.red,
            ),
        );
        return;
    }

    try {
        final task = Task(
            id: 0,
            nom: newTask.text,
            priority: editPriority,
            dueDate: selecteDate,
        );

        await apiService.createTask(task);
        await loadTasks();

        newTask.clear();
        editPriority = 'moyenne';
        selecteDate = null;
        setState(() => isFormDisplayed = false);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Tâche ajoutée !"),
                backgroundColor: Colors.green,
            ),
        );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
            ),
        );
    }
}

  //fermer la tâches 
  void exitAddTask() {
    setState(() {
      newTask.clear();
      selectedPriority = 'moyenne';
      selecteDate = null;
      isFormDisplayed = false;
    });
  }
    
  //Delete avec api
  Future<void> deleteTask(String id) async {
    stopAndRemoveTimer(id);
    
    try {
        await apiService.deleteTask(int.parse(id));
        await loadTasks();

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Tâche supprimée"),
                backgroundColor: Colors.green,
            ),
        );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
            ),
        );
    }
}
  //obtenir la couleur des priorités
  Color getPriorityColor(String priority, bool isCompleted) {
    if (isCompleted) return Colors.grey;
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
  
  //afficher la barre de recherche 
  void showSearchBar(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }
  
  //affiche les tâches triées
  void showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Trier par'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Nom (A à Z)'),
                leading: const Icon(Icons.sort_by_alpha),
                onTap: () {
                  setState(() {
                    tasks.sort((a, b) =>
                        a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Nom (Z à A)'),
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
  
  //Affiche les tâches 
  List<Task> searchTasks() {
    if (searchQuery.isEmpty) return tasks;
    return tasks
        .where((task) =>
            task.nom.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }
  
  // modifier une tache avec API 
  Future<void> modifyTask(String id, String newName, String newPriority,
    DateTime? newDate) async {
    
    try {
        final task = Task(
            id: int.parse(id),
            nom: newName,
            priority: newPriority,
            dueDate: newDate,
            isCompleted: tasks.firstWhere((t) => t.id == int.parse(id)).isCompleted,
        );

        await apiService.updateTask(task);
        await loadTasks();

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Tâche mise à jour"),
                backgroundColor: Colors.green,
            ),
        );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
            ),
        );
    }
}

Future<void> toggleTaskCompletion(String id) async {
    stopAndRemoveTimer(id);
    
    try {
        final task = tasks.firstWhere((t) => t.id == int.parse(id));
        
        final updatedTask = Task(
            id: task.id,
            nom: task.nom,
            priority: task.priority,
            dueDate: task.dueDate,
            isCompleted: !task.isCompleted,
        );

        await apiService.updateTask(updatedTask);
        await loadTasks();

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    updatedTask.isCompleted ? "Tâche terminée" : "Tâche réactivée"
                ),
                backgroundColor: Colors.lightBlue,
            ),
        );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
            ),
        );
    }
}
 
 //Affichage de la card de la modification 
  void showEditDialog(Task task) {
    editTaskController.text = task.nom;
    editPriority = task.priority;
    editDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: 500),
        title: const Text('Modifier la tâche'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editTaskController,
              decoration: const InputDecoration(
                labelText: 'Nom de la tâche',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                buildPriorityChip('Relax', Colors.lightBlue),
                const SizedBox(width: 8),
                buildPriorityChip('moyenne', Colors.yellow),
                const SizedBox(width: 8),
                buildPriorityChip('Urgent', Colors.red),
              ],
            ),
            const SizedBox(height: 10),
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
                  child: const Text('Choisir'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              modifyTask(
                task.id.toString(),
                editTaskController.text,
                editPriority,
                editDate,
              );
              Navigator.pop(context);
            },
            child: const Text('MODIFIER'),
          ),
        ],
      ),
    );
  }
  
  //construction des chpis de priorité
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  // Annuler le timer et le retirer 
  void stopAndRemoveTimer(String taskId) {
    final state = timerControllers[taskId];
    if (state != null) {
      state.dispose();
      timerControllers.remove(taskId);
    }
  }
  
  //formattage temps
  String formatDuration(int totalSeconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(totalSeconds ~/ 3600);
    String minutes = twoDigits((totalSeconds % 3600) ~/ 60);
    String seconds = twoDigits(totalSeconds % 60);
    return "$hours:$minutes:$seconds";
  }
  
  //affichage temps
  void showTimerDialog(Task task) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Définir le minuteur pour la tâche : "${task.nom}"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Durée : ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildTimePickerColumn(
                      label: 'Heures',
                      value: hours,
                      onIncrement: () => setStateDialog(() => hours++),
                      onDecrement: () => setStateDialog(() {
                        if (hours > 0) hours--;
                      }),
                    ),
                    buildTimePickerColumn(
                      label: 'Minutes',
                      value: minutes,
                      onIncrement: () => setStateDialog(
                          () => minutes = (minutes + 1) % 60),
                      onDecrement: () => setStateDialog(() {
                        if (minutes > 0) minutes--;
                      }),
                    ),
                    buildTimePickerColumn(
                      label: 'Secondes',
                      value: seconds,
                      onIncrement: () => setStateDialog(
                          () => seconds = (seconds + 1) % 60),
                      onDecrement: () => setStateDialog(() {
                        if (seconds > 0) seconds--;
                      }),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ANNULER'),
              ),
              ElevatedButton(
                onPressed: () {
                  int totalSeconds = hours * 3600 + minutes * 60 + seconds;
                  if (totalSeconds > 0) {
                    Navigator.pop(context);
                    startTimer(task.id.toString(), totalSeconds);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez définir une durée'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('DÉMARRER'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  //sélectionneur de temps 
  Widget buildTimePickerColumn({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: onDecrement,
            ),
            Text(value.toString()),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }

  //  demarrage du timer()
  void startTimer(String taskId, int seconds) {
    final state = TimerState(seconds);
    state.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        state.remainingSeconds--;
        if (state.remainingSeconds <= 0) {
          timer.cancel();
          showTimerCompletionDialog(taskId);
        }
      });
    });
    timerControllers[taskId] = state;
    setState(() {});
  }

  // pause() /et resume() timer
  void pauseOrResumeTimer(String taskId) {
    final state = timerControllers[taskId];
    if (state == null) return;
    if (state.isPaused) {
      // Reprendre
      state.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          state.remainingSeconds--;
          if (state.remainingSeconds <= 0) {
            timer.cancel();
            showTimerCompletionDialog(taskId);
          }
        });
      });
      state.isPaused = false;
    } else {
      // Pause
      state.timer?.cancel();
      state.isPaused = true;
    }
    setState(() {});
  }
  
  //annulation timer
  void cancelTimer(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le minuteur'),
        content: const Text('Voulez-vous vraiment annuler ce minuteur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NON'),
          ),
          ElevatedButton(
            onPressed: () {
              stopAndRemoveTimer(taskId);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('OUI'),
          ),
        ],
      ),
    );
  }

  //afficher le timer terminé
  void showTimerCompletionDialog(String taskId) {
    stopAndRemoveTimer(taskId);
    final task = tasks.firstWhere((t) => t.id.toString() == taskId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Minuteur terminé !'),
        content: Text('Le minuteur pour "${task.nom}" est terminé. Que souhaitez-vous faire ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('IGNORER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showTimerDialog(task);
            },
            child: const Text('NOUVEAU TIMER'),
          ),
          ElevatedButton(
            onPressed: () {
              toggleTaskCompletion(taskId);
              Navigator.pop(context);
            },
            child: const Text('TERMINER'),
          ),
        ],
      ),
    );
  }

  //Affichage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (isFormDisplayed) _buildAddTaskForm(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.lightBlue),
                onPressed: () => showSearchBar(context),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, color: Colors.lightBlue),
                onPressed: () => showSortOptions(context),
              ),
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
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
                      final task = searchTasks()[index];
                      final hasTimer =  timerControllers.containsKey(task.id.toString());
                      final state = timerControllers[task.id.toString()];

                      return Dismissible(
                        key:Key(task.id.toString()),
                        direction: task.isCompleted
                            ? DismissDirection.endToStart
                            : DismissDirection.horizontal,
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Row(
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Row(
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
                            toggleTaskCompletion(task.id.toString());
                            return false;
                          }
                          return true;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            deleteTask(task.id.toString());
                          }
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                getPriorityColor(task.priority, task.isCompleted),
                            radius: 8,
                          ),
                          title: Text(
                            task.nom,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.none
                                  : null,
                              color: task.isCompleted ? Colors.grey : Colors.black,
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
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: task.isCompleted
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasTimer && state != null)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          
                                          color: state.isPaused
                                              ? Colors.grey
                                              : Colors.orange,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () => pauseOrResumeTimer(task.id.toString()),
                                              child: Icon(
                                                state.isPaused
                                                    ? Icons.play_arrow
                                                    : Icons.pause,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            
                                            Text(
                                              formatDuration(state.remainingSeconds),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => cancelTimer(task.id.toString()),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (!hasTimer)
                                      IconButton(
                                        icon: const Icon(Icons.timer,
                                            color: Colors.lightBlue),
                                        onPressed: () => showTimerDialog(task),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.lightBlue),
                                      onPressed: () => showEditDialog(task),
                                    ),
                                  ],
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

  Widget _buildAddTaskForm() {
    return Padding(
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
              const Center(
                child: Text(
                  'Ma todo List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const Divider(height: 20),
              TextField(
                controller: newTask,
                decoration: const InputDecoration(
                  labelText: 'Nom de la tâche',
                  hintText: 'Ex: Apprendre Flutter',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  prefixIcon: Icon(Icons.task),
                ),
              ),
              const Divider(height: 20),
              const Text(
                'Priorité',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildPriorityChip('Relax', Colors.lightBlue),
                  buildPriorityChip('moyenne', Colors.yellow),
                  buildPriorityChip('Urgent', Colors.red),
                ],
              ),
              const Divider(height: 20),
              const Text(
                'Date d\'échéance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Divider(height: 20),
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
                            color: selecteDate == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final today = DateTime.now();
                        final todayMidnight = DateTime(today.year, today.month, today.day);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: todayMidnight,
                          firstDate: todayMidnight,
                          lastDate: DateTime(2070),
                        );
                        if (picked != null) {
                          setState(() => selecteDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Choisir'),
                    ),
                    if (selecteDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => selecteDate = null),
                      ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'AJOUTER',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: exitAddTask,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
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
    );
  }
}