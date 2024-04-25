import 'dart:io';

import 'package:discord_rich_presence/discord_rich_presence.dart';

void main() async {
  final discordRpc = DiscordRPC("APP_ID");

  await discordRpc.connect();

  sleep(Duration(seconds: 1));

  await discordRpc.setActivity(
    Activity(
      details: "Details of the example",
      state: "Example",
      assets: Assets(
        largeText: "Example",
      ),
      timestamps: Timestamps(
        start: DateTime.now().millisecondsSinceEpoch,
      ),
      buttons: [
        Button(
          label: "Google",
          url: "https://google.com",
        ),
      ],
    ),
  );

  await Future.delayed(Duration(seconds: 5));

  await discordRpc.clearActivity();
}
