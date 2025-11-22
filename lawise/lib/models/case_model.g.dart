// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'case_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CaseModelAdapter extends TypeAdapter<CaseModel> {
  @override
  final int typeId = 0;

  @override
  CaseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CaseModel(
      id: fields[0] as String,
      title: fields[1] as String,
      plaintiff: fields[2] as String,
      defendant: fields[3] as String,
      caseNumber: fields[4] as String,
      court: fields[5] as String,
      hearingDate: fields[6] as DateTime,
      status: fields[7] as CaseStatus,
      notes: fields[8] as String?,
      attachmentPaths: (fields[9] as List).cast<String>(),
      attachmentUrls: (fields[10] as List).cast<String>(),
      isSynced: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      ownerId: fields[14] as String,
      lastNotePreview: fields[15] as String?,
      category: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CaseModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.plaintiff)
      ..writeByte(3)
      ..write(obj.defendant)
      ..writeByte(4)
      ..write(obj.caseNumber)
      ..writeByte(5)
      ..write(obj.court)
      ..writeByte(6)
      ..write(obj.hearingDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.attachmentPaths)
      ..writeByte(10)
      ..write(obj.attachmentUrls)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.ownerId)
      ..writeByte(15)
      ..write(obj.lastNotePreview)
      ..writeByte(16)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CaseStatusAdapter extends TypeAdapter<CaseStatus> {
  @override
  final int typeId = 1;

  @override
  CaseStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CaseStatus.draft;
      case 1:
        return CaseStatus.inProgress;
      case 2:
        return CaseStatus.closed;
      default:
        return CaseStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, CaseStatus obj) {
    switch (obj) {
      case CaseStatus.draft:
        writer.writeByte(0);
        break;
      case CaseStatus.inProgress:
        writer.writeByte(1);
        break;
      case CaseStatus.closed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
