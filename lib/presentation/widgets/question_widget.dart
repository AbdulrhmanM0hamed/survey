import 'package:flutter/material.dart';
import 'package:survey/core/enums/question_type.dart';
import 'package:survey/data/models/question_model.dart';
import 'package:survey/presentation/widgets/question_widgets/choice_question_widget.dart';
import 'package:survey/presentation/widgets/question_widgets/date_question_widget.dart';
import 'package:survey/presentation/widgets/question_widgets/image_question_widget.dart';
import 'package:survey/presentation/widgets/question_widgets/text_question_widget.dart';
import 'package:survey/presentation/widgets/question_widgets/yes_no_question_widget.dart';

class QuestionWidget extends StatelessWidget {
  final QuestionModel question;
  final dynamic initialValue;
  final Function(dynamic) onChanged;
  final bool isRequired;
  final int? groupInstanceId;

  const QuestionWidget({
    super.key,
    required this.question,
    this.initialValue,
    required this.onChanged,
    required this.isRequired,
    this.groupInstanceId,
  });

  @override
  Widget build(BuildContext context) {
    print('🎯 Building QuestionWidget: id=${question.id}, code=${question.code}, type=${question.questionType}, text=${question.text.substring(0, question.text.length > 30 ? 30 : question.text.length)}...');
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildQuestionWidget(),
    );
  }

  Widget _buildQuestionWidget() {
    switch (question.questionType) {
      case QuestionType.text:
      case QuestionType.integer:
      case QuestionType.decimal:
        return TextQuestionWidget(
          question: question,
          initialValue: initialValue?.toString(),
          onChanged: (value) {
            print('QuestionWidget.onChanged: received value="$value" (${value.runtimeType})');
            
            // Convert value based on question type
            dynamic convertedValue;
            
            if (question.questionType == QuestionType.integer) {
              // For integer: convert to int
              final intValue = int.tryParse(value);
              print('  Converting to int: intValue=$intValue');
              if (intValue != null) {
                convertedValue = intValue;
              } else {
                // If empty or invalid, pass null or 0
                convertedValue = value.isEmpty ? null : 0;
              }
            } else if (question.questionType == QuestionType.decimal) {
              // For decimal: convert to double
              final doubleValue = double.tryParse(value);
              if (doubleValue != null) {
                convertedValue = doubleValue;
              } else {
                convertedValue = value.isEmpty ? null : 0.0;
              }
            } else {
              // For text: keep as string
              convertedValue = value;
            }
            
            print('  Converted value: $convertedValue (${convertedValue.runtimeType})');
            
            // Only trigger onChanged if value is not null
            if (convertedValue != null) {
              print('  ✅ Calling onChanged with value: $convertedValue');
              onChanged(convertedValue);
              print('  ✅ onChanged completed');
            } else {
              print('  ❌ convertedValue is null, not calling onChanged');
            }
          },
          isRequired: isRequired,
        );

      case QuestionType.yesNo:
        return YesNoQuestionWidget(
          question: question,
          initialValue: initialValue as bool?,
          onChanged: onChanged,
          isRequired: isRequired,
        );

      case QuestionType.singleChoice:
        return ChoiceQuestionWidget(
          question: question,
          initialValue: initialValue,
          onChanged: onChanged,
          isRequired: isRequired,
          isMultiChoice: false,
        );

      case QuestionType.multiChoice:
        return ChoiceQuestionWidget(
          question: question,
          initialValue: initialValue ?? [],
          onChanged: onChanged,
          isRequired: isRequired,
          isMultiChoice: true,
        );

      case QuestionType.date:
        return DateQuestionWidget(
          question: question,
          initialValue: initialValue != null
              ? DateTime.tryParse(initialValue.toString())
              : null,
          onChanged: (date) => onChanged(date.toIso8601String()),
          isRequired: isRequired,
        );

      case QuestionType.image:
        return ImageQuestionWidget(
          questionText: question.text,
          isRequired: isRequired,
          initialValue: initialValue?.toString(),
          onChanged: onChanged,
        );

      case QuestionType.rating:
      case QuestionType.duration:
        // For now, use text widget - can be enhanced later
        return TextQuestionWidget(
          question: question,
          initialValue: initialValue?.toString(),
          onChanged: onChanged,
          isRequired: isRequired,
        );
    }
  }
}
