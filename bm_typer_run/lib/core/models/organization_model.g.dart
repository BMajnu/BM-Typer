// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrganizationModelAdapter extends TypeAdapter<OrganizationModel> {
  @override
  final int typeId = 21;

  @override
  OrganizationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrganizationModel(
      id: fields[0] as String,
      name: fields[1] as String,
      adminEmail: fields[2] as String,
      adminUserId: fields[3] as String?,
      memberCount: fields[4] as int,
      maxMembers: fields[5] as int,
      subscriptionType: fields[6] as String,
      expiryDate: fields[7] as DateTime?,
      createdAt: fields[8] as DateTime,
      isActive: fields[9] as bool,
      logoUrl: fields[10] as String?,
      address: fields[11] as String?,
      phone: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrganizationModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.adminEmail)
      ..writeByte(3)
      ..write(obj.adminUserId)
      ..writeByte(4)
      ..write(obj.memberCount)
      ..writeByte(5)
      ..write(obj.maxMembers)
      ..writeByte(6)
      ..write(obj.subscriptionType)
      ..writeByte(7)
      ..write(obj.expiryDate)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.logoUrl)
      ..writeByte(11)
      ..write(obj.address)
      ..writeByte(12)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrgMemberModelAdapter extends TypeAdapter<OrgMemberModel> {
  @override
  final int typeId = 22;

  @override
  OrgMemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrgMemberModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      email: fields[2] as String,
      name: fields[3] as String,
      role: fields[4] as String,
      joinedAt: fields[5] as DateTime,
      isActive: fields[6] as bool,
      teamLeadId: fields[7] as String?,
      isTeamLead: fields[8] as bool,
      photoUrl: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrgMemberModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.joinedAt)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.teamLeadId)
      ..writeByte(8)
      ..write(obj.isTeamLead)
      ..writeByte(9)
      ..write(obj.photoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgMemberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
