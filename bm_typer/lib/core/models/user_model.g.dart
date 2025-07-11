// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      email: fields[2] as String,
      wpmHistory: (fields[3] as List?)?.cast<double>(),
      accuracyHistory: (fields[4] as List?)?.cast<double>(),
      highestWpm: fields[5] as double?,
      completedLessons: (fields[6] as List?)?.cast<String>(),
      unlockedAchievements: (fields[7] as List?)?.cast<String>(),
      xpPoints: fields[8] as int?,
      level: fields[9] as int?,
      streakCount: fields[10] as int?,
      lastLoginDate: fields[11] as DateTime?,
      shownAchievementNotifications: (fields[12] as List?)?.cast<String>(),
      goalWpm: fields[13] as double?,
      goalAccuracy: fields[14] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.wpmHistory)
      ..writeByte(4)
      ..write(obj.accuracyHistory)
      ..writeByte(5)
      ..write(obj.highestWpm)
      ..writeByte(6)
      ..write(obj.completedLessons)
      ..writeByte(7)
      ..write(obj.unlockedAchievements)
      ..writeByte(8)
      ..write(obj.xpPoints)
      ..writeByte(9)
      ..write(obj.level)
      ..writeByte(10)
      ..write(obj.streakCount)
      ..writeByte(11)
      ..write(obj.lastLoginDate)
      ..writeByte(12)
      ..write(obj.shownAchievementNotifications)
      ..writeByte(13)
      ..write(obj.goalWpm)
      ..writeByte(14)
      ..write(obj.goalAccuracy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
