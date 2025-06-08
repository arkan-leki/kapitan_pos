// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 3;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      items: (fields[1] as List).cast<OrderItem>(),
      orderType: fields[2] as OrderType,
      customerName: fields[3] as String,
      deliveryAddress: fields[4] as String,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(5)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.orderType)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.deliveryAddress)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderTypeAdapter extends TypeAdapter<OrderType> {
  @override
  final int typeId = 1;

  @override
  OrderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderType.onsite;
      case 1:
        return OrderType.delivery;
      default:
        return OrderType.onsite;
    }
  }

  @override
  void write(BinaryWriter writer, OrderType obj) {
    switch (obj) {
      case OrderType.onsite:
        writer.writeByte(0);
        break;
      case OrderType.delivery:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
