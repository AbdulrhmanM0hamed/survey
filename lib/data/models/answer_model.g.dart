// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnswerModelAdapter extends TypeAdapter<AnswerModel> {
  @override
  final int typeId = 7;

  @override
  AnswerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnswerModel(
      questionId: fields[0] as int,
      questionCode: fields[1] as String,
      value: fields[2] as dynamic,
      timestamp: fields[3] as DateTime,
      groupInstanceId: fields[4] as int?,
      questionType: fields[5] as int?,
      groupId: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AnswerModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.questionCode)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.groupInstanceId)
      ..writeByte(5)
      ..write(obj.questionType)
      ..writeByte(6)
      ..write(obj.groupId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SurveyAnswersModelAdapter extends TypeAdapter<SurveyAnswersModel> {
  @override
  final int typeId = 8;

  @override
  SurveyAnswersModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SurveyAnswersModel(
      surveyId: fields[0] as int,
      surveyCode: fields[1] as String,
      answers: (fields[2] as List).cast<AnswerModel>(),
      startedAt: fields[3] as DateTime,
      completedAt: fields[4] as DateTime?,
      isDraft: fields[5] as bool,
      researcherName: fields[6] as String?,
      supervisorName: fields[7] as String?,
      cityName: fields[8] as String?,
      neighborhoodName: fields[9] as String?,
      streetName: fields[10] as String?,
      isApproved: fields[11] as bool?,
      rejectReason: fields[12] as String?,
      researcherId: fields[13] as int?,
      supervisorId: fields[14] as int?,
      cityId: fields[15] as int?,
      latitude: fields[16] as double?,
      longitude: fields[17] as double?,
      buildingFloorsCount: fields[18] as int?,
      apartmentsPerFloor: fields[19] as int?,
      selectedFloor: fields[20] as int?,
      selectedApartment: fields[21] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SurveyAnswersModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.surveyId)
      ..writeByte(1)
      ..write(obj.surveyCode)
      ..writeByte(2)
      ..write(obj.answers)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.isDraft)
      ..writeByte(6)
      ..write(obj.researcherName)
      ..writeByte(7)
      ..write(obj.supervisorName)
      ..writeByte(8)
      ..write(obj.cityName)
      ..writeByte(9)
      ..write(obj.neighborhoodName)
      ..writeByte(10)
      ..write(obj.streetName)
      ..writeByte(11)
      ..write(obj.isApproved)
      ..writeByte(12)
      ..write(obj.rejectReason)
      ..writeByte(13)
      ..write(obj.researcherId)
      ..writeByte(14)
      ..write(obj.supervisorId)
      ..writeByte(15)
      ..write(obj.cityId)
      ..writeByte(16)
      ..write(obj.latitude)
      ..writeByte(17)
      ..write(obj.longitude)
      ..writeByte(18)
      ..write(obj.buildingFloorsCount)
      ..writeByte(19)
      ..write(obj.apartmentsPerFloor)
      ..writeByte(20)
      ..write(obj.selectedFloor)
      ..writeByte(21)
      ..write(obj.selectedApartment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurveyAnswersModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
