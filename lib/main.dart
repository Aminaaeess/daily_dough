import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ============================================================
// DAILY DOUGH
// A simple iOS-style daily task planner.
// ============================================================


// ============================================================
// COLORS
// ============================================================

class AppColors {
  static const yellow = Color(0xFFFFD84D);
  static const yellowLight = Color(0xFFFFF4BF);
  static const background = Color(0xFFFFFCF3);

  static const text = Color(0xFF171717);
  static const secondary = Color(0xFF8A8A8A);
  static const white = Color(0xFFFFFFFF);

  static const gray = Color(0xFFF3F3F3);
  static const grayDark = Color(0xFFE4E4E4);

  static const red = Color(0xFFFF5C5C);
}


// ============================================================
// TASK MODEL
// ============================================================

class Task {
  final String id;
  String title;
  bool completed;
  DateTime date;
  TimeOfDay? time;
  String category;
  String note;

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.completed = false,
    this.time,
    this.category = 'Personal',
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'date': date.toIso8601String(),
      'hour': time?.hour,
      'minute': time?.minute,
      'category': category,
      'note': note,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? taskTime;

    if (json['hour'] != null && json['minute'] != null) {
      taskTime = TimeOfDay(
        hour: json['hour'],
        minute: json['minute'],
      );
    }

    return Task(
      id: json['id'],
      title: json['title'],
      completed: json['completed'] ?? false,
      date: DateTime.parse(json['date']),
      time: taskTime,
      category: json['category'] ?? 'Personal',
      note: json['note'] ?? '',
    );
  }
}


// ============================================================
// APP
// ============================================================

void main() {
  runApp(const DailyDoughApp());
}


class DailyDoughApp extends StatelessWidget {
  const DailyDoughApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Dough',

      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.yellow,

        scaffoldBackgroundColor: AppColors.background,

        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: AppColors.text,
          ),
        ),
      ),

      home: MainNavigation(),
    );
  }
}


// ============================================================
// MAIN NAVIGATION
// ============================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}


class _MainNavigationState extends State<MainNavigation> {

  int selectedIndex = 0;

  final List<Widget> pages = const [
    TodayPage(),
    CalendarPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: AppColors.background,

      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.white.withOpacity(0.96),

        activeColor: AppColors.text,
        inactiveColor: AppColors.secondary,

        border: const Border(
          top: BorderSide(
            color: AppColors.grayDark,
            width: 0.5,
          ),
        ),

        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.checkmark_circle),
            label: 'Today',
          ),

          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: 'Calendar',
          ),

          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear),
            label: 'Settings',
          ),
        ],
      ),

      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return pages[index];
          },
        );
      },
    );
  }
}


// ============================================================
// TODAY PAGE
// ============================================================

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}


class _TodayPageState extends State<TodayPage> {

  final List<Task> tasks = [];

