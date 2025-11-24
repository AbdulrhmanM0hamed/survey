enum ConditionAction {
  show(1, 'إظهار', 'Show'),
  hide(2, 'إخفاء', 'Hide'),
  require(3, 'مطلوب', 'Require'),
  repetition(4, 'تكرار', 'Repetition'),
  disable(5, 'تعطيل', 'Disable');

  final int value;
  final String displayNameAr;
  final String displayNameEn;

  const ConditionAction(this.value, this.displayNameAr, this.displayNameEn);

  static ConditionAction fromValue(int value) {
    return ConditionAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => ConditionAction.show,
    );
  }
}
