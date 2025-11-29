import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/question_group_model.dart';
import 'package:survey/data/models/question_model.dart';
import 'package:survey/data/models/section_model.dart';
import 'package:survey/presentation/screens/survey_details/viewmodel/survey_details_viewmodel.dart';
import 'package:survey/presentation/widgets/question_widget.dart';
import 'package:survey/presentation/widgets/question_widgets/rating_question_widget.dart';
import 'package:survey/core/enums/question_type.dart';

class SurveyDetailsScreen extends StatefulWidget {
  final int surveyId;

  const SurveyDetailsScreen({super.key, required this.surveyId});

  @override
  State<SurveyDetailsScreen> createState() => _SurveyDetailsScreenState();
}

class _SurveyDetailsScreenState extends State<SurveyDetailsScreen> {
  int _currentSectionIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if there are pre-survey info arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final viewModel = context.read<SurveyDetailsViewModel>();

      if (args != null) {
        viewModel.setPreSurveyInfo(
          researcherName: args['researcherName'] as String?,
          supervisorName: args['supervisorName'] as String?,
          cityName: args['cityName'] as String?,
          researcherId: args['researcherId'] as int?,
          supervisorId: args['supervisorId'] as int?,
          cityId: args['cityId'] as int?,
          neighborhoodName: args['neighborhoodName'] as String?,
          streetName: args['streetName'] as String?,
          isApproved: args['isApproved'] as bool?,
          rejectReason: args['rejectReason'] as String?,
          startTime: args['startTime'] as DateTime?,
          latitude: args['latitude'] as double?,
          longitude: args['longitude'] as double?,
        );
      }

      await viewModel.loadSurvey(widget.surveyId);

