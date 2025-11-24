// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_group_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionGroupModelAdapter extends TypeAdapter<QuestionGroupModel> {
  @override
  final int typeId = 3;

  @override
  QuestionGroupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionGroupModel(
      id: fields[0] as int,
      name: fields[1] as String,
      minCount: fields[2] as int,
      maxCount: fields[3] as int?,
      code: fields[4] as String,
      order: fields[5] as int,
      isActive: fields[6] as bool,
      questions: (fields[7] as List).cast<QuestionModel>(),
      targetConditions: (fields[8] as List).cast<ConditionModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, QuestionGroupModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.minCount)
      ..writeByte(3)
      ..write(obj.maxCount)
      ..writeByte(4)
      ..write(obj.code)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.questions)
      ..writeByte(8)
      ..write(obj.targetConditions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionGroupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
