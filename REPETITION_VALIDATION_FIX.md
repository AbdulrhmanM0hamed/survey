# Repetition Count Validation Fix

## Problem
The API was rejecting surveys with the error: "لا يمكن أن يزيد عدد التكرارات عن 20" (Repetition count cannot exceed 20).

This occurred for questions: 40873, 40875, 40878, 40884, 20913, 20938, 20993

### Root Cause
- Question 20889 ("عدد أفراد العائلة" - Number of family members) controls the repetition count for Group 88
- Groups inside Group 88 (20090, 20091, 20092, 20093) inherit this repetition count
- When users entered values > 20, the API rejected the entire survey
- No client-side validation was preventing users from entering invalid values

## Solution

### Part 1: Prevent Future Invalid Entries (COMPLETED)
Added dynamic validation to `TextQuestionWidget` that:

1. **Detects Repetition Control Questions**: Checks if a question has `sourceConditions` with `ConditionAction.repetition` (value = 4)

2. **Validates Maximum Value**: For integer questions that control repetition, validates that the value does not exceed 20

3. **Shows Error Message**: Displays "لا يمكن أن يزيد عدد التكرارات عن 20" when validation fails

4. **Prevents Invalid Submission**: Blocks auto-save and manual submission when validation fails

**File Modified**: `lib/presentation/widgets/question_widgets/text_question_widget.dart`

### Part 2: Fix Existing Invalid Surveys (COMPLETED)
Added automatic correction logic in `SurveyDetailsViewModel` that:

1. **Loads Survey Structure**: Fetches the survey definition to identify repetition control questions

2. **Caps Repetition Values**: Automatically caps any repetition control question values > 20 to exactly 20

3. **Removes Excess Answers**: Deletes answers for group instances > 20 (e.g., if user entered 25, removes instances 21-25)

4. **Applies Before Upload**: Runs automatically before each survey upload, ensuring only valid data is sent to API

**File Modified**: `lib/presentation/screens/survey_details/viewmodel/survey_details_viewmodel.dart`

**Method Added**: `_fixRepetitionCounts(SurveyAnswersModel surveyAnswers)`

## How It Works

### For New Surveys
When a user tries to enter a value > 20 in Question 20889:
- Red error message appears immediately
- Red border shows around the text field
- Value is NOT saved
- User must enter ≤ 20 to proceed

### For Existing Surveys
When uploading surveys with repetition counts > 20:
1. System loads survey structure
2. Identifies Question 20889 as repetition control
3. Caps its value to 20
4. Removes answers for group instances 21+
5. Uploads the corrected data
6. API accepts the survey successfully

## Benefits

✅ **Dynamic Solution**: Works for any question that controls repetition, not hardcoded to specific question IDs

✅ **Real-time Feedback**: Shows error message immediately when user enters invalid value

✅ **Prevents API Errors**: Blocks submission of invalid data before it reaches the API

✅ **Fixes Old Data**: Automatically corrects existing surveys with invalid repetition counts

✅ **User-Friendly**: Clear Arabic error message explains the limitation

✅ **Consistent**: Uses the same error message as the API

✅ **Non-Destructive**: Only removes excess group instances, preserves all valid data

## Testing

### Test New Entry Validation
1. Navigate to Question 20889 ("عدد أفراد العائلة")
2. Try entering a value > 20 (e.g., 25)
3. Verify that:
   - Red error message appears: "لا يمكن أن يزيد عدد التكرارات عن 20"
   - Red border appears around the text field
   - Value is NOT saved when you leave the field
   - Repeating groups do NOT expand beyond 20 instances
4. Enter a valid value ≤ 20
5. Verify that:
   - Error message disappears
   - Border returns to normal
   - Value is saved correctly

### Test Automatic Fix for Existing Surveys
1. Have surveys with repetition counts > 20 saved locally
2. Go to "رفع الاستبيانات" (Upload Surveys)
3. Watch the logs for:
   - "🔧 Checking for repetition count issues..."
   - "📍 Found repetition control question: 20889"
   - "⚠️ Found repetition count > 20: Question 20889 = [value]"
   - "🔧 Capping to 20..."
   - "🗑️ Removing answer for group instance [X] (> 20)"
   - "✅ Fixed repetition count issues"
4. Verify that:
   - Survey uploads successfully
   - No API errors about repetition counts
   - Survey is removed from local storage after successful upload

## Related Questions

This validation applies to any question that has:
- Type: Integer (`QuestionType.integer`)
- Source Conditions with Action: Repetition (`ConditionAction.repetition`)

In the current survey, this includes Question 20889 which controls Group 88 repetitions.

## Debug Logs

The fix includes comprehensive logging:
- 🔧 Checking for issues
- 📥 Loading survey structure
- 📍 Found repetition control questions
- ⚠️ Found values > 20
- 🔧 Capping values
- 🗑️ Removing excess answers
- ✅ Fix completed
