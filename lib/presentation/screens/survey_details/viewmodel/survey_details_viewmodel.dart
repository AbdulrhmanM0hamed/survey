import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:survey/core/enums/condition_action.dart';
import 'package:survey/core/enums/condition_operator.dart';
import 'package:survey/core/enums/target_type.dart';
import 'package:survey/core/services/excel_export_service.dart';
import 'package:survey/core/services/excel_export_service_syncfusion.dart';
import 'package:survey/data/datasources/remote/questionnaire_remote_datasource.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/question_group_model.dart';
import 'package:survey/data/models/question_model.dart';
import 'package:survey/data/models/section_model.dart';
import 'package:survey/data/models/survey_model.dart';
import 'package:survey/domain/repositories/survey_repository.dart';

enum SurveyDetailsState { initial, loading, loaded, error, saving }

class SurveyDetailsViewModel extends ChangeNotifier {
  final SurveyRepository repository;

  SurveyDetailsViewModel({required this.repository});

  SurveyDetailsState _state = SurveyDetailsState.initial;
  SurveyDetailsState get state => _state;

  SurveyModel? _survey;
  SurveyModel? get survey => _survey;

  SurveyAnswersModel? _surveyAnswers;
  SurveyAnswersModel? get surveyAnswers => _surveyAnswers;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Track visibility and requirements for questions/groups/sections
  final Map<int, bool> _questionVisibility = {};
  final Map<int, bool> _groupVisibility = {};
  final Map<int, bool> _sectionVisibility = {};
  final Map<int, bool> _questionRequired = {};
  
  // Instance-specific visibility for questions inside repeated groups
  // Key format: "${questionId}_${instanceId}"
  final Map<String, bool> _instanceQuestionVisibility = {};

  // Track group repetitions
  final Map<int, int> _groupRepetitions = {};

  String? _researcherName;
  String? _supervisorName;
  String? _cityName;
  int? _researcherId;
  int? _supervisorId;
  int? _cityId;
  String? _neighborhoodName;
  String? _streetName;
  bool? _isApproved;
  String? _rejectReason;
  DateTime? _startTime;
  double? _latitude;
  double? _longitude;
  int? _buildingFloorsCount;
  int? _apartmentsPerFloor;
  int? _selectedFloor;
  int? _selectedApartment;

  void setPreSurveyInfo({
    String? researcherName,
    String? supervisorName,
    String? cityName,
    int? researcherId,
    int? supervisorId,
    int? cityId,
    String? neighborhoodName,
    String? streetName,
    bool? isApproved,
    String? rejectReason,
    DateTime? startTime,
    double? latitude,
    double? longitude,
    int? buildingFloorsCount,
    int? apartmentsPerFloor,
    int? selectedFloor,
    int? selectedApartment,
  }) {
    _researcherName = researcherName;
    _supervisorName = supervisorName;
    _cityName = cityName;
    _researcherId = researcherId;
    _supervisorId = supervisorId;
    _cityId = cityId;
    _neighborhoodName = neighborhoodName;
    _streetName = streetName;
    _isApproved = isApproved;
    _rejectReason = rejectReason;
    _startTime = startTime;
    _latitude = latitude;
    _longitude = longitude;
    _buildingFloorsCount = buildingFloorsCount;
    _apartmentsPerFloor = apartmentsPerFloor;
    _selectedFloor = selectedFloor;
    _selectedApartment = selectedApartment;
  }

  Future<void> loadSurvey(int surveyId) async {
    _setState(SurveyDetailsState.loading);

    // Load survey details
    final surveyResult = await repository.getSurveyById(id: surveyId);

    await surveyResult.fold(
      (failure) async {
        _errorMessage = failure.message;
        _setState(SurveyDetailsState.error);
      },
      (survey) async {
        _survey = survey;

        // Load saved answers if exists
        final answersResult = await repository.getSurveyAnswers(
          surveyId: surveyId,
        );

        answersResult.fold(
          (failure) {
            // No saved answers, create new
            //print('📝 No saved answers found (failure), creating new SurveyAnswersModel');
            _surveyAnswers = SurveyAnswersModel(
              surveyId: surveyId,
              surveyCode: survey.code,
              answers: [],
              startedAt: _startTime ?? DateTime.now(),
              isDraft: true,
              researcherName: _researcherName,
              supervisorName: _supervisorName,
              cityName: _cityName,
              neighborhoodName: _neighborhoodName,
              streetName: _streetName,
              isApproved: _isApproved,
              rejectReason: _rejectReason,
              researcherId: _researcherId,
              supervisorId: _supervisorId,
              cityId: _cityId,
              latitude: _latitude,
              longitude: _longitude,
              buildingFloorsCount: _buildingFloorsCount,
              apartmentsPerFloor: _apartmentsPerFloor,
              selectedFloor: _selectedFloor,
              selectedApartment: _selectedApartment,
            );
            //print('   _surveyAnswers created with: researcher=${_researcherName}, supervisor=${_supervisorName}, city=${_cityName}');
            //print('   IDs: researcher=$_researcherId, supervisor=$_supervisorId, city=$_cityId');
            //print('   _surveyAnswers is null? ${_surveyAnswers == null}');

            // Save immediately to update Hive with new fields
            repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
          },
          (savedAnswers) {
            //print('📝 Found saved answers result (success branch)');
            //print('   savedAnswers is null? ${savedAnswers == null}');

            if (savedAnswers == null) {
              // Repository returned Right(null), create new
              //print('   savedAnswers is null, creating new');
              _surveyAnswers = SurveyAnswersModel(
                surveyId: surveyId,
                surveyCode: survey.code,
                answers: [],
                startedAt: _startTime ?? DateTime.now(),
                isDraft: true,
                researcherName: _researcherName,
                supervisorName: _supervisorName,
                cityName: _cityName,
                neighborhoodName: _neighborhoodName,
                streetName: _streetName,
                isApproved: _isApproved,
                rejectReason: _rejectReason,
                researcherId: _researcherId,
                supervisorId: _supervisorId,
                cityId: _cityId,
                latitude: _latitude,
                longitude: _longitude,
                buildingFloorsCount: _buildingFloorsCount,
                apartmentsPerFloor: _apartmentsPerFloor,
                selectedFloor: _selectedFloor,
                selectedApartment: _selectedApartment,
              );

              // Save immediately
              repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
            } else {
              // Check if this is an old draft with no answers - start fresh
              if (savedAnswers.isDraft && savedAnswers.answers.isEmpty) {
                //print('   Found empty draft, creating new survey with fresh startedAt');
                _surveyAnswers = SurveyAnswersModel(
                  surveyId: surveyId,
                  surveyCode: survey.code,
                  answers: [],
                  startedAt: _startTime ?? DateTime.now(), // Fresh start time
                  isDraft: true,
                  researcherName: _researcherName,
                  supervisorName: _supervisorName,
                  cityName: _cityName,
                  neighborhoodName: _neighborhoodName,
                  streetName: _streetName,
                  isApproved: _isApproved,
                  rejectReason: _rejectReason,
                  researcherId: _researcherId,
                  supervisorId: _supervisorId,
                  cityId: _cityId,
                  latitude: _latitude,
                  longitude: _longitude,
                  buildingFloorsCount: _buildingFloorsCount,
                  apartmentsPerFloor: _apartmentsPerFloor,
                  selectedFloor: _selectedFloor,
                  selectedApartment: _selectedApartment,
                );
              } else {
                // Has answers
                //print('   Loading saved answers and updating with new pre-survey info');

                // CRITICAL FIX: If startTime is provided (fresh start from list), update startedAt
                // regardless of whether it has answers or not, because user clicked "Start" now.
                // Unless you want to strictly preserve history for drafts.
                // Given the user request "start starts when I click SurveyCard", we should update it.
                final newStartTime = _startTime ?? savedAnswers.startedAt;
                //print('   🕒 Updating startedAt from ${savedAnswers.startedAt} to $newStartTime');

                _surveyAnswers = savedAnswers.copyWith(
                  researcherName: _researcherName,
                  supervisorName: _supervisorName,
                  cityName: _cityName,
                  neighborhoodName: _neighborhoodName,
                  streetName: _streetName,
                  isApproved: _isApproved,
                  rejectReason: _rejectReason,
                  researcherId: _researcherId,
                  supervisorId: _supervisorId,
                  cityId: _cityId,
                  latitude: _latitude,
                  longitude: _longitude,
                  buildingFloorsCount: _buildingFloorsCount,
                  apartmentsPerFloor: _apartmentsPerFloor,
                  selectedFloor: _selectedFloor,
                  selectedApartment: _selectedApartment,
                  startedAt: newStartTime, // Update start time!
                );
                //print('   Updated: researcher=${_researcherName}, supervisor=${_supervisorName}, city=${_cityName}');
                //print('   IDs: researcher=$_researcherId, supervisor=$_supervisorId, city=$_cityId');
              }

              // Save updated survey answers
              repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
            }
            //print('   _surveyAnswers loaded with ${_surveyAnswers?.answers.length ?? 0} answers');
            //print('   _surveyAnswers is null? ${_surveyAnswers == null}');
          },
        );

        //print('📝 After fold: _surveyAnswers is null? ${_surveyAnswers == null}');

        _initializeVisibilityAndRequirements();
        _evaluateAllConditions();

        _errorMessage = null;
        _setState(SurveyDetailsState.loaded);

        //print('📝 loadSurvey completed. Final check: _surveyAnswers is null? ${_surveyAnswers == null}');
      },
    );
  }

