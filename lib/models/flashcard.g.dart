// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 1;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Flashcard(
      id: fields[0] as String,
      deckId: fields[1] as String,
      questionZh: fields[2] as String,
      questionEn: fields[3] as String,
      answerZh: fields[4] as String,
      answerEn: fields[5] as String,
      knowledgeTag: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deckId)
      ..writeByte(2)
      ..write(obj.questionZh)
      ..writeByte(3)
      ..write(obj.questionEn)
      ..writeByte(4)
      ..write(obj.answerZh)
      ..writeByte(5)
      ..write(obj.answerEn)
      ..writeByte(6)
      ..write(obj.knowledgeTag);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
