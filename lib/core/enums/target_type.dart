enum TargetType {
  question(1, 'سؤال', 'Question'),
  group(2, 'مجموعة', 'Group'),
  section(3, 'قسم', 'Section');

  final int value;
  final String displayNameAr;
  final String displayNameEn;

  const TargetType(this.value, this.displayNameAr, this.displayNameEn);

  static TargetType fromValue(int value) {
    return TargetType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TargetType.question,
    );
  }
}
