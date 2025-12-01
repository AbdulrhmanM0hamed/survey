import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:survey/presentation/screens/pre_survey_info/pre_survey_info_screen.dart';
import 'package:survey/presentation/screens/surveys_list/viewmodel/surveys_list_viewmodel.dart';
import 'package:survey/presentation/screens/survey_details/viewmodel/survey_details_viewmodel.dart';
import 'package:survey/presentation/widgets/survey_card.dart';

class SurveysListScreen extends StatefulWidget {
  const SurveysListScreen({super.key});

  @override
  State<SurveysListScreen> createState() => _SurveysListScreenState();
}

class _SurveysListScreenState extends State<SurveysListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SurveysListViewModel>().loadSurveys();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xff25935F),
        title: const Text(
          'الاستبيانات',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            tooltip: 'رفع الاستبيانات',
            onPressed: () => _uploadSurveys(context),
          ),
      
        ],
      ),
      body: Consumer<SurveysListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == SurveysListState.loading &&
              viewModel.surveys.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.state == SurveysListState.error &&
              viewModel.surveys.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage ?? 'حدث خطأ',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        viewModel.loadSurveys();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff25935F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.surveys.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد استبيانات متاحة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xff25935F),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'عدد الاستبيانات المتاحة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${viewModel.totalCount}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: viewModel.surveys.length,
                    itemBuilder: (context, index) {
                      final survey = viewModel.surveys[index];
                      return SurveyCard(
                        survey: survey,
                        onTap: () {
                          final startTime = DateTime.now();
                          //print('🕒 Survey Start Time captured: $startTime');
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PreSurveyInfoScreen(
                                surveyId: survey.id,
                                surveyCode: survey.code,
                                startTime: startTime,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadSurveys(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.cloud_upload, color: Color(0xff25935F), size: 48),
        title: const Text(
          'رفع الاستبيانات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد رفع جميع الاستبيانات المكتملة إلى السيرفر؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff25935F),
              foregroundColor: Colors.white,
            ),
            child: const Text('رفع'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'جاري رفع الاستبيانات...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Upload surveys
      final viewModel = context.read<SurveyDetailsViewModel>();
      final result = await viewModel.uploadCompletedSurveys();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show result
      if (context.mounted) {
        final uploaded = result['uploaded'] ?? 0;
        final failed = result['failed'] ?? 0;
        final message = result['message'] ?? '';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(
              uploaded > 0 ? Icons.check_circle : Icons.error,
              color: uploaded > 0 ? Colors.green : Colors.red,
              size: 48,
            ),
            title: Text(
              uploaded > 0 ? 'تم الرفع بنجاح' : 'فشل الرفع',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                if (uploaded > 0 || failed > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (uploaded > 0)
                        Chip(
                          avatar: const Icon(Icons.check, color: Colors.white, size: 16),
                          label: Text('$uploaded نجح'),
                          backgroundColor: Colors.green,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      if (failed > 0)
                        Chip(
                          avatar: const Icon(Icons.close, color: Colors.white, size: 16),
                          label: Text('$failed فشل'),
                          backgroundColor: Colors.red,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff25935F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
