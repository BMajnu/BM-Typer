import 'package:hive/hive.dart';

part 'user_role.g.dart';

@HiveType(typeId: 20)
enum UserRole {
  @HiveField(0)
  student,

  @HiveField(1)
  teamLead,

  @HiveField(2)
  orgAdmin,

  @HiveField(3)
  superAdmin,
}
