import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:survey/data/models/management_information_model.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/survey_model.dart';
import 'package:survey/data/datasources/management_information_remote_datasource.dart';
import 'package:survey/presentation/screens/survey_details/survey_details_screen.dart';
import 'package:survey/core/storage/hive_service.dart';
import 'package:survey/core/services/excel_export_service.dart';
import 'package:dio/dio.dart';

class PreSurveyInfoScreen extends StatefulWidget {
  final int surveyId;
  final String surveyCode;

  const PreSurveyInfoScreen({
    super.key,
    required this.surveyId,
    required this.surveyCode,
  });

  @override
  State<PreSurveyInfoScreen> createState() => _PreSurveyInfoScreenState();
}

class _PreSurveyInfoScreenState extends State<PreSurveyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  ManagementInformationModel? _selectedResearcher;
  ManagementInformationModel? _selectedSupervisor;
  ManagementInformationModel? _selectedCity;
  
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();
  
  bool? _isApproved;
  
  List<ManagementInformationModel> _researchers = [];
  List<ManagementInformationModel> _supervisors = [];
  List<ManagementInformationModel> _cities = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  late ManagementInformationRemoteDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    // Initialize data source with your base URL
    final dio = Dio(BaseOptions(baseUrl: 'http://45.94.209.137:8080/api'));
    _dataSource = ManagementInformationRemoteDataSourceImpl(dio: dio);
    _loadData();
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _streetController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _dataSource.getManagementInformations(ManagementInformationType.researcherName),
        _dataSource.getManagementInformations(ManagementInformationType.supervisorName),
        _dataSource.getManagementInformations(ManagementInformationType.cityName),
      ]);

      setState(() {
        _researchers = results[0].items;
        _supervisors = results[1].items;
        _cities = results[2].items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      // Check if user rejected participation
      if (_isApproved == false) {
        await _handleRejection();
      } else {
        // Navigate to survey details with the selected values
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SurveyDetailsScreen(
              surveyId: widget.surveyId,
            ),
            settings: RouteSettings(
              arguments: {
                'surveyId': widget.surveyId,
                'surveyCode': widget.surveyCode,
                'researcherName': _selectedResearcher?.name,
                'supervisorName': _selectedSupervisor?.name,
                'cityName': _selectedCity?.name,
                'neighborhoodName': _neighborhoodController.text.trim(),
                'streetName': _streetController.text.trim(),
                'isApproved': _isApproved,
                'rejectReason': _isApproved == false ? _rejectReasonController.text.trim() : null,
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleRejection() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create completed survey answers with rejection
      final surveyAnswers = SurveyAnswersModel(
        surveyId: widget.surveyId,
        surveyCode: widget.surveyCode,
        answers: [], // No answers - rejected
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        isDraft: false,
        researcherName: _selectedResearcher?.name,
        supervisorName: _selectedSupervisor?.name,
        cityName: _selectedCity?.name,
        neighborhoodName: _neighborhoodController.text.trim(),
        streetName: _streetController.text.trim(),
        isApproved: false,
        rejectReason: _rejectReasonController.text.trim(),
      );

      // Try to get survey from cache first
      final cachedSurveyJson = HiveService.getData<String>(
        boxName: HiveService.surveyDetailsBox,
        key: 'survey_${widget.surveyId}',
      );

      SurveyModel? survey;
      
      if (cachedSurveyJson != null) {
        // Use cached survey
        final jsonMap = jsonDecode(cachedSurveyJson) as Map<String, dynamic>;
        survey = SurveyModel.fromJson(jsonMap);
        print('✅ Using cached survey for rejection export');
      } else {
        // Try to fetch from API
        try {
          final dio = Dio(BaseOptions(baseUrl: 'http://45.94.209.137:8080/api'));
          final response = await dio.get('/Surveys/${widget.surveyId}');
          
          if (response.statusCode == 200 && response.data['errorCode'] == 0) {
            survey = SurveyModel.fromJson(response.data['data']);
            print('✅ Fetched survey from API for rejection export');
          }
        } catch (apiError) {
          print('⚠️ Could not fetch survey from API: $apiError');
        }
      }

      if (survey != null) {
        // Export to Excel
        final excelService = ExcelExportService();
        await excelService.exportSurveyToExcel(
          survey: survey,
          surveyAnswers: surveyAnswers,
        );
        print('✅ Excel exported successfully for rejection');
      } else {
        // Save to Hive anyway even if Excel export fails
        await HiveService.saveData(
          boxName: HiveService.answersBox,
          key: 'survey_answers_${widget.surveyId}',
          value: jsonEncode(surveyAnswers.toJson()),
        );
        print('💾 Saved rejection to Hive (Excel export skipped - survey not found)');
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.orange, size: 48),
            title: const Text('تم تسجيل عدم القبول'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  survey != null 
                      ? 'تم حفظ البيانات بنجاح في ملف Excel'
                      : 'تم حفظ البيانات بنجاح (سيتم التصدير لاحقاً)',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'السبب: ${_rejectReasonController.text.trim()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to surveys list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff25935F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _handleRejection: $e');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('معلومات ما قبل الاستبيان'),
          centerTitle: true,
          backgroundColor: Color(0xff25935F),
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff25935F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Header
                        const Card(
                          color: Color(0xff25935F),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, size: 48, color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  'يرجى اختيار المعلومات التالية قبل البدء',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Researcher Name
                        _buildDropdownCard(
                          title: 'اسم الباحث',
                          icon: Icons.person,
                          items: _researchers,
                          selectedValue: _selectedResearcher,
                          onChanged: (value) {
                            setState(() {
                              _selectedResearcher = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'يرجى اختيار اسم الباحث';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Supervisor Name
                        _buildDropdownCard(
                          title: 'اسم المشرف',
                          icon: Icons.supervisor_account,
                          items: _supervisors,
                          selectedValue: _selectedSupervisor,
                          onChanged: (value) {
                            setState(() {
                              _selectedSupervisor = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'يرجى اختيار اسم المشرف';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // City Name
                        _buildDropdownCard(
                          title: 'اسم المدينة',
                          icon: Icons.location_city,
                          items: _cities,
                          selectedValue: _selectedCity,
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'يرجى اختيار اسم المدينة';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Neighborhood Name
                        _buildTextFieldCard(
                          title: 'اسم الحى / القرية',
                          icon: Icons.home_work,
                          controller: _neighborhoodController,
                          hintText: 'أدخل اسم الحى أو القرية',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم الحى / القرية';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Street Name
                        _buildTextFieldCard(
                          title: 'اسم الشارع',
                          icon: Icons.signpost,
                          controller: _streetController,
                          hintText: 'أدخل اسم الشارع',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم الشارع';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Approval Status
                        _buildApprovalCard(),
                        
                        // Reject Reason (conditional)
                        if (_isApproved == false) ...[
                          const SizedBox(height: 16),
                          _buildTextFieldCard(
                            title: 'سبب عدم القبول',
                            icon: Icons.error_outline,
                            controller: _rejectReasonController,
                            hintText: 'أدخل سبب عدم القبول',
                            maxLines: 3,
                            validator: (value) {
                              if (_isApproved == false && (value == null || value.trim().isEmpty)) {
                                return 'يرجى إدخال سبب عدم القبول';
                              }
                              return null;
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Continue Button
                        ElevatedButton(
                          onPressed: _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff25935F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'المتابعة',
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
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required String title,
    required IconData icon,
    required List<ManagementInformationModel> items,
    required ManagementInformationModel? selectedValue,
    required void Function(ManagementInformationModel?) onChanged,
    required String? Function(ManagementInformationModel?) validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xff25935F).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Color(0xff25935F), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedValue != null ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ManagementInformationModel>(
              value: selectedValue,
              decoration: InputDecoration(
                hintText: 'اختر $title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xff25935F), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: onChanged,
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xff25935F).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Color(0xff25935F), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.text.isNotEmpty ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xff25935F), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: validator,
              onChanged: (value) {
                setState(() {}); // Update red/green circle
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xff25935F).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Color(0xff25935F), size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'قبول المشاركة في البحث الميداني',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isApproved != null ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    label: 'قبل',
                    value: true,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionButton(
                    label: 'لم يقبل',
                    value: false,
                    icon: Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool value,
    required IconData icon,
  }) {
    final isSelected = _isApproved == value;

    return InkWell(
      onTap: () {
        setState(() {
          _isApproved = value;
          if (value == true) {
            // Clear reject reason if approved
            _rejectReasonController.clear();
          }
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
