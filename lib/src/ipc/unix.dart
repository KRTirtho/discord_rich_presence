import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:discord_rich_presence/src/ipc/ipc.dart';
import 'package:path/path.dart';

const ENV_KEYS = ["XDG_RUNTIME_DIR", "TMPDIR", "TMP", "TEMP"];
const APP_SUBPATHS = [
  "",
  "app/com.discordapp.Discord/",
  "snap.discord-canary/",
  "snap.discord/",
];

class UnixIPC extends UniversalIPC {
  Socket? _socket;

  UnixIPC();

  Stream<Uint8List>? _stream;

  @override
  Future<void> connectIpc() async {
    if (_socket != null) {
      return;
    }

    final pipePattern =
        ENV_KEYS.map((key) => Platform.environment[key]).firstWhere(
              (element) => element != null,
              orElse: () => null,
            );
    if (pipePattern == null) {
      throw SocketException("Failed to find a valid pipe pattern");
    }

    Socket? socket;
    outer:
    for (int i = 0; i < 10; i++) {
      for (final appSubpath in APP_SUBPATHS) {
        try {
          socket = await Socket.connect(
            InternetAddress(
              join(pipePattern, appSubpath, "discord-ipc-$i"),
              type: InternetAddressType.unix,
            ),
            0,
          );
          break outer;
        } catch (e) {
          print("Failed to connect to $appSubpath: $e");
          continue;
        }
      }
    }

    if (socket == null) {
      throw SocketException("Failed to connect to Discord IPC");
    }

    _socket = socket;
    _stream = _socket!.asBroadcastStream();
  }

  @override
  Future<void> closeIpc() async {
    if (_socket == null) {
      return;
    }

    await send("", 2);

    await _stream!.drain();
    await _socket!.flush();
    await _socket!.close();
    _socket = null;
    _stream = null;
  }

  @override
  Future<void> send(String json, int opcode) {
    if (_socket == null) {
      throw SocketException("IPC is not connected");
    }

    final data = utf8.encode(json);
    final packed = pack(opcode, data.length);
    _socket!.add(packed);
    _socket!.add(data);
    return _socket!.flush();
  }

  @override
  Stream<String> get stream {
    if (_stream == null) {
      throw SocketException("IPC is not connected");
    }

    return _stream!.cast<Uint8List>().map((event) {
      final unpacked = unpack(event);
      return utf8.decode(event.sublist(8, 8 + unpacked.dataLen));
    });
  }
}
