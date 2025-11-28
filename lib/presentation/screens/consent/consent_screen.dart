import 'package:flutter/material.dart';
import 'package:survey/presentation/screens/survey_details/survey_details_screen.dart';
import 'package:geolocator/geolocator.dart';

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
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خدمات الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم رفض إذن الوصول للموقع'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('إذن الموقع مرفوض بشكل دائم. يرجى تفعيله من إعدادات التطبيق.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Try to get last known position first (faster)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      
      Position finalPosition;
      
      // If no last known position, get current position
      if (lastPosition != null) {
        finalPosition = lastPosition;
        print('📍 Using last known position');
      } else {
        print('📍 Getting current position...');
        try {
          // Try medium accuracy first
          finalPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 15),
            ),
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('timeout_medium');
            },
          );
        } catch (e) {
          if (e.toString().contains('timeout_medium')) {
            print('⚠️ Medium accuracy timeout, trying low accuracy...');
            // Fallback to low accuracy (faster)
            finalPosition = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 10),
              ),
            ).timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception('timeout');
              },
            );
          } else {
            rethrow;
          }
        }
      }

      if (mounted) {
        setState(() {
          _latitude = finalPosition.latitude;
          _longitude = finalPosition.longitude;
          _isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديد الموقع بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        
        String errorMessage;
        if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
          errorMessage = 'لم نتمكن من تحديد الموقع.\n\nيمكنك:\n• المحاولة مرة أخرى\n• أو المتابعة بدون تحديد الموقع';
        } else {
          errorMessage = 'حدث خطأ أثناء تحديد الموقع.\nيمكنك المتابعة بدون تحديد الموقع.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'حسناً',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _continue() {
    // Validate that user selected an option
    if (_isApproved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار أحد الخيارات (أقبل / لا أقبل)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate reject reason if rejected
    if (_isApproved == false && _rejectReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ذكر سبب عدم الموافقة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
            'latitude': _latitude,
            'longitude': _longitude,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff25935F),
          title: const Text(
            'قبول الاستبيان',
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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Text
                    Text(
                      'عزيزي المشارك، أنا الباحث ${widget.researcherName ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff25935F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Body Text
                    const Text(
                      'أعمل ضمن فريق المسح الميداني للمرصد الحضري لمنطقة الباحة، والذي يهدف لرصد بيانات التنمية الحضرية والأحوال المعيشية للأسر، وذلك لإنتاج المؤشرات التي تدعم إعداد خطط وبرامج تنموية، تسهم في رفع وتحسين جودة الحياة بمنطقة الباحة والارتقاء بمستوى خدماتها الأساسية، علماً بأنه ليس مطلوب منك الإدلاء بأسماء الأشخاص، وسيتم التعامل مع جميع المعلومات التي ستقدمونها بسرية تامة لأغراض التخطيط والتحليل العلمي للمرصد الحضري.',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.8,
                        color: Color(0xFF2D5A52), // Darker green/blue text like image
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'شاكرين ومقدرين تعاونكم معنا.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xff25935F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Location Picker Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xff25935F).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xff25935F),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'تحديد الموقع الجغرافي',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '(اختياري)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _latitude != null && _longitude != null
                                      ? const Color(0xff4CAF50)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_latitude != null && _longitude != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'تم تحديد الموقع',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'خط العرض: ${_latitude!.toStringAsFixed(6)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  Text(
                                    'خط الطول: ${_longitude!.toStringAsFixed(6)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ElevatedButton.icon(
                            onPressed: _isLoadingLocation ? null : _pickLocation,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(_latitude != null ? Icons.refresh : Icons.my_location),
                            label: Text(_isLoadingLocation
                                ? 'جاري تحديد الموقع...'
                                : _latitude != null
                                    ? 'إعادة تحديد الموقع'
                                    : 'تحديد الموقع الحالي'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff25935F),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          if (_latitude == null && _longitude == null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'يمكنك المتابعة بدون تحديد الموقع إذا واجهت صعوبة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Question Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'قبول المشاركة في البحث الميداني',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isApproved == null 
                                      ? Colors.grey 
                                      : (_isApproved! ? const Color(0xff4CAF50) : Colors.red),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اختر إجابة واحدة:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Radio Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<bool>(
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
                                    const Text('أقبل'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<bool>(
                                      value: false,
                                      groupValue: _isApproved,
                                      onChanged: (value) {
                                        setState(() {
                                          _isApproved = value;
                                        });
                                      },
                                      activeColor: const Color(0xff25935F),
                                    ),
                                    const Text('لا أقبل'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Reject Reason Field (only if rejected)
                          if (_isApproved == false) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _rejectReasonController,
                              decoration: InputDecoration(
                                labelText: 'سبب عدم الموافقة *',
                                hintText: 'يرجى ذكر سبب عدم الموافقة',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              validator: (value) {
                                if (_isApproved == false && (value == null || value.trim().isEmpty)) {
                                  return 'يرجى ذكر سبب عدم الموافقة';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Button
            InkWell(
              onTap: _isApproved != null ? _continue : null,
              child: Container(
                width: double.infinity,
                height: 60,
                color: _isApproved != null 
                    ? const Color(0xff25935F) 
                    : Colors.grey.shade400,
                alignment: Alignment.center,
                child: const Text(
                  'متابعة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
