import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:survey/data/models/management_information_model.dart';
import 'package:survey/data/datasources/management_information_remote_datasource.dart';
import 'package:survey/data/datasources/local/management_information_local_datasource.dart';
import 'package:survey/presentation/screens/consent/consent_screen.dart';
import 'package:dio/dio.dart';

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

  ManagementInformationModel? _selectedResearcher;
  ManagementInformationModel? _selectedSupervisor;
  ManagementInformationModel? _selectedCity;

  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  List<ManagementInformationModel> _researchers = [];
  List<ManagementInformationModel> _supervisors = [];
  List<ManagementInformationModel> _cities = [];

  bool _isLoading = true;
  String? _errorMessage;

  late ManagementInformationRemoteDataSource _remoteDataSource;
  late ManagementInformationLocalDataSource _localDataSource;

  @override
  void initState() {
    super.initState();
    // Initialize data sources
    final dio = Dio(BaseOptions(baseUrl: 'http://45.94.209.137:8080/api'));
    _remoteDataSource = ManagementInformationRemoteDataSourceImpl(dio: dio);
    _localDataSource = ManagementInformationLocalDataSourceImpl();
    _loadData();
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection =
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      List<ManagementInformationResponse> results;

      if (hasConnection) {
        // Try to fetch from remote
        try {
          results = await Future.wait([
            _remoteDataSource.getManagementInformations(
              ManagementInformationType.researcherName,
            ),
            _remoteDataSource.getManagementInformations(
              ManagementInformationType.supervisorName,
            ),
            _remoteDataSource.getManagementInformations(
              ManagementInformationType.cityName,
            ),
          ]);

          // Cache the results
          await Future.wait([
            _localDataSource.cacheManagementInformations(
              ManagementInformationType.researcherName,
              results[0],
            ),
            _localDataSource.cacheManagementInformations(
              ManagementInformationType.supervisorName,
              results[1],
            ),
            _localDataSource.cacheManagementInformations(
              ManagementInformationType.cityName,
              results[2],
            ),
          ]);

          //print('✅ Data fetched from API and cached');
        } catch (e) {
          //print('⚠️ API failed, trying cache: $e');
          // If API fails, try cache
          results = await _loadFromCache();
        }
      } else {
        //print('📡 No internet, loading from cache');
        // No connection, use cache
        results = await _loadFromCache();
      }

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

  Future<List<ManagementInformationResponse>> _loadFromCache() async {
    final researchers = await _localDataSource.getCachedManagementInformations(
      ManagementInformationType.researcherName,
    );
    final supervisors = await _localDataSource.getCachedManagementInformations(
      ManagementInformationType.supervisorName,
    );
    final cities = await _localDataSource.getCachedManagementInformations(
      ManagementInformationType.cityName,
    );

    if (researchers == null || supervisors == null || cities == null) {
      throw Exception('لا توجد بيانات محفوظة. يرجى الاتصال بالإنترنت أولاً.');
    }

    return [researchers, supervisors, cities];
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      // Navigate to consent screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsentScreen(
            surveyId: widget.surveyId,
            surveyCode: widget.surveyCode,
            researcherName: _selectedResearcher?.name,
            supervisorName: _selectedSupervisor?.name,
            cityName: _selectedCity?.name,
            researcherId: _selectedResearcher?.id,
            supervisorId: _selectedSupervisor?.id,
            cityId: _selectedCity?.id,
            neighborhoodName: _neighborhoodController.text.trim(),
            streetName: _streetController.text.trim(),
            startTime: widget.startTime,
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
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
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
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.white,
                                ),
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

                        // Researcher Name (only show if has data)
                        if (_researchers.isNotEmpty) ...[
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
                        ],

                        // Supervisor Name (only show if has data)
                        if (_supervisors.isNotEmpty) ...[
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
                        ],

                        // City Name (Radio Buttons - only show if has data)
                        if (_cities.isNotEmpty) Card(
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
                                      child: const Icon(Icons.location_city, color: Color(0xff25935F), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'اسم المدينة',
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
                                        color: _selectedCity != null ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_cities.isEmpty)
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
                                if (_selectedCity == null)
                                  // Hidden validator to ensure selection
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
                        const SizedBox(height: 45),
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
              isExpanded: true,
              decoration: InputDecoration(
                hintText: ' $title',
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
                    color: Color(0xff25935F),
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
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
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
                    color: controller.text.isNotEmpty
                        ? Colors.green
                        : Colors.red,
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
                    color: Color(0xff25935F),
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
              onChanged: (value) {
                setState(() {}); // Update red/green circle
              },
            ),
          ],
        ),
      ),
    );
  }
}
