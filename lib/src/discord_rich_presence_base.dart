import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:discord_rich_presence/src/ipc/ipc.dart';
import 'package:discord_rich_presence/src/ipc/unix.dart';
import 'package:discord_rich_presence/src/ipc/windows.dart';
import 'package:discord_rich_presence/src/models/activity.dart';
import 'package:uuid/uuid.dart';

class DiscordRPC {
  late UniversalIPC _ipc;
  final String clientId;
  static const Uuid _uuid = Uuid();

  StreamSubscription? _subscription;

  DiscordRPC(this.clientId) {
    if (Platform.isWindows) {
      _ipc = WindowsIPC();
    } else {
      _ipc = UnixIPC();
    }
  }

  Future<void> connect() async {
    await _ipc.connectIpc();
    await _sendHandshake();

    _subscription = _ipc.stream.listen(
      (json) {
        print("Received: $json");
      },
      onDone: () {
        print("Disconnected");
      },
    );
  }

  Future<void> _sendHandshake() async {
    await _ipc.send(
      jsonEncode({
        "v": 1,
        "client_id": clientId,
      }),
      0,
    );
  }

  Future<void> setActivity(Activity activity) {
    return _ipc.send(
      jsonEncode({
        "cmd": "SET_ACTIVITY",
        "args": {
          "pid": pid,
          "activity": activity.toJson(),
        },
        "nonce": _uuid.v4(),
      }),
      1,
    );
  }

  Future<void> clearActivity() {
    return _ipc.send(
      jsonEncode({
        "cmd": "SET_ACTIVITY",
        "args": {
          "pid": pid,
          "activity": null,
        },
        "nonce": _uuid.v4(),
      }),
      1,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _ipc.closeIpc();
  }
}
