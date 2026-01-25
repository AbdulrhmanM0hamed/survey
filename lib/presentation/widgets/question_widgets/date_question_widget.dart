import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey/data/models/question_model.dart';

class DateQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final DateTime? initialValue;
  final Function(DateTime) onChanged;
  final bool isRequired;

  const DateQuestionWidget({
    super.key,
    required this.question,
    this.initialValue,
    required this.onChanged,
    required this.isRequired,
  });

  @override
  State<DateQuestionWidget> createState() => _DateQuestionWidgetState();
}

class _DateQuestionWidgetState extends State<DateQuestionWidget> {
  DateTime? _selectedDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialValue;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff25935F),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        widget.onChanged(picked);
      });
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
                  color: _selectedDate != null 
                      ? Colors.green 
                      : Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? _dateFormat.format(_selectedDate!)
                      : 'اختر التاريخ',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate != null
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Color(0xff25935F),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
