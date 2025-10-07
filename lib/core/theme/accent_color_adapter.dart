import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AccentColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 2;

  @override
  Color read(BinaryReader reader) {
    final int value = reader.readInt();
    return Color(value);
  }

  @override
  void write(BinaryWriter writer, Color accentColor) {
    writer.writeInt(accentColor.toARGB32());
  }
}