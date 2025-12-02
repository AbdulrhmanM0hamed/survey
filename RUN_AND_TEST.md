# 🧪 تشغيل واختبار التكرار

## الخطوة 1: تشغيل التطبيق

```bash
flutter run
```

## الخطوة 2: افتح الاستبيان

1. في الشاشة الرئيسية، اضغط على "استبيان تجريبي صغير"
2. انتظر حتى يتم تحميل الاستبيان

## الخطوة 3: أدخل عدد الأفراد

في سؤال **"كم عدد أفراد الأسرة المقيمين بشكل دائم؟"**:

1. اكتب: `5`
2. اضغط **Done** على الكيبورد
3. أو اضغط زر ✓ الأخضر

## الخطوة 4: راقب الـ Console

يجب أن تظهر الرسائل التالية:

```
💾 saveAnswer: questionId=10850, code=HH_MEMBERS_COUNT, value=5
🔄 Re-evaluating conditions after saving answer...
🔍 Evaluating 1 conditions for question 10850 (HH_MEMBERS_COUNT)
   Condition: targetType=TargetType.group, action=ConditionAction.repetition, operator=ConditionOperator.repeatForCount
   Answer value: 5
      _getAnswerValue(10850) = 5 (type: int)
   Condition met: true
📌 _applyGroupAction: groupId=83, action=ConditionAction.repetition
   answerValue from sourceQuestionId=10850: 5
      _getAnswerValue(10850) = 5 (type: int)
   ✅ Setting _groupRepetitions[83] = 5
🔄 getGroupRepetitions: groupId=83, count=5
🎨 Building group 83 (كتلة بيانات فرد من أفراد الأسرة) with 5 repetitions
   📝 Generating instance 0 for group 83
   📝 Generating instance 1 for group 83
   📝 Generating instance 2 for group 83
   📝 Generating instance 3 for group 83
   📝 Generating instance 4 for group 83
```

## الخطوة 5: تحقق من الواجهة

يجب أن تشاهد:

```
✅ القسم الأول: بيانات الأسرة والأفراد
   ├── بيانات أساسية عن الأسرة
   │   └── كم عدد أفراد الأسرة: 5 ✓
   │
   ├── كتلة بيانات فرد من أفراد الأسرة
   │   ├── التكرار 1
   │   │   ├── الفرد رقم: __
   │   │   ├── الجنس: __
   │   │   └── الحالة التعليمية: __
   │   │
   │   ├── التكرار 2
   │   │   ├── الفرد رقم: __
   │   │   ├── الجنس: __
   │   │   └── الحالة التعليمية: __
   │   │
   │   ├── التكرار 3
   │   │   ├── الفرد رقم: __
   │   │   ├── الجنس: __
   │   │   └── الحالة التعليمية: __
   │   │
   │   ├── التكرار 4
   │   │   ├── الفرد رقم: __
   │   │   ├── الجنس: __
   │   │   └── الحالة التعليمية: __
   │   │
   │   └── التكرار 5
   │       ├── الفرد رقم: __
   │       ├── الجنس: __
   │       └── الحالة التعليمية: __
```

---

## ❌ إذا لم يظهر التكرار

### احتمال 1: القيمة لم تُحفظ

**راقب Console:**
```
💾 saveAnswer: questionId=10850, code=HH_MEMBERS_COUNT, value=5
```

**إذا لم تظهر:**
- تأكد أنك ضغطت Done أو زر ✓
- تحقق من الـ TextQuestionWidget

### احتمال 2: الشرط لم يُقيّم

**راقب Console:**
```
🔍 Evaluating 1 conditions for question 10850
```

**إذا لم تظهر:**
- المشكلة في _evaluateAllConditions
- تحقق من sourceConditions في الـ JSON

### احتمال 3: الـ Action لم يُطبّق

**راقب Console:**
```
📌 _applyGroupAction: groupId=83, action=ConditionAction.repetition
✅ Setting _groupRepetitions[83] = 5
```

**إذا لم تظهر:**
- المشكلة في _applyConditionAction
- تحقق من targetType و action

### احتمال 4: الواجهة لم تتحدث

**راقب Console:**
```
🔄 getGroupRepetitions: groupId=83, count=5
🎨 Building group 83 with 5 repetitions
```

**إذا ظهر count=1:**
- المشكلة في _groupRepetitions
- تحقق من notifyListeners()

**إذا ظهر count=5 لكن الواجهة مش متحدثة:**
- المشكلة في Consumer
- تأكد من ChangeNotifierProvider

---

## 🔍 Debug إضافي

### طباعة جميع الإجابات

أضف في saveAnswer:

```dart
////print('All answers: ${_surveyAnswers!.answers.map((a) => "${a.questionId}:${a.value}").join(", ")}');
```

### طباعة جميع الـ repetitions

أضف في _evaluateAllConditions:

```dart
////print('All repetitions: $_groupRepetitions');
```

### طباعة الـ sourceConditions

أضف في loadSurvey بعد loading:

```dart
for (var section in _survey!.sections!) {
  for (var group in section.questionGroups) {
    for (var question in group.questions) {
      if (question.sourceConditions.isNotEmpty) {
        ////print('Question ${question.id} has ${question.sourceConditions.length} sourceConditions');
      }
    }
  }
}
```

---

## ✅ النتيجة المتوقعة

**بعد كل الخطوات:**
- ✅ القيمة 5 محفوظة
- ✅ الشرط اتقيّم
- ✅ الـ Action اتطبّق
- ✅ _groupRepetitions[83] = 5
- ✅ الواجهة عرضت 5 تكرارات
- ✅ كل تكرار فيه 3 أسئلة

**شغّل التطبيق وجرب دلوقتي! 🚀**
