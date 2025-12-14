// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TypingSessionAdapter extends TypeAdapter<TypingSession> {
  @override
  final int typeId = 2;

  @override
  TypingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TypingSession(
      wpm: fields[0] as double,
      accuracy: fields[1] as double,
      timestamp: fields[2] as DateTime,
      lessonId: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TypingSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.wpm)
      ..writeByte(1)
      ..write(obj.accuracy)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.lessonId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
