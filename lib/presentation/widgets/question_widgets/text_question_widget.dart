import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:survey/core/enums/question_type.dart';
import 'package:survey/data/models/question_model.dart';

class TextQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final String? initialValue;
  final Function(String) onChanged;
  final bool isRequired;

  const TextQuestionWidget({
    super.key,
    required this.question,
    this.initialValue,
    required this.onChanged,
    required this.isRequired,
  });

  @override
  State<TextQuestionWidget> createState() => _TextQuestionWidgetState();
}

class _TextQuestionWidgetState extends State<TextQuestionWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    print('📋 TextQuestionWidget initState: initialValue="${widget.initialValue}"');
  }

  @override
  void didUpdateWidget(TextQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if initialValue changed
    if (widget.initialValue != oldWidget.initialValue) {
      print('📋 TextQuestionWidget didUpdateWidget: old="${oldWidget.initialValue}", new="${widget.initialValue}"');
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.question.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.isRequired)
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          keyboardType: _getKeyboardType(),
          inputFormatters: _getInputFormatters(),
          maxLines: widget.question.questionType == QuestionType.text ? 3 : 1,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: _getHintText(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      // Close keyboard and trigger save
                      print('✓ Check button pressed: value="${_controller.text}"');
                      FocusScope.of(context).unfocus();
                      widget.onChanged(_controller.text);
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            // Update UI to show/hide check button (only for suffix icon)
            if (mounted) {
              setState(() {});
            }
            // For text type, save while typing
            if (widget.question.questionType == QuestionType.text) {
              widget.onChanged(value);
            }
          },
          onSubmitted: (value) {
            // When user presses Done on keyboard - save the value
            print('📝 TextField onSubmitted: value="$value", type=${widget.question.questionType}');
            widget.onChanged(value);
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.question.questionType) {
      case QuestionType.integer:
        return TextInputType.number;
      case QuestionType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _getInputFormatters() {
    switch (widget.question.questionType) {
      case QuestionType.integer:
        return [FilteringTextInputFormatter.digitsOnly];
      case QuestionType.decimal:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ];
      default:
        return null;
    }
  }

  String _getHintText() {
    switch (widget.question.questionType) {
      case QuestionType.integer:
        return 'أدخل رقماً صحيحاً';
      case QuestionType.decimal:
        return 'أدخل رقماً عشرياً';
      default:
        return 'أدخل إجابتك هنا...';
    }
  }
}
