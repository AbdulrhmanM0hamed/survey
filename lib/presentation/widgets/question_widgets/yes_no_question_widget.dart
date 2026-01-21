import 'package:flutter/material.dart';
import 'package:survey/data/models/question_model.dart';

class YesNoQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final dynamic initialValue; // Changed from bool? to dynamic (can be bool or int choiceId)
  final Function(int) onChanged; // Changed from bool to int (choiceId)
  final bool isRequired;

  const YesNoQuestionWidget({
    super.key,
    required this.question,
    this.initialValue,
    required this.onChanged,
    required this.isRequired,
  });

  @override
  State<YesNoQuestionWidget> createState() => _YesNoQuestionWidgetState();
}

class _YesNoQuestionWidgetState extends State<YesNoQuestionWidget> {
  int? _selectedChoiceId; // Changed to store choiceId instead of bool

  @override
  void initState() {
    super.initState();
    // Convert initial value to choiceId if needed
    if (widget.initialValue is int) {
      _selectedChoiceId = widget.initialValue as int;
    } else if (widget.initialValue is bool) {
      // Legacy: convert bool to choiceId using question choices
      final bool value = widget.initialValue as bool;
      if (widget.question.choices.length >= 2) {
        _selectedChoiceId = value 
            ? widget.question.choices[0].id  // true = "نعم" (first choice)
            : widget.question.choices[1].id; // false = "لا" (second choice)
      }
    }
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
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedChoiceId != null 
                      ? Colors.green 
                      : Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.question.choices.length >= 2) ...[
              Expanded(
                child: _buildOptionButton(
                  label: widget.question.choices[0].label, // "نعم"
                  choiceId: widget.question.choices[0].id,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOptionButton(
                  label: widget.question.choices[1].label, // "لا"
                  choiceId: widget.question.choices[1].id,
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required int choiceId,
    required IconData icon,
  }) {
    final isSelected = _selectedChoiceId == choiceId;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedChoiceId = choiceId;
          widget.onChanged(choiceId);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xffA93538) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Color(0xffA93538).withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xffA93538) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Color(0xffA93538) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