      // If survey is rejected, save and exit immediately
      if (args != null && args['isApproved'] == false) {
        if (!mounted) return;

        // Show processing dialog
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
                    Text('جاري حفظ عدم الموافقة وإنهاء الاستبيان...'),
                  ],
                ),
              ),
            ),
          ),
        );

        try {
          // Complete survey (saves to Excel and marks as done)
          await viewModel.completeSurvey();

          if (!mounted) return;
          Navigator.pop(context); // Close processing dialog

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم حفظ رفض الاستبيان بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Go back to home/previous screen
          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Close processing dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء الحفظ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside TextFields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Color(0xff25935F),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Consumer<SurveyDetailsViewModel>(
            builder: (context, viewModel, child) {
              return Text(
                viewModel.survey?.name ?? 'الاستبيان',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
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
                    } else if (value == 'clear_form') {
                      await _showClearFormDialog(context, viewModel);
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
                      value: 'clear_form',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('مسح الإجابات'),
                        ],
                      ),
                    ),
                    // const PopupMenuItem(
                    //   value: 'export_clear',
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.cloud_upload, color: Color(0xff25935F)),
                    //       SizedBox(width: 12),
                    //       Text('تصدير وحذف البيانات'),
                    //     ],
                    //   ),
                    // ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<SurveyDetailsViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.state == SurveyDetailsState.loading) {
              return const Center(child: CircularProgressIndicator());
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

            if (viewModel.survey == null || viewModel.visibleSections.isEmpty) {
              return const Center(child: Text('لا توجد بيانات'));
            }

            final sections = viewModel.visibleSections;

            return Column(
              children: [
                // Progress Indicator
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
                      if (_currentSectionIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate current section before proceeding
                            if (!_validateCurrentSection(
                              sections[_currentSectionIndex],
                              viewModel,
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'يرجى ملء جميع الحقول المطلوبة قبل المتابعة',
                                  ),
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
                            backgroundColor: Color(0xff25935F),
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
      ), // Close GestureDetector
    );
  }

  Widget _buildSectionContent(
    SectionModel section,
    SurveyDetailsViewModel viewModel,
  ) {
    // Pre-process questions and groups
    final groups = viewModel.getVisibleGroups(section);
    final questions = viewModel.getVisibleQuestions(section: section);
    final List<Widget> regularWidgets = [];
    final List<QuestionModel> ratingQuestions = [];

    // Create a map of source question ID to group for quick lookup
    final Map<int, QuestionGroupModel> sourceQuestionToGroup = {};
    for (var group in groups) {
      for (var condition in group.targetConditions) {
        sourceQuestionToGroup[condition.sourceQuestionId] = group;
      }
    }

    // Separate rating questions from other questions
    for (var question in questions) {
      if (question.questionType == QuestionType.rating) {
        ratingQuestions.add(question);
      } else {
        // Add non-rating question
        regularWidgets.add(_buildDirectQuestion(question, viewModel));

        // Check if this question has a related group
        final relatedGroup = sourceQuestionToGroup[question.id];
        if (relatedGroup != null) {
          // Add the related group immediately after the question
          regularWidgets.add(_buildQuestionGroup(relatedGroup, viewModel));
          // Remove from groups list to avoid duplicating
          groups.remove(relatedGroup);
        }
      }
    }

    // Add any remaining groups that weren't linked to questions
    for (var group in groups) {
      regularWidgets.add(_buildQuestionGroup(group, viewModel));
    }

    // Build with CustomScrollView to support sticky header
    return CustomScrollView(
      slivers: [
        // Section Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff25935F).withValues(alpha: 0.7),
                    Color(0xff25935F).withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff25935F).withValues(alpha: 0.2),
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
          ),
        ),

        // Regular questions and groups
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => regularWidgets[index],
              childCount: regularWidgets.length,
            ),
          ),
        ),

        // Sticky Rating Header (if there are rating questions)
        if (ratingQuestions.isNotEmpty)
          SliverPersistentHeader(
            delegate: _RatingHeaderDelegate(),
            pinned: true,
          ),

        // Rating Questions (without individual headers)
        if (ratingQuestions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final question = ratingQuestions[index];
                // Find answer for this question
                AnswerModel? answer;
                try {
                  answer = viewModel.surveyAnswers?.answers.firstWhere(
                    (a) => a.questionId == question.id,
                  );
                } catch (e) {
                  answer = null;
                }

                // Convert initialValue to int for rating
                int? ratingInitialValue;
                if (answer?.value != null) {
                  if (answer!.value is int) {
                    ratingInitialValue = answer.value;
                  } else if (answer.value is String) {
                    ratingInitialValue = int.tryParse(answer.value.toString());
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: RatingQuestionWidget(
                    question: question,
                    initialValue: ratingInitialValue,
                    onChanged: (value) async {
                      try {
                        await viewModel.saveAnswer(
                          questionId: question.id,
                          questionCode: question.code,
                          value: value,
                        );
                      } catch (e, stackTrace) {
                        print('❌ ERROR in saveAnswer: $e');
                        print('   StackTrace: $stackTrace');
                      }
                    },
                    isRequired: viewModel.isQuestionRequired(question.id),
                    showHeader: false, // Don't show individual headers
                  ),
                );
              }, childCount: ratingQuestions.length),
            ),
          ),
      ],
    );
  }

  Widget _buildDirectQuestion(question, viewModel) {
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
              print(
                '🔴 Direct Question callback: questionId=${question.id}, code=${question.code}, value=$value',
              );
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
                // Text(
                //   '🐛 DEBUG INFO:',
                //   style: TextStyle(
                //     fontSize: 12,
                //     color: Colors.red.shade900,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // Text(
                //   'Question ID: ${question.id}',
                //   style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                // ),
                // Text(
                //   'Question Type: ${question.questionType}',
                //   style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                // ),
                // Text(
                //   'Saved answer: ${answer?.value} (${answer?.value.runtimeType})',
                //   style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                // ),
                // Text(
                //   'Source Conditions: ${question.sourceConditions.length}',
                //   style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                // ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionGroup(
    QuestionGroupModel group,
    SurveyDetailsViewModel viewModel,
  ) {
    final repetitions = viewModel.getGroupRepetitions(group.id);
    print(
      '🎨 Building group ${group.id} (${group.name}) with $repetitions repetitions',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.name.isNotEmpty) ...[
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   margin: const EdgeInsets.only(bottom: 12),
          //   decoration: BoxDecoration(
          //     color: Color(0xff25935F).withValues(alpha: 0.05),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Color(0xff25935F).withValues(alpha: 0.2)),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(Icons.group_work, color: Color(0xff25935F).withValues(alpha: 0.7)),
          //           const SizedBox(width: 12),
          //           Expanded(
          //             child: Text(
          //               group.name,
          //               style: TextStyle(
          //                 fontSize: 18,
          //                 fontWeight: FontWeight.w600,
          //                 color: Color(0xff25935F).withValues(alpha: 0.9),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 8),
          //       // Text(
          //       //   '🔄 DEBUG: Group ID ${group.id}, Repetitions: $repetitions',
          //       //   style: TextStyle(
          //       //     fontSize: 12,
          //       //     color: Colors.red.shade700,
          //       //     fontWeight: FontWeight.bold,
          //       //   ),
          //       // ),
          //     ],
          //   ),
          // ),
        ],
        ...List.generate(repetitions, (instanceIndex) {
          print(
            '   📝 Generating instance $instanceIndex for group ${group.id}',
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Always show instance number for debugging
              // Container(
              //   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              //   margin: const EdgeInsets.symmetric(vertical: 4),
              //   decoration: BoxDecoration(
              //     color: Colors.orange.shade100,
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.orange.shade300),
              //   ),
              //   child: Text(
              //     'التكرار ${instanceIndex + 1} من $repetitions',
              //     style: TextStyle(
              //       fontSize: 14,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.orange.shade900,
              //     ),
              //   ),
              // ),
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
                final initialValue =
                    (question.code == 'IND_MEMBER_INDEX' &&
                        answer?.value == null)
                    ? (instanceIndex + 1)
                    : answer?.value;

                // Auto-save member index on first render
                if (question.code == 'IND_MEMBER_INDEX' &&
                    answer?.value == null) {
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
                      print(
                        '🔵 QuestionWidget callback: questionId=${question.id}, code=${question.code}, value=$value, instanceIndex=$instanceIndex',
                      );
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

      for (
        int instanceIndex = 0;
        instanceIndex < repetitions;
        instanceIndex++
      ) {
        for (final question in group.questions) {
          if (!viewModel.isQuestionVisible(question.id)) continue;
          if (!viewModel.isQuestionRequired(question.id)) continue;

          // Check if answer exists for this question
          final answer = viewModel.getAnswer(
            questionId: question.id,
            groupInstanceId: instanceIndex,
          );

          // Validate based on question type
          bool isAnswerMissing = false;
          if (answer == null || answer.value == null) {
            isAnswerMissing = true;
          } else {
            // Check choice questions (type 4 = single, 5 = multi)
            if (question.type == 4 || question.type == 5) {
              if (answer.value is List && (answer.value as List).isEmpty) {
                isAnswerMissing = true;
              }
            }
            // Check image questions (type 9)
            else if (question.type == 9) {
              if (answer.value.toString().trim().isEmpty) {
                isAnswerMissing = true;
              }
            }
            // Check other types (text, number, etc.)
            else {
              if (answer.value.toString().trim().isEmpty) {
                isAnswerMissing = true;
              }
            }
          }

          if (isAnswerMissing) {
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

      // Validate based on question type
      bool isAnswerMissing = false;
      if (answer == null || answer.value == null) {
        isAnswerMissing = true;
      } else {
        // Check choice questions (type 4 = single, 5 = multi)
        if (question.type == 4 || question.type == 5) {
          if (answer.value is List && (answer.value as List).isEmpty) {
            isAnswerMissing = true;
          }
        }
        // Check image questions (type 9)
        else if (question.type == 9) {
          if (answer.value.toString().trim().isEmpty) {
            isAnswerMissing = true;
          }
        }
        // Check other types (text, number, etc.)
        else {
          if (answer.value.toString().trim().isEmpty) {
            isAnswerMissing = true;
          }
        }
      }

      if (isAnswerMissing) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    content: Text('✅ تم إنهاء الاستبيان وحفظه في Excel'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff25935F),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                final errorMessage = e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.orange),
            SizedBox(width: 12),
            Text('تصدير وحذف', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      content: Text(
                        'تم التصدير والحذف بنجاح: ${result['filePath']}',
                      ),
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
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 32,
                          ),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
                            backgroundColor: Color(0xff25935F),
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
                      content: Text(
                        'تم التصدير والحذف بنجاح: ${result['filePath']}',
                      ),
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

  Future<void> _showClearFormDialog(
    BuildContext context,
    SurveyDetailsViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'مسح الإجابات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'سيتم مسح جميع الإجابات من الحقول. سيتم الاحتفاظ بالبيانات المحفوظة في التخزين المحلي.\n\nهل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              
              // Clear form answers
              viewModel.clearFormAnswers();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح جميع الإجابات بنجاح'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.delete_sweep),
            label: const Text('مسح'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              backgroundColor: Color(0xff25935F),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Delegate for sticky rating header
class _RatingHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const List<Map<String, dynamic>> ratingOptions = [
    {'value': 1, 'text': 'غير راضي اطلاقا'},
    {'value': 2, 'text': 'غير راضي'},
    {'value': 3, 'text': 'محايد'},
    {'value': 4, 'text': 'راضي'},
    {'value': 5, 'text': 'راضي تماما'},
    {'value': 6, 'text': 'غير متوفر'},
  ];

  @override
  double get minExtent => 136.0;

  @override
  double get maxExtent => 136.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff25935F).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xff25935F).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.star_rate, color: const Color(0xff25935F), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'مقياس التقييم:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff25935F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Horizontal layout for rating options
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ratingOptions.map((option) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xff25935F).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xff25935F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${option['value']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option['text'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_RatingHeaderDelegate oldDelegate) => false;
}
