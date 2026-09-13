import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../models/crm_task.dart';
import '../services/crm_task_service.dart';

class CrmTasksScreen extends StatefulWidget {
  const CrmTasksScreen({super.key});

  @override
  State<CrmTasksScreen> createState() => _CrmTasksScreenState();
}

class _CrmTasksScreenState extends State<CrmTasksScreen> with SingleTickerProviderStateMixin {
  final CrmTaskService _service = CrmTaskService.instance;
  late final TabController _tabController;

  List<CrmTask> _allTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await _service.getTasks();
      if (mounted) {
        setState(() {
          _allTasks = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeTask(String id) async {
    try {
      await _service.completeTask(id);
      _fetchTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  void _showCreateTaskModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;
    String priority = 'MEDIUM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.checkSquare, size: 20, color: Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              Text('Create CRM Task', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task Title *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description / Instructions', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Low')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                          DropdownMenuItem(value: 'HIGH', child: Text('High')),
                          DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => priority = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendar, size: 14),
                        label: Text(
                          dueDate == null ? 'Due Date' : '${dueDate!.day}/${dueDate!.month}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDlgState(() => dueDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, elevation: 0),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  await _service.createTask(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    priority: priority,
                    dueDate: dueDate,
                  );
                  _fetchTasks();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Task created successfully')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Create Task', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<CrmTask> get _todoList => _allTasks.where((t) => t.status == TaskStatus.todo).toList();
  List<CrmTask> get _inProgressList => _allTasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<CrmTask> get _completedList => _allTasks.where((t) => t.status == TaskStatus.completed).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Internal CRM Tasks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage task assignments, lead actions, and internal workflow checklists.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('New Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: _showCreateTaskModal,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  Tab(text: 'To Do (${_todoList.length})'),
                  Tab(text: 'In Progress (${_inProgressList.length})'),
                  Tab(text: 'Completed (${_completedList.length})'),
                  Tab(text: 'All (${_allTasks.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTaskList(_todoList, 'No pending tasks in To Do.'),
                        _buildTaskList(_inProgressList, 'No tasks currently In Progress.'),
                        _buildTaskList(_completedList, 'No completed tasks recorded.'),
                        _buildTaskList(_allTasks, 'No tasks created yet.'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<CrmTask> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.checkSquare, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final t = list[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  t.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  color: t.isCompleted ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                ),
                onPressed: t.isCompleted ? null : () => _completeTask(t.id),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                            color: t.isCompleted ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.priority,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    if (t.description != null && t.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(t.description!, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                    if (t.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
