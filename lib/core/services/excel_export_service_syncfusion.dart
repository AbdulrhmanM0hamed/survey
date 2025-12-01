import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart' as ExcelPkg;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:survey/core/enums/question_type.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/question_model.dart';
import 'package:survey/data/models/survey_model.dart';

class ExcelExportServiceSyncfusion {
  /// Sheet name for responses
  static const String _sheetName = 'الاستبيانات';
  
  /// Header structure cache
  List<Map<String, dynamic>> _headerStructure = [];
  
  /// Export survey answers to Excel with image support using Syncfusion
  /// Creates a new file per survey or appends to existing one
  Future<String?> exportSurveyToExcel({
    required SurveyModel survey,
    required SurveyAnswersModel surveyAnswers,
    Map<int, int>? groupRepetitions,
  }) async {
    //print('📊 Starting Syncfusion Excel export with images...');
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Get the file path - one file per day
      final directory = await _getExportDirectory();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'survey_${survey.id}_${survey.code}_$today.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      //print('📁 Using file: $fileName');
      //print('📍 Full path: $filePath');

      // Debug: Log all saved answers
      //print('📋 All saved answers (${surveyAnswers.answers.length} total):');
      for (final answer in surveyAnswers.answers) {
        //print('   Q${answer.questionId} (${answer.questionCode}): ${answer.value} (${answer.value.runtimeType})');
      }

      // Build header structure FIRST
      _buildHeaderStructure(survey, surveyAnswers, groupRepetitions);

      // Step 1: Read existing data if file exists (using excel package)
      // Store as Map (header text -> value) to handle header changes correctly
      List<Map<String, String>> existingData = []; // Store as header->value maps
      List<String> oldHeaders = [];
      Map<String, String> imageMap = {}; // Map of "row_col" -> base64
      
      if (await file.exists()) {
        //print('📂 File exists, reading old data with old header structure...');
        try {
          final bytes = await file.readAsBytes();
          final excel = ExcelPkg.Excel.decodeBytes(bytes);
          final sheet = excel.sheets[excel.getDefaultSheet()];
          
          if (sheet != null && sheet.maxRows > 0) {
            // First, read old headers
            for (int j = 0; j < 500; j++) { // Max 500 columns
              final cell = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: 0));
              final headerValue = cell.value?.toString() ?? '';
              if (headerValue.isEmpty) break;
              oldHeaders.add(headerValue);
            }
            //print('📊 Old file has ${oldHeaders.length} columns');
            
            // Read data rows mapped by old headers
            if (sheet.maxRows > 1) {
              for (int i = 1; i < sheet.maxRows; i++) {
                Map<String, String> rowData = {};
                for (int j = 0; j < oldHeaders.length; j++) {
                  final cell = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i));
                  final cellValue = cell.value?.toString() ?? '';
                  rowData[oldHeaders[j]] = cellValue;
                  
                  // Check if this is an image column - match by header structure
                  final newHeaderIndex = _findHeaderIndexByText(oldHeaders[j]);
                  if (newHeaderIndex >= 0 && newHeaderIndex < _headerStructure.length) {
                    final header = _headerStructure[newHeaderIndex];
                    if (header['type'] != 'basic') {
                      final questionId = header['questionId'];
                      final question = _findQuestion(survey, questionId);
                      
                      if (question != null && (question.type == 'image' || question.type == '9' || question.type == 9)) {
                        final instanceIndex = header['instanceIndex'] ?? 0;
                        final imagePath = '${directory.path}/survey_${survey.id}_images/Q${questionId}_${instanceIndex}_row${i}.jpg';
                        final imageFile = File(imagePath);
                        
                        if (await imageFile.exists()) {
                          final imageBytes = await imageFile.readAsBytes();
                          final base64Image = base64Encode(imageBytes);
                          // Map to new column position
                          imageMap['${existingData.length + 2}_${newHeaderIndex + 1}'] = base64Image;
                          //print('📸 Found saved image: $imagePath');
                        }
                      }
                    }
                  }
                }
                existingData.add(rowData);
              }
            }
            //print('📊 Read ${existingData.length} existing rows with ${imageMap.length} images');
          }
        } catch (e) {
          //print('⚠️ Could not read existing file: $e');
        }
      }

      // Step 2: Create new Syncfusion workbook
      //print('📝 Creating new Syncfusion workbook...');
      final Workbook workbook = Workbook();
      final Worksheet worksheet = workbook.worksheets[0];
      worksheet.name = _sheetName;
      
      // Enable Right-to-Left (RTL) for Arabic text
      worksheet.isRightToLeft = true;
      //print('✅ RTL mode enabled for Arabic text');

      // Step 3: Add headers
      await _addHeadersSyncfusion(worksheet, survey, surveyAnswers);

      // Step 4: Add existing data with EXACT HEADER MATCH and re-insert images
      int currentRow = 2; // Start after header
      for (int rowIdx = 0; rowIdx < existingData.length; rowIdx++) {
        final oldRowData = existingData[rowIdx];
        
        // Write data to new columns using exact header match
        for (int col = 0; col < _headerStructure.length; col++) {
          final newHeader = _headerStructure[col];
          final newHeaderText = _formatHeaderText(newHeader);
          final cell = worksheet.getRangeByIndex(currentRow, col + 1);
          
          // Check if this cell should have an image
          final imageKey = '${currentRow}_${col + 1}';
          if (imageMap.containsKey(imageKey)) {
            // Re-insert the image
            //print('🖼️ Re-inserting image at row $currentRow, col ${col + 1}');
            await _insertImageToCell(worksheet, imageMap[imageKey]!, currentRow, col + 1);
          } else {
            // Regular text cell - use exact header match from old data
            String cellValue = '';
            if (oldRowData.containsKey(newHeaderText)) {
              cellValue = oldRowData[newHeaderText]!;
            }
            // If no exact match, leave empty (for new columns)
            cell.setText(cellValue);
          }
        }
        currentRow++;
      }
      //print('📋 Added ${existingData.length} existing rows with ${imageMap.length} images, matched to new ${_headerStructure.length} columns');

      // Step 5: Add new survey response with images
      await _addSurveyResponseSyncfusion(worksheet, survey, surveyAnswers, currentRow, directory: directory);

      // Step 6: Save workbook
      //print('💾 Saving workbook...');
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      
      await file.writeAsBytes(bytes);
      
      // Verify
      if (await file.exists()) {
        final fileSize = await file.length();
        //print('✅ Excel file saved! Size: $fileSize bytes');
        //print('📍 Location: ${file.path}');
      }
      
      return filePath;
    } catch (e, stackTrace) {
      //print('❌ Error exporting to Excel: $e');
      //print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get export directory based on platform
  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      // Use Download folder on Android
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      //print('📁 Export directory: ${directory.path}');
      return directory;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Build header structure from survey
  void _buildHeaderStructure(SurveyModel survey, SurveyAnswersModel surveyAnswers, Map<int, int>? groupRepetitions) {
    _headerStructure = [];
    _buildHeaderStructureInternal(survey, surveyAnswers, _headerStructure, groupRepetitions);
  }

  /// Internal method to build header structure
  void _buildHeaderStructureInternal(
    SurveyModel survey,
    SurveyAnswersModel surveyAnswers,
    List<Map<String, dynamic>> structure,
    Map<int, int>? groupRepetitions,
  ) {
    // Basic info columns
    structure.addAll([
      {'type': 'basic', 'text': 'رقم الاستجابة'},
      {'type': 'basic', 'text': 'كود الاستبيان'},
      {'type': 'basic', 'text': 'اسم الاستبيان'},
      {'type': 'basic', 'text': 'اسم الباحث'},
      {'type': 'basic', 'text': 'اسم المشرف'},
      {'type': 'basic', 'text': 'اسم المدينة'},
      {'type': 'basic', 'text': 'اسم الحى / القرية'},
      {'type': 'basic', 'text': 'اسم الشارع'},
      {'type': 'basic', 'text': 'قبول المشاركة'},
      {'type': 'basic', 'text': 'سبب عدم القبول'},
      {'type': 'basic', 'text': 'تاريخ البدء'},
      {'type': 'basic', 'text': 'تاريخ الإنهاء'},
      {'type': 'basic', 'text': 'الحالة'},
      {'type': 'basic', 'text': 'خط العرض (Latitude)'},
      {'type': 'basic', 'text': 'خط الطول (Longitude)'},
    ]);

    // Question columns
    // Groups and questions share the SAME order numbering in the survey
    // Merge them and sort by order to get correct Excel column order
    for (final section in survey.sections ?? []) {
      // Create combined list of groups and questions with their order
      final List<Map<String, dynamic>> items = [];
      
      for (final group in section.questionGroups) {
        items.add({'type': 'group', 'order': group.order, 'data': group});
      }
      
      for (final question in section.questions) {
        items.add({'type': 'question', 'order': question.order, 'data': question});
      }
      
      // Sort by order to get correct sequence
      // If order is equal, Questions come before Groups
      items.sort((a, b) {
        final orderA = a['order'] as int;
        final orderB = b['order'] as int;
        
        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        
        // Same order: Questions before Groups
        if (a['type'] == 'question' && b['type'] == 'group') {
          return -1; // a comes first
        } else if (a['type'] == 'group' && b['type'] == 'question') {
          return 1; // b comes first
        }
        
        return 0; // Same type, keep original order
      });
      
      // DYNAMIC REORDERING: Move groups to appear right after their triggering questions
      // This ensures related questions and groups are adjacent in Excel
      final Map<int, int> groupToQuestionMap = {}; // groupId -> triggering questionId
      
      // First pass: identify which groups should be moved after which questions
      for (final item in items) {
        if (item['type'] == 'group') {
          final group = item['data'];
          
          // Check if this group has a triggering question via targetConditions
          for (final condition in group.targetConditions) {
            if (condition.sourceQuestionId != null) {
              groupToQuestionMap[group.id] = condition.sourceQuestionId;
              //print('🔗 Group ${group.id} (${group.name}) should appear after Q${condition.sourceQuestionId}');
              break; // Use first triggering question
            }
          }
        }
      }
      
      // Second pass: build reordered list
      final List<Map<String, dynamic>> reorderedItems = [];
      final Set<int> processedGroupIds = {};
      
      for (final item in items) {
        // Skip groups that will be moved (they'll be added after their triggering question)
        if (item['type'] == 'group') {
          final group = item['data'];
          if (groupToQuestionMap.containsKey(group.id)) {
            continue; // Skip, will be added later
          }
        }
        
        reorderedItems.add(item);
        
        // If this is a question, add any groups triggered by it
        if (item['type'] == 'question') {
          final question = item['data'];
          
          // Find groups that this question triggers
          for (final otherItem in items) {
            if (otherItem['type'] == 'group') {
              final group = otherItem['data'];
              
              // Skip if already processed
              if (processedGroupIds.contains(group.id)) continue;
              
              // Check if this group should appear after current question
              if (groupToQuestionMap[group.id] == question.id) {
                reorderedItems.add(otherItem);
                processedGroupIds.add(group.id);
                //print('✅ Added Group ${group.id} after Q${question.id}');
              }
            }
          }
        }
      }
      
      // Replace items with reordered list
      items.clear();
      items.addAll(reorderedItems);
      
      // Process in sorted order
      for (final item in items) {
        if (item['type'] == 'group') {
          final group = item['data'];
          final fromMap = groupRepetitions?[group.id] ?? 0;
          final fromAnswers = _getMaxRepetitions(group.id, surveyAnswers);
          final maxRepetitions = fromMap > fromAnswers ? fromMap : fromAnswers;
          //print('📊 Group ${group.id} (${group.name}): order=${group.order}, fromMap=$fromMap, fromAnswers=$fromAnswers, using maxRepetitions=$maxRepetitions');
          //print('   Group has ${group.questions.length} questions');
          
          for (int i = 0; i < maxRepetitions; i++) {
            for (final question in group.questions) {
              //print('   📋 Adding group question to header: ${question.id} - ${question.code} - ${question.text.substring(0, question.text.length > 30 ? 30 : question.text.length)}...');
              structure.add({
                'type': 'group',
                'text': '${question.code} (${i + 1})',
                'fullText': '${question.text} (تكرار ${i + 1})',
                'questionId': question.id,
                'instanceIndex': i,
              });
            }
          }
        } else {
          final question = item['data'];
          //print('📋 Adding direct question to header: ${question.id} - ${question.code} - order=${question.order} - ${question.text.substring(0, question.text.length > 30 ? 30 : question.text.length)}...');
          structure.add({
            'type': 'direct',
            'text': question.code,
            'fullText': question.text,
            'questionId': question.id,
            'instanceIndex': null,
          });
        }
      }
    }
  }

  /// Get maximum repetitions for a group
  int _getMaxRepetitions(int groupId, SurveyAnswersModel surveyAnswers) {
    final groupAnswers = surveyAnswers.answers.where((a) => a.groupId == groupId).toList();
    if (groupAnswers.isEmpty) {
      // For groups with no answers, check if there are any repetitions set in the system
      // This should be coordinated with the ViewModel's _groupRepetitions
      // For now, return 0 for groups that have no saved answers
      //print('📊 Group $groupId has no saved answers, returning 0 repetitions');
      return 0;
    }
    
    final maxInstance = groupAnswers.map((a) => a.groupInstanceId ?? 0).reduce((a, b) => a > b ? a : b);
    final result = maxInstance + 1;
    //print('📊 Group $groupId has $result repetitions based on saved answers');
    return result;
  }

  /// Find question by ID in survey
  QuestionModel? _findQuestion(SurveyModel survey, int questionId) {
    for (final section in survey.sections ?? []) {
      for (final question in section.questions) {
        if (question.id == questionId) return question;
      }
      for (final group in section.questionGroups) {
        for (final question in group.questions) {
          if (question.id == questionId) return question;
        }
      }
    }
    return null;
  }

  /// Format answer value for display
  String _formatAnswerValue(dynamic value, QuestionModel? question) {
    if (value == null) return '';
    
    // Handle rating questions (type 6) - convert numbers to Arabic text
    if (question != null && question.questionType == QuestionType.rating) {
      final ratingMap = {
        1: 'غير راضي اطلاقا',
        2: 'غير راضي',
        3: 'محايد',
        4: 'راضي',
        5: 'راضي تماما',
        6: 'غير متوفر',
      };
      
      if (value is int && ratingMap.containsKey(value)) {
        return ratingMap[value]!;
      } else if (value is String) {
        final intValue = int.tryParse(value);
        if (intValue != null && ratingMap.containsKey(intValue)) {
          return ratingMap[intValue]!;
        }
      }
    }
    
    // Handle Yes/No questions (type 3) - convert boolean to Arabic text
    if (question != null && question.questionType == QuestionType.yesNo) {
      if (value is bool) {
        return value ? 'نعم' : 'لا';
      } else if (value is String) {
        if (value.toLowerCase() == 'true') return 'نعم';
        if (value.toLowerCase() == 'false') return 'لا';
      }
    }
    
    if (question != null && question.choices.isNotEmpty) {
      //print('🔍 Formatting value: "$value" for question ${question.id}');
      //print('   Available choices: ${question.choices.map((c) => '${c.code}="${c.label}"').join(', ')}');
      
      if (value is List) {
        return value.map((v) {
          // Try matching by code first, then by id
          var choice = question.choices.where((c) => c.code == v.toString()).firstOrNull;
          if (choice == null) {
            choice = question.choices.where((c) => c.id.toString() == v.toString()).firstOrNull;
          }
          final result = choice?.label ?? v.toString();
          //print('   Matched "$v" → "$result"');
          return result;
        }).join(', ');
      } else {
        // Try matching by code first, then by id
        var choice = question.choices.where((c) => c.code == value.toString()).firstOrNull;
        if (choice == null) {
          choice = question.choices.where((c) => c.id.toString() == value.toString()).firstOrNull;
        }
        final result = choice?.label ?? value.toString();
        //print('   Matched "$value" → "$result"');
        return result;
      }
    }
    
    if (value is List) {
      return value.map((v) => v.toString()).join(', ');
    }
    return value.toString();
  }

  /// Add headers using Syncfusion
  Future<void> _addHeadersSyncfusion(Worksheet worksheet, SurveyModel survey, SurveyAnswersModel surveyAnswers) async {
    for (int i = 0; i < _headerStructure.length; i++) {
      final header = _headerStructure[i];
      final cell = worksheet.getRangeByIndex(1, i + 1);
      cell.setText(header['fullText'] ?? header['text']);
      
      // Style header
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#4472C4';
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.hAlign = HAlignType.center;
      cell.cellStyle.vAlign = VAlignType.center;
    }
  }

  /// Add survey response with image support using Syncfusion
  Future<void> _addSurveyResponseSyncfusion(
    Worksheet worksheet,
    SurveyModel survey,
    SurveyAnswersModel surveyAnswers,
    int rowIndex,
    {required Directory directory}
  ) async {
    //print('➕ Adding new response at row $rowIndex');

    for (int colIndex = 0; colIndex < _headerStructure.length; colIndex++) {
      final header = _headerStructure[colIndex];
      final cell = worksheet.getRangeByIndex(rowIndex, colIndex + 1);

      if (header['type'] == 'basic') {
        // Handle basic info columns
        String cellValue = '';
        switch (header['text']) {
          case 'رقم الاستجابة':
            cellValue = surveyAnswers.surveyId.toString();
            break;
          case 'كود الاستبيان':
            cellValue = surveyAnswers.surveyCode;
            break;
          case 'اسم الاستبيان':
            cellValue = survey.name;
            break;
          case 'اسم الباحث':
            cellValue = surveyAnswers.researcherName ?? '';
            break;
          case 'اسم المشرف':
            cellValue = surveyAnswers.supervisorName ?? '';
            break;
          case 'اسم المدينة':
            cellValue = surveyAnswers.cityName ?? '';
            break;
          case 'اسم الحى / القرية':
            cellValue = surveyAnswers.neighborhoodName ?? '';
            if (cellValue.isNotEmpty) //print('🏘️ Writing Neighborhood: $cellValue');
            break;
          case 'اسم الشارع':
            cellValue = surveyAnswers.streetName ?? '';
            break;
          case 'خط العرض (Latitude)':
            cellValue = surveyAnswers.latitude?.toString() ?? '';
            if (cellValue.isNotEmpty) //print('🌍 Writing Latitude: $cellValue');
            break;
          case 'خط الطول (Longitude)':
            cellValue = surveyAnswers.longitude?.toString() ?? '';
            if (cellValue.isNotEmpty) //print('🌍 Writing Longitude: $cellValue');
            break;
          case 'قبول المشاركة':
            cellValue = surveyAnswers.isApproved == null 
                ? '' 
                : (surveyAnswers.isApproved! ? 'قبل' : 'لم يقبل');
            break;
          case 'سبب عدم القبول':
            cellValue = surveyAnswers.rejectReason ?? '';
            break;
          case 'تاريخ البدء':
            cellValue = DateFormat('yyyy-MM-dd HH:mm:ss').format(surveyAnswers.startedAt);
            break;
          case 'تاريخ الإنهاء':
            cellValue = surveyAnswers.completedAt != null
                ? DateFormat('yyyy-MM-dd HH:mm:ss').format(surveyAnswers.completedAt!)
                : '';
            break;
          case 'الحالة':
            cellValue = surveyAnswers.isDraft ? 'مسودة' : 'مكتمل';
            break;
        }
        cell.setText(cellValue);
      } else {
        // Handle question columns
        final questionId = header['questionId'];
        final instanceIndex = header['instanceIndex'];
        
        final answer = surveyAnswers.answers.firstWhere(
          (a) => a.questionId == questionId && 
                 (instanceIndex == null || a.groupInstanceId == instanceIndex),
          orElse: () => AnswerModel(
            questionId: questionId,
            questionCode: '',
            value: '',
            timestamp: DateTime.now(),
          ),
        );
        
        //print('🔍 Processing question $questionId (instance: $instanceIndex): answer value = ${answer.value}');

        if (answer.value != null && answer.value.toString().isNotEmpty) {
          final question = _findQuestion(survey, questionId);
          
          // Debug: Log question type
          if (question != null) {
            //print('🔍 Question ID: ${question.id}, Type: "${question.type}", Value length: ${answer.value.toString().length}');
          }
          
          // Check if this is an image question (type can be 'image' or 9)
          final isImageQuestion = question != null && 
              (question.type == 'image' || 
               question.type == '9' || 
               question.type == 9 ||
               answer.value.toString().startsWith('data:image'));
          
          if (isImageQuestion) {
            //print('🖼️ Detected image question! Inserting image...');
            
            // Save image as file for future re-insertion
            final imagesDir = Directory('${directory.path}/survey_${survey.id}_images');
            if (!await imagesDir.exists()) {
              await imagesDir.create(recursive: true);
            }
            
            final imagePath = '${imagesDir.path}/Q${questionId}_${instanceIndex ?? 0}_row${rowIndex}.jpg';
            try {
              String pureBase64 = answer.value.toString();
              if (pureBase64.startsWith('data:image')) {
                final commaIndex = pureBase64.indexOf(',');
                if (commaIndex != -1) {
                  pureBase64 = pureBase64.substring(commaIndex + 1);
                }
              }
              pureBase64 = pureBase64.replaceAll(RegExp(r'\s+'), '');
              final imageBytes = base64Decode(pureBase64);
              await File(imagePath).writeAsBytes(imageBytes);
              //print('💾 Saved image for future use: $imagePath');
            } catch (e) {
              //print('❌ Failed to save image file: $e');
            }
            
            // Insert actual image!
            await _insertImageToCell(worksheet, answer.value.toString(), rowIndex, colIndex + 1);
          } else {
            // Regular text value
            final cellValue = _formatAnswerValue(answer.value, question);
            cell.setText(cellValue);
          }
        }
      }
    }
  }

  /// Insert image into Excel cell using Syncfusion
  Future<void> _insertImageToCell(Worksheet worksheet, String base64String, int row, int col) async {
    try {
      //print('🖼️ Inserting image at row $row, col $col');
      
      // Remove data URI prefix if present
      String pureBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          pureBase64 = base64String.substring(commaIndex + 1);
        }
      }
      
      // Clean whitespace
      pureBase64 = pureBase64.replaceAll(RegExp(r'\s+'), '');
      
      // Decode to Uint8List
      final Uint8List imageBytes = base64Decode(pureBase64);
      //print('📦 Image size: ${imageBytes.length} bytes');
      
      // Set cell size for image
      worksheet.setRowHeightInPixels(row, 100);
      worksheet.setColumnWidthInPixels(col, 120);
      
      // Add image to worksheet
      final Picture picture = worksheet.pictures.addStream(row, col, imageBytes);
      picture.height = 95;
      picture.width = 115;
      
      //print('✅ Image inserted successfully');
    } catch (e) {
      //print('❌ Failed to insert image: $e');
      // Fallback: show error in cell
      final cell = worksheet.getRangeByIndex(row, col);
      cell.setText('[Image Error: $e]');
      cell.cellStyle.fontColor = '#FF0000';
    }
  }

  /// Add headers to Excel sheet using excel package (OLD - NOT USED)
  void _addHeadersExcel(ExcelPkg.Sheet sheet, SurveyModel survey, SurveyAnswersModel surveyAnswers) {
    _buildHeaderStructure(survey, surveyAnswers, null);
    
    for (int i = 0; i < _headerStructure.length; i++) {
      final header = _headerStructure[i];
      final cell = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = ExcelPkg.TextCellValue(header['fullText'] ?? header['text']);
      cell.cellStyle = ExcelPkg.CellStyle(
        bold: true,
        fontSize: 10,
        horizontalAlign: ExcelPkg.HorizontalAlign.Center,
        verticalAlign: ExcelPkg.VerticalAlign.Center,
      );
    }
  }

  /// Add survey response as new row using excel package
  Future<void> _addSurveyResponseExcel(
    ExcelPkg.Sheet sheet,
    SurveyModel survey,
    SurveyAnswersModel surveyAnswers,
    Directory directory,
  ) async {
    final rowIndex = sheet.maxRows;
    //print('➕ Adding new response at row $rowIndex');

    for (int colIndex = 0; colIndex < _headerStructure.length; colIndex++) {
      final header = _headerStructure[colIndex];
      String cellValue = '';

      if (header['type'] == 'basic') {
        // Handle basic info columns
        switch (header['text']) {
          case 'رقم الاستجابة':
            cellValue = surveyAnswers.surveyId.toString();
            break;
          case 'كود الاستبيان':
            cellValue = surveyAnswers.surveyCode;
            break;
          case 'اسم الاستبيان':
            cellValue = survey.name;
            break;
          case 'اسم الباحث':
            cellValue = surveyAnswers.researcherName ?? '';
            break;
          case 'اسم المشرف':
            cellValue = surveyAnswers.supervisorName ?? '';
            break;
          case 'اسم المدينة':
            cellValue = surveyAnswers.cityName ?? '';
            break;
          case 'اسم الحى / القرية':
            cellValue = surveyAnswers.neighborhoodName ?? '';
            if (cellValue.isNotEmpty) //print('🏘️ Writing Neighborhood: $cellValue');
            break;
          case 'اسم الشارع':
            cellValue = surveyAnswers.streetName ?? '';
            break;
          case 'خط العرض (Latitude)':
            cellValue = surveyAnswers.latitude?.toString() ?? '';
            if (cellValue.isNotEmpty) //print('🌍 Writing Latitude: $cellValue');
            break;
          case 'خط الطول (Longitude)':
            cellValue = surveyAnswers.longitude?.toString() ?? '';
            if (cellValue.isNotEmpty) //print('🌍 Writing Longitude: $cellValue');
            break;
          case 'قبول المشاركة':
            cellValue = surveyAnswers.isApproved == null 
                ? '' 
                : (surveyAnswers.isApproved! ? 'قبل' : 'لم يقبل');
            break;
          case 'سبب عدم القبول':
            cellValue = surveyAnswers.rejectReason ?? '';
            break;
          case 'تاريخ البدء':
            cellValue = DateFormat('yyyy-MM-dd HH:mm:ss').format(surveyAnswers.startedAt);
            break;
          case 'تاريخ الإنهاء':
            cellValue = surveyAnswers.completedAt != null
                ? DateFormat('yyyy-MM-dd HH:mm:ss').format(surveyAnswers.completedAt!)
                : '';
            break;
          case 'الحالة':
            cellValue = surveyAnswers.isDraft ? 'مسودة' : 'مكتمل';
            break;
        }
      } else {
        // Handle question columns
        final questionId = header['questionId'];
        final instanceIndex = header['instanceIndex'];
        
        final answer = surveyAnswers.answers.firstWhere(
          (a) => a.questionId == questionId && 
                 (instanceIndex == null || a.groupInstanceId == instanceIndex),
          orElse: () => AnswerModel(
            questionId: questionId,
            questionCode: '',
            value: '',
            timestamp: DateTime.now(),
          ),
        );

        // Find the question for this answer to format it properly
        final question = _findQuestion(survey, questionId);
        
        // Check if this is an image question
        final isImageQuestion = question != null && 
            (question.type == 'image' || 
             question.type == '9' || 
             question.type == 9 ||
             answer.value.toString().startsWith('data:image'));
        
        if (isImageQuestion && answer.value != null && answer.value.toString().isNotEmpty) {
          // Save image as file and put path in cell
          final imagePath = await _saveImageAsFile(directory, survey.id, questionId, instanceIndex ?? 0, answer.value.toString());
          cellValue = imagePath ?? '[Image Error]';
        } else {
          cellValue = _formatAnswerValue(answer.value, question);
        }
      }

      final cell = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));
      cell.value = ExcelPkg.TextCellValue(cellValue);
    }
  }

  /// Save image as file and return file path
  Future<String?> _saveImageAsFile(Directory directory, int surveyId, int questionId, int instanceIndex, String base64String) async {
    try {
      // Create images subfolder
      final imagesDir = Directory('${directory.path}/survey_${surveyId}_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Remove data URI prefix if present
      String pureBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          pureBase64 = base64String.substring(commaIndex + 1);
        }
      }
      
      // Clean whitespace
      pureBase64 = pureBase64.replaceAll(RegExp(r'\s+'), '');
      
      // Decode and save
      final imageBytes = base64Decode(pureBase64);
      final imagePath = '${imagesDir.path}/Q${questionId}_${instanceIndex}.jpg';
      await File(imagePath).writeAsBytes(imageBytes);
      //print('📸 Saved image: $imagePath');
      return imagePath;
    } catch (e) {
      //print('❌ Failed to save image: $e');
      return null;
    }
  }

  /// Save images as separate files in the same directory as Excel
  Future<void> _saveImagesAsSeparateFiles(Directory directory, SurveyModel survey, SurveyAnswersModel surveyAnswers) async {
    try {
      int imageCount = 0;
      
      // Create images subfolder
      final imagesDir = Directory('${directory.path}/survey_${survey.id}_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Find all image questions and save their answers
      for (final answer in surveyAnswers.answers) {
        final question = _findQuestion(survey, answer.questionId);
        
        if (question != null && question.type == 'image' && answer.value != null) {
          final base64String = answer.value.toString();
          if (base64String.isNotEmpty) {
            try {
              // Remove data URI prefix if present
              String pureBase64 = base64String;
              if (base64String.startsWith('data:image')) {
                final commaIndex = base64String.indexOf(',');
                if (commaIndex != -1) {
                  pureBase64 = base64String.substring(commaIndex + 1);
                }
              }
              
              // Clean whitespace
              pureBase64 = pureBase64.replaceAll(RegExp(r'\s+'), '');
              
              // Decode and save
              final imageBytes = base64Decode(pureBase64);
              final imagePath = '${imagesDir.path}/Q${question.id}_${answer.groupInstanceId ?? 0}.jpg';
              await File(imagePath).writeAsBytes(imageBytes);
              imageCount++;
              //print('📸 Saved image: $imagePath');
            } catch (e) {
              //print('⚠️ Failed to save image for Q${question.id}: $e');
            }
          }
        }
      }
      
      //print('✅ Saved $imageCount images to ${imagesDir.path}');
    } catch (e) {
      //print('❌ Error saving images: $e');
    }
  }

  /// Share Excel file
  Future<void> shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'ملف Excel للاستبيان',
      );
    } catch (e) {
      //print('❌ Error sharing file: $e');
    }
  }

  /// Get information about the Excel file for a specific survey
  Future<Map<String, dynamic>?> getSurveyExcelFileInfo(int surveyId, String surveyCode) async {
    try {
      final directory = await _getExportDirectory();
      final fileName = 'survey_${surveyId}_$surveyCode.xlsx';
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        final stats = await file.stat();
        return {
          'exists': true,
          'path': file.path,
          'size': stats.size,
          'lastModified': stats.modified,
        };
      }
      return null;
    } catch (e) {
      //print('❌ Error getting file info: $e');
      return null;
    }
  }

  /// Format header text from header map (same as old excel_export_service.dart)
  String _formatHeaderText(Map<String, dynamic> header) {
    if (header['type'] == 'basic') {
      return header['text'];
    } else {
      String text = header['fullText'] ?? header['text'];
      if (header['instanceIndex'] != null) {
        text = '[${header['instanceIndex'] + 1}] $text';
      }
      return text;
    }
  }

  /// Find header index by text for matching old data to new structure
  int _findHeaderIndexByText(String headerText) {
    for (int i = 0; i < _headerStructure.length; i++) {
      final formattedText = _formatHeaderText(_headerStructure[i]);
      if (formattedText == headerText) {
        return i;
      }
    }
    return -1; // Not found
  }
}
