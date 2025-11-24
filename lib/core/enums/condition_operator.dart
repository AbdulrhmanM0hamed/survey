enum ConditionOperator {
  equals(1, 'يساوي', 'Equals'),
  notEquals(2, 'لا يساوي', 'NotEquals'),
  greaterThan(3, 'أكبر من', 'GreaterThan'),
  lessThan(4, 'أقل من', 'LessThan'),
  greaterThanOrEqual(5, 'أكبر من أو يساوي', 'GreaterThanOrEqual'),
  lessThanOrEqual(6, 'أقل من أو يساوي', 'LessThanOrEqual'),
  contains(7, 'يحتوي على', 'Contains'),
  startsWith(8, 'يبدأ بـ', 'StartsWith'),
  endsWith(9, 'ينتهي بـ', 'EndsWith'),
  inList(10, 'ضمن', 'In'),
  repeatForCount(11, 'تكرار بالعدد', 'RepeatForCount');

  final int value;
  final String displayNameAr;
  final String displayNameEn;

  const ConditionOperator(this.value, this.displayNameAr, this.displayNameEn);

  static ConditionOperator fromValue(int value) {
    return ConditionOperator.values.firstWhere(
      (operator) => operator.value == value,
      orElse: () => ConditionOperator.equals,
    );
  }

  bool evaluate(dynamic sourceValue, dynamic targetValue) {
    switch (this) {
      case ConditionOperator.equals:
        return sourceValue == targetValue;
      case ConditionOperator.notEquals:
        return sourceValue != targetValue;
      case ConditionOperator.greaterThan:
        return _compareNumbers(sourceValue, targetValue, (a, b) => a > b);
      case ConditionOperator.lessThan:
        return _compareNumbers(sourceValue, targetValue, (a, b) => a < b);
      case ConditionOperator.greaterThanOrEqual:
        return _compareNumbers(sourceValue, targetValue, (a, b) => a >= b);
      case ConditionOperator.lessThanOrEqual:
        return _compareNumbers(sourceValue, targetValue, (a, b) => a <= b);
      case ConditionOperator.contains:
        return sourceValue.toString().contains(targetValue.toString());
      case ConditionOperator.startsWith:
        return sourceValue.toString().startsWith(targetValue.toString());
      case ConditionOperator.endsWith:
        return sourceValue.toString().endsWith(targetValue.toString());
      case ConditionOperator.inList:
        if (targetValue is List) {
          return targetValue.contains(sourceValue);
        }
        return false;
      case ConditionOperator.repeatForCount:
        return true; // Special case handled separately
    }
  }

  bool _compareNumbers(
    dynamic a,
    dynamic b,
    bool Function(num, num) compare,
  ) {
    final numA = num.tryParse(a.toString());
    final numB = num.tryParse(b.toString());
    if (numA == null || numB == null) return false;
    return compare(numA, numB);
  }
}
