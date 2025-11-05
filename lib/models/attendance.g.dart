// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 4;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attendance(
      traineeId: fields[0] as String,
      status: fields[1] as PresenceStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.traineeId)
      ..writeByte(1)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PresenceStatusAdapter extends TypeAdapter<PresenceStatus> {
  @override
  final int typeId = 3;

  @override
  PresenceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PresenceStatus.Present;
      case 1:
        return PresenceStatus.Absent;
      case 2:
        return PresenceStatus.CatchUp;
      default:
        return PresenceStatus.Present;
    }
  }

  @override
  void write(BinaryWriter writer, PresenceStatus obj) {
    switch (obj) {
      case PresenceStatus.Present:
        writer.writeByte(0);
        break;
      case PresenceStatus.Absent:
        writer.writeByte(1);
        break;
      case PresenceStatus.CatchUp:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresenceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
