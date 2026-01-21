import 'package:flutter/material.dart';
import 'package:survey/data/models/question_model.dart';

class RatingQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final int? initialValue;
  final Function(int) onChanged;
  final bool isRequired;
  final bool showHeader;

  const RatingQuestionWidget({
    super.key,
    required this.question,
    this.initialValue,
    required this.onChanged,
    required this.isRequired,
    this.showHeader = true,
  });

  @override
  State<RatingQuestionWidget> createState() => _RatingQuestionWidgetState();
}

class _RatingQuestionWidgetState extends State<RatingQuestionWidget> {
  int? selectedValue;

  // Fixed rating options for type 6 (Rating)
  static const List<Map<String, dynamic>> ratingOptions = [
    {'value': 1, 'text': 'غير راضي اطلاقا'},
    {'value': 2, 'text': 'غير راضي'},
    {'value': 3, 'text': 'محايد'},
    {'value': 4, 'text': 'راضي'},
    {'value': 5, 'text': 'راضي تماما'},
    {'value': 6, 'text': 'غير متوفر'},
  ];

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(RatingQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        selectedValue = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with rating options (show only once)
        if (widget.showHeader) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xffA93538).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xffA93538).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مقياس التقييم:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xffA93538),
                  ),
                ),
                const SizedBox(height: 12),
                ...ratingOptions.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xffA93538),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${option['value']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          option['text'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],

        // Question row with radio buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question text
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: widget.question.text),
                    if (widget.isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Radio buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ratingOptions.map((option) {
                  final isSelected = selectedValue == option['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedValue = option['value'];
                      });
                      widget.onChanged(option['value']);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xffA93538) 
                              : Colors.grey.shade400,
                          width: isSelected ? 3 : 2,
                        ),
                        color: isSelected 
                            ? const Color(0xffA93538).withOpacity(0.1) 
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected 
                                ? const Color(0xffA93538) 
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Numbers below radio buttons
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ratingOptions.map((option) {
                  return SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        '${option['value']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedValue == option['value'] 
                              ? const Color(0xffA93538) 
                              : Colors.grey.shade600,
                          fontWeight: selectedValue == option['value'] 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Validation message
              if (widget.isRequired && selectedValue == null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'هذا السؤال مطلوب',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
