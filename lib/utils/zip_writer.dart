import 'dart:convert';
import 'dart:typed_data';

/// A minimal, dependency-free ZIP writer.
///
/// Entries are stored uncompressed (method 0) which is all SevaSetu needs to
/// bundle small sample documents. The produced archive is a standard ZIP and
/// opens in any unarchiver.
class ZipEntry {
  const ZipEntry(this.name, this.data);
  final String name;
  final Uint8List data;
}

class ZipWriter {
  ZipWriter._();

  static Uint8List write(List<ZipEntry> entries) {
    final builder = BytesBuilder(copy: false);
    final central = <int>[]; // central directory bytes
    var offset = 0;

    for (final entry in entries) {
      final name = utf8.encode(entry.name);
      final crc = crc32(entry.data);
      final time = DateTime.now();
      final dosTime =
          (time.hour << 11) | (time.minute << 5) | (time.second ~/ 2);
      final dosDate = ((time.year - 1980) << 9) | (time.month << 5) | time.day;

      // ---- Local file header ----
      _u32(builder, 0x04034b50);
      _u16(builder, 20); // version needed
      _u16(builder, 0); // flags
      _u16(builder, 0); // method: stored
      _u16(builder, dosTime);
      _u16(builder, dosDate);
      _u32(builder, crc);
      _u32(builder, entry.data.length);
      _u32(builder, entry.data.length);
      _u16(builder, name.length);
      _u16(builder, 0); // extra length
      builder.add(name);
      builder.add(entry.data);

      // ---- Central directory record ----
      final centralBuilder = BytesBuilder(copy: false);
      _u32(centralBuilder, 0x02014b50);
      _u16(centralBuilder, 20); // version made by
      _u16(centralBuilder, 20); // version needed
      _u16(centralBuilder, 0); // flags
      _u16(centralBuilder, 0); // method
      _u16(centralBuilder, dosTime);
      _u16(centralBuilder, dosDate);
      _u32(centralBuilder, crc);
      _u32(centralBuilder, entry.data.length);
      _u32(centralBuilder, entry.data.length);
      _u16(centralBuilder, name.length);
      _u16(centralBuilder, 0); // extra
      _u16(centralBuilder, 0); // comment
      _u16(centralBuilder, 0); // disk
      _u16(centralBuilder, 0); // internal attrs
      _u32(centralBuilder, 0); // external attrs
      _u32(centralBuilder, offset);
      centralBuilder.add(name);
      central.addAll(centralBuilder.toBytes());

      offset += 30 + name.length + entry.data.length;
    }

    final centralBytes = Uint8List.fromList(central);
    final cdStart = builder.length;
    builder.add(centralBytes);

    // ---- End of central directory ----
    _u32(builder, 0x06054b50);
    _u16(builder, 0); // this disk
    _u16(builder, 0); // cd start disk
    _u16(builder, entries.length);
    _u16(builder, entries.length);
    _u32(builder, centralBytes.length);
    _u32(builder, cdStart);
    _u16(builder, 0); // comment length

    return builder.toBytes();
  }

  static void _u16(BytesBuilder b, int v) {
    b.addByte(v & 0xFF);
    b.addByte((v >> 8) & 0xFF);
  }

  static void _u32(BytesBuilder b, int v) {
    b.addByte(v & 0xFF);
    b.addByte((v >> 8) & 0xFF);
    b.addByte((v >> 16) & 0xFF);
    b.addByte((v >> 24) & 0xFF);
  }

  /// Standard CRC-32 (IEEE 802.3 polynomial 0xEDB88320).
  static final Uint32List _crcTable = _buildCrcTable();

  static Uint32List _buildCrcTable() {
    final table = Uint32List(256);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
      table[n] = c;
    }
    return table;
  }

  static int crc32(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc = (crc >> 8) ^ _crcTable[(crc ^ byte) & 0xFF];
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
