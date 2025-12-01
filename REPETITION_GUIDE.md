# 🔄 دليل نظام التكرار (Repetition System)

## نظرة عامة

نظام التكرار يسمح بتكرار مجموعة أسئلة (Question Group) ديناميكياً بناءً على قيمة رقمية من سؤال آخر.

---

## 📝 مثال عملي من البيانات

### السيناريو: بيانات أفراد الأسرة

```
السؤال المصدر (Source):
- ID: 10850
- Code: HH_MEMBERS_COUNT
- Text: "كم عدد أفراد الأسرة المقيمين بشكل دائم؟"
- Type: Integer (1)

المجموعة المستهدفة (Target Group):
- ID: 83
- Code: INDIVIDUAL_BLOCK
- Name: "كتلة بيانات فرد من أفراد الأسرة"
- Questions: 3 أسئلة (رقم الفرد، الجنس، الحالة التعليمية)
```

### الشرط (Condition):

```json
{
  "id": 11,
  "sourceQuestionId": 10850,       // السؤال: عدد الأفراد
  "targetType": 2,                 // الهدف: Group
  "targetGroupId": 83,             // المجموعة: بيانات الفرد
  "action": 4,                     // الإجراء: Repetition
  "operator": 11,                  // المعامل: RepeatForCount
  "value": null                    // القيمة: null (يستخدم قيمة السؤال)
}
```

---

## ⚙️ كيف يعمل النظام؟

### 1️⃣ المستخدم يدخل العدد

```
المستخدم يكتب: 5
↓
يتم حفظ الإجابة: questionId=10850, value=5
↓
_evaluateAllConditions() يُستدعى
```

### 2️⃣ تقييم الشرط

```dart
// في _evaluateQuestionConditions
for (final condition in question.sourceConditions) {
  final answer = _getAnswerValue(condition.sourceQuestionId);
  // answer = 5
  
  final conditionMet = _isConditionMet(answer, condition);
  // conditionMet = true (لأن answer موجود و operator = RepeatForCount)
  
  if (conditionMet) {
    _applyConditionAction(condition);
  }
}
```

### 3️⃣ تطبيق التكرار

```dart
// في _applyGroupAction
case ConditionAction.repetition:
  final answerValue = _getAnswerValue(condition.sourceQuestionId);
  int count = 1;
  
  if (answerValue != null) {
    if (answerValue is int) {
      count = answerValue; // count = 5
    }
  }
  
  _groupRepetitions[groupId] = count; // _groupRepetitions[83] = 5
```

### 4️⃣ عرض المجموعة متكررة

```dart
// في الشاشة
final repetitions = viewModel.getGroupRepetitions(group.id);
// repetitions = 5

...List.generate(repetitions, (instanceIndex) {
  // يتكرر 5 مرات: instanceIndex = 0, 1, 2, 3, 4
  
  return Column(
    children: [
      Text('التكرار ${instanceIndex + 1}'), // التكرار 1، 2، 3، 4، 5
      ...viewModel.getVisibleQuestions(group: group).map((question) {
        return QuestionWidget(
          question: question,
          groupInstanceId: instanceIndex, // مهم جداً!
          onChanged: (value) {
            viewModel.saveAnswer(
              questionId: question.id,
              questionCode: question.code,
              value: value,
              groupInstanceId: instanceIndex, // يحفظ مع instanceId
            );
          },
        );
      }),
    ],
  );
})
```

---

## 🎯 النتيجة النهائية

### إذا أدخل المستخدم: `3`

```
القسم الأول
├── بيانات أساسية عن الأسرة
│   └── عدد الأفراد: 3 ✓
│
├── كتلة بيانات فرد من أفراد الأسرة - التكرار 1
│   ├── رقم الفرد: __
│   ├── الجنس: __
│   └── الحالة التعليمية: __
│
├── كتلة بيانات فرد من أفراد الأسرة - التكرار 2
│   ├── رقم الفرد: __
│   ├── الجنس: __
│   └── الحالة التعليمية: __
│
└── كتلة بيانات فرد من أفراد الأسرة - التكرار 3
    ├── رقم الفرد: __
    ├── الجنس: __
    └── الحالة التعليمية: __
```

---

## 🔑 النقاط المهمة

### 1. **groupInstanceId**

كل تكرار لازم يكون له `groupInstanceId` فريد:

```dart
// التكرار 1
groupInstanceId: 0

// التكرار 2
groupInstanceId: 1

// التكرار 3
groupInstanceId: 2
```

### 2. **حفظ الإجابات**

كل إجابة تُحفظ مع الـ `groupInstanceId`:

