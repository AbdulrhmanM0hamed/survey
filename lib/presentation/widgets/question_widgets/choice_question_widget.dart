import 'package:flutter/material.dart';
import 'package:survey/data/models/choice_model.dart';
import 'package:survey/data/models/question_model.dart';

class ChoiceQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final dynamic initialValue;
  final Function(dynamic) onChanged;
  final bool isRequired;
  final bool isMultiChoice;

  const ChoiceQuestionWidget({
    super.key,
    required this.question,
    this.initialValue,
    required this.onChanged,
    required this.isRequired,
    required this.isMultiChoice,
  });

  @override
  State<ChoiceQuestionWidget> createState() => _ChoiceQuestionWidgetState();
}

class _ChoiceQuestionWidgetState extends State<ChoiceQuestionWidget> {
  late dynamic _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue ??
        (widget.isMultiChoice ? <String>[] : null);
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
                  color: _hasValue() 
                      ? Colors.green 
                      : Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.question.choices.map((choice) {
          return _buildChoiceItem(choice);
        }),
      ],
    );
  }

  bool _hasValue() {
    if (widget.isMultiChoice) {
      return (_selectedValue as List).isNotEmpty;
    } else {
      return _selectedValue != null;
    }
  }

  Widget _buildChoiceItem(ChoiceModel choice) {
    if (widget.isMultiChoice) {
      final isSelected = (_selectedValue as List).contains(choice.code);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xff25935F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Color(0xff25935F).withValues(alpha: 0.05) : Colors.white,
        ),
        child: CheckboxListTile(
          value: isSelected,
          title: Text(
            choice.label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onChanged: (bool? value) {
            setState(() {
              List<String> currentList = List.from(_selectedValue as List);
              if (value == true) {
                currentList.add(choice.code);
              } else {
                currentList.remove(choice.code);
              }
              _selectedValue = currentList;
              widget.onChanged(_selectedValue);
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Color(0xff25935F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      final isSelected = _selectedValue == choice.code;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xff25935F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Color(0xff25935F).withValues(alpha: 0.05) : Colors.white,
        ),
        child: RadioListTile<String>(
          value: choice.code,
          groupValue: _selectedValue as String?,
          title: Text(
            choice.label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onChanged: (String? value) {
            setState(() {
              _selectedValue = value;
              widget.onChanged(_selectedValue);
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Color(0xff25935F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
