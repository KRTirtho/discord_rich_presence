import 'dart:typed_data';

abstract class UniversalIPC {
  Future<void> connectIpc();
  Future<void> closeIpc();
  Future<void> send(String json, int opcode);
  Stream<String> get stream;

  Uint8List pack(int opcode, int dataLen) {
    final buffer = Uint8List(8); // Allocate 8 bytes for opcode and data length
    ByteData data = buffer.buffer.asByteData();
    data.setUint32(0, opcode, Endian.little);
    data.setUint32(4, dataLen, Endian.little);
    return buffer;
  }

  ({int opcode, int dataLen}) unpack(Uint8List data) {
    if (data.length < 8) {
      throw ArgumentError('Data length is less than expected (8 bytes)');
    }
    final byteData = data.buffer.asByteData();
    final opcode = byteData.getUint32(0, Endian.little);
    final dataLen = byteData.getUint32(4, Endian.little);
    return (opcode: opcode, dataLen: dataLen);
  }
}