  DateTime selectedDate = DateTime.now();

  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    loadTasks();
  }


  // ----------------------------------------------------------
  // STORAGE
  // ----------------------------------------------------------

  Future<void> loadTasks() async {

    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('daily_dough_tasks');

    if (saved != null) {
      tasks.clear();

      for (final item in saved) {
        tasks.add(
          Task.fromJson(
            jsonDecode(item),
          ),
        );
      }
    }

    // Demo tasks only on first launch.
    if (tasks.isEmpty) {
      final today = DateTime.now();

      tasks.addAll([
        Task(
          id: '1',
          title: 'Finish UI homework',
          completed: false,
          date: today,
          category: 'Study',
        ),
        Task(
          id: '2',
          title: 'Take a shower',
          completed: false,
          date: today,
          category: 'Personal',
          time: const TimeOfDay(hour: 18, minute: 30),
        ),
        Task(
          id: '3',
          title: 'Go to work',
          completed: true,
          date: today,
          category: 'Work',
        ),
      ]);

      await saveTasks();
    }

    setState(() {
      isLoading = false;
    });
  }


  Future<void> saveTasks() async {

    final prefs = await SharedPreferences.getInstance();

    final data = tasks
        .map(
          (task) => jsonEncode(task.toJson()),
        )
        .toList();

    await prefs.setStringList(
      'daily_dough_tasks',
      data,
    );
  }


  // ----------------------------------------------------------
  // DATE
  // ----------------------------------------------------------

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }


  List<Task> get todayTasks {
    return tasks
        .where(
          (task) => sameDay(
            task.date,
            selectedDate,
          ),
        )
        .toList();
  }


  // ----------------------------------------------------------
  // TASK ACTIONS
  // ----------------------------------------------------------

  Future<void> toggleTask(Task task) async {

    setState(() {
      task.completed = !task.completed;
    });

    await saveTasks();
  }


  Future<void> deleteTask(Task task) async {

    setState(() {
      tasks.removeWhere(
        (item) => item.id == task.id,
      );
    });

    await saveTasks();
  }


  Future<void> addTask() async {

    final result = await showCupertinoModalPopup<TaskFormResult>(
      context: context,
      builder: (context) {
        return TaskSheet(
          initialDate: selectedDate,
        );
      },
    );

    if (result == null) return;

    final newTask = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: result.title,
      date: result.date,
      time: result.time,
      category: result.category,
      note: result.note,
    );

    setState(() {
      tasks.add(newTask);
    });

    await saveTasks();
  }


  Future<void> editTask(Task task) async {

    final result = await showCupertinoModalPopup<TaskFormResult>(
      context: context,
      builder: (context) {
        return TaskSheet(
          initialDate: task.date,
          initialTask: task,
        );
      },
    );

    if (result == null) return;

    setState(() {

      task.title = result.title;
      task.date = result.date;
      task.time = result.time;
      task.category = result.category;
      task.note = result.note;

    });

    await saveTasks();
  }


  // ----------------------------------------------------------
  // DATE NAVIGATION
  // ----------------------------------------------------------

  void previousDay() {

    setState(() {
      selectedDate = selectedDate.subtract(
        const Duration(days: 1),
      );
    });
  }


  void nextDay() {

    setState(() {
      selectedDate = selectedDate.add(
        const Duration(days: 1),
      );
    });
  }


  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    final dayTasks = todayTasks;

    final completed = dayTasks
        .where(
          (task) => task.completed,
        )
        .length;

    final total = dayTasks.length;

    final progress = total == 0
        ? 0.0
        : completed / total;


    return CupertinoPageScaffold(

      backgroundColor: AppColors.background,

      child: SafeArea(

        child: Stack(

          children: [

            CustomScrollView(

              physics: const BouncingScrollPhysics(),

              slivers: [

                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(
                      24,
                      18,
                      24,
                      0,
                    ),

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(

                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [

                            Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                const Text(
                                  'Good morning, Amina',
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  formatLongDate(
                                    selectedDate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color:
                                        AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),

                            GestureDetector(

                              onTap: () {
                                setState(() {
                                  selectedDate =
                                      DateTime.now();
                                });
                              },

                              child: Container(

                                width: 44,
                                height: 44,

                                decoration:
                                    const BoxDecoration(
                                  color:
                                      AppColors.yellow,
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  CupertinoIcons
                                      .calendar_today,
                                  size: 20,
                                  color:
                                      AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // ------------------------------------------------
                        // PROGRESS
                        // ------------------------------------------------

                        Container(

                          padding:
                              const EdgeInsets.all(18),

                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),

                          child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Row(

                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,

                                children: [

                                  const Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),

                                  Text(
                                    '$completed of $total',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color:
                                          AppColors.secondary,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 13),

                              ClipRRect(

                                borderRadius:
                                    BorderRadius.circular(10),

                                child: Container(

                                  height: 9,

                                  color: AppColors.gray,

                                  child: FractionallySizedBox(

                                    alignment:
                                        Alignment.centerLeft,

                                    widthFactor: progress,

                                    child: AnimatedContainer(

                                      duration:
                                          const Duration(
                                        milliseconds: 300,
                                      ),

                                      decoration:
                                          BoxDecoration(
                                        color:
                                            AppColors.yellow,
                                        borderRadius:
                                            BorderRadius
                                                .circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ------------------------------------------------
                        // DATE SELECTOR
                        // ------------------------------------------------

                        DateSelector(
                          selectedDate: selectedDate,
                          onDateChanged: (date) {

                            setState(() {
                              selectedDate = date;
                            });

                          },
                        ),

                        const SizedBox(height: 28),

                        Row(

                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [

                            const Text(
                              'Tasks',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            if (total > 0)
                              Text(
                                '$total ${total == 1 ? 'task' : 'tasks'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color:
                                      AppColors.secondary,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ------------------------------------------------
                // TASKS
                // ------------------------------------------------

                if (dayTasks.isEmpty)

                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyTasks(),
                  )

                else

                  SliverPadding(

                    padding:
                        const EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      120,
                    ),

                    sliver: SliverList(

                      delegate:
                          SliverChildBuilderDelegate(

                        (context, index) {

                          final task =
                              dayTasks[index];

                          return Padding(

                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),

                            child: TaskTile(
                              task: task,

                              onToggle: () =>
                                  toggleTask(task),

                              onEdit: () =>
                                  editTask(task),

                              onDelete: () =>
                                  deleteTask(task),
                            ),
                          );
                        },

                        childCount: dayTasks.length,
                      ),
                    ),
                  ),
              ],
            ),

            // ------------------------------------------------
            // FLOATING ADD BUTTON
            // ------------------------------------------------

            Positioned(

              right: 24,
              bottom: 20,

              child: GestureDetector(

                onTap: addTask,

                child: Container(

                  width: 60,
                  height: 60,

                  decoration: BoxDecoration(

                    color: AppColors.yellow,

                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.yellow.withOpacity(
                          0.35,
                        ),
                        blurRadius: 20,
                        offset:
                            const Offset(0, 7),
                      ),
                    ],
                  ),

                  child: const Icon(
                    CupertinoIcons.add,
                    size: 27,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// DATE SELECTOR
// ============================================================

class DateSelector extends StatelessWidget {

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });


  @override
  Widget build(BuildContext context) {

    final dates = List.generate(
      7,
      (index) => DateTime.now().add(
        Duration(days: index - 3),
      ),
    );


    return SizedBox(

      height: 74,

      child: ListView.separated(

        scrollDirection: Axis.horizontal,

        physics:
            const BouncingScrollPhysics(),

        itemCount: dates.length,

        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 8),

        itemBuilder: (context, index) {

          final date = dates[index];

          final selected =
              sameDate(
            date,
            selectedDate,
          );

          return GestureDetector(

            onTap: () =>
                onDateChanged(date),

            child: AnimatedContainer(

              duration:
                  const Duration(
                milliseconds: 200,
              ),

              width: 54,

              decoration: BoxDecoration(

                color: selected
                    ? AppColors.yellow
                    : AppColors.white,

                borderRadius:
                    BorderRadius.circular(17),
              ),

              child: Column(

                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  Text(
                    weekdayShort(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color: selected
                          ? AppColors.text
                          : AppColors.secondary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


// ============================================================
// TASK TILE
// ============================================================

class TaskTile extends StatelessWidget {

  final Task task;

  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;


  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });


  @override
  Widget build(BuildContext context) {

    return Dismissible(

      key: ValueKey(task.id),

      direction:
          DismissDirection.endToStart,

      background: Container(

        alignment:
            Alignment.centerRight,

        padding:
            const EdgeInsets.only(
          right: 22,
        ),

        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius:
              BorderRadius.circular(18),
        ),

        child: const Icon(
          CupertinoIcons.delete,
          color: AppColors.white,
        ),
      ),

      onDismissed: (_) =>
          onDelete(),

      child: GestureDetector(

        onTap: onToggle,

        onLongPress: onEdit,

        child: AnimatedContainer(

          duration:
              const Duration(
            milliseconds: 220,
          ),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),

          decoration: BoxDecoration(

            color: AppColors.white,

            borderRadius:
                BorderRadius.circular(18),
          ),

          child: Row(

            children: [

              AnimatedContainer(

                duration:
                    const Duration(
                  milliseconds: 200,
                ),

                width: 25,
                height: 25,

                decoration: BoxDecoration(

                  shape: BoxShape.circle,

                  color: task.completed
                      ? AppColors.yellow
                      : AppColors.white,

                  border: Border.all(
                    color: task.completed
                        ? AppColors.yellow
                        : AppColors.grayDark,
                    width: 1.7,
                  ),
                ),

                child: task.completed

                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 15,
                        color:
                            AppColors.text,
                      )

                    : null,
              ),

              const SizedBox(width: 14),

              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      task.title,

                      style: TextStyle(

                        fontSize: 16,

                        fontWeight:
                            FontWeight.w500,

                        color: task.completed
                            ? AppColors.secondary
                            : AppColors.text,

                        decoration:
                            task.completed
                                ? TextDecoration
                                    .lineThrough
                                : TextDecoration.none,
                      ),
                    ),

                    if (task.time != null ||
                        task.category.isNotEmpty)

                      const SizedBox(height: 6),

                    Row(

                      children: [

                        if (task.time != null) ...[

                          const Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color:
                                AppColors.secondary,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            formatTime(
                              task.time!,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.secondary,
                            ),
                          ),
                        ],

                        if (task.time != null &&
                            task.category.isNotEmpty)

                          const SizedBox(width: 10),

                        if (task.category.isNotEmpty)

                          Text(
                            task.category,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.secondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color:
                    AppColors.grayDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// ADD / EDIT TASK SHEET
// ============================================================

class TaskFormResult {

  final String title;
  final DateTime date;
  final TimeOfDay? time;
  final String category;
  final String note;


  TaskFormResult({
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    required this.note,
  });
}


class TaskSheet extends StatefulWidget {

  final DateTime initialDate;
  final Task? initialTask;


  const TaskSheet({
    super.key,
    required this.initialDate,
    this.initialTask,
  });


  @override
  State<TaskSheet> createState() =>
      _TaskSheetState();
}


class _TaskSheetState extends State<TaskSheet> {

  late TextEditingController titleController;
  late TextEditingController noteController;

  late DateTime selectedDate;

  TimeOfDay? selectedTime;

  String category = 'Personal';


  final categories = [
    'Personal',
    'Study',
    'Work',
    'Health',
    'Home',
  ];


  @override
  void initState() {

    super.initState();

    final task = widget.initialTask;

    titleController = TextEditingController(
      text: task?.title ?? '',
    );

    noteController = TextEditingController(
      text: task?.note ?? '',
    );

    selectedDate =
        task?.date ?? widget.initialDate;

    selectedTime =
        task?.time;

    category =
        task?.category ?? 'Personal';
  }


  @override
  void dispose() {

    titleController.dispose();
    noteController.dispose();

    super.dispose();
  }


  void save() {

    final title =
        titleController.text.trim();

    if (title.isEmpty) return;

    Navigator.pop(

      context,

      TaskFormResult(

        title: title,

        date: selectedDate,

        time: selectedTime,

        category: category,

        note: noteController.text.trim(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    final isEditing =
        widget.initialTask != null;


    return Padding(

      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context)
                .viewInsets
                .bottom,
      ),

      child: Container(

        constraints:
            const BoxConstraints(
          maxHeight: 720,
        ),

        decoration:
            const BoxDecoration(

          color: AppColors.white,

          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),

        child: SafeArea(

          top: false,

          child: SingleChildScrollView(

            padding:
                const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20,
            ),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Center(

                  child: Container(
                    width: 38,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.grayDark,
                      borderRadius:
                          BorderRadius.circular(
                        4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  isEditing
                      ? 'Edit Task'
                      : 'New Task',

                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 20),

                CupertinoTextField(

                  controller:
                      titleController,

                  autofocus:
                      !isEditing,

                  placeholder:
                      'What do you need to do?',

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  style:
                      const TextStyle(
                    fontSize: 16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.gray,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // DATE

                SettingsRow(

                  icon:
                      CupertinoIcons.calendar,

                  title:
                      'Date',

                  value:
                      formatShortDate(
                    selectedDate,
                  ),

                  onTap: () async {

                    await showCupertinoModalPopup(

                      context: context,

                      builder: (context) {

                        return Container(

                          height: 300,

                          color:
                              AppColors.white,

                          child:
                              CupertinoDatePicker(

                            mode:
                                CupertinoDatePickerMode
                                    .date,

                            initialDateTime:
                                selectedDate,

                            onDateTimeChanged:
                                (date) {

                              setState(() {
                                selectedDate =
                                    date;
                              });

                            },
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                // TIME

                SettingsRow(

                  icon:
                      CupertinoIcons.clock,

                  title:
                      'Time',

                  value:
                      selectedTime == null
                          ? 'Add time'
                          : formatTime(
                              selectedTime!,
                            ),

                  onTap: () async {

                    final now =
                        DateTime.now();

                    await showCupertinoModalPopup(

                      context: context,

                      builder: (context) {

                        return Container(

                          height: 300,

                          color:
                              AppColors.white,

                          child:
                              CupertinoDatePicker(

                            mode:
                                CupertinoDatePickerMode
                                    .time,

                            initialDateTime:
                                DateTime(
                              now.year,
                              now.month,
                              now.day,
                              selectedTime?.hour ??
                                  now.hour,
                              selectedTime?.minute ??
                                  now.minute,
                            ),

                            onDateTimeChanged:
                                (date) {

                              setState(() {

                                selectedTime =
                                    TimeOfDay(
                                  hour:
                                      date.hour,
                                  minute:
                                      date.minute,
                                );

                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                const Text(
                  'Category',
                  style:
                      TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(

                  height: 42,

                  child: ListView.separated(

                    scrollDirection:
                        Axis.horizontal,

                    itemCount:
                        categories.length,

                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      width: 8,
                    ),

                    itemBuilder:
                        (context, index) {

                      final item =
                          categories[index];

                      final selected =
                          category == item;

                      return GestureDetector(

                        onTap: () {

                          setState(() {
                            category =
                                item;
                          });

                        },

                        child:
                            AnimatedContainer(

                          duration:
                              const Duration(
                            milliseconds:
                                180,
                          ),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                          ),

                          alignment:
                              Alignment.center,

                          decoration:
                              BoxDecoration(
                            color: selected
                                ? AppColors
                                    .yellow
                                : AppColors
                                    .gray,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),

                          child: Text(
                            item,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                CupertinoTextField(

                  controller:
                      noteController,

                  placeholder:
                      'Add a note',

                  maxLines: 3,

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.gray,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(

                  children: [

                    Expanded(

                      child:
                          CupertinoButton(

                        color:
                            AppColors.gray,

                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),

                        onPressed: () =>
                            Navigator.pop(
                          context,
                        ),

                        child:
                            const Text(
                          'Cancel',
                          style:
                              TextStyle(
                            color:
                                AppColors.text,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child:
                          CupertinoButton(

                        color:
                            AppColors.yellow,

                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),

                        onPressed:
                            save,

                        child:
                            Text(
                          isEditing
                              ? 'Save'
                              : 'Add',

                          style:
                              const TextStyle(
                            color:
                                AppColors.text,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
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
    );
  }
}


// ============================================================
// CALENDAR PAGE
// ============================================================

class CalendarPage extends StatelessWidget {

  const CalendarPage({super.key});


  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(

      backgroundColor:
          AppColors.background,

      navigationBar:
          const CupertinoNavigationBar(
        backgroundColor:
            AppColors.background,
        border: null,
        middle: Text(
          'Calendar',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      child: SafeArea(

        child: ListView(

          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.all(24),

          children: [

            Container(

              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration:
                  BoxDecoration(

                color:
                    AppColors.white,

                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'Plan your days',
                    style:
                        TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Choose a day to see what is waiting for you.',
                    style:
                        TextStyle(
                      fontSize: 14,
                      color:
                          AppColors.secondary,
                    ),
                  ),

                  const SizedBox(height: 22),

                  CalendarMonth(),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const InfoCard(
              icon:
                  CupertinoIcons
                      .checkmark_circle,
              title:
                  'Keep it simple',
              subtitle:
                  'Daily Dough is made for the little things that keep your day moving.',
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// SIMPLE MONTH CALENDAR
// ============================================================

class CalendarMonth extends StatefulWidget {

  const CalendarMonth({super.key});

  @override
  State<CalendarMonth> createState() =>
      _CalendarMonthState();
}


class _CalendarMonthState
    extends State<CalendarMonth> {

  DateTime selected =
      DateTime.now();


  @override
  Widget build(BuildContext context) {

    final firstDay =
        DateTime(
      selected.year,
      selected.month,
      1,
    );

    final days =
        DateTime(
      selected.year,
      selected.month + 1,
      0,
    ).day;

    final start =
        firstDay.weekday - 1;


    return Column(

      children: [

        Row(

          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            GestureDetector(

              onTap: () {

                setState(() {

                  selected =
                      DateTime(
                    selected.year,
                    selected.month - 1,
                    1,
                  );

                });
              },

              child:
                  const Icon(
                CupertinoIcons
                    .chevron_left,
              ),
            ),

            Text(
              monthName(
                selected.month,
              ),
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            GestureDetector(

              onTap: () {

                setState(() {

                  selected =
                      DateTime(
                    selected.year,
                    selected.month + 1,
                    1,
                  );

                });
              },

              child:
                  const Icon(
                CupertinoIcons
                    .chevron_right,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        GridView.builder(

          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),

          itemCount:
              start + days,

          itemBuilder:
              (context, index) {

            if (index < start) {
              return const SizedBox();
            }

            final day =
                index - start + 1;

            final date =
                DateTime(
              selected.year,
              selected.month,
              day,
            );

            final isToday =
                sameDate(
              date,
              DateTime.now(),
            );

            return Center(

              child: Container(

                width: 36,
                height: 36,

                decoration:
                    BoxDecoration(
                  color: isToday
                      ? AppColors.yellow
                      : null,
                  shape:
                      BoxShape.circle,
                ),

                alignment:
                    Alignment.center,

                child: Text(
                  '$day',
                  style:
                      TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}


// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {

  const SettingsPage({super.key});


  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(

      backgroundColor:
          AppColors.background,

      navigationBar:
          const CupertinoNavigationBar(
        backgroundColor:
            AppColors.background,
        border: null,
        middle: Text(
          'Settings',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      child: SafeArea(

        child: ListView(

          padding:
              const EdgeInsets.all(24),

          children: [

            // PROFILE

            Container(

              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration:
                  BoxDecoration(
                color:
                    AppColors.white,
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),

              child: Row(

                children: [

                  Container(

                    width: 54,
                    height: 54,

                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.yellow,
                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        const Center(
                      child: Text(
                        'A',
                        style:
                            TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        'Amina',
                        style:
                            TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Making today count.',
                        style:
                            TextStyle(
                          fontSize: 13,
                          color:
                              AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const SettingsSectionTitle(
              title: 'Preferences',
            ),

            const SizedBox(height: 8),

            SettingsCard(

              children: [

                SettingsRow(

                  icon:
                      CupertinoIcons
                          .paintbrush,

                  title:
                      'Appearance',

                  value:
                      'Light',

                  onTap: () {},
                ),

                const Divider(
                  height: 1,
                ),

                SettingsRow(

                  icon:
                      CupertinoIcons
                          .bell,

                  title:
                      'Notifications',

                  value:
                      'Coming soon',

                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 22),

            const SettingsSectionTitle(
              title: 'Daily Dough',
            ),

            const SizedBox(height: 8),

            SettingsCard(

              children: [

                SettingsRow(

                  icon:
                      CupertinoIcons
                          .info_circle,

                  title:
                      'About',

                  value:
                      'Version 1.0',

                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Center(

              child: Text(
                'Made for your everyday little things.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 13,
                  color:
                      AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// SETTINGS COMPONENTS
// ============================================================

class SettingsSectionTitle
    extends StatelessWidget {

  final String title;

  const SettingsSectionTitle({
    super.key,
    required this.title,
  });


  @override
  Widget build(BuildContext context) {

    return Padding(

      padding:
          const EdgeInsets.only(
        left: 4,
      ),

      child: Text(
        title.toUpperCase(),
        style:
            const TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
          color:
              AppColors.secondary,
          letterSpacing:
              0.8,
        ),
      ),
    );
  }
}


class SettingsCard
    extends StatelessWidget {

  final List<Widget> children;

  const SettingsCard({
    super.key,
    required this.children,
  });


  @override
  Widget build(BuildContext context) {

    return Container(

      decoration:
          BoxDecoration(
        color:
            AppColors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Column(
        children: children,
      ),
    );
  }
}


class SettingsRow
    extends StatelessWidget {

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;


  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      behavior:
          HitTestBehavior.opaque,

      child: Padding(

        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        child: Row(

          children: [

            Icon(
              icon,
              size: 19,
              color:
                  AppColors.text,
            ),

            const SizedBox(width: 13),

            Expanded(

              child: Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),

            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    AppColors.secondary,
              ),
            ),

            const SizedBox(width: 6),

            const Icon(
              CupertinoIcons
                  .chevron_right,
              size: 14,
              color:
                  AppColors.grayDark,
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// EMPTY STATE
// ============================================================

class EmptyTasks
    extends StatelessWidget {

  const EmptyTasks({super.key});


  @override
  Widget build(BuildContext context) {

    return Center(

      child: Padding(

        padding:
            const EdgeInsets.symmetric(
          horizontal: 45,
        ),

        child: Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            Container(

              width: 72,
              height: 72,

              decoration:
                  const BoxDecoration(
                color:
                    AppColors.yellowLight,
                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                CupertinoIcons
                    .sun_max,
                size: 31,
                color:
                    AppColors.text,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nothing on your plate.',
              style:
                  TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'A calm day is a good day. Add something when you are ready.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 14,
                height: 1.4,
                color:
                    AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// INFO CARD
// ============================================================

class InfoCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;


  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });


  @override
  Widget build(BuildContext context) {

    return Container(

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            AppColors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(

            width: 40,
            height: 40,

            decoration:
                const BoxDecoration(
              color:
                  AppColors.yellowLight,
              shape:
                  BoxShape.circle,
            ),

            child:
                Icon(
              icon,
              size: 19,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color:
                        AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// HELPERS
// ============================================================

bool sameDate(
  DateTime a,
  DateTime b,
) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}


String weekdayShort(DateTime date) {

  const names = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  return names[date.weekday - 1];
}


String formatLongDate(DateTime date) {

  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return
      '${weekdays[date.weekday - 1]}, '
      '${months[date.month - 1]} '
      '${date.day}';
}


String formatShortDate(DateTime date) {

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return
      '${months[date.month - 1]} '
      '${date.day}';
}


String formatTime(TimeOfDay time) {

  final hour =
      time.hourOfPeriod == 0
          ? 12
          : time.hourOfPeriod;

  final minute =
      time.minute.toString().padLeft(
        2,
        '0',
      );

  final period =
      time.period == DayPeriod.am
          ? 'AM'
          : 'PM';

  return '$hour:$minute $period';
}


String monthName(int month) {

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month - 1];
}