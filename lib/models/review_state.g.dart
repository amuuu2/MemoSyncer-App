// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewStateAdapter extends TypeAdapter<ReviewState> {
  @override
  final int typeId = 2;

  @override
  ReviewState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewState(
      cardId: fields[0] as String,
      easinessFactor: fields[1] as double,
      interval: fields[2] as int,
      repetitions: fields[3] as int,
      nextReview: fields[4] as DateTime?,
      reviewHistory: (fields[5] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReviewState obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.cardId)
      ..writeByte(1)
      ..write(obj.easinessFactor)
      ..writeByte(2)
      ..write(obj.interval)
      ..writeByte(3)
      ..write(obj.repetitions)
      ..writeByte(4)
      ..write(obj.nextReview)
      ..writeByte(5)
      ..write(obj.reviewHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
