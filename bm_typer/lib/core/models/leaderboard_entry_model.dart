import 'package:hive/hive.dart';

class LeaderboardEntry {
  // Hive field indices retained for manual adapter reference
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String userName;

  @HiveField(2)
  final double wpm;

  @HiveField(3)
  final double accuracy;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? lessonId;

  @HiveField(6)
  final int level;

  @HiveField(7)
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.wpm,
    required this.accuracy,
    required this.timestamp,
    this.lessonId,
    required this.level,
    this.avatarUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.userName == userName &&
        other.wpm == wpm &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp &&
        other.lessonId == lessonId &&
        other.level == level &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        userName.hashCode ^
        wpm.hashCode ^
        accuracy.hashCode ^
        timestamp.hashCode ^
        lessonId.hashCode ^
        level.hashCode ^
        avatarUrl.hashCode;
  }
}

class LeaderboardEntryAdapter extends TypeAdapter<LeaderboardEntry> {
  @override
  final int typeId = 3;

  @override
  LeaderboardEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeaderboardEntry(
      userId: fields[0] as String,
      userName: fields[1] as String,
      wpm: fields[2] as double,
      accuracy: fields[3] as double,
      timestamp: fields[4] as DateTime,
      lessonId: fields[5] as String?,
      level: fields[6] as int,
      avatarUrl: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LeaderboardEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.userName)
      ..writeByte(2)
      ..write(obj.wpm)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.lessonId)
      ..writeByte(6)
      ..write(obj.level)
      ..writeByte(7)
      ..write(obj.avatarUrl);
  }
}
