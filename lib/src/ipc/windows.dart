import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:discord_rich_presence/src/ipc/ipc.dart';

class WindowsIPC extends UniversalIPC {
  int? _handle;

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
  }

  @override
  Future<void> send(String json, int opcode) async {
    if (_handle == null) {
      throw Exception('IPC not connected');
    }

    final data = pack(opcode, json.length);
    final written = calloc<Uint32>();

    final dataPtr = VirtualAllocEx(
      GetCurrentProcess(),
      nullptr,
      data.lengthInBytes,
      VIRTUAL_ALLOCATION_TYPE.MEM_COMMIT | VIRTUAL_ALLOCATION_TYPE.MEM_RESERVE,
      PAGE_PROTECTION_FLAGS.PAGE_READWRITE,
    ).cast<Uint8>();

    dataPtr.asTypedList(data.lengthInBytes).setAll(0, data);

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
  // TODO: implement stream
  Stream<String> get stream => throw UnimplementedError();
}
