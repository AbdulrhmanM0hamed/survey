// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condition_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConditionModelAdapter extends TypeAdapter<ConditionModel> {
  @override
  final int typeId = 1;

  @override
  ConditionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConditionModel(
      id: fields[0] as int,
      targetType: fields[1] as int,
      targetTypeString: fields[2] as String,
      targetQuestionId: fields[3] as int?,
      targetGroupId: fields[4] as int?,
      targetSectionId: fields[5] as int?,
      targetQuestionName: fields[6] as String?,
      targetGroupName: fields[7] as String?,
      targetSectionName: fields[8] as String?,
      action: fields[9] as int,
      actionString: fields[10] as String,
      value: fields[11] as String?,
      description: fields[12] as String?,
      operator: fields[13] as int,
      operatorString: fields[14] as String,
      sourceQuestionId: fields[15] as int,
      sourceQuestionText: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConditionModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.targetType)
      ..writeByte(2)
      ..write(obj.targetTypeString)
      ..writeByte(3)
      ..write(obj.targetQuestionId)
      ..writeByte(4)
      ..write(obj.targetGroupId)
      ..writeByte(5)
      ..write(obj.targetSectionId)
      ..writeByte(6)
      ..write(obj.targetQuestionName)
      ..writeByte(7)
      ..write(obj.targetGroupName)
      ..writeByte(8)
      ..write(obj.targetSectionName)
      ..writeByte(9)
      ..write(obj.action)
      ..writeByte(10)
      ..write(obj.actionString)
      ..writeByte(11)
      ..write(obj.value)
      ..writeByte(12)
      ..write(obj.description)
      ..writeByte(13)
      ..write(obj.operator)
      ..writeByte(14)
      ..write(obj.operatorString)
      ..writeByte(15)
      ..write(obj.sourceQuestionId)
      ..writeByte(16)
      ..write(obj.sourceQuestionText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConditionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
