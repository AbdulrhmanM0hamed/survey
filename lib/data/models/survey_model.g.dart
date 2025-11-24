// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SurveyModelAdapter extends TypeAdapter<SurveyModel> {
  @override
  final int typeId = 5;

  @override
  SurveyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SurveyModel(
      id: fields[0] as int,
      code: fields[1] as String,
      name: fields[2] as String,
      version: fields[3] as String,
      description: fields[4] as String,
      language: fields[5] as String,
      scope: fields[6] as String,
      termsAndConditions: fields[7] as String?,
      isActive: fields[8] as bool,
      sections: (fields[9] as List?)?.cast<SectionModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, SurveyModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.language)
      ..writeByte(6)
      ..write(obj.scope)
      ..writeByte(7)
      ..write(obj.termsAndConditions)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.sections);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurveyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SurveyListResponseAdapter extends TypeAdapter<SurveyListResponse> {
  @override
  final int typeId = 6;

  @override
  SurveyListResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SurveyListResponse(
      items: (fields[0] as List).cast<SurveyModel>(),
      total: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SurveyListResponse obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.items)
      ..writeByte(1)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurveyListResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
