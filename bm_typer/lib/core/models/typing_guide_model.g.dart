// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_guide_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyPosition _$KeyPositionFromJson(Map<String, dynamic> json) => KeyPosition(
      key: json['key'] as String,
      finger: $enumDecode(_$FingerEnumMap, json['finger']),
      hand: $enumDecode(_$HandEnumMap, json['hand']),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$KeyPositionToJson(KeyPosition instance) =>
    <String, dynamic>{
      'key': instance.key,
      'finger': _$FingerEnumMap[instance.finger]!,
      'hand': _$HandEnumMap[instance.hand]!,
      'x': instance.x,
      'y': instance.y,
    };

const _$FingerEnumMap = {
  Finger.leftPinky: 'leftPinky',
  Finger.leftRing: 'leftRing',
  Finger.leftMiddle: 'leftMiddle',
  Finger.leftIndex: 'leftIndex',
  Finger.leftThumb: 'leftThumb',
  Finger.rightThumb: 'rightThumb',
  Finger.rightIndex: 'rightIndex',
  Finger.rightMiddle: 'rightMiddle',
  Finger.rightRing: 'rightRing',
  Finger.rightPinky: 'rightPinky',
};

const _$HandEnumMap = {
  Hand.left: 'left',
  Hand.right: 'right',
};

TypingGuide _$TypingGuideFromJson(Map<String, dynamic> json) => TypingGuide(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      keySequence: (json['keySequence'] as List<dynamic>)
          .map((e) => KeyPosition.fromJson(e as Map<String, dynamic>))
          .toList(),
      lessonId: json['lessonId'] as String,
      guidanceLevel: (json['guidanceLevel'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$TypingGuideToJson(TypingGuide instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'keySequence': instance.keySequence,
      'lessonId': instance.lessonId,
      'guidanceLevel': instance.guidanceLevel,
    };
