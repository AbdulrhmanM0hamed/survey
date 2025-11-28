import 'package:flutter/material.dart';
import 'package:survey/presentation/screens/survey_details/survey_details_screen.dart';

class ConsentScreen extends StatefulWidget {
  final int surveyId;
  final String surveyCode;
  final String? researcherName;
  final String? supervisorName;
  final String? cityName;
  final int? researcherId;
  final int? supervisorId;
  final int? cityId;
  final String? neighborhoodName;
  final String? streetName;
  final DateTime? startTime;

  const ConsentScreen({
    super.key,
    required this.surveyId,
    required this.surveyCode,
    this.researcherName,
    this.supervisorName,
    this.cityName,
    this.researcherId,
    this.supervisorId,
    this.cityId,
    this.neighborhoodName,
    this.streetName,
    this.startTime,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool? _isApproved;
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      // Navigate to survey details with consent info
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SurveyDetailsScreen(
            surveyId: widget.surveyId,
          ),
          settings: RouteSettings(
            arguments: {
              'researcherName': widget.researcherName,
              'supervisorName': widget.supervisorName,
              'cityName': widget.cityName,
              'researcherId': widget.researcherId,
              'supervisorId': widget.supervisorId,
              'cityId': widget.cityId,
              'neighborhoodName': widget.neighborhoodName,
              'streetName': widget.streetName,
              'isApproved': _isApproved,
              'rejectReason': _isApproved == false ? _rejectReasonController.text.trim() : '',
              'startTime': widget.startTime,
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff25935F),
        title: const Text(
          'الموافقة على المشاركة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Consent Text Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xff25935F),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'نص الموافقة على المشاركة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff25935F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'الباحة، والذي يهدف رصد بيانات التنمية الحضرية وقياس المؤشرات وتوفير قاعدة بيانات شاملة لأوضاع السكان والمساكن والأحوال المعيشية للأسر بمنطقة الباحة، وذلك من خلال جمع البيانات عن طريق عينة عشوائية يتم توزيعها على محافظات منطقة الباحة، حيث إن الهدف الأساسي من هذا المسح هو إنتاج مؤشرات اجتماعية واقتصادية لإعداد خطط وبرامج تنموية حضرية، تسهم في رفع وتحسين جودة الحياة بمنطقة الباحة والارتقاء بمستوى خدماتها الأساسية.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'سيتم مقابلة رب الأسرة أو من ينوب عنه لجمع المعلومات الأساسية عن الأسرة ككل ومعلومات عن أفراد أسرته، علماً بأنه ليس مطلوب منك الإدلاء بأسماء الأشخاص، وسيتم التعامل مع جميع المعلومات التي ستقدمونها بسرية تامة لأغراض التخطيط والدراسة والتحليل العلمي للرصد الحضري.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'إن إدلاءك بالبيانات الصحيحة سيسهم في الخروج بنتائج دقيقة تساعد في التخطيط السليم وتوفير الخدمات بصورة علمية، كما أن التخطيط السليم الذي يعود على المجتمع بالخير الحقيقي، يبدأ من المعلومات السليمة الدقيقة، شاكرين ومقدرين تعاونكم معنا.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Approval Question
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'هل توافق على المشاركة في هذا الاستبيان؟ *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<bool>(
                      title: const Text('نعم، أوافق على المشاركة'),
                      value: true,
                      groupValue: _isApproved,
                      onChanged: (value) {
                        setState(() {
                          _isApproved = value;
                          if (value == true) {
                            _rejectReasonController.clear();
                          }
                        });
                      },
                      activeColor: const Color(0xff25935F),
                    ),
                    RadioListTile<bool>(
                      title: const Text('لا، لا أوافق على المشاركة'),
                      value: false,
                      groupValue: _isApproved,
                      onChanged: (value) {
                        setState(() {
                          _isApproved = value;
                        });
                      },
                      activeColor: Colors.red,
                    ),
                    
                    // Reject Reason Field (shown when not approved)
                    if (_isApproved == false) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rejectReasonController,
                        decoration: InputDecoration(
                          labelText: 'سبب عدم الموافقة *',
                          hintText: 'يرجى ذكر سبب عدم الموافقة على المشاركة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xff25935F),
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.comment_outlined),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (_isApproved == false && (value == null || value.trim().isEmpty)) {
                            return 'يرجى ذكر سبب عدم الموافقة';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    if (_isApproved == null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'يرجى اختيار أحد الخيارات للمتابعة',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Continue Button
            ElevatedButton(
              onPressed: _isApproved != null ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff25935F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'متابعة للاستبيان',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'يمكنك المتابعة للاستبيان حتى لو لم توافق على المشاركة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
