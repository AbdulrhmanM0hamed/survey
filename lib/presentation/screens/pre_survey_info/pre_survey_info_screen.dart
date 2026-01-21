import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:survey/data/models/management_information_model.dart';
import 'package:survey/data/models/lookup_model.dart';
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

  // Governorates selection
  LookupModel? _selectedGovernorate;
  List<LookupModel> _governorates = [];
  bool _isLoadingGovernorates = true;
  String? _governoratesError;

  // Areas selection
  LookupModel? _selectedArea;
  List<LookupModel> _areas = [];
  bool _isLoadingAreas = false;
  String? _areasError;

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
    _remoteDataSource = ManagementInformationRemoteDataSourceImpl(
      dioClient: Injection.dioClient,
    );
    _localDataSource = ManagementInformationLocalDataSourceImpl();
    _loadGovernorates();
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

  Future<bool> _hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
  }

  Future<void> _loadGovernorates() async {
    setState(() {
      _isLoadingGovernorates = true;
      _governoratesError = null;
    });

    try {
      final hasConnection = await _hasConnection();
      LookupResponse? response;

      if (hasConnection) {
        try {
          response = await _remoteDataSource.getGovernorates();
          await _localDataSource.cacheGovernorates(response);
        } catch (e) {
          response = await _localDataSource.getCachedGovernorates();
        }
      } else {
        response = await _localDataSource.getCachedGovernorates();
      }

      setState(() {
        _governorates = response?.items ?? [];
        _isLoadingGovernorates = false;
      });
    } catch (e) {
      setState(() {
        _governoratesError = 'فشل تحميل المحافظات';
        _isLoadingGovernorates = false;
      });
    }
  }

  Future<void> _loadAreas(int governorateId) async {
    setState(() {
      _isLoadingAreas = true;
      _areasError = null;
      _areas = [];
      _selectedArea = null;
    });

    try {
      final hasConnection = await _hasConnection();
      LookupResponse? response;

      if (hasConnection) {
        try {
          response = await _remoteDataSource.getAreas(governorateId);
          await _localDataSource.cacheAreas(governorateId, response);
        } catch (e) {
          response = await _localDataSource.getCachedAreas(governorateId);
        }
      } else {
        response = await _localDataSource.getCachedAreas(governorateId);
      }

      setState(() {
        _areas = response?.items ?? [];
        _isLoadingAreas = false;
      });
    } catch (e) {
      setState(() {
        _areasError = 'فشل تحميل المناطق';
        _isLoadingAreas = false;
      });
    }
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
      _citiesError = null;
    });

    try {
      final hasConnection = await _hasConnection();
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
          citiesResponse = await _localDataSource
              .getCachedManagementInformations(
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
            governorateId: _selectedGovernorate!.id,
            areaId: _selectedArea!.id,
            governorateName: _selectedGovernorate!.name,
            areaName: _selectedArea!.name,
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
          backgroundColor: const Color(0xffA93538),
          foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              const Card(
                color: Color(0xffA93538),
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

              // Governorate Selection
              _buildSelectionCard<LookupModel>(
                title: 'المحافظة',
                icon: Icons.map,
                items: _governorates,
                selectedItem: _selectedGovernorate,
                isLoading: _isLoadingGovernorates,
                error: _governoratesError,
                onRetry: _loadGovernorates,
                onChanged: (value) {
                  setState(() {
                    _selectedGovernorate = value;
                    _selectedArea = null;
                    _areas = [];
                  });
                  if (value != null) {
                    _loadAreas(value.id);
                  }
                },
                itemLabel: (item) => item.name,
                emptyMessage: 'لا توجد محافظات متاحة',
                validationMessage: 'يرجى اختيار المحافظة',
              ),
              const SizedBox(height: 16),

              // Area Selection (Dependent on Governorate)
              if (_selectedGovernorate != null) ...[
                _buildSelectionCard<LookupModel>(
                  title: 'المنطقة',
                  icon: Icons.location_on_outlined,
                  items: _areas,
                  selectedItem: _selectedArea,
                  isLoading: _isLoadingAreas,
                  error: _areasError,
                  onRetry: () => _loadAreas(_selectedGovernorate!.id),
                  onChanged: (value) {
                    setState(() {
                      _selectedArea = value;
                    });
                  },
                  itemLabel: (item) => item.name,
                  emptyMessage: 'لا توجد مناطق متاحة',
                  validationMessage: 'يرجى اختيار المنطقة',
                ),
                const SizedBox(height: 16),
              ],

              // Neighborhood Name
              _buildTextFieldCard(
                title: 'اسم الحى / القرية',
                icon: Icons.home_work,
                controller: _neighborhoodController,
                hintText: 'أدخل اسم الحى أو القرية',
                isOptional: true,
                showIndicator: false, // إخفاء النقطة
                validator: (value) {
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
                isOptional: true,
                showIndicator: false, // إخفاء النقطة
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Building Selection Section Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffA93538), Color(0xffA93538)],
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
                  backgroundColor: const Color(0xffA93538),
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
              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard<T>({
    required String title,
    required IconData icon,
    required List<T> items,
    required T? selectedItem,
    required bool isLoading,
    required String? error,
    required VoidCallback onRetry,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    required String emptyMessage,
    required String validationMessage,
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
                    color: const Color(0xffA93538).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xffA93538), size: 24),
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
                    color: selectedItem != null ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
    
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Center(
                child: Column(
                  children: [
                    Text(error, style: const TextStyle(color: Colors.red)),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(emptyMessage),
              )
            else
              // عرض الخيارات في Grid (شبكة)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عمودين في كل صف
                  childAspectRatio: 3.5, // نسبة العرض للارتفاع
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedItem == item;
                  
                  return InkWell(
                    onTap: () => onChanged(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xffA93538) 
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected 
                            ? const Color(0xffA93538).withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              itemLabel(item),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected 
                                    ? const Color(0xffA93538)
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xffA93538)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: isSelected 
                                  ? const Color(0xffA93538)
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (selectedItem == null && !isLoading && items.isNotEmpty)
              FormField<T>(
                validator: (value) {
                  if (selectedItem == null) return validationMessage;
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
    bool isOptional = false,
    bool showIndicator = true, // معامل جديد للتحكم في إظهار النقطة
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
                    color: const Color(0xffA93538).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xffA93538), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isOptional) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(اختياري)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
                const Spacer(),
                if (showIndicator) // إظهار النقطة فقط إذا كان showIndicator = true
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.text.isNotEmpty
                          ? Colors.green
                          : (isOptional ? Colors.grey.shade400 : Colors.red),
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
                  borderSide: const BorderSide(
                    color: Color(0xffA93538),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                    color: const Color(0xffA93538).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xffA93538), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
                  borderSide: const BorderSide(
                    color: Color(0xffA93538),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: validator,
              onChanged: onChanged,
            ),
            if (selectedValue != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffA93538).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xffA93538).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$selectedLabel: ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xffA93538),
                      ),
                    ),
                    Text(
                      '$selectedValue',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffA93538),
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
