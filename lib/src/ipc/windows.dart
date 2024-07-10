import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:discord_rich_presence/src/ipc/ipc.dart';

class WindowsIPC extends UniversalIPC {
  int? _handle;
  StreamSubscription? _subscription;
  ReceivePort? _receivePort;

  final _streamController = StreamController<String>();

  @override
  Future<void> closeIpc() async {
    if (_handle == null) {
      return;
    }

    _subscription?.cancel();
    _receivePort?.close();
    CloseHandle(_handle!);
    _handle = null;
  }

  void _startListening() async {
    _receivePort = ReceivePort();
    await Isolate.spawn(_listen, [_handle, _receivePort!.sendPort]);
    _subscription = _receivePort!.listen((message) {
      _streamController.add(message);
    });
  }

  static void _listen(List args) {
    final handle = args[0] as int;
    final sendPort = args[1] as SendPort;
    final lpBuffer = wsalloc(128);
    final lpNumBytesRead = calloc<DWORD>();

    try {
      while (true) {
        final bytesRead = calloc<Uint32>();

        try {
          final result = ReadFile(
            handle,
            lpBuffer.cast(),
            128,
            lpNumBytesRead,
            nullptr,
          );

          if (result != NULL) {
            final message = lpBuffer.toDartString();
            sendPort.send(message);
          } else {
            stdout
                .writeln('Failed to read from pipe. Error: ${GetLastError()}');
          }
        } finally {
          free(bytesRead);
        }
      }
    } finally {
      free(lpBuffer);
      free(lpNumBytesRead);
    }
  }

  @override
  Future<void> connectIpc() async {
    for (int i = 0; i < 10; i++) {
      final pipeNamePtr = TEXT(r'\\.\pipe\discord-ipc-' + i.toString());
      try {
        while (true) {
          _handle = CreateFile(
            pipeNamePtr,
            GENERIC_ACCESS_RIGHTS.GENERIC_READ,
            FILE_SHARE_MODE.FILE_SHARE_READ | FILE_SHARE_MODE.FILE_SHARE_WRITE,
            nullptr,
            FILE_CREATION_DISPOSITION.OPEN_EXISTING,
            FILE_FLAGS_AND_ATTRIBUTES.FILE_ATTRIBUTE_NORMAL,
            NULL,
          );

          if (_handle != INVALID_HANDLE_VALUE) {
            break;
          } else {
            final error = GetLastError();
            if (error != WIN32_ERROR.ERROR_PIPE_BUSY) {
              stderr.writeln('Failed to connect to named pipe. Error: $error');
              return;
            }
            stdout.writeln('Waiting for client to connect...');
            Sleep(1000); // Wait for 1 second before retrying
          }
        }

        stdout.writeln('Client connected to \\\\.\\pipe\\discord-ipc-$i');
        _startListening();
        break;
      } catch (e) {
        print('Failed to connect to pipe: $e');
        continue;
      } finally {
        free(pipeNamePtr);
      }
    }
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

    final written = calloc<DWORD>();

    final success = WriteFile(
      _handle!,
      dataPtr,
      data.length,
      written,
      nullptr,
    );

    if (success == INVALID_HANDLE_VALUE) {
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