  void _initializeVisibilityAndRequirements() {
    if (_survey?.sections == null) return;

    for (final section in _survey!.sections!) {
      _sectionVisibility[section.id] = section.isActive;

      for (final group in section.questionGroups) {
        _groupVisibility[group.id] = group.isActive;
        _groupRepetitions[group.id] = group.minCount;

        for (final question in group.questions) {
          _questionVisibility[question.id] = question.isActive;
          _questionRequired[question.id] = question.isRequired;
          //print('📋 Init Group Question ${question.id}: visible=${question.isActive}, required=${question.isRequired}');
        }
      }

      for (final question in section.questions) {
        _questionVisibility[question.id] = question.isActive;
        _questionRequired[question.id] = question.isRequired;
        //print('📋 Init Section Question ${question.id}: visible=${question.isActive}, required=${question.isRequired}');
      }
    }
  }

  void _evaluateAllConditions() {
    if (_survey?.sections == null || _surveyAnswers == null) return;

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 EVALUATING ALL CONDITIONS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Reset visibility and requirements to default state before re-evaluation
    _resetConditionsToDefault();

    // Evaluate all source conditions from all questions
    for (final section in _survey!.sections!) {
      for (final group in section.questionGroups) {
        // Special debug for group that should be affected by question 20985
        if (group.name.contains('السمنه او النحافة') || group.id == 98) {
          //print('🔍 SPECIAL DEBUG - Group ${group.id} (${group.name}):');
          //print('   targetConditions: ${group.targetConditions.length}');
          for (final cond in group.targetConditions) {
            //print('   - sourceQuestionId: ${cond.sourceQuestionId}, action: ${cond.actionEnum}, operator: ${cond.operatorEnum}');
          }
        }

        // Evaluate group target conditions
        _evaluateGroupConditions(group);

        // Check if this group has Repetition condition (is a repeating group)
        final hasRepetitionCondition = group.targetConditions.any(
          (c) => c.actionEnum == ConditionAction.repetition,
        );
        
        final repetitions = _groupRepetitions[group.id] ?? 1;

        for (final question in group.questions) {
          // Special debug for question 20985 inside groups
          if (question.id == 20985) {
            // Special handling: Q20985 should control group 96 repetitions (السمنه او النحافة)
            final answer = _getAnswerValue(20985);
            if (answer != null && answer is int && answer > 0) {
              _groupRepetitions[96] = answer;
              _groupVisibility[96] = true;
            }
          }
          
          // For questions in repeating groups, evaluate for each instance
          if (hasRepetitionCondition && question.sourceConditions.isNotEmpty) {
            for (int instanceIndex = 0; instanceIndex < repetitions; instanceIndex++) {
              _evaluateQuestionConditions(question, groupInstanceId: instanceIndex);
            }
          } else {
            // For non-repeating groups, evaluate without instanceId
            _evaluateQuestionConditions(question);
          }
        }
      }

      for (final question in section.questions) {
        // Special debug for question 20985
        if (question.id == 20985) {
          //print('🔍 SPECIAL DEBUG - Question 20985 (عدد الافراد من ذوي الهمم):');
          //print('   sourceConditions: ${question.sourceConditions.length}');
          for (final cond in question.sourceConditions) {
            //print('   - targetType: ${cond.targetTypeEnum}, action: ${cond.actionEnum}, targetGroupId: ${cond.targetGroupId}');
          }

          // Special handling: Q20985 should control group 96 repetitions (السمنه او النحافة)
          final answer = _getAnswerValue(20985);
          if (answer != null && answer is int && answer > 0) {
            //print('🔧 SPECIAL FIX: Setting group 96 repetitions to $answer based on Q20985 answer');
            _groupRepetitions[96] = answer;
            // Also make group 96 visible
            _groupVisibility[96] = true;
          }
        }
        _evaluateQuestionConditions(question);
      }
    }

    // Show final state of all groups
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 FINAL STATE - Group Visibility:');
    for (final entry in _groupVisibility.entries) {
      final reps = _groupRepetitions[entry.key] ?? 0;
      if (entry.value) {
        print('   ✅ Group ${entry.key}: VISIBLE, repetitions=$reps');
      } else {
        print('   ❌ Group ${entry.key}: HIDDEN');
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  void _resetConditionsToDefault() {
    if (_survey?.sections == null) return;

    // First, collect all questions/groups that are targets of Show conditions
    final Set<int> questionsWithShowConditions = {};
    final Set<int> groupsWithShowConditions = {};
    final Set<int> sectionsWithShowConditions = {};

    // Scan all questions to find their sourceConditions
    for (final section in _survey!.sections!) {
      for (final group in section.questionGroups) {
        for (final question in group.questions) {
          for (final condition in question.sourceConditions) {
            if (condition.actionEnum == ConditionAction.show) {
              if (condition.targetTypeEnum == TargetType.question && condition.targetQuestionId != null) {
                questionsWithShowConditions.add(condition.targetQuestionId!);
              } else if (condition.targetTypeEnum == TargetType.group && condition.targetGroupId != null) {
                groupsWithShowConditions.add(condition.targetGroupId!);
              } else if (condition.targetTypeEnum == TargetType.section && condition.targetSectionId != null) {
                sectionsWithShowConditions.add(condition.targetSectionId!);
              }
            }
          }
        }
        // Also check group's targetConditions
        for (final condition in group.targetConditions) {
          if (condition.actionEnum == ConditionAction.show) {
            groupsWithShowConditions.add(group.id);
          }
        }
        for (final question in section.questions) {
          for (final condition in question.sourceConditions) {
            if (condition.actionEnum == ConditionAction.show) {
              if (condition.targetTypeEnum == TargetType.question && condition.targetQuestionId != null) {
                questionsWithShowConditions.add(condition.targetQuestionId!);
              } else if (condition.targetTypeEnum == TargetType.group && condition.targetGroupId != null) {
                groupsWithShowConditions.add(condition.targetGroupId!);
              } else if (condition.targetTypeEnum == TargetType.section && condition.targetSectionId != null) {
                sectionsWithShowConditions.add(condition.targetSectionId!);
              }
            }
          }
        }
      }
    }

    // Now reset visibility with Show targets hidden by default
    for (final section in _survey!.sections!) {
      // Reset section visibility
      if (sectionsWithShowConditions.contains(section.id)) {
        _sectionVisibility[section.id] = false;
      } else {
        _sectionVisibility[section.id] = section.isActive;
      }

      for (final group in section.questionGroups) {
        // Check if group is a target of Show condition
        if (groupsWithShowConditions.contains(group.id)) {
          _groupVisibility[group.id] = false;
        } else {
          _groupVisibility[group.id] = group.isActive;
        }
        _groupRepetitions[group.id] = group.minCount;

        for (final question in group.questions) {
          // Check if question is a target of Show condition
          if (questionsWithShowConditions.contains(question.id)) {
            _questionVisibility[question.id] = false;
          } else {
            _questionVisibility[question.id] = question.isActive;
          }
          _questionRequired[question.id] = question.isRequired;
        }
      }

      for (final question in section.questions) {
        // Check if question is a target of Show condition
        if (questionsWithShowConditions.contains(question.id)) {
          _questionVisibility[question.id] = false;
        } else {
          _questionVisibility[question.id] = question.isActive;
        }
        _questionRequired[question.id] = question.isRequired;
      }
    }
    
    print('🔄 Reset: ${questionsWithShowConditions.length} questions, ${groupsWithShowConditions.length} groups hidden by default (Show conditions)');
  }

  void _evaluateGroupConditions(QuestionGroupModel group) {
    // Evaluate all targetConditions for this group
    if (group.targetConditions.isNotEmpty) {
      //print('🔍 Evaluating ${group.targetConditions.length} conditions for group ${group.id} (${group.code})');
    }

    // Special debug for Group 97
    if (group.id == 97) {
      //print('⭐⭐⭐ SPECIAL DEBUG GROUP 97 ⭐⭐⭐');
      //print('   Group name: ${group.name}');
      //print('   targetConditions count: ${group.targetConditions.length}');
    }

    // Special debug for Group 101 (الجنسية)
    if (group.id == 101) {
      //print('🌟🌟🌟 SPECIAL DEBUG GROUP 101 (الجنسية) 🌟🌟🌟');
      //print('   Group name: ${group.name}');
      //print('   Group code: ${group.code}');
      //print('   Current visibility: ${_groupVisibility[101]}');
      //print('   targetConditions count: ${group.targetConditions.length}');
    }

    // Since all conditions in a group target the same group, use OR logic
    bool anyConditionMet = false;
    dynamic firstCondition = group.targetConditions.isNotEmpty
        ? group.targetConditions.first
        : null;

    for (final condition in group.targetConditions) {
      final answer = _getAnswerValue(condition.sourceQuestionId);
      //print('   Group Condition: action=${condition.actionEnum}, value=${condition.value}, operator=${condition.operatorEnum}');
      //print('   Answer value: $answer (type: ${answer.runtimeType})');

      // Debug: show source question choices for Group 97 and 101
      if (group.id == 97 || group.id == 101) {
        final sourceQ = _findQuestionById(condition.sourceQuestionId);
        if (sourceQ != null) {
          //print('   Source Question ${sourceQ.id} (${sourceQ.code}) choices:');
          for (final c in sourceQ.choices) {
            //print('      - id: ${c.id}, code: "${c.code}", label: "${c.label}"');
          }
        } else {
          //print('   ⚠️ Source Question ${condition.sourceQuestionId} NOT FOUND!');
        }
      }

      // Check if condition is met
      final conditionMet = _isConditionMet(answer, condition);
      //print('   Group Condition met: $conditionMet');

      if (conditionMet) {
        anyConditionMet = true;
        // Don't break - we want to log all conditions
      }
    }

    // Apply action based on OR result
    if (firstCondition != null) {
      if (anyConditionMet) {
        //print('   ✅ At least one condition met → applying action');
        _applyConditionAction(firstCondition);

        // Extra debug for Group 101
        if (group.id == 101) {
          //print('   🌟 Group 101 visibility after action: ${_groupVisibility[101]}');
          //print('   🌟 Group 101 repetitions: ${_groupRepetitions[101]}');
        }
      } else {
        //print('   ❌ No conditions met → applying reverse action');
        _applyReverseConditionAction(firstCondition);

        // Extra debug for Group 101
        if (group.id == 101) {
          //print('   🌟 Group 101 visibility after reverse: ${_groupVisibility[101]}');
        }
      }
    }
  }

  void _evaluateQuestionConditions(QuestionModel question, {int? groupInstanceId}) {
    // Evaluate all sourceConditions from this question
    if (question.sourceConditions.isNotEmpty) {
      //print('🔍 Evaluating ${question.sourceConditions.length} conditions for question ${question.id} (${question.code}) [instance: $groupInstanceId]');
    }

    // Special debug for questions 20906 and 20911 (الجنسية)
    if (question.id == 20906 || question.id == 20911) {
      //print('🌟 SPECIAL DEBUG Q${question.id} (${question.text})');
      //print('   Question code: ${question.code}');
      //print('   Current answer: ${_getAnswerValue(question.id, groupInstanceId: groupInstanceId)}');
      //print('   sourceConditions count: ${question.sourceConditions.length}');
      for (final cond in question.sourceConditions) {
        //print('   - targetGroupId: ${cond.targetGroupId}, action: ${cond.actionEnum}, value: "${cond.value}"');
      }
    }

    // Group conditions by target (targetType + targetId)
    final Map<String, List<dynamic>> groupedConditions = {};
    final Map<String, bool> targetResults = {};

    for (final condition in question.sourceConditions) {
      // Create a unique key for each target
      String targetKey;
      if (condition.targetTypeEnum == TargetType.question &&
          condition.targetQuestionId != null) {
        targetKey = 'Q${condition.targetQuestionId}';
      } else if (condition.targetTypeEnum == TargetType.group &&
          condition.targetGroupId != null) {
        targetKey = 'G${condition.targetGroupId}';
      } else if (condition.targetTypeEnum == TargetType.section &&
          condition.targetSectionId != null) {
        targetKey = 'S${condition.targetSectionId}';
      } else {
        continue; // Skip invalid conditions
      }

      if (!groupedConditions.containsKey(targetKey)) {
        groupedConditions[targetKey] = [];
        targetResults[targetKey] = false; // Initialize as false
      }
      groupedConditions[targetKey]!.add(condition);
    }

    // Evaluate each group of conditions with OR logic
    for (final entry in groupedConditions.entries) {
      final targetKey = entry.key;
      final conditions = entry.value;

      bool anyConditionMet = false;
      dynamic firstCondition = conditions.first;

      //print('📋 Evaluating ${conditions.length} conditions for target $targetKey');

      for (final condition in conditions) {
        // Use groupInstanceId when getting answer for instance-specific evaluation
        final answer = _getAnswerValue(condition.sourceQuestionId, groupInstanceId: groupInstanceId);
        //print('   Condition: value=${condition.value}, operator=${condition.operatorEnum}');
        //print('   Answer value: $answer');

        // Check if condition is met
        final conditionMet = _isConditionMet(answer, condition);
        //print('   Condition met: $conditionMet');

        if (conditionMet) {
          anyConditionMet = true;
          // Don't break - we want to log all conditions
        }
      }

      // Apply action based on OR result - pass groupInstanceId for instance-specific visibility
      if (anyConditionMet) {
        //print('   ✅ At least one condition met → applying action');
        _applyConditionAction(firstCondition, groupInstanceId: groupInstanceId);
      } else {
        //print('   ❌ No conditions met → applying reverse action');
        _applyReverseConditionAction(firstCondition, groupInstanceId: groupInstanceId);
      }
    }
  }

  bool _isConditionMet(dynamic answer, dynamic condition) {
    // Special case for RepeatForCount: always apply if answer exists
    if (condition.operatorEnum == ConditionOperator.repeatForCount) {
      return answer != null;
    }

    if (answer == null) return false;

    // Convert boolean answers to text for Yes/No questions
    dynamic compareValue = answer;
    if (answer is bool) {
      compareValue = answer ? "نعم" : "لا";
      //print('   🔄 Converted boolean $answer to text: $compareValue');
    }

    // Convert choice IDs to labels for choice questions
    if (answer is int) {
      // Find the question to get its choices
      final sourceQuestion = _findQuestionById(condition.sourceQuestionId);
      if (sourceQuestion != null && sourceQuestion.choices.isNotEmpty) {
        final choice = sourceQuestion.choices.firstWhere(
          (c) => c.id == answer,
          orElse: () => sourceQuestion.choices.firstWhere(
            (c) => c.code == answer.toString(),
            orElse: () => sourceQuestion.choices.first,
          ),
        );
        compareValue = choice.label;
        //print('   🔄 Converted choice ID $answer to label: $compareValue');

        // Special handling for question 20957 - check if choice contains "نعم"
        if (condition.sourceQuestionId == 20957 && condition.value == "نعم") {
          if (choice.label.contains("نعم")) {
            compareValue = "نعم";
            //print('   🔧 SPECIAL FIX: Q20957 choice contains نعم, setting compareValue to نعم');
          }
        }
      }
    }

    // Handle MultiChoice answers (List)
    if (answer is List) {
      //print('   🔄 Processing List answer: $answer for condition value: "${condition.value}"');
      final sourceQuestion = _findQuestionById(condition.sourceQuestionId);

      if (sourceQuestion != null && sourceQuestion.choices.isNotEmpty) {
        // Check if any selected item matches the condition value
        for (final item in answer) {
          String itemLabel = item.toString();

          if (item is int) {
            final choice = sourceQuestion.choices
                .where((c) => c.id == item)
                .firstOrNull;
            if (choice != null) {
              itemLabel = choice.label;
            }
          }

          //print('      - Checking item: $item -> "$itemLabel" vs "${condition.value}"');

          // If operator is EQUALS, we treat it as "CONTAINS" for multi-select
          // i.e., if the selected list contains the value, condition is met
          if (condition.operatorEnum == ConditionOperator.equals) {
            if (itemLabel == condition.value ||
                itemLabel.contains(condition.value)) {
              //print('      ✅ Match found! Condition met.');
              return true;
            }
          }
        }

        // If we finished loop without match for Equals, return false
        if (condition.operatorEnum == ConditionOperator.equals) {
          return false;
        }
      }
    }

    final result = condition.operatorEnum.evaluate(
      compareValue,
      condition.value,
    );
    //print('   📊 Comparison: $compareValue ${condition.operatorEnum} ${condition.value} = $result');

    return result;
  }

  void _applyConditionAction(dynamic condition, {int? groupInstanceId}) {
    final action = condition.actionEnum;
    final targetType = condition.targetTypeEnum;

    switch (targetType) {
      case TargetType.question:
        if (condition.targetQuestionId != null) {
          _applyQuestionAction(condition.targetQuestionId!, action, groupInstanceId: groupInstanceId);
        }
        break;
      case TargetType.group:
        if (condition.targetGroupId != null) {
          _applyGroupAction(condition.targetGroupId!, action, condition);
        }
        break;
      case TargetType.section:
        if (condition.targetSectionId != null) {
          _applySectionAction(condition.targetSectionId!, action);
        }
        break;
    }
  }

  void _applyReverseConditionAction(dynamic condition, {int? groupInstanceId}) {
    final action = condition.actionEnum;
    final targetType = condition.targetTypeEnum;

    switch (targetType) {
      case TargetType.question:
        if (condition.targetQuestionId != null) {
          _applyReverseQuestionAction(condition.targetQuestionId!, action, groupInstanceId: groupInstanceId);
        }
        break;
      case TargetType.group:
        if (condition.targetGroupId != null) {
          _applyReverseGroupAction(condition.targetGroupId!, action);
        }
        break;
      case TargetType.section:
        if (condition.targetSectionId != null) {
          _applyReverseSectionAction(condition.targetSectionId!, action);
        }
        break;
    }
  }

  void _applyQuestionAction(int questionId, ConditionAction action, {int? groupInstanceId}) {
    switch (action) {
      case ConditionAction.show:
        if (groupInstanceId != null) {
          // Instance-specific visibility
          final instanceKey = '${questionId}_$groupInstanceId';
          _instanceQuestionVisibility[instanceKey] = true;
          print('✅ SHOW Question $questionId [instance $groupInstanceId] → visible=true');
        } else {
          // General visibility (affects all instances)
          _questionVisibility[questionId] = true;
          print('✅ SHOW Question $questionId → visible=true');
        }
        break;
      case ConditionAction.hide:
        if (groupInstanceId != null) {
          final instanceKey = '${questionId}_$groupInstanceId';
          _instanceQuestionVisibility[instanceKey] = false;
          print('❌ HIDE Question $questionId [instance $groupInstanceId] → visible=false');
        } else {
          _questionVisibility[questionId] = false;
          print('❌ HIDE Question $questionId → visible=false');
        }
        break;
      case ConditionAction.require:
        _questionRequired[questionId] = true;
        break;
      case ConditionAction.disable:
        _questionVisibility[questionId] = false;
        break;
      case ConditionAction.repetition:
        // Not applicable to questions
        break;
    }
  }

  void _applyGroupAction(
    int groupId,
    ConditionAction action,
    dynamic condition,
  ) {
    //print('📌 _applyGroupAction: groupId=$groupId, action=$action');

    switch (action) {
      case ConditionAction.show:
        _groupVisibility[groupId] = true;
        // Show all questions in this group
        final group = _findGroupById(groupId);
        if (group != null) {
          for (final question in group.questions) {
            _questionVisibility[question.id] = question.isActive;
            // Make questions in conditional groups optional (not required)
            _questionRequired[question.id] = false;
          }
        }
        // Ensure the group has at least 1 repetition when shown
        final currentRepetitions = _groupRepetitions[groupId] ?? 0;
        if (currentRepetitions == 0) {
          _groupRepetitions[groupId] = 1;
          print(
            '✅ SHOW Group $groupId → visible=true, repetitions=1, showed ${group?.questions.length ?? 0} questions (all optional) (triggered by Q${condition?.sourceQuestionId})',
          );
        } else {
          print(
            '✅ SHOW Group $groupId → visible=true, repetitions=$currentRepetitions, showed ${group?.questions.length ?? 0} questions (all optional) (triggered by Q${condition?.sourceQuestionId})',
          );
        }
        break;
      case ConditionAction.hide:
        _groupVisibility[groupId] = false;
        // Hide all questions in this group
        final group = _findGroupById(groupId);
        if (group != null) {
          for (final question in group.questions) {
            _questionVisibility[question.id] = false;
          }
        }
        print(
          '❌ HIDE Group $groupId → visible=false, hid ${group?.questions.length ?? 0} questions',
        );
        break;
      case ConditionAction.require:
        _groupVisibility[groupId] = true;
        // When a group is required, ensure it has at least 1 repetition
        final group = _findGroupById(groupId);
        if (group != null) {
          // Show all questions in this group
          for (final question in group.questions) {
            _questionVisibility[question.id] = question.isActive;
            // Make questions in conditional required groups optional
            _questionRequired[question.id] = false;
          }
          final currentRepetitions =
              _groupRepetitions[groupId] ?? group.minCount;
          if (currentRepetitions == 0) {
            _groupRepetitions[groupId] = 1;
            //print('   ⚠️ Group $groupId is now REQUIRED (visible) with 1 repetition, showed ${group.questions.length} questions');
          } else {
            //print('   ⚠️ Group $groupId is now REQUIRED (visible) with $currentRepetitions repetitions, showed ${group.questions.length} questions');
          }
        }
        break;
      case ConditionAction.repetition:
        // Get the answer value and convert to int
        final answerValue = _getAnswerValue(condition.sourceQuestionId);
        //print('   answerValue from sourceQuestionId=${condition.sourceQuestionId}: $answerValue');

        int count = 1; // Default to 1 if no value

        if (answerValue != null) {
          if (answerValue is int) {
            count = answerValue;
          } else if (answerValue is double) {
            count = answerValue.toInt();
          } else if (answerValue is String) {
            count = int.tryParse(answerValue) ?? 1;
          }
        }

        // Ensure count is at least minCount
        final group = _findGroupById(groupId);
        if (group != null && count < group.minCount) {
          count = group.minCount;
        }

        //print('   ✅ Setting _groupRepetitions[$groupId] = $count');
        _groupRepetitions[groupId] = count;
        break;
      default:
        break;
    }
  }

  void _applySectionAction(int sectionId, ConditionAction action) {
    switch (action) {
      case ConditionAction.show:
        _sectionVisibility[sectionId] = true;
        break;
      case ConditionAction.hide:
        _sectionVisibility[sectionId] = false;
        break;
      default:
        break;
    }
  }

  void _applyReverseQuestionAction(int questionId, ConditionAction action, {int? groupInstanceId}) {
    // Get the default state from the original question
    final question = _findQuestionById(questionId);
    if (question == null) return;

    switch (action) {
      case ConditionAction.show:
        // Reverse of Show: HIDE the question (it was shown by condition, now condition is not met)
        if (groupInstanceId != null) {
          final instanceKey = '${questionId}_$groupInstanceId';
          _instanceQuestionVisibility[instanceKey] = false;
          print('🔄 REVERSE SHOW: Question $questionId [instance $groupInstanceId] → visible=false');
        } else {
          _questionVisibility[questionId] = false;
          print('🔄 REVERSE SHOW: Question $questionId → visible=false (condition not met)');
        }
        break;
      case ConditionAction.hide:
        // Reverse of Hide: show the question
        _questionVisibility[questionId] = question.isActive;
        break;
      case ConditionAction.require:
        // Reverse of Require: return to default requirement
        _questionRequired[questionId] = question.isRequired;
        break;
      case ConditionAction.disable:
        // Reverse of Disable: enable the question
        _questionVisibility[questionId] = question.isActive;
        break;
      case ConditionAction.repetition:
        // Not applicable to questions
        break;
    }
  }

  void _applyReverseGroupAction(int groupId, ConditionAction action) {
    // Get the default state from the original group
    final group = _findGroupById(groupId);
    if (group == null) return;

    switch (action) {
      case ConditionAction.show:
        // IMPORTANT: Don't hide the group if it's currently visible
        // It might be visible due to another condition from a different question
        // Only hide if it was originally hidden (default state)
        final currentVisibility = _groupVisibility[groupId] ?? false;

        // Special handling for Group 101 - check if any other condition is met
        if (groupId == 101 && currentVisibility) {
          //print('   Group 101 is currently visible, checking other conditions before hiding...');

          // Check if any target condition for this group is met
          bool anyConditionMet = false;
          for (final section in _survey?.sections ?? []) {
            for (final grp in section.questionGroups) {
              if (grp.id == groupId) {
                for (final cond in grp.targetConditions) {
                  final answer = _getAnswerValue(cond.sourceQuestionId);
                  if (_isConditionMet(answer, cond)) {
                    anyConditionMet = true;
                    //print('   Condition from Q${cond.sourceQuestionId} is still met, keeping group visible');
                    break;
                  }
                }
                if (anyConditionMet) break;
              }
            }
            if (anyConditionMet) break;
          }

          if (!anyConditionMet) {
            _groupVisibility[groupId] = false;
            _clearGroupAnswers(groupId);
            //print('   🔄 Group $groupId hidden (no conditions met), clearing answers...');
          }
        } else {
          // Check if this group has Show targetConditions
          // If it does, it should be hidden when condition is not met
          bool hasShowConditions = false;
          for (final section in _survey?.sections ?? []) {
            for (final grp in section.questionGroups) {
              if (grp.id == groupId) {
                hasShowConditions = grp.targetConditions.any(
                  (c) => c.actionEnum == ConditionAction.show,
                );
                break;
              }
            }
            if (hasShowConditions) break;
          }

          if (hasShowConditions) {
            // This group has Show conditions, so hide it when not met
            _groupVisibility[groupId] = false;
            _clearGroupAnswers(groupId);
            print(
              '🔄 REVERSE SHOW: Group $groupId → visible=false (conditions not met)',
            );
          } else if (!group.isActive) {
            // Only hide if the group was originally hidden by default
            _groupVisibility[groupId] = false;
            _clearGroupAnswers(groupId);
            //print('   🔄 Group $groupId hidden (Show condition not met, isActive=false)');
          } else {
            //print('   ℹ️ Group $groupId keeps default visibility (${group.isActive})');
          }
        }
        break;
      case ConditionAction.hide:
        // Reverse of Hide: SHOW the group
        _groupVisibility[groupId] = true;
        //print('   🔄 Group $groupId shown (Hide condition not met)');
        break;
      case ConditionAction.require:
        // Reverse of Require: return to default visibility and repetitions
        _groupVisibility[groupId] = group.isActive;
        _groupRepetitions[groupId] = group.minCount;
        //print('   🔄 Group $groupId returned to default state: visible=${group.isActive}, repetitions=${group.minCount}');
        break;
      case ConditionAction.repetition:
        // Reverse of Repetition: return to minCount
        _groupRepetitions[groupId] = group.minCount;
        // If minCount is 0, hide the group to avoid validation issues
        if (group.minCount == 0) {
          _groupVisibility[groupId] = false;
          _clearGroupAnswers(groupId);
          print(
            '🔄 REVERSE REPETITION: Group $groupId → visible=false, repetitions=0 (minCount=0)',
          );
        } else {
          //print('   ℹ️ Group $groupId returned to minCount=${group.minCount}');
        }
        break;
      default:
        break;
    }
  }

  void _applyReverseSectionAction(int sectionId, ConditionAction action) {
    // Get the default state from the original section
    final section = _findSectionById(sectionId);
    if (section == null) return;

    switch (action) {
      case ConditionAction.show:
        // Reverse of Show: return to default visibility
        _sectionVisibility[sectionId] = section.isActive;
        break;
      case ConditionAction.hide:
        // Reverse of Hide: show the section
        _sectionVisibility[sectionId] = section.isActive;
        break;
      default:
        break;
    }
  }

  QuestionModel? _findQuestionById(int questionId) {
    if (_survey?.sections == null) return null;

    for (final section in _survey!.sections!) {
      for (final group in section.questionGroups) {
        for (final question in group.questions) {
          if (question.id == questionId) return question;
        }
      }
      for (final question in section.questions) {
        if (question.id == questionId) return question;
      }
    }
    return null;
  }

  QuestionGroupModel? _findGroupById(int groupId) {
    if (_survey?.sections == null) return null;

    for (final section in _survey!.sections!) {
      for (final group in section.questionGroups) {
        if (group.id == groupId) return group;
      }
    }
    return null;
  }

  SectionModel? _findSectionById(int sectionId) {
    if (_survey?.sections == null) return null;

    for (final section in _survey!.sections!) {
      if (section.id == sectionId) return section;
    }
    return null;
  }

  Future<void> _clearGroupAnswers(int groupId) async {
    if (_surveyAnswers == null) return;

    // Find the group to access its questions
    final group = _findGroupById(groupId);
    if (group != null) {
      // Hide all questions in this group
      for (final question in group.questions) {
        _questionVisibility[question.id] = false;
      }
      print(
        '🗑️ _clearGroupAnswers: Group $groupId → hid ${group.questions.length} questions',
      );
    }

    // Count answers before clearing
    final answersCount = _surveyAnswers!.answers
        .where((a) => a.groupId == groupId)
        .length;

    if (answersCount == 0) return; // Nothing to clear

    // Remove all answers for this group
    _surveyAnswers = _surveyAnswers!.copyWith(
      answers: _surveyAnswers!.answers
          .where((a) => a.groupId != groupId)
          .toList(),
    );

    // Save the updated answers
    await repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
  }

  dynamic _getAnswerValue(int questionId, {int? groupInstanceId}) {
    // If groupInstanceId is provided, search for that specific instance
    // If null, search for any instance of this question
    final answer = _surveyAnswers?.answers.firstWhere(
      (a) =>
          a.questionId == questionId &&
          (groupInstanceId == null || a.groupInstanceId == groupInstanceId),
      orElse: () => AnswerModel(
        questionId: questionId,
        questionCode: '',
        value: null,
        timestamp: DateTime.now(),
      ),
    );
    final value = answer?.value;
    //print('      _getAnswerValue($questionId, instance=$groupInstanceId) = $value (type: ${value.runtimeType})');
    return value;
  }

  bool isQuestionVisible(int questionId, {int? groupInstanceId}) {
    // First check instance-specific visibility if groupInstanceId is provided
    if (groupInstanceId != null) {
      final instanceKey = '${questionId}_$groupInstanceId';
      if (_instanceQuestionVisibility.containsKey(instanceKey)) {
        final result = _instanceQuestionVisibility[instanceKey]!;
        if (questionId == 30861) {
          print('🔍 isQuestionVisible(30861, instance=$groupInstanceId): found in _instanceQuestionVisibility → $result');
        }
        return result;
      }
    }
    // Fall back to general question visibility
    final result = _questionVisibility[questionId] ?? true;
    if (questionId == 30861) {
      print('🔍 isQuestionVisible(30861, instance=$groupInstanceId): fallback to _questionVisibility → $result');
    }
    return result;
  }

  bool isGroupVisible(int groupId) {
    return _groupVisibility[groupId] ?? true;
  }

  bool isSectionVisible(int sectionId) {
    return _sectionVisibility[sectionId] ?? true;
  }

  bool isQuestionRequired(int questionId) {
    return _questionRequired[questionId] ?? false;
  }

  int getGroupRepetitions(int groupId) {
    // If group is hidden, return 0 to skip validation
    final isVisible = isGroupVisible(groupId);
    if (!isVisible) {
      print('⚠️ getGroupRepetitions: Group $groupId is HIDDEN, returning 0');
      return 0;
    }
    return _groupRepetitions[groupId] ?? 1;
  }

  /// Checks if a specific question is currently triggering a conditional group
  /// Returns true if THIS question's answer meets any condition (Show or Repetition)
  bool isQuestionTriggeringGroup(
    int groupId,
    int questionId, {
    int? groupInstanceId,
  }) {
    final group = _findGroupById(groupId);
    if (group == null || group.targetConditions.isEmpty) {
      return false;
    }

    // Check if THIS question is the source for any condition of this group
    for (final condition in group.targetConditions) {
      if (condition.sourceQuestionId != questionId) {
        continue;
      }

      // Get answer for this specific instance
      final answer = _getAnswerValue(
        questionId,
        groupInstanceId: groupInstanceId,
      );

      // For Show conditions: check if the condition is met
      if (condition.actionEnum == ConditionAction.show) {
        final isMet = _isConditionMet(answer, condition);
        //print('🔍 isQuestionTriggeringGroup (Show): groupId=$groupId, questionId=$questionId, instance=$groupInstanceId, answer=$answer, isMet=$isMet');
        if (isMet) {
          return true;
        }
      }
      // For Repetition conditions: check if answer exists and > 0
      else if (condition.actionEnum == ConditionAction.repetition) {
        final hasValue = answer != null && answer.toString().isNotEmpty;
        int? count;
        if (answer is int) {
          count = answer;
        } else if (answer is String) {
          count = int.tryParse(answer);
        }
        final shouldShow = hasValue && count != null && count > 0;
        //print('🔍 isQuestionTriggeringGroup (Repetition): groupId=$groupId, questionId=$questionId, instance=$groupInstanceId, answer=$answer, shouldShow=$shouldShow');
        if (shouldShow) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> saveAnswer({
    required int questionId,
    required String questionCode,
    required dynamic value,
    int? groupInstanceId,
  }) async {
    //print('💾 saveAnswer called: questionId=$questionId, code=$questionCode, value=$value');
    //print('   _surveyAnswers is null? ${_surveyAnswers == null}');

    // Special debug for nationality questions
    if (questionId == 20906 || questionId == 20911) {
      //print('🌟🌟🌟 SAVING NATIONALITY QUESTION Q$questionId 🌟🌟🌟');
      //print('   Value: $value (type: ${value.runtimeType})');
      //print('   This should trigger Group 101 (الجنسية) if value is "اخري" choice');
    }

    if (_surveyAnswers == null) {
      //print('   ❌ EARLY RETURN: _surveyAnswers is null!');
      return;
    }

    //print('   ✅ _surveyAnswers exists, proceeding...');

    // Find the question to get its type and groupId
    QuestionModel? question;
    int? groupId;

    //print('   🔍 Searching for question $questionId in ${_survey?.sections?.length ?? 0} sections');

    for (final section in _survey?.sections ?? []) {
      //print('      Checking section ${section.id}: ${section.questions.length} direct questions, ${section.questionGroups.length} groups');

      // Search in direct questions
      for (final q in section.questions) {
        if (q.id == questionId) {
          question = q;
          //print('      ✅ Found in direct questions: type=${q.type}');
          break;
        }
      }

      // Search in groups
      if (question == null) {
        for (final group in section.questionGroups) {
          //print('         Checking group ${group.id} (${group.questions.length} questions)');
          for (final q in group.questions) {
            if (q.id == questionId) {
              question = q;
              groupId = group.id;
              //print('         ✅ Found in group $groupId: type=${q.type}');
              break;
            }
          }
          if (question != null) break;
        }
      }

      if (question != null) break;
    }

    if (question == null) {
      //print('   ⚠️ WARNING: Question $questionId not found in survey structure!');
    }

    final answer = AnswerModel(
      questionId: questionId,
      questionCode: questionCode,
      value: value,
      timestamp: DateTime.now(),
      groupInstanceId: groupInstanceId,
      questionType: question?.type, // Add question type
      groupId: groupId, // Add group ID if in a group
    );

    //print('   📋 Final answer: questionType=${question?.type}, groupId=$groupId, groupInstanceId=$groupInstanceId');

    final result = await repository.saveAnswer(
      answer: answer,
      surveyId: _surveyAnswers!.surveyId,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (_) {
        // Update local answers
        final existingIndex = _surveyAnswers!.answers.indexWhere(
          (a) =>
              a.questionId == questionId &&
              a.groupInstanceId == groupInstanceId,
        );

        List<AnswerModel> updatedAnswers;
        if (existingIndex != -1) {
          updatedAnswers = List.from(_surveyAnswers!.answers);
          updatedAnswers[existingIndex] = answer;
        } else {
          updatedAnswers = [..._surveyAnswers!.answers, answer];
        }

        _surveyAnswers = _surveyAnswers!.copyWith(answers: updatedAnswers);

        //print('🔄 Re-evaluating conditions after saving answer...');
        // Re-evaluate conditions - pass groupInstanceId for instance-specific evaluation
        _evaluateAllConditions();
        
        // Also evaluate instance-specific conditions if this question has sourceConditions
        if (question != null && question.sourceConditions.isNotEmpty && groupInstanceId != null) {
          _evaluateQuestionConditions(question, groupInstanceId: groupInstanceId);
        }

        notifyListeners();
      },
    );
  }

  Future<void> completeSurvey() async {
    if (_surveyAnswers == null) return;

    _setState(SurveyDetailsState.saving);

    final completedAnswers = _surveyAnswers!.copyWith(
      completedAt: DateTime.now(),
      isDraft: false,
    );

    // Save as completed (with unique key including timestamp)
    final result = await repository.saveSurveyAnswers(
      surveyAnswers: completedAnswers,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(SurveyDetailsState.error);
      },
      (_) async {
        _surveyAnswers = completedAnswers;

        // Auto export to Excel
        try {
          final excelService = ExcelExportServiceSyncfusion();
          final filePath = await excelService.exportSurveyToExcel(
            survey: _survey!,
            surveyAnswers: completedAnswers,
            groupRepetitions: _groupRepetitions,
          );
          //print('✅ Auto exported to Excel: $filePath');
        } catch (e) {
          //print('⚠️ Auto export failed: $e');
        }

        // Delete draft version after successful completion
        await repository.deleteSurveyAnswers(surveyId: _survey!.id);
        //print('✅ Survey completed, saved locally, and exported to Excel');

        _setState(SurveyDetailsState.loaded);
      },
    );
  }

  void _setState(SurveyDetailsState newState) {
    _state = newState;
    notifyListeners();
  }

  List<SectionModel> get visibleSections {
    if (_survey?.sections == null) return [];
    final sections = _survey!.sections!
        .where((section) => isSectionVisible(section.id))
        .toList();

    // Sort by order to maintain JSON order
    sections.sort((a, b) => a.order.compareTo(b.order));

    return sections;
  }

  List<QuestionGroupModel> getVisibleGroups(SectionModel section) {
    final visibleGroups = section.questionGroups
        .where((group) => isGroupVisible(group.id))
        .toList();

    // Sort by order to maintain JSON order
    visibleGroups.sort((a, b) => a.order.compareTo(b.order));

    //print('📦 getVisibleGroups for section ${section.id}:');
    for (var group in section.questionGroups) {
      //print('   Group ${group.id} (${group.code}): visible=${isGroupVisible(group.id)}, repetitions=${getGroupRepetitions(group.id)}');
    }

    return visibleGroups;
  }

  List<QuestionModel> getVisibleQuestions({
    SectionModel? section,
    QuestionGroupModel? group,
    int? groupInstanceId,
  }) {
    if (group != null) {
      final allQuestions = group.questions;
      // For repeating groups, we return ALL questions and let the UI filter by instance
      // This is because conditional questions may be visible in some instances but not others
      final visibleQuestions = allQuestions.toList();

      // Sort by order to maintain JSON order
      visibleQuestions.sort((a, b) => a.order.compareTo(b.order));

      return visibleQuestions;
    } else if (section != null) {
      final visibleQuestions = section.questions
          .where((question) => isQuestionVisible(question.id))
          .toList();

      // Sort by order to maintain JSON order
      visibleQuestions.sort((a, b) => a.order.compareTo(b.order));

      return visibleQuestions;
    }
    return [];
  }

  AnswerModel? getAnswer({required int questionId, int? groupInstanceId}) {
    if (_surveyAnswers == null) return null;

    try {
      return _surveyAnswers!.answers.firstWhere(
        (a) =>
            a.questionId == questionId && a.groupInstanceId == groupInstanceId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Export survey answers to daily Excel file
  Future<String?> exportToExcel() async {
    if (_survey == null || _surveyAnswers == null) {
      throw Exception('No survey data to export');
    }

    try {
      _setState(SurveyDetailsState.saving);

      // Ensure completedAt is set before export
      if (_surveyAnswers!.completedAt == null) {
        _surveyAnswers = _surveyAnswers!.copyWith(
          completedAt: DateTime.now(),
          isDraft: false,
        );

        // Save updated survey answers
        await repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
        //print('✅ Set completedAt before export: ${_surveyAnswers!.completedAt}');
      }

      // Export to daily Excel file
      //print('📊 Exporting to Excel with groupRepetitions: $_groupRepetitions');
      final excelService = ExcelExportServiceSyncfusion();
      final filePath = await excelService.exportSurveyToExcel(
        survey: _survey!,
        surveyAnswers: _surveyAnswers!,
        groupRepetitions: _groupRepetitions,
      );

      // Keep data in local storage
      //print('✅ Data kept in local storage');

      _setState(SurveyDetailsState.loaded);
      return filePath;
    } catch (e) {
      _errorMessage = 'فشل تصدير البيانات: $e';
      _setState(SurveyDetailsState.error);
      rethrow;
    }
  }

  /// Export to daily Excel file (keeps local data)
  Future<Map<String, dynamic>> exportAndClearLocalData() async {
    if (_survey == null || _surveyAnswers == null) {
      throw Exception('No survey data to export');
    }

    try {
      _setState(SurveyDetailsState.saving);

      // Ensure completedAt is set before export
      if (_surveyAnswers!.completedAt == null) {
        _surveyAnswers = _surveyAnswers!.copyWith(
          completedAt: DateTime.now(),
          isDraft: false,
        );

        // Save updated survey answers
        await repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
        //print('✅ Set completedAt before export: ${_surveyAnswers!.completedAt}');
      }

      // Export to daily Excel file
      final excelService = ExcelExportServiceSyncfusion();
      final filePath = await excelService.exportSurveyToExcel(
        survey: _survey!,
        surveyAnswers: _surveyAnswers!,
        groupRepetitions: _groupRepetitions,
      );

      if (filePath == null) {
        throw Exception('Failed to export to Excel');
      }

      // Keep data in local storage - don't delete!
      //print('✅ Data kept in local storage for survey ${_survey!.id}');

      _setState(SurveyDetailsState.loaded);

      return {
        'success': true,
        'filePath': filePath,
        'message': 'تم التصدير بنجاح',
      };
    } catch (e) {
      _errorMessage = 'فشل التصدير والحذف: $e';
      _setState(SurveyDetailsState.error);
      rethrow;
    }
  }

  /// Share exported Excel file
  Future<void> shareExcelFile(String filePath) async {
    try {
      final excelService = ExcelExportServiceSyncfusion();
      await excelService.shareExcelFile(filePath);
    } catch (e) {
      _errorMessage = 'فشل مشاركة الملف: $e';
      rethrow;
    }
  }

  /// Upload all completed surveys to API
  Future<Map<String, dynamic>> uploadCompletedSurveys() async {
    try {
      _setState(SurveyDetailsState.loading);

      // Get all completed surveys from local storage
      final result = await repository.getAllCompletedAnswers();

      List<SurveyAnswersModel> completedSurveys = [];
      result.fold(
        (failure) => throw Exception(
          'Failed to load completed surveys: ${failure.message}',
        ),
        (surveys) => completedSurveys = surveys,
      );

      if (completedSurveys.isEmpty) {
        _setState(SurveyDetailsState.loaded);
        return {
          'success': true,
          'uploaded': 0,
          'failed': 0,
          'message': 'لا توجد استبيانات لرفعها',
        };
      }

      //print('📤 Found ${completedSurveys.length} completed surveys to upload');

      // Initialize API datasource
      final dio = Dio(BaseOptions(baseUrl: 'http://45.94.209.137:8080/api'));
      final apiDataSource = QuestionnaireRemoteDataSourceImpl(dio: dio);

      int uploaded = 0;
      int failed = 0;
      final failedSurveys = <String>[];

      // Upload each survey one by one
      for (int i = 0; i < completedSurveys.length; i++) {
        final surveyAnswers = completedSurveys[i];

        try {
          print(
            '📤 Uploading survey ${i + 1}/${completedSurveys.length}: Survey ID ${surveyAnswers.surveyId}',
          );

          // Convert to API format
          final apiData = QuestionnaireRemoteDataSourceImpl.convertToApiFormat(
            surveyAnswers,
          );

          // Submit to API
          final response = await apiDataSource.submitQuestionnaire(apiData);

          print('📥 رد السيرفر الكامل:');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print(response);
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          // Check if upload was successful
          bool isSuccess = false;
          if (response is Map) {
            // Check for error code
            final errorCode = response['errorCode'];
            isSuccess = errorCode == null || errorCode == 0;
          } else {
            // If response is not a map, consider it successful
            isSuccess = response != null;
          }

          if (isSuccess) {
            uploaded++;
            print('✅ Survey ${i + 1} uploaded successfully');

            // Delete from local storage after successful upload
            final key =
                'survey_${surveyAnswers.surveyId}_${surveyAnswers.completedAt?.millisecondsSinceEpoch}';
            await repository.deleteCompletedSurveyAnswer(key);
            print('🗑️ Deleted from local storage');
          } else {
            failed++;
            final errorMsg = response is Map
                ? response['errorMessage'] ?? 'Unknown error'
                : 'Upload failed';
            failedSurveys.add('Survey ${surveyAnswers.surveyId}: $errorMsg');
            print('⚠️ Survey ${i + 1} upload failed: $errorMsg');
          }

          // Small delay between uploads
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          failed++;
          failedSurveys.add('Survey ${surveyAnswers.surveyId}: $e');
          print('❌ Error uploading survey ${i + 1}: $e');
        }
      }

      _setState(SurveyDetailsState.loaded);

      final message = uploaded > 0
          ? 'تم رفع $uploaded استبيان بنجاح${failed > 0 ? "، فشل رفع $failed" : ""}'
          : 'فشل رفع جميع الاستبيانات';

      return {
        'success': uploaded > 0,
        'uploaded': uploaded,
        'failed': failed,
        'failedSurveys': failedSurveys,
        'message': message,
      };
    } catch (e) {
      _errorMessage = 'فشل رفع الاستبيانات: $e';
      _setState(SurveyDetailsState.error);
      return {
        'success': false,
        'uploaded': 0,
        'failed': 0,
        'message': 'حدث خطأ: $e',
      };
    }
  }

  /// Get Excel file info for current survey
  Future<Map<String, dynamic>?> getExcelFileInfo() async {
    if (_survey == null) return null;

    try {
      final excelService = ExcelExportServiceSyncfusion();
      return await excelService.getSurveyExcelFileInfo(
        _survey!.id,
        _survey!.code,
      );
    } catch (e) {
      //print('Error getting Excel file info: $e');
      return null;
    }
  }

  /// Clear all answers from memory (does NOT delete from local storage)
  /// This resets the form to empty state
  void clearFormAnswers() {
    //print('🗑️ Clearing all form answers from memory...');

    if (_surveyAnswers != null) {
      // Clear the answers list
      _surveyAnswers!.answers.clear();
      //print('✅ Cleared ${_surveyAnswers!.answers.length} answers');

      // Reset visibility and conditions to initial state
      if (_survey != null) {
        _initializeVisibilityAndRequirements();
        _evaluateAllConditions();
      }

      notifyListeners();
      //print('✅ Form answers cleared successfully');
    }
  }
}
