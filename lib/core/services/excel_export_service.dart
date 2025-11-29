import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as Syncfusion;
import 'package:survey/core/enums/condition_action.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/question_model.dart';
import 'package:survey/data/models/survey_model.dart';

class ExcelExportService {
  /// Sheet name for responses
  static const String _sheetName = 'الاستبيانات';
  
  /// Export survey answers to Excel
  /// Creates a new file per survey or appends to existing one
  Future<String?> exportSurveyToExcel({
    required SurveyModel survey,
    required SurveyAnswersModel surveyAnswers,
  }) async {
    print('📊 Starting Excel export...');
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

      // Get the file path - unique per survey
      final directory = await _getExportDirectory();
      final fileName = 'survey_${survey.id}_${survey.code}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      print('📁 Using file: $fileName');

      Excel excel;
      Sheet sheet;

      // Check if file exists
      if (await file.exists()) {
        print('📂 File exists, loading and appending...');
        // Load existing file
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
        sheet = excel.sheets[excel.getDefaultSheet()]!;
        
        print('📊 Current rows in file: ${sheet.maxRows}');
        
        // Check if file has data and correct structure
        if (sheet.maxRows == 0) {
          // Empty file - just add headers
          print('📄 File is empty, adding headers...');
          _addHeaders(sheet, survey, surveyAnswers);
        } else {
          // File has data - check structure
          final firstCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
          final hasCorrectStructure = firstCell.value?.toString() == 'رقم الاستجابة';
          
          if (!hasCorrectStructure) {
            // Old structure detected - backup and recreate
            print('⚠️ Old Excel structure detected. Creating backup and new file...');
            final backupPath = '${directory.path}/${fileName.replaceAll('.xlsx', '')}_backup_${DateTime.now().millisecondsSinceEpoch}.xlsx';
            await file.copy(backupPath);
            print('✅ Backup created: $backupPath');
            
            // Delete old file and create new one
            await file.delete();
            excel = Excel.createExcel();
            
            // Delete default Sheet1 and create our sheet
            final defaultSheet = excel.getDefaultSheet();
            if (defaultSheet != null) {
              excel.delete(defaultSheet);
            }
            
            sheet = excel[_sheetName];
            _addHeaders(sheet, survey, surveyAnswers);
          } else {
            // Compatible structure - check if we need to expand headers
            print('✅ Compatible structure found, checking for header expansion...');
            _expandHeadersIfNeeded(sheet, survey, surveyAnswers);
          }
        }
      } else {
        print('📄 File does not exist, creating new file...');
        // Create new Excel file
        excel = Excel.createExcel();
        
        // Delete default Sheet1 and create our sheet
        final defaultSheet = excel.getDefaultSheet();
        if (defaultSheet != null) {
          excel.delete(defaultSheet);
        }
        
        sheet = excel[_sheetName];
        
        // Add headers
        _addHeaders(sheet, survey, surveyAnswers);
      }

      // Add survey response as new row
      _addSurveyResponse(sheet, survey, surveyAnswers);

      // Save Excel file
      print('💾 Encoding Excel file...');
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        print('📁 Writing to file: $filePath');
        await file.writeAsBytes(excelBytes);
        print('✅ Excel file saved successfully!');
        return filePath;
      }

