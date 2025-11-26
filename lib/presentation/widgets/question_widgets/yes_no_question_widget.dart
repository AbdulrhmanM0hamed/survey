import 'package:flutter/material.dart';
import 'package:survey/data/models/question_model.dart';

class YesNoQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final bool? initialValue;
  final Function(bool) onChanged;
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
  bool? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
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
                  color: _selectedValue != null 
                      ? Colors.green 
                      : Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOptionButton(
                label: 'نعم',
                value: true,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionButton(
                label: 'لا',
                value: false,
                icon: Icons.cancel_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool value,
    required IconData icon,
  }) {
    final isSelected = _selectedValue == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedValue = value;
          widget.onChanged(value);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xff25935F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Color(0xff25935F).withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xff25935F) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Color(0xff25935F) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