```json
{
  "questionId": 10853,
  "questionCode": "IND_MEMBER_INDEX",
  "value": "1",
  "groupInstanceId": 0  // التكرار الأول
}

{
  "questionId": 10853,
  "questionCode": "IND_MEMBER_INDEX",
  "value": "2",
  "groupInstanceId": 1  // التكرار الثاني
}
```

### 3. **التحديث الديناميكي**

لو المستخدم غيّر العدد من `3` إلى `5`:

```
1. يتم حفظ القيمة الجديدة: 5
2. _evaluateAllConditions() يُستدعى
3. _groupRepetitions[83] = 5
4. notifyListeners() يُستدعى
5. الواجهة تتحدث وتعرض 5 تكرارات
```

### 4. **الحد الأدنى (minCount)**

```dart
// في _applyGroupAction
if (group != null && count < group.minCount) {
  count = group.minCount;
}
```

إذا المستخدم أدخل `0` أو قيمة أقل من `minCount`، يتم استخدام `minCount`.

---

## 🐛 استكشاف المشاكل

### المشكلة: التكرار لا يظهر

✅ **الحلول:**

1. **تحقق من نوع السؤال المصدر:**
   ```dart
   "type": 1  // يجب أن يكون Integer
   ```

2. **تحقق من الشرط:**
   ```json
   {
     "targetType": 2,        // Group
     "action": 4,            // Repetition
     "operator": 11          // RepeatForCount
   }
   ```

3. **تحقق من حفظ الإجابة:**
   ```dart
   // أضف //print في saveAnswer
   //print('Saved answer: questionId=$questionId, value=$value');
   ```

4. **تحقق من التقييم:**
   ```dart
   // أضف //print في _applyGroupAction
   //print('Repetition: groupId=$groupId, count=$count');
   ```

---

## 💡 نصائح للمطورين

### 1. استخدم TextField مع Done button

```dart
TextField(
  textInputAction: TextInputAction.done,
  onSubmitted: (value) {
    // Close keyboard
    FocusScope.of(context).unfocus();
    // Trigger save
    widget.onChanged(value);
  },
)
```

### 2. أضف زر تأكيد مرئي

```dart
suffixIcon: _controller.text.isNotEmpty
    ? IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        onPressed: () {
          FocusScope.of(context).unfocus();
          widget.onChanged(_controller.text);
        },
      )
    : null,
```

### 3. تحويل القيم بشكل صحيح

```dart
if (question.questionType == QuestionType.integer) {
  final intValue = int.tryParse(value);
  if (intValue != null) {
    onChanged(intValue); // حفظ كـ int
  }
}
```

---

## 📊 مخطط التدفق الكامل

```
┌──────────────────────────────────────┐
│   المستخدم يدخل عدد الأفراد: 5      │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│  TextField.onChanged() أو onSubmitted│
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│    QuestionWidget.onChanged(5)       │
│    (تحويل إلى int)                   │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   viewModel.saveAnswer(              │
│     questionId: 10850,               │
│     value: 5                         │
│   )                                  │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   repository.saveAnswer()            │
│   (حفظ في Hive)                      │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _surveyAnswers تحديث محلياً        │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _evaluateAllConditions()           │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _resetConditionsToDefault()        │
│   (إعادة تهيئة كل شيء)               │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _evaluateQuestionConditions()      │
│   (للسؤال 10850)                    │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _isConditionMet(answer=5, ...)     │
│   RepeatForCount → true              │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _applyConditionAction()            │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _applyGroupAction(                 │
│     groupId: 83,                     │
│     action: Repetition               │
│   )                                  │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   _groupRepetitions[83] = 5          │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   notifyListeners()                  │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   Consumer<SurveyDetailsViewModel>   │
│   يعيد بناء الـ Widget                │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   getGroupRepetitions(83) → 5        │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│   List.generate(5, ...)              │
│   عرض 5 تكرارات من المجموعة          │
└──────────────────────────────────────┘
```

---

## ✅ التحقق من العمل

### اختبر بالخطوات التالية:

1. افتح الاستبيان `DEMO_SMALL_SURVEY`
2. في سؤال "عدد الأفراد"، اكتب: `2`
3. اضغط Done على الكيبورد أو زر ✓
4. **يجب أن تظهر المجموعة مرتين فوراً**
5. غيّر العدد إلى: `5`
6. اضغط Done
7. **يجب أن تظهر المجموعة 5 مرات فوراً**

---

## 🎉 الخلاصة

نظام التكرار:
- ✅ يعمل ديناميكياً مع setState
- ✅ يحفظ كل إجابة مع groupInstanceId
- ✅ يدعم التحديث الفوري
- ✅ يتعامل مع minCount و maxCount
- ✅ مُحسّن للأداء

**كل شيء جاهز ويعمل! 🚀**
