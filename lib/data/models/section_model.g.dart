// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SectionModelAdapter extends TypeAdapter<SectionModel> {
  @override
  final int typeId = 4;

  @override
  SectionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SectionModel(
      id: fields[0] as int,
      name: fields[1] as String,
      order: fields[2] as int,
      isForEnumeratorOnly: fields[3] as bool,
      isActive: fields[4] as bool,
      questionGroups: (fields[5] as List).cast<QuestionGroupModel>(),
      questions: (fields[6] as List).cast<QuestionModel>(),
      targetConditions: (fields[7] as List).cast<ConditionModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, SectionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.isForEnumeratorOnly)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.questionGroups)
      ..writeByte(6)
      ..write(obj.questions)
      ..writeByte(7)
      ..write(obj.targetConditions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
