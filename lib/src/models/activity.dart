class Activity {
  final String? state;
  final String? details;
  final Timestamps? timestamps;
  final Assets? assets;
  final Party? party;
  final Secrets? secrets;
  final bool? instance;
  final List<Button>? buttons;

  Activity({
    this.state,
    this.details,
    this.timestamps,
    this.assets,
    this.party,
    this.secrets,
    this.instance,
    this.buttons,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        state: json["state"],
        details: json["details"],
        timestamps: json["timestamps"] == null
            ? null
            : Timestamps.fromJson(json["timestamps"]),
        assets: json["assets"] == null ? null : Assets.fromJson(json["assets"]),
        party: json["party"] == null ? null : Party.fromJson(json["party"]),
        secrets:
            json["secrets"] == null ? null : Secrets.fromJson(json["secrets"]),
        instance: json["instance"],
        buttons: json["buttons"] == null
            ? null
            : List<Button>.from(json["buttons"].map((x) => Button.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "state": state,
        "details": details,
        "timestamps": timestamps?.toJson(),
        "assets": assets?.toJson(),
        "party": party?.toJson(),
        "secrets": secrets?.toJson(),
        "instance": instance,
        "buttons": buttons == null
            ? null
            : List<dynamic>.from(buttons!.map((x) => x.toJson())),
      }..removeWhere((key, value) => value == null);
}

class Assets {
  final String? largeImage;
  final String? largeText;
  final String? smallImage;
  final String? smallText;

  Assets({
    this.largeImage,
    this.largeText,
    this.smallImage,
    this.smallText,
  });

  factory Assets.fromJson(Map<String, dynamic> json) => Assets(
        largeImage: json["large_image"],
        largeText: json["large_text"],
        smallImage: json["small_image"],
        smallText: json["small_text"],
      );

  Map<String, dynamic> toJson() => {
        "large_image": largeImage,
        "large_text": largeText,
        "small_image": smallImage,
        "small_text": smallText,
      }..removeWhere((key, value) => value == null);
}

class Party {
  final String? id;
  final (int, int)? size;

  Party({
    this.id,
    this.size,
  });

  factory Party.fromJson(Map<String, dynamic> json) => Party(
      id: json["id"],
      size: json["size"] == null ? null : (json["size"][0], json["size"][1]));

  Map<String, dynamic> toJson() => {
        "id": id,
        "size": size == null ? null : [size!.$1, size!.$2]
      }..removeWhere((key, value) => value == null);
}

class Secrets {
  final String? join;
  final String? spectate;
  final String? match;

  Secrets({
    this.join,
    this.spectate,
    this.match,
  });

  factory Secrets.fromJson(Map<String, dynamic> json) => Secrets(
        join: json["join"],
        spectate: json["spectate"],
        match: json["match"],
      );

  Map<String, dynamic> toJson() => {
        "join": join,
        "spectate": spectate,
        "match": match,
      }..removeWhere((key, value) => value == null);
}

class Timestamps {
  final int? start;
  final int? end;

  Timestamps({
    this.start,
    this.end,
  });

  factory Timestamps.fromJson(Map<String, dynamic> json) => Timestamps(
        start: json["start"],
        end: json["end"],
      );

  Map<String, dynamic> toJson() => {
        "start": start,
        "end": end,
      }..removeWhere((key, value) => value == null);
}

class Button {
  final String? label;
  final String? url;

  Button({
    this.label,
    this.url,
  });

  factory Button.fromJson(Map<String, dynamic> json) => Button(
        label: json["label"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "label": label,
        "url": url,
      }..removeWhere((key, value) => value == null);
}
