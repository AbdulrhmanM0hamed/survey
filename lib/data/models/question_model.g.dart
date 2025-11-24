// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionModelAdapter extends TypeAdapter<QuestionModel> {
  @override
  final int typeId = 2;

  @override
  QuestionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionModel(
      id: fields[0] as int,
      code: fields[1] as String,
      text: fields[2] as String,
      type: fields[3] as int,
      scope: fields[4] as int,
      order: fields[5] as int,
      isRequired: fields[6] as bool,
      isActive: fields[7] as bool,
      choices: (fields[8] as List).cast<ChoiceModel>(),
      sourceConditions: (fields[9] as List).cast<ConditionModel>(),
      targetConditions: (fields[10] as List).cast<ConditionModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, QuestionModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.scope)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.isRequired)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.choices)
      ..writeByte(9)
      ..write(obj.sourceConditions)
      ..writeByte(10)
      ..write(obj.targetConditions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