      print('❌ Failed to encode Excel file');
      return null;
    } catch (e, stackTrace) {
      print('❌ Error exporting to Excel: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get the directory for export (Downloads folder)
  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      // Use Downloads directory on Android
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else {
      // Use documents directory on other platforms
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Build header structure from survey model with dynamic instance count
  void _buildHeaderStructure(SurveyModel survey, SurveyAnswersModel surveyAnswers) {
    _headerStructure.clear();
    _buildHeaderStructureInternal(survey, surveyAnswers, _headerStructure);
  }
  
  /// Legacy structure builder (kept for reference)
  void _buildHeaderStructureOld(SurveyModel survey, SurveyAnswersModel surveyAnswers) {
    final List<Map<String, dynamic>> headerStructure = [];
    
    // Basic info columns
    headerStructure.add({'type': 'basic', 'text': 'Response ID', 'section': ''});
    headerStructure.add({'type': 'basic', 'text': 'Survey Code', 'section': ''});
    headerStructure.add({'type': 'basic', 'text': 'Survey Name', 'section': ''});
    headerStructure.add({'type': 'basic', 'text': 'Started At', 'section': ''});
    headerStructure.add({'type': 'basic', 'text': 'Completed At', 'section': ''});
    headerStructure.add({'type': 'basic', 'text': 'Status', 'section': ''});

    // Sort sections by order
    final sortedSections = (survey.sections ?? [])..sort((a, b) => a.order.compareTo(b.order));

    // Build header structure for each section
    for (final section in sortedSections) {
      // Sort groups by order
      final sortedGroups = section.questionGroups..sort((a, b) => a.order.compareTo(b.order));
      
      // Process groups
      for (final group in sortedGroups) {
        // Sort questions in group by order
        final sortedQuestions = group.questions..sort((a, b) => a.order.compareTo(b.order));
        
        // Check if group can repeat (maxCount != 1 or has repetition condition)
        final hasRepetition = group.targetConditions.any((c) => c.actionEnum == ConditionAction.repetition);
        
        // Calculate actual number of instances from answers
        int maxInstances = 1;
        Set<int> uniqueInstances = {};
        
        if (hasRepetition) {
          // Find unique groupInstanceIds based on RECENT answers only
          // This prevents counting old/deleted instances
          if (sortedQuestions.isNotEmpty) {
            final firstQuestion = sortedQuestions.first;
            
            // Get all answers for first question, sorted by timestamp (newest first)
            final allAnswersForFirstQ = surveyAnswers.answers
                .where((a) => a.questionId == firstQuestion.id && a.groupInstanceId != null)
                .toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            print('🔍 Question "${firstQuestion.text}" (ID: ${firstQuestion.id}): Found ${allAnswersForFirstQ.length} answers');
            
            // Only consider instances that have been updated recently (within last edit session)
            // Strategy: group by instanceId and take only the most recent timestamp for each
            final instanceTimestamps = <int, DateTime>{};
            for (var ans in allAnswersForFirstQ) {
              final instId = ans.groupInstanceId!;
              if (!instanceTimestamps.containsKey(instId) || ans.timestamp.isAfter(instanceTimestamps[instId]!)) {
                instanceTimestamps[instId] = ans.timestamp;
              }
            }
            
            // Find the most recent timestamp across all instances
            if (instanceTimestamps.isNotEmpty) {
              final mostRecentTime = instanceTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b);
              
              // Only include instances that were updated within 1 minute of the most recent one
              // This assumes all instances in a session are filled close together
              final timeThreshold = mostRecentTime.subtract(const Duration(minutes: 1));
              
              uniqueInstances = instanceTimestamps.entries
                  .where((e) => e.value.isAfter(timeThreshold))
                  .map((e) => e.key)
                  .toSet();
              
              print('🕐 Most recent edit: $mostRecentTime, threshold: $timeThreshold');
              print('📋 Group "${group.name}": Found ${uniqueInstances.length} recent instances (IDs: ${uniqueInstances.toList()..sort()})');
              print('   Excluded old instances: ${instanceTimestamps.keys.where((k) => !uniqueInstances.contains(k)).toList()}');
              
              maxInstances = uniqueInstances.length;
            }
          }
        }
        
        if (maxInstances > 1) {
          // For repeated groups, group columns by instance (all questions for instance 1, then instance 2, etc.)
          // Use actual instance IDs found in answers
          final sortedInstanceIds = uniqueInstances.toList()..sort();
          for (int instanceId in sortedInstanceIds) {
            for (final question in sortedQuestions) {
              headerStructure.add({
                'type': 'group',
                'section': section.name,
                'group': group.name,
                'text': '[${instanceId + 1}] ${question.code}',
                'fullText': question.text,
                'questionId': question.id,
                'instanceIndex': instanceId,
              });
            }
          }
        } else {
          // Non-repeated group - one column per question
          for (final question in sortedQuestions) {
            headerStructure.add({
              'type': 'group',
              'section': section.name,
              'group': group.name,
              'text': question.code,
              'fullText': question.text,
              'questionId': question.id,
              'instanceIndex': null,
            });
          }
        }
      }
      
      // Sort direct questions in section by order
      final sortedDirectQuestions = section.questions..sort((a, b) => a.order.compareTo(b.order));
      
      // Process direct questions
      for (final question in sortedDirectQuestions) {
        headerStructure.add({
          'type': 'direct',
          'section': section.name,
          'text': question.code,
          'fullText': question.text,
          'questionId': question.id,
        });
      }
    }

    _headerStructure = headerStructure;
  }

  /// Add headers to Excel sheet - Question text in Arabic
  void _addHeaders(Sheet sheet, SurveyModel survey, SurveyAnswersModel surveyAnswers) {
    // Build the header structure first
    _buildHeaderStructure(survey, surveyAnswers);
    
    final headerStructure = _headerStructure;

    // Single header row with question text (Arabic)
    for (int i = 0; i < headerStructure.length; i++) {
      final header = headerStructure[i];
      
      // Use full question text as header (Arabic)
      String headerText;
      if (header['type'] == 'basic') {
        // Translate basic info headers to Arabic
        switch (header['text']) {
          case 'Response ID':
            headerText = 'رقم الاستجابة';
            break;
          case 'Survey Code':
            headerText = 'كود الاستبيان';
            break;
          case 'Survey Name':
            headerText = 'اسم الاستبيان';
            break;
          case 'Started At':
            headerText = 'تاريخ البدء';
            break;
          case 'Completed At':
            headerText = 'تاريخ الانتهاء';
            break;
          case 'Status':
            headerText = 'الحالة';
            break;
          default:
            headerText = header['text'];
        }
      } else {
        // For questions, use the full text (already in Arabic)
        // Add instance number prefix if repeated group
        if (header['instanceIndex'] != null) {
          headerText = '[${header['instanceIndex'] + 1}] ${header['fullText'] ?? header['text']}';
        } else {
          headerText = header['fullText'] ?? header['text'];
        }
      }
      
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headerText);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }
  }

  List<Map<String, dynamic>> _headerStructure = [];

  /// Expand headers if needed and preserve existing data
  void _expandHeadersIfNeeded(Sheet sheet, SurveyModel survey, SurveyAnswersModel surveyAnswers) {
    _headerStructure.clear();
    
    print('📖 Reading existing headers...');
    
    // Read existing headers
    final existingHeaders = <String>[];
    final headerRow = sheet.row(0);
    for (var cell in headerRow) {
      if (cell == null || cell.value == null) break;
      existingHeaders.add(cell.value.toString());
    }
    
    print('📋 Found ${existingHeaders.length} existing headers');
    
    // Build header structure for new survey
    final tempHeaderStructure = <Map<String, dynamic>>[];
    _buildHeaderStructureInternal(survey, surveyAnswers, tempHeaderStructure);
    
    print('🔍 New survey needs ${tempHeaderStructure.length} headers');
    
    // Check if we need to expand
    if (tempHeaderStructure.length > existingHeaders.length) {
      final existingInstanceCount = _countInstancesInHeaders(existingHeaders);
      final newInstanceCount = _countInstancesInStructure(tempHeaderStructure);
      
      print('📈 Expanding structure: $existingInstanceCount → $newInstanceCount أفراد');
      print('   Rebuilding file with ${tempHeaderStructure.length} columns in correct order');
      
      // Build old header structure for mapping
      final oldHeaderStructure = <Map<String, dynamic>>[];
      for (var headerText in existingHeaders) {
        // Try to parse header to extract metadata
        final match = RegExp(r'^\[(\d+)\]\s*(.+)$').firstMatch(headerText);
        if (match != null) {
          // Repeated group question
          oldHeaderStructure.add({
            'text': headerText,
            'instanceIndex': int.parse(match.group(1)!) - 1,
            'fullText': match.group(2),
          });
        } else {
          // Non-repeated or basic
          oldHeaderStructure.add({
            'text': headerText,
            'fullText': headerText,
            'instanceIndex': null,
          });
        }
      }
      
      // Read existing data rows with old structure
      final existingRowsData = <Map<String, String>>[];
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final rowData = <String, String>{};
        for (int colIndex = 0; colIndex < existingHeaders.length; colIndex++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));
          final headerKey = existingHeaders[colIndex];
          rowData[headerKey] = cell.value?.toString() ?? '';
        }
        existingRowsData.add(rowData);
      }
      
      print('💾 Preserved ${existingRowsData.length} existing rows');
      
      // Clear all rows except keeping the sheet (no clear method available)
      // We'll overwrite by writing new headers and data
      
      // Write new headers
      for (int i = 0; i < tempHeaderStructure.length; i++) {
        final header = tempHeaderStructure[i];
        String headerText = _formatHeaderText(header);
        
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headerText);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
      
      print('📋 Rebuilt headers with new structure');
      
      // Rewrite existing data rows with mapping
      for (int rowIndex = 0; rowIndex < existingRowsData.length; rowIndex++) {
        final oldRowData = existingRowsData[rowIndex];
        
        for (int colIndex = 0; colIndex < tempHeaderStructure.length; colIndex++) {
          final newHeader = tempHeaderStructure[colIndex];
          final newHeaderText = _formatHeaderText(newHeader);
          
          // Try to find matching data from old headers - EXACT MATCH ONLY
          String cellValue = '';
          
          // Only use exact header text match
          if (oldRowData.containsKey(newHeaderText)) {
            cellValue = oldRowData[newHeaderText]!;
          }
          // If no exact match found, leave cell empty (for new columns)
          
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
          cell.value = TextCellValue(cellValue);
        }
      }
      
      print('✅ Rebuilt ${existingRowsData.length} rows with new column order');
    } else if (tempHeaderStructure.length < existingHeaders.length) {
      // New survey has fewer columns - can still append
      print('⚠️ New survey has fewer columns (${_countInstancesInStructure(tempHeaderStructure)} vs ${_countInstancesInHeaders(existingHeaders)} أفراد)');
      print('   Will append with empty cells for missing columns');
    } else {
      print('✅ Header structure matches exactly');
    }
    
    // Use the larger structure (existing or new)
    _headerStructure = tempHeaderStructure.length >= existingHeaders.length 
        ? tempHeaderStructure 
        : _rebuildStructureFromHeaders(existingHeaders, survey, surveyAnswers);
    
    print('📋 Using structure with ${_headerStructure.length} columns');
  }
  
  /// Format header text from header map
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
  
  /// Rebuild structure from existing headers when new survey has fewer columns
  List<Map<String, dynamic>> _rebuildStructureFromHeaders(List<String> headers, SurveyModel survey, SurveyAnswersModel surveyAnswers) {
    // For now, just use the new structure and pad with nulls during write
    // This is a simplified approach
    final structure = <Map<String, dynamic>>[];
    _buildHeaderStructureInternal(survey, surveyAnswers, structure);
    
    // Pad to match existing header count if needed
    while (structure.length < headers.length) {
      structure.add({
        'type': 'padding',
        'text': '',
        'fullText': '',
        'questionId': -1,
        'instanceIndex': null,
      });
    }
    
    return structure;
  }
  
  /// Count instances in header structure
  int _countInstancesInStructure(List<Map<String, dynamic>> structure) {
    int maxInstance = 0;
    for (var header in structure) {
      if (header['instanceIndex'] != null) {
        final idx = header['instanceIndex'] as int;
        if (idx > maxInstance) maxInstance = idx;
      }
    }
    return maxInstance > 0 ? maxInstance + 1 : 0;
  }
  
  /// Count instances from existing headers
  int _countInstancesInHeaders(List<String> headers) {
    int maxInstance = 0;
    for (var header in headers) {
      final match = RegExp(r'^\[(\d+)\]').firstMatch(header);
      if (match != null) {
        final instanceNum = int.parse(match.group(1)!);
        if (instanceNum > maxInstance) maxInstance = instanceNum;
      }
    }
    return maxInstance;
  }
  
  /// Internal method to build header structure without clearing
  /// Maintains natural question order from survey structure
  void _buildHeaderStructureInternal(SurveyModel survey, SurveyAnswersModel surveyAnswers, List<Map<String, dynamic>> structure) {
    // Add basic info columns
    structure.add({'type': 'basic', 'text': 'رقم الاستجابة'});
    structure.add({'type': 'basic', 'text': 'كود الاستبيان'});
    structure.add({'type': 'basic', 'text': 'اسم الاستبيان'});
    structure.add({'type': 'basic', 'text': 'اسم الباحث'});
    structure.add({'type': 'basic', 'text': 'اسم المشرف'});
    structure.add({'type': 'basic', 'text': 'اسم المدينة'});
    structure.add({'type': 'basic', 'text': 'اسم الحى / القرية'});
    structure.add({'type': 'basic', 'text': 'اسم الشارع'});
    structure.add({'type': 'basic', 'text': 'قبول المشاركة'});
    structure.add({'type': 'basic', 'text': 'سبب عدم القبول'});
    structure.add({'type': 'basic', 'text': 'تاريخ البدء'});
    structure.add({'type': 'basic', 'text': 'تاريخ الإنهاء'});
    structure.add({'type': 'basic', 'text': 'الحالة'});

    // Sort sections by order
    final sortedSections = survey.sections ?? []
      ..sort((a, b) => a.order.compareTo(b.order));

    // Build header structure for each section - MAINTAIN NATURAL ORDER
    for (final section in sortedSections) {
      // Sort groups by order
      final sortedGroups = section.questionGroups..sort((a, b) => a.order.compareTo(b.order));
      
      // Process groups IN NATURAL ORDER
      for (final group in sortedGroups) {
        // Sort questions in group by order
        final sortedQuestions = group.questions..sort((a, b) => a.order.compareTo(b.order));
        
        // Check if group can repeat
        final hasRepetition = group.targetConditions.any((c) => c.actionEnum == ConditionAction.repetition);
        
        // Calculate actual number of instances from answers
        int maxInstances = 1;
        Set<int> uniqueInstances = {};
        
        if (hasRepetition) {
          // Find unique groupInstanceIds based on RECENT answers only
          if (sortedQuestions.isNotEmpty) {
            final firstQuestion = sortedQuestions.first;
            
            // Get all answers for first question
            final allAnswersForFirstQ = surveyAnswers.answers
                .where((a) => a.questionId == firstQuestion.id && a.groupInstanceId != null)
                .toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            // Group by instanceId and take most recent timestamp
            final instanceTimestamps = <int, DateTime>{};
            for (var ans in allAnswersForFirstQ) {
              final instId = ans.groupInstanceId!;
              if (!instanceTimestamps.containsKey(instId) || ans.timestamp.isAfter(instanceTimestamps[instId]!)) {
                instanceTimestamps[instId] = ans.timestamp;
              }
            }
            
            // Find recent instances
            if (instanceTimestamps.isNotEmpty) {
              final mostRecentTime = instanceTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b);
              final timeThreshold = mostRecentTime.subtract(const Duration(minutes: 1));
              
              uniqueInstances = instanceTimestamps.entries
                  .where((e) => e.value.isAfter(timeThreshold))
                  .map((e) => e.key)
                  .toSet();
              
              maxInstances = uniqueInstances.length;
            }
          }
        }
        
        if (maxInstances > 1) {
          // For repeated groups - add directly to structure IN ORDER
          final sortedInstanceIds = uniqueInstances.toList()..sort();
          for (int instanceId in sortedInstanceIds) {
            for (final question in sortedQuestions) {
              structure.add({
                'type': 'group',
                'section': section.name,
                'group': group.name,
                'text': '[${instanceId + 1}] ${question.code}',
                'fullText': question.text,
                'questionId': question.id,
                'instanceIndex': instanceId,
              });
            }
          }
        } else {
          // Non-repeated group - add directly to structure IN ORDER
          for (final question in sortedQuestions) {
            structure.add({
              'type': 'group',
              'section': section.name,
              'group': group.name,
              'text': question.code,
              'fullText': question.text,
              'questionId': question.id,
              'instanceIndex': null,
            });
          }
        }
      }
      
      // Process direct questions IN ORDER
      final sortedDirectQuestions = section.questions..sort((a, b) => a.order.compareTo(b.order));
      for (final question in sortedDirectQuestions) {
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

  /// Add survey response as new row using header structure
  void _addSurveyResponse(
    Sheet sheet,
    SurveyModel survey,
    SurveyAnswersModel surveyAnswers,
  ) {
    // Data starts from row 1 (row 0 is headers)
    final rowIndex = sheet.maxRows;
    print('➕ Adding new response at row $rowIndex');

    // Use the header structure to ensure correct column order
    for (int colIndex = 0; colIndex < _headerStructure.length; colIndex++) {
      final header = _headerStructure[colIndex];
      String cellValue = '';

      if (header['type'] == 'basic') {
        // Handle basic info columns
        switch (header['text']) {
          case 'رقم الاستجابة':
          case 'Response ID':
            cellValue = surveyAnswers.surveyId.toString();
            break;
          case 'كود الاستبيان':
          case 'Survey Code':
            cellValue = surveyAnswers.surveyCode;
            break;
          case 'اسم الاستبيان':
          case 'Survey Name':
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
            break;
          case 'اسم الشارع':
            cellValue = surveyAnswers.streetName ?? '';
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
          case 'Started At':
            cellValue = DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(surveyAnswers.startedAt);
            break;
          case 'تاريخ الإنهاء':
          case 'Completed At':
            cellValue = surveyAnswers.completedAt != null
                ? DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(surveyAnswers.completedAt!)
                : 'غير منتهي';
            break;
          case 'الحالة':
          case 'Status':
            cellValue = surveyAnswers.isDraft ? 'مسودة' : 'مكتمل';
            break;
        }
      } else if (header['type'] == 'group' || header['type'] == 'direct') {
        // Handle question answers
        final questionId = header['questionId'];
        final instanceIndex = header['instanceIndex'];

        // Find the answer
        final answer = surveyAnswers.answers.where((a) {
          if (instanceIndex != null) {
            // For repeated groups, match both questionId and instanceIndex
            return a.questionId == questionId && a.groupInstanceId == instanceIndex;
          } else {
            // For non-repeated questions or direct questions
            // Match questionId and (groupInstanceId is null OR 0)
            return a.questionId == questionId && (a.groupInstanceId == null || a.groupInstanceId == 0);
          }
        }).firstOrNull;

        if (answer != null && answer.value != null) {
          // Only write value if answer exists and has actual data
          final question = _findQuestion(survey, questionId);
          cellValue = _formatAnswerValue(answer.value, question);
        }
        // If no answer found or value is null, cellValue remains empty string
      } else if (header['type'] == 'padding') {
        // Padding column - leave empty
        cellValue = '';
      }

      // Write cell value
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex))
          .value = TextCellValue(cellValue);
    }
  }

  /// Find question by ID in survey
  QuestionModel? _findQuestion(SurveyModel survey, int questionId) {
    for (final section in survey.sections ?? []) {
      // Check direct questions
      for (final question in section.questions) {
        if (question.id == questionId) return question;
      }
      // Check questions in groups
      for (final group in section.questionGroups) {
        for (final question in group.questions) {
          if (question.id == questionId) return question;
        }
      }
    }
    return null;
  }

  /// Format answer value for display with choice labels
  String _formatAnswerValue(dynamic value, QuestionModel? question) {
    if (value == null) return '';
    
    // If question has choices, convert code to label
    if (question != null && question.choices.isNotEmpty) {
      if (value is List) {
        // Multiple choice - map each code to label
        return value.map((v) {
          final choice = question.choices.where((c) => c.code == v.toString()).firstOrNull;
          return choice?.label ?? v.toString();
        }).join(', ');
      } else {
        // Single choice - find the label
        final choice = question.choices.where((c) => c.code == value.toString()).firstOrNull;
        return choice?.label ?? value.toString();
      }
    }
    
    // No choices - return value as is
    if (value is List) {
      return value.map((v) => v.toString()).join(', ');
    }
    return value.toString();
  }

  /// Export to daily Excel file - one file per day with all surveys
  Future<String?> exportToDailyExcel({
    required SurveyModel survey,
    required SurveyAnswersModel surveyAnswers,
  }) async {
    print('📊 Starting Daily Excel export...');
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

      // Get today's date for filename
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final directory = await _getExportDirectory();
      final fileName = '${survey.code}_$today.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      print('📁 Daily file: $fileName');

      Excel excel;
      Sheet sheet;

      const String sheetName = _sheetName;
      
      // Check if today's file exists
      if (await file.exists()) {
        print('📂 Today\'s file exists, appending...');
        // Load existing file
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
        
        // Use Responses sheet (should already exist)
        sheet = excel.sheets[sheetName]!;
        
        // Check if we need to expand headers (in case survey structure changed)
        print('✅ Compatible structure found, checking for header expansion...');
        _expandHeadersIfNeeded(sheet, survey, surveyAnswers);
      } else {
        print('📝 Creating new daily file...');
        // Create new file
        excel = Excel.createExcel();
        
        // Delete default sheet and create Responses sheet
        final defaultSheet = excel.getDefaultSheet();
        if (defaultSheet != null) {
          excel.delete(defaultSheet);
        }
        
        // Create Responses sheet
        sheet = excel[sheetName];
        
        // Add headers
        _addHeaders(sheet, survey, surveyAnswers);
      }

      // Add survey response as new row
      _addSurveyResponse(sheet, survey, surveyAnswers);

      // Save file
      final bytes = excel.encode();
      await file.writeAsBytes(bytes!);

      print('✅ Daily Excel export completed: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error exporting to daily Excel: $e');
      return null;
    }
  }

  /// Share Excel file
  Future<void> shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Survey Responses',
        text: 'Survey responses exported on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );
    } catch (e) {
      print('❌ Error sharing file: $e');
      rethrow;
    }
  }

  /// Delete specific survey Excel file
  Future<bool> deleteSurveyExcelFile(int surveyId, String surveyCode) async {
    try {
      final directory = await _getExportDirectory();
      final fileName = 'survey_${surveyId}_$surveyCode.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted Excel file: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting Excel file: $e');
      return false;
    }
  }

  /// Get specific survey export file info
  Future<Map<String, dynamic>?> getSurveyExcelFileInfo(int surveyId, String surveyCode) async {
    try {
      final directory = await _getExportDirectory();
      final fileName = 'survey_${surveyId}_$surveyCode.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        final stat = await file.stat();
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.sheets[excel.getDefaultSheet()];
        
        return {
          'path': filePath,
          'fileName': fileName,
          'size': stat.size,
          'modified': stat.modified,
          'rows': sheet?.maxRows ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error getting file info: $e');
      return null;
    }
  }
}
