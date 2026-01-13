import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:survey/data/models/task_model.dart';
import 'package:survey/presentation/screens/tasks/viewmodel/tasks_viewmodel.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksViewModel>().loadTasks();
    });
  }

  Future<void> _openInGoogleMaps(double latitude, double longitude) async {
    // Try geo: scheme first (works better on Android)
    final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    
    try {
      // Try geo: scheme first
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
        return;
      }
      
      // Fallback to web URL
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Last resort - just launch without checking
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح خرائط جوجل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmComplete(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الزيارة'),
          content: Text('هل تريد تأكيد زيارة "${task.title}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff25935F),
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final viewModel = context.read<TasksViewModel>();
      final success = await viewModel.completeTask(task.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم تأكيد الزيارة بنجاح' : 'فشل تأكيد الزيارة'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المواقع'),
          centerTitle: true, 
          backgroundColor: const Color(0xff25935F),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<TasksViewModel>().loadTasks(),
            ),
          ],
        ),
        body: Consumer<TasksViewModel>(
          builder: (context, viewModel, child) {
            switch (viewModel.state) {
              case TasksState.initial:
              case TasksState.loading:
                return const Center(child: CircularProgressIndicator());
              
              case TasksState.error:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage ?? 'حدث خطأ',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => viewModel.loadTasks(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff25935F),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              
              case TasksState.loaded:
                if (viewModel.tasks.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد مواقع',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.loadTasks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.tasks.length,
                    itemBuilder: (context, index) {
                      final task = viewModel.tasks[index];
                      return _TaskCard(
                        task: task,
                        isCompleting: viewModel.completingTaskId == task.id,
                        onOpenMap: () => _openInGoogleMaps(task.latitude, task.longitude),
                        onComplete: task.isDone ? null : () => _confirmComplete(task),
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isCompleting;
  final VoidCallback onOpenMap;
  final VoidCallback? onComplete;

  const _TaskCard({
    required this.task,
    required this.isCompleting,
    required this.onOpenMap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: task.isDone
                        ? Colors.green.withValues(alpha: 0.1)
                        : const Color(0xff25935F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    task.isDone ? Icons.check_circle : Icons.location_on,
                    color: task.isDone ? Colors.green : const Color(0xff25935F),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تاريخ المهمة: ${dateFormat.format(task.taskDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'تمت الزيارة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${task.latitude.toStringAsFixed(4)}, ${task.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (task.isDone && task.completedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'تم الإنجاز: ${dateFormat.format(task.completedAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.map),
                    label: const Text('فتح في الخريطة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff25935F),
                      side: const BorderSide(color: Color(0xff25935F)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isCompleting ? null : onComplete,
                    icon: isCompleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(task.isDone ? Icons.check : Icons.check_circle_outline),
                    label: Text(task.isDone ? 'تمت' : 'تأكيد الزيارة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.isDone ? Colors.grey : const Color(0xff25935F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
