import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/question_group_model.dart';
import 'package:survey/data/models/section_model.dart';
import 'package:survey/presentation/screens/survey_details/viewmodel/survey_details_viewmodel.dart';
import 'package:survey/presentation/widgets/question_widget.dart';

class SurveyDetailsScreen extends StatefulWidget {
  final int surveyId;

  const SurveyDetailsScreen({
    super.key,
    required this.surveyId,
  });

  @override
  State<SurveyDetailsScreen> createState() => _SurveyDetailsScreenState();
}

class _SurveyDetailsScreenState extends State<SurveyDetailsScreen> {
  int _currentSectionIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if there are pre-survey info arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        context.read<SurveyDetailsViewModel>().setPreSurveyInfo(
          researcherName: args['researcherName'] as String?,
          supervisorName: args['supervisorName'] as String?,
          cityName: args['cityName'] as String?,
          neighborhoodName: args['neighborhoodName'] as String?,
          streetName: args['streetName'] as String?,
          isApproved: args['isApproved'] as bool?,
          rejectReason: args['rejectReason'] as String?,
        );
      }
      
      context.read<SurveyDetailsViewModel>().loadSurvey(widget.surveyId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<SurveyDetailsViewModel>(
          builder: (context, viewModel, child) {
            return Text(
              viewModel.survey?.name ?? 'الاستبيان',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          Consumer<SurveyDetailsViewModel>(
            builder: (context, viewModel, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'export') {
                    await _showExportDialog(context, viewModel);
                  } else if (value == 'export_clear') {
                    await _showExportAndClearDialog(context, viewModel);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, color: Colors.green),
                        SizedBox(width: 12),
                        Text('تصدير إلى Excel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_clear',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('تصدير وحذف البيانات'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<SurveyDetailsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == SurveyDetailsState.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.state == SurveyDetailsState.error) {
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
                        viewModel.loadSurvey(widget.surveyId);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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

          if (viewModel.survey == null ||
              viewModel.visibleSections.isEmpty) {
            return const Center(
              child: Text('لا توجد بيانات'),
            );
          }

          final sections = viewModel.visibleSections;

          return Column(
            children: [
              // Progress Indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'القسم ${_currentSectionIndex + 1} من ${sections.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(((_currentSectionIndex + 1) / sections.length) * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentSectionIndex + 1) / sections.length,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Sections Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sections.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSectionIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildSectionContent(sections[index], viewModel);
                  },
                ),
              ),

              // Navigation Buttons
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentSectionIndex > 0)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('السابق'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (_currentSectionIndex > 0)
                      const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate current section before proceeding
                          if (!_validateCurrentSection(sections[_currentSectionIndex], viewModel)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى ملء جميع الحقول المطلوبة قبل المتابعة'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          if (_currentSectionIndex < sections.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _showCompletionDialog(context, viewModel);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentSectionIndex < sections.length - 1
                                  ? 'التالي'
                                  : 'إنهاء الاستبيان',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentSectionIndex < sections.length - 1
                                  ? Icons.arrow_forward
                                  : Icons.check_circle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionContent(
    SectionModel section,
    SurveyDetailsViewModel viewModel,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Title
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  section.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Question Groups
        ...viewModel.getVisibleGroups(section).map((group) {
          return _buildQuestionGroup(group, viewModel);
        }),

        // Direct questions (not in groups)
        ...viewModel
            .getVisibleQuestions(section: section)
            .map((question) {
          // Find answer for this question
          AnswerModel? answer;
          try {
            answer = viewModel.surveyAnswers?.answers.firstWhere(
              (a) => a.questionId == question.id,
            );
          } catch (e) {
            answer = null;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuestionWidget(
                question: question,
                initialValue: answer?.value,
                onChanged: (value) async {
                  try {
                    print('🔴 Direct Question callback: questionId=${question.id}, code=${question.code}, value=$value');
                    print('   Calling viewModel.saveAnswer...');
                    await viewModel.saveAnswer(
                      questionId: question.id,
                      questionCode: question.code,
                      value: value,
                    );
                    print('   saveAnswer completed successfully');
                  } catch (e, stackTrace) {
                    print('❌ ERROR in saveAnswer: $e');
                    print('   StackTrace: $stackTrace');
                  }
                },
                isRequired: viewModel.isQuestionRequired(question.id),
              ),
              // Debug info for HH_MEMBERS_COUNT
              if (question.code == 'HH_MEMBERS_COUNT') ...[
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🐛 DEBUG INFO:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Question ID: ${question.id}',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                      Text(
                        'Question Type: ${question.questionType}',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                      Text(
                        'Saved answer: ${answer?.value} (${answer?.value.runtimeType})',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                      Text(
                        'Source Conditions: ${question.sourceConditions.length}',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _buildQuestionGroup(
    QuestionGroupModel group,
    SurveyDetailsViewModel viewModel,
  ) {
    final repetitions = viewModel.getGroupRepetitions(group.id);
    print('🎨 Building group ${group.id} (${group.name}) with $repetitions repetitions');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.name.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_work, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '🔄 DEBUG: Group ID ${group.id}, Repetitions: $repetitions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        ...List.generate(repetitions, (instanceIndex) {
          print('   📝 Generating instance $instanceIndex for group ${group.id}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Always show instance number for debugging
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  'التكرار ${instanceIndex + 1} من $repetitions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              ...viewModel.getVisibleQuestions(group: group).map((question) {
                // Find answer for this question and instance
                AnswerModel? answer;
                try {
                  answer = viewModel.surveyAnswers?.answers.firstWhere(
                    (a) =>
                        a.questionId == question.id &&
                        a.groupInstanceId == instanceIndex,
                  );
                } catch (e) {
                  answer = null;
                }

                // Auto-fill member index with (instanceIndex + 1)
                final initialValue = (question.code == 'IND_MEMBER_INDEX' && answer?.value == null)
                    ? (instanceIndex + 1)
                    : answer?.value;

                // Auto-save member index on first render
                if (question.code == 'IND_MEMBER_INDEX' && answer?.value == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    viewModel.saveAnswer(
                      questionId: question.id,
                      questionCode: question.code,
                      value: instanceIndex + 1,
                      groupInstanceId: instanceIndex,
                    );
                  });
                }

                return QuestionWidget(
                  question: question,
                  initialValue: initialValue,
                  onChanged: (value) async {
                    try {
                      print('🔵 QuestionWidget callback: questionId=${question.id}, code=${question.code}, value=$value, instanceIndex=$instanceIndex');
                      print('   Calling viewModel.saveAnswer...');
                      await viewModel.saveAnswer(
                        questionId: question.id,
                        questionCode: question.code,
                        value: value,
                        groupInstanceId: instanceIndex,
                      );
                      print('   saveAnswer completed successfully');
                    } catch (e, stackTrace) {
                      print('❌ ERROR in saveAnswer: $e');
                      print('   StackTrace: $stackTrace');
                    }
                  },
                  isRequired: viewModel.isQuestionRequired(question.id),
                  groupInstanceId: instanceIndex,
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  bool _validateCurrentSection(
    SectionModel section,
    SurveyDetailsViewModel viewModel,
  ) {
    // Get all required questions in the current section
    List<int> missingQuestions = [];

    // Check questions in groups
    for (final group in section.questionGroups) {
      if (!viewModel.isGroupVisible(group.id)) continue;

      final repetitions = viewModel.getGroupRepetitions(group.id);
      
      for (int instanceIndex = 0; instanceIndex < repetitions; instanceIndex++) {
        for (final question in group.questions) {
          if (!viewModel.isQuestionVisible(question.id)) continue;
          if (!viewModel.isQuestionRequired(question.id)) continue;

          // Check if answer exists for this question
          final answer = viewModel.getAnswer(
            questionId: question.id,
            groupInstanceId: instanceIndex,
          );

          if (answer == null || answer.value == null || answer.value.toString().trim().isEmpty) {
            missingQuestions.add(question.id);
          }
        }
      }
    }

    // Check direct questions in section
    for (final question in section.questions) {
      if (!viewModel.isQuestionVisible(question.id)) continue;
      if (!viewModel.isQuestionRequired(question.id)) continue;

      final answer = viewModel.getAnswer(questionId: question.id);
      
      if (answer == null || answer.value == null || answer.value.toString().trim().isEmpty) {
        missingQuestions.add(question.id);
      }
    }

    return missingQuestions.isEmpty;
  }

  void _showCompletionDialog(
    BuildContext context,
    SurveyDetailsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'إنهاء الاستبيان',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من إنهاء الاستبيان؟ سيتم حفظ جميع الإجابات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.completeSurvey();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ الاستبيان بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(
    BuildContext context,
    SurveyDetailsViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Colors.green),
            SizedBox(width: 12),
            Text(
              'تصدير إلى Excel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'سيتم تصدير إجابات هذا الاستبيان إلى ملف Excel في مجلد التنزيلات. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              Navigator.pop(context);
              
              // Show loading
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
                          Text('جاري التصدير...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                print('🎯 Starting export from UI...');
                final filePath = await viewModel.exportToExcel();
                print('✅ Export completed, filePath: $filePath');
                
                print('🔄 Closing loading dialog...');
                navigator.pop(); // Close loading using saved navigator
                print('✅ Loading dialog closed');
                
                if (filePath != null) {
                  print('📋 Showing success dialog...');
                  if (mounted) {
                    try {
                      _showExportSuccessDialog(context, viewModel, filePath);
                    } catch (e) {
                      print('❌ Error showing success dialog: $e');
                      print('⚠️ Showing snackbar instead');
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('تم التصدير بنجاح: $filePath'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'مشاركة',
                            textColor: Colors.white,
                            onPressed: () async {
                              await viewModel.shareExcelFile(filePath);
                            },
                          ),
                        ),
                      );
                    }
                  } else {
                    print('⚠️ Widget not mounted, showing snackbar instead');
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('تم التصدير بنجاح: $filePath'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              } catch (e) {
                print('❌ Export error: $e');
                navigator.pop(); // Close loading using saved navigator
                
                // Show error message
                final errorMessage = e.toString().replaceFirst('Exception: ', '');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 7),
                    action: SnackBarAction(
                      label: 'حسناً',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('تصدير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportAndClearDialog(
    BuildContext context,
    SurveyDetailsViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'تصدير وحذف',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'سيتم تصدير إجابات هذا الاستبيان إلى ملف Excel ثم حذف البيانات من التخزين المحلي. هذا الإجراء لا يمكن التراجع عنه!\n\nهل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            label: const Text('تصدير وحذف'),
            icon: const Icon(Icons.cloud_upload),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              Navigator.pop(context);
              
              // Show loading
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
                          Text('جاري التصدير والحذف...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                print('🎯 Starting export and clear from UI...');
                final result = await viewModel.exportAndClearLocalData();
                print('✅ Export and clear completed: $result');
                
                print('🔄 Closing loading dialog...');
                navigator.pop(); // Close loading using saved navigator
                print('✅ Loading dialog closed');
                
                if (!mounted) {
                  print('⚠️ Widget not mounted, showing snackbar instead');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('تم التصدير والحذف بنجاح: ${result['filePath']}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  return;
                }
                
                print('📋 Showing success dialog...');
                // Show success
                try {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'نجح التصدير',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result['message']),
                          const SizedBox(height: 12),
                          Text(
                            'المسار: ${result['filePath']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context); // Go back to survey list
                          },
                          child: const Text('إغلاق'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await viewModel.shareExcelFile(result['filePath']);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('مشاركة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  print('❌ Error showing success dialog: $e');
                  print('⚠️ Showing snackbar instead');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('تم التصدير والحذف بنجاح: ${result['filePath']}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                print('❌ Export and clear error: $e');
                navigator.pop(); // Close loading using saved navigator
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('فشل التصدير: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportSuccessDialog(
    BuildContext context,
    SurveyDetailsViewModel viewModel,
    String? filePath,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text(
              'تم التصدير بنجاح',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم حفظ الملف في مجلد التنزيلات:'),
            const SizedBox(height: 12),
            Text(
              filePath ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (filePath != null) {
                await viewModel.shareExcelFile(filePath);
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('مشاركة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
