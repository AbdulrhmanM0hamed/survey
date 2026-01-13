import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:survey/data/models/management_information_model.dart';
import 'package:survey/data/datasources/management_information_remote_datasource.dart';
import 'package:survey/data/datasources/local/management_information_local_datasource.dart';
import 'package:survey/presentation/screens/consent/consent_screen.dart';
import 'package:survey/core/di/injection.dart';

class PreSurveyInfoScreen extends StatefulWidget {
  final int surveyId;
  final String surveyCode;
  final DateTime? startTime;

  const PreSurveyInfoScreen({
    super.key,
    required this.surveyId,
    required this.surveyCode,
    this.startTime,
  });

  @override
  State<PreSurveyInfoScreen> createState() => _PreSurveyInfoScreenState();
}

class _PreSurveyInfoScreenState extends State<PreSurveyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _random = Random();

  // City selection
  ManagementInformationModel? _selectedCity;
  List<ManagementInformationModel> _cities = [];
  bool _isLoadingCities = true;
  String? _citiesError;

  // Text Controllers
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _apartmentsController = TextEditingController();

  // Random selections for building
  int? _selectedFloor;
  int? _selectedApartment;

  late ManagementInformationRemoteDataSource _remoteDataSource;
  late ManagementInformationLocalDataSource _localDataSource;

  @override
  void initState() {
    super.initState();
    _remoteDataSource = ManagementInformationRemoteDataSourceImpl(dioClient: Injection.dioClient);
    _localDataSource = ManagementInformationLocalDataSourceImpl();
    _loadCities();
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _streetController.dispose();
    _floorsController.dispose();
    _apartmentsController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
      _citiesError = null;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection =
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      ManagementInformationResponse? citiesResponse;

      if (hasConnection) {
        try {
          citiesResponse = await _remoteDataSource.getManagementInformations(
            ManagementInformationType.cityName,
          );
          await _localDataSource.cacheManagementInformations(
            ManagementInformationType.cityName,
            citiesResponse,
          );
        } catch (e) {
          citiesResponse = await _localDataSource.getCachedManagementInformations(
            ManagementInformationType.cityName,
          );
        }
      } else {
        citiesResponse = await _localDataSource.getCachedManagementInformations(
          ManagementInformationType.cityName,
        );
      }

      setState(() {
        _cities = citiesResponse?.items ?? [];
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        _citiesError = 'فشل تحميل المدن';
        _isLoadingCities = false;
      });
    }
  }

  void _generateRandomFloor() {
    final floors = int.tryParse(_floorsController.text);
    if (floors != null && floors > 0) {
      setState(() {
        _selectedFloor = _random.nextInt(floors) + 1;
      });
    }
  }

  void _generateRandomApartment() {
    final apartments = int.tryParse(_apartmentsController.text);
    if (apartments != null && apartments > 0) {
      setState(() {
        _selectedApartment = _random.nextInt(apartments) + 1;
      });
    }
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsentScreen(
            surveyId: widget.surveyId,
            surveyCode: widget.surveyCode,
            cityName: _selectedCity?.name,
            cityId: _selectedCity?.id,
            neighborhoodName: _neighborhoodController.text.trim(),
            streetName: _streetController.text.trim(),
            startTime: widget.startTime,
            buildingFloorsCount: int.tryParse(_floorsController.text),
            apartmentsPerFloor: int.tryParse(_apartmentsController.text),
            selectedFloor: _selectedFloor,
            selectedApartment: _selectedApartment,
          ),
        ),
      );
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
          backgroundColor: const Color(0xff25935F),
          foregroundColor: Colors.white,
        ),
        body: Form(
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
                        'يرجى إدخال المعلومات التالية قبل البدء',
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

              // City Selection (Radio Buttons)
              _buildCitySelectionCard(),
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
              const SizedBox(height: 32),

              // Building Selection Section Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff25935F), Color(0xff1d7a4d)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.apartment, size: 32, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تحديد الشقة المراد زيارتها عشوائياً',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Floors Count Field
              _buildNumberFieldCard(
                title: 'عدد الأدوار في المبنى',
                icon: Icons.layers,
                controller: _floorsController,
                hintText: 'أدخل العدد',
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = null;
                  });
                  if (value.isNotEmpty) {
                    _generateRandomFloor();
                  }
                },
                selectedValue: _selectedFloor,
                selectedLabel: 'الدور المختار',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال عدد الأدوار';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'يرجى إدخال رقم صحيح أكبر من صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Apartments Count Field
              _buildNumberFieldCard(
                title: 'عدد الشقق في الدور',
                icon: Icons.door_front_door,
                controller: _apartmentsController,
                hintText: 'أدخل العدد',
                onChanged: (value) {
                  setState(() {
                    _selectedApartment = null;
                  });
                  if (value.isNotEmpty) {
                    _generateRandomApartment();
                  }
                },
                selectedValue: _selectedApartment,
                selectedLabel: 'الشقة المختارة',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال عدد الشقق';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'يرجى إدخال رقم صحيح أكبر من صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Continue Button
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff25935F),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitySelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: const Color(0xff25935F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_city, color: Color(0xff25935F), size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'اسم المدينة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedCity != null ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingCities)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_citiesError != null)
              Center(
                child: Column(
                  children: [
                    Text(_citiesError!, style: const TextStyle(color: Colors.red)),
                    TextButton(
                      onPressed: _loadCities,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else if (_cities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('لا توجد مدن متاحة'),
              )
            else
              ..._cities.map((city) {
                return RadioListTile<ManagementInformationModel>(
                  title: Text(city.name),
                  value: city,
                  groupValue: _selectedCity,
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
                  activeColor: const Color(0xff25935F),
                  contentPadding: EdgeInsets.zero,
                );
              }),
            if (_selectedCity == null && !_isLoadingCities && _cities.isNotEmpty)
              FormField<ManagementInformationModel>(
                validator: (value) {
                  if (_selectedCity == null) return 'يرجى اختيار المدينة';
                  return null;
                },
                builder: (state) {
                  if (state.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 12.0),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: const Color(0xff25935F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xff25935F), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: validator,
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberFieldCard({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    required void Function(String) onChanged,
    required int? selectedValue,
    required String selectedLabel,
    required String? Function(String?) validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: const Color(0xff25935F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xff25935F), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: validator,
              onChanged: onChanged,
            ),
            if (selectedValue != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff25935F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xff25935F).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$selectedLabel: ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff25935F),
                      ),
                    ),
                    Text(
                      '$selectedValue',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff25935F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
