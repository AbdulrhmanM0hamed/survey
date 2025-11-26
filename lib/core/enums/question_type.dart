enum QuestionType {
  text(0, 'نص', 'Text'),
  integer(1, 'عدد صحيح', 'Integer'),
  decimal(2, 'عدد عشري', 'Decimal'),
  yesNo(3, 'نعم/لا', 'YesNo'),
  singleChoice(4, 'اختيار واحد', 'SingleChoice'),
  multiChoice(5, 'اختيارات متعددة', 'MultiChoice'),
  rating(6, 'تقييم', 'Rating'),
  date(7, 'تاريخ', 'Date'),
  duration(8, 'مدة', 'Duration'),
  image(9, 'صورة', 'Image');

  final int value;
  final String displayNameAr;
  final String displayNameEn;

  const QuestionType(this.value, this.displayNameAr, this.displayNameEn);

  static QuestionType fromValue(int value) {
    return QuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuestionType.text,
    );
  }
}
