// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'choice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChoiceModelAdapter extends TypeAdapter<ChoiceModel> {
  @override
  final int typeId = 0;

  @override
  ChoiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChoiceModel(
      id: fields[0] as int,
      code: fields[1] as String,
      label: fields[2] as String,
      sortOrder: fields[3] as int,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChoiceModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.sortOrder)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChoiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
