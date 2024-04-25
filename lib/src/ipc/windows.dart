import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:discord_rich_presence/src/ipc/ipc.dart';

class WindowsIPC extends UniversalIPC {
  int? _handle;
  final _streamController = StreamController<String>();

  @override
  Future<void> closeIpc() async {
    if (_handle == null) {
      return;
    }
  }

  @override
  Future<void> connectIpc() async {
    for (int i = 0; i < 10; i++) {
      try {
        final pipeName = r'\\.\pipe\discord-ipc-' + i.toString();

        _handle = CreateNamedPipe(
          TEXT(pipeName),
          FILE_FLAGS_AND_ATTRIBUTES.PIPE_ACCESS_DUPLEX,
          NAMED_PIPE_MODE.PIPE_TYPE_BYTE |
              NAMED_PIPE_MODE.PIPE_READMODE_BYTE |
              NAMED_PIPE_MODE.PIPE_WAIT,
          1,
          0,
          0,
          0,
          nullptr,
        );

        if (_handle == INVALID_HANDLE_VALUE) {
          throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
        }
      } catch (e) {
        print('Failed to connect to pipe: $e');
        continue;
      }
    }

    if (_handle == null) {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }

    // non blocking read file loop. We can use unpack to know the size of the next message
    // and then read that amount of bytes
    await Future(() async {
      while (true) {
        final data = calloc<Uint8>(4096);
        final read = calloc<Uint32>();

        final success = ReadFile(
          _handle!,
          data,
          8,
          read,
          nullptr,
        );

        if (success == 0) {
          throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
        }

        final size = data.asTypedList(8).buffer.asByteData().getUint64(0);

        calloc.free(data);
        calloc.free(read);

        final data2 = calloc<Uint8>(size);
        final read2 = calloc<Uint32>();

        final success2 = ReadFile(
          _handle!,
          data2,
          size,
          read2,
          nullptr,
        );

        if (success2 == 0) {
          throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
        }

        final json = utf8.decode(data2.asTypedList(size));

        _streamController.add(json);

        calloc.free(data2);
        calloc.free(read2);
      }
    });
  }

  void write(Uint8List data) {
    final dataPtr = VirtualAllocEx(
      GetCurrentProcess(),
      nullptr,
      data.lengthInBytes,
      VIRTUAL_ALLOCATION_TYPE.MEM_COMMIT | VIRTUAL_ALLOCATION_TYPE.MEM_RESERVE,
      PAGE_PROTECTION_FLAGS.PAGE_READWRITE,
    ).cast<Uint8>();

    dataPtr.asTypedList(data.lengthInBytes).setAll(0, data);

    final written = calloc<Uint32>();

    final success = WriteFile(
      _handle!,
      dataPtr,
      data.length,
      written,
      nullptr,
    );

    if (success == 0) {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }

    calloc.free(written);
    VirtualFreeEx(
      GetCurrentProcess(),
      dataPtr,
      0,
      VIRTUAL_FREE_TYPE.MEM_RELEASE,
    );
  }

  @override
  Future<void> send(String json, int opcode) async {
    if (_handle == null) {
      throw Exception('IPC not connected');
    }

    final data = pack(opcode, json.length);

    write(data);
    write(utf8.encode(json));
  }

  @override
  Stream<String> get stream => _streamController.stream;
}
