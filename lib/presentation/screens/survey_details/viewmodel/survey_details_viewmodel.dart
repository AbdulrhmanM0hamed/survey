import 'package:flutter/foundation.dart';
import 'package:survey/core/enums/condition_action.dart';
import 'package:survey/core/enums/condition_operator.dart';
import 'package:survey/core/enums/target_type.dart';
import 'package:survey/core/services/excel_export_service.dart';
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

  // Track group repetitions
  final Map<int, int> _groupRepetitions = {};

  String? _researcherName;
  String? _supervisorName;
  String? _cityName;
  String? _neighborhoodName;
  String? _streetName;
  bool? _isApproved;
  String? _rejectReason;

  void setPreSurveyInfo({
    String? researcherName,
    String? supervisorName,
    String? cityName,
    String? neighborhoodName,
    String? streetName,
    bool? isApproved,
    String? rejectReason,
  }) {
    _researcherName = researcherName;
    _supervisorName = supervisorName;
    _cityName = cityName;
    _neighborhoodName = neighborhoodName;
    _streetName = streetName;
    _isApproved = isApproved;
    _rejectReason = rejectReason;
    print('📝 Pre-survey info set: researcher=$researcherName, supervisor=$supervisorName, city=$cityName, neighborhood=$neighborhoodName, street=$streetName, approved=$isApproved, reject=$rejectReason');
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
        final answersResult =
            await repository.getSurveyAnswers(surveyId: surveyId);

        answersResult.fold(
          (failure) {
            // No saved answers, create new
            print('📝 No saved answers found (failure), creating new SurveyAnswersModel');
            _surveyAnswers = SurveyAnswersModel(
              surveyId: surveyId,
              surveyCode: survey.code,
              answers: [],
              startedAt: DateTime.now(),
              isDraft: true,
              researcherName: _researcherName,
              supervisorName: _supervisorName,
              cityName: _cityName,
              neighborhoodName: _neighborhoodName,
              streetName: _streetName,
              isApproved: _isApproved,
              rejectReason: _rejectReason,
            );
            print('   _surveyAnswers created with: researcher=${_researcherName}, supervisor=${_supervisorName}, city=${_cityName}');
            print('   _surveyAnswers is null? ${_surveyAnswers == null}');
            
            // Save immediately to update Hive with new fields
            repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
          },
          (savedAnswers) {
            print('📝 Found saved answers result (success branch)');
            print('   savedAnswers is null? ${savedAnswers == null}');
            
            if (savedAnswers == null) {
              // Repository returned Right(null), create new
              print('   savedAnswers is null, creating new');
              _surveyAnswers = SurveyAnswersModel(
                surveyId: surveyId,
                surveyCode: survey.code,
                answers: [],
                startedAt: DateTime.now(),
                isDraft: true,
                researcherName: _researcherName,
                supervisorName: _supervisorName,
                cityName: _cityName,
                neighborhoodName: _neighborhoodName,
                streetName: _streetName,
                isApproved: _isApproved,
                rejectReason: _rejectReason,
              );
              
              // Save immediately
              repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
            } else {
              print('   Loading saved answers and updating with new pre-survey info');
              _surveyAnswers = savedAnswers.copyWith(
                researcherName: _researcherName,
                supervisorName: _supervisorName,
                cityName: _cityName,
                neighborhoodName: _neighborhoodName,
                streetName: _streetName,
                isApproved: _isApproved,
                rejectReason: _rejectReason,
              );
              print('   Updated: researcher=${_researcherName}, supervisor=${_supervisorName}, city=${_cityName}');
              
              // Save updated survey answers with new pre-survey info
              repository.saveSurveyAnswers(surveyAnswers: _surveyAnswers!);
            }
            print('   _surveyAnswers loaded with ${_surveyAnswers?.answers.length ?? 0} answers');
            print('   _surveyAnswers is null? ${_surveyAnswers == null}');
          },
        );

        print('📝 After fold: _surveyAnswers is null? ${_surveyAnswers == null}');

        _initializeVisibilityAndRequirements();
        _evaluateAllConditions();

        _errorMessage = null;
        _setState(SurveyDetailsState.loaded);
        
        print('📝 loadSurvey completed. Final check: _surveyAnswers is null? ${_surveyAnswers == null}');
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
        }
      }

      for (final question in section.questions) {
        _questionVisibility[question.id] = question.isActive;
        _questionRequired[question.id] = question.isRequired;
      }
    }
  }

  void _evaluateAllConditions() {
    if (_survey?.sections == null || _surveyAnswers == null) return;

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 EVALUATE ALL CONDITIONS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Reset visibility and requirements to default state before re-evaluation
    _resetConditionsToDefault();
    print('After reset: _groupRepetitions = $_groupRepetitions');

    // Evaluate all source conditions from all questions
    for (final section in _survey!.sections!) {
      for (final group in section.questionGroups) {
        for (final question in group.questions) {
          _evaluateQuestionConditions(question);
        }
      }

      for (final question in section.questions) {
        _evaluateQuestionConditions(question);
      }
    }

    print('\nAfter evaluation: _groupRepetitions = $_groupRepetitions');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  void _resetConditionsToDefault() {
    if (_survey?.sections == null) return;

    for (final section in _survey!.sections!) {
      // Reset section visibility to its default state
      _sectionVisibility[section.id] = section.isActive;

      for (final group in section.questionGroups) {
        // Reset group visibility and repetitions to default
        _groupVisibility[group.id] = group.isActive;
        _groupRepetitions[group.id] = group.minCount;

        for (final question in group.questions) {
          // Reset question visibility and requirements to default
          _questionVisibility[question.id] = question.isActive;
          _questionRequired[question.id] = question.isRequired;
        }
      }

      for (final question in section.questions) {
        _questionVisibility[question.id] = question.isActive;
        _questionRequired[question.id] = question.isRequired;
      }
    }
  }

  void _evaluateQuestionConditions(QuestionModel question) {
    // Evaluate all sourceConditions from this question
    if (question.sourceConditions.isNotEmpty) {
      print('🔍 Evaluating ${question.sourceConditions.length} conditions for question ${question.id} (${question.code})');
    }
    
    for (final condition in question.sourceConditions) {
      final answer = _getAnswerValue(condition.sourceQuestionId);
      print('   Condition: targetType=${condition.targetTypeEnum}, action=${condition.actionEnum}, operator=${condition.operatorEnum}');
      print('   Answer value: $answer');

      // Check if condition is met
      final conditionMet = _isConditionMet(answer, condition);
      print('   Condition met: $conditionMet');

      if (conditionMet) {
        _applyConditionAction(condition);
      } else {
        // Apply reverse action if condition is not met
        _applyReverseConditionAction(condition);
      }
    }
  }

  bool _isConditionMet(dynamic answer, dynamic condition) {
    // Special case for RepeatForCount: always apply if answer exists
    if (condition.operatorEnum == ConditionOperator.repeatForCount) {
      return answer != null;
    }
    
    if (answer == null) return false;

    return condition.operatorEnum.evaluate(answer, condition.value);
  }

  void _applyConditionAction(dynamic condition) {
    final action = condition.actionEnum;
    final targetType = condition.targetTypeEnum;

    switch (targetType) {
      case TargetType.question:
        if (condition.targetQuestionId != null) {
          _applyQuestionAction(condition.targetQuestionId!, action);
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

  void _applyReverseConditionAction(dynamic condition) {
    final action = condition.actionEnum;
    final targetType = condition.targetTypeEnum;

    switch (targetType) {
      case TargetType.question:
        if (condition.targetQuestionId != null) {
          _applyReverseQuestionAction(condition.targetQuestionId!, action);
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

  void _applyQuestionAction(int questionId, ConditionAction action) {
    switch (action) {
      case ConditionAction.show:
        _questionVisibility[questionId] = true;
        break;
      case ConditionAction.hide:
        _questionVisibility[questionId] = false;
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

  void _applyGroupAction(int groupId, ConditionAction action, dynamic condition) {
    print('📌 _applyGroupAction: groupId=$groupId, action=$action');
    
    switch (action) {
      case ConditionAction.show:
        _groupVisibility[groupId] = true;
        break;
      case ConditionAction.hide:
        _groupVisibility[groupId] = false;
        break;
      case ConditionAction.repetition:
        // Get the answer value and convert to int
        final answerValue = _getAnswerValue(condition.sourceQuestionId);
        print('   answerValue from sourceQuestionId=${condition.sourceQuestionId}: $answerValue');
        
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
        
        print('   ✅ Setting _groupRepetitions[$groupId] = $count');
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

  void _applyReverseQuestionAction(int questionId, ConditionAction action) {
    // Get the default state from the original question
    final question = _findQuestionById(questionId);
    if (question == null) return;

    switch (action) {
      case ConditionAction.show:
        // Reverse of Show: return to default visibility
        _questionVisibility[questionId] = question.isActive;
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
        // Reverse of Show: return to default visibility
        _groupVisibility[groupId] = group.isActive;
        break;
      case ConditionAction.hide:
        // Reverse of Hide: show the group
        _groupVisibility[groupId] = group.isActive;
        break;
      case ConditionAction.repetition:
        // Reverse of Repetition: return to minCount
        _groupRepetitions[groupId] = group.minCount;
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

  dynamic _getAnswerValue(int questionId) {
    final answer = _surveyAnswers?.answers.firstWhere(
      (a) => a.questionId == questionId,
      orElse: () => AnswerModel(
        questionId: questionId,
        questionCode: '',
        value: null,
        timestamp: DateTime.now(),
      ),
    );
    final value = answer?.value;
    print('      _getAnswerValue($questionId) = $value (type: ${value.runtimeType})');
    return value;
  }

  bool isQuestionVisible(int questionId) {
    return _questionVisibility[questionId] ?? true;
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
    final count = _groupRepetitions[groupId] ?? 1;
    print('🔄 getGroupRepetitions: groupId=$groupId, count=$count');
    return count;
  }

  Future<void> saveAnswer({
    required int questionId,
    required String questionCode,
    required dynamic value,
    int? groupInstanceId,
  }) async {
    print('💾 saveAnswer called: questionId=$questionId, code=$questionCode, value=$value');
    print('   _surveyAnswers is null? ${_surveyAnswers == null}');
    
    if (_surveyAnswers == null) {
      print('   ❌ EARLY RETURN: _surveyAnswers is null!');
      return;
    }

    print('   ✅ _surveyAnswers exists, proceeding...');

    final answer = AnswerModel(
      questionId: questionId,
      questionCode: questionCode,
      value: value,
      timestamp: DateTime.now(),
      groupInstanceId: groupInstanceId,
    );

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

        print('🔄 Re-evaluating conditions after saving answer...');
        // Re-evaluate conditions
        _evaluateAllConditions();

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

    final result = await repository.saveSurveyAnswers(
      surveyAnswers: completedAnswers,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(SurveyDetailsState.error);
      },
      (_) {
        _surveyAnswers = completedAnswers;
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
    return _survey!.sections!
        .where((section) => isSectionVisible(section.id))
        .toList();
  }

  List<QuestionGroupModel> getVisibleGroups(SectionModel section) {
    final visibleGroups = section.questionGroups
        .where((group) => isGroupVisible(group.id))
        .toList();
    
    print('📦 getVisibleGroups for section ${section.id}:');
    for (var group in section.questionGroups) {
      print('   Group ${group.id} (${group.code}): visible=${isGroupVisible(group.id)}, repetitions=${getGroupRepetitions(group.id)}');
    }
    
    return visibleGroups;
  }

  List<QuestionModel> getVisibleQuestions(
      {SectionModel? section, QuestionGroupModel? group}) {
    if (group != null) {
      return group.questions
          .where((question) => isQuestionVisible(question.id))
          .toList();
    } else if (section != null) {
      return section.questions
          .where((question) => isQuestionVisible(question.id))
          .toList();
    }
    return [];
  }

  AnswerModel? getAnswer({required int questionId, int? groupInstanceId}) {
    if (_surveyAnswers == null) return null;
    
    try {
      return _surveyAnswers!.answers.firstWhere(
        (a) => a.questionId == questionId && a.groupInstanceId == groupInstanceId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Export survey answers to Excel
  Future<String?> exportToExcel() async {
    if (_survey == null || _surveyAnswers == null) {
      throw Exception('No survey data to export');
    }

    try {
      _setState(SurveyDetailsState.saving);
      
      final excelService = ExcelExportService();
      final filePath = await excelService.exportSurveyToExcel(
        survey: _survey!,
        surveyAnswers: _surveyAnswers!,
      );

      _setState(SurveyDetailsState.loaded);
      return filePath;
    } catch (e) {
      _errorMessage = 'فشل تصدير البيانات: $e';
      _setState(SurveyDetailsState.error);
      rethrow;
    }
  }

  /// Export to Excel and delete local data
  Future<Map<String, dynamic>> exportAndClearLocalData() async {
    if (_survey == null || _surveyAnswers == null) {
      throw Exception('No survey data to export');
    }

    try {
      _setState(SurveyDetailsState.saving);

      // 1. Export to Excel
      final excelService = ExcelExportService();
      final filePath = await excelService.exportSurveyToExcel(
        survey: _survey!,
        surveyAnswers: _surveyAnswers!,
      );

      if (filePath == null) {
        throw Exception('Failed to export to Excel');
      }

      // 2. Delete local storage
      await repository.deleteSurveyAnswers(surveyId: _survey!.id);

      // 3. Reset local state
      _surveyAnswers = SurveyAnswersModel(
        surveyId: _survey!.id,
        surveyCode: _survey!.code,
        answers: [],
        startedAt: DateTime.now(),
        isDraft: true,
      );

      _setState(SurveyDetailsState.loaded);
      
      return {
        'success': true,
        'filePath': filePath,
        'message': 'تم التصدير بنجاح وحذف البيانات المحلية',
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
      final excelService = ExcelExportService();
      await excelService.shareExcelFile(filePath);
    } catch (e) {
      _errorMessage = 'فشل مشاركة الملف: $e';
      rethrow;
    }
  }

  /// Get Excel file info for current survey
  Future<Map<String, dynamic>?> getExcelFileInfo() async {
    if (_survey == null) return null;
    
    try {
      final excelService = ExcelExportService();
      return await excelService.getSurveyExcelFileInfo(_survey!.id, _survey!.code);
    } catch (e) {
      print('Error getting Excel file info: $e');
      return null;
    }
  }
}
