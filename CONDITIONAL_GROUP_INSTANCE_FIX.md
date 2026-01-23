# Conditional Group Instance ID Fix

## Problem
When uploading surveys, questions 20993 and 20994 (in Group 104) were being removed before upload, causing the server to reject the survey with error: "بعض الأسئلة الإلزامية لم يتم الإجابة عليها: 20993, 20994"

## Root Cause
Group 104 is a **conditional group** (triggered by question 20947). The system was generating a massive `groupInstanceId`:
- `triggerSourceQuestionId * 10000 + parentInstanceId`
- `20947 * 10000 + 0 = 209470000`

This huge ID exceeded the validation limit of 20, causing the system to remove these answers before upload.

## Solution

### 1. Fixed Instance ID Generation (survey_details_screen.dart)
**Before:**
```dart
effectiveInstanceId = (triggerSourceQuestionId * 10000) + (effectiveInstanceId ?? 0);
```

**After:**
```dart
// For conditional (non-repeating) groups, use parentInstanceId
// Don't multiply by large numbers - keep instance IDs small
effectiveInstanceId = parentInstanceId ?? 0;
```

### 2. Improved Validation Logic (survey_details_viewmodel.dart)
**Before:**
- Removed ALL answers with `groupInstanceId > 20`
- Didn't distinguish between repeating groups and conditional groups

**After:**
- Only validates instance IDs for **repeating groups** (groups with repetition conditions)
- Conditional groups can use any instance ID without being removed
- Checks if group has `ConditionAction.repetition` before applying the 20-instance limit

## Impact
- Conditional groups (like Group 104) now use small instance IDs (0, 1, 2, etc.)
- Answers from conditional groups are no longer removed during upload
- Repeating groups still have proper validation (max 20 instances)
- Server will now accept surveys with conditional group answers

## Testing
1. Complete a survey with conditional groups
2. Verify groupInstanceId values are small (< 20)
3. Upload the survey
4. Confirm server accepts all required questions including 20993, 20994
