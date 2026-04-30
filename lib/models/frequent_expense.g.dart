// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequent_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FrequentExpenseAdapter extends TypeAdapter<FrequentExpense> {
  @override
  final int typeId = 4;

  @override
  FrequentExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FrequentExpense(
      name: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      subcategory: fields[4] as String,
      description: fields[5] as String,
      fromIncomeSource: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FrequentExpense obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.subcategory)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.fromIncomeSource);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequentExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
