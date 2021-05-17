import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:syncthing_monitor/database.dart';
import 'package:http/http.dart' as http;

class SyncthingServerEntry {
  final String address;
  final String _name;
  final String apiKey;
  final int hiveKey;

  Uri get addressUri => Uri.parse(address);

  // cache
  String _cachedName;
  String _cachedId;

  Future<String> get cachedName async => _name ?? _cachedName;
  Future<String> get name async => _name ?? serverName;
  Future<String> get serverName async {
    final id = await this.id;
    try {
      if (id == null) {
        throw Exception("id is null");
      }
      final res = await http.get(address + "/rest/system/config", headers: {
        "X-API-Key": this.apiKey,
      });
      final config = jsonDecode(res.body) as Map<String, dynamic>;
      final devices = config["devices"] as List<dynamic>;

      for (Map<String, dynamic> device in devices) {
        if (device["deviceID"] == id) {
          final serverName = device["name"];
          if (_cachedName != serverName) {
            _cachedName = serverName;
            await save();
            break;
          }
        }
      }
    }
    catch (e) {
    }
    return _cachedName;
  }
  Future<String> get id async {
    try {
      final res = await http.get(address + "/rest/system/ping", headers: {
        "X-API-Key": apiKey,
      });
      if (!res.headers.containsKey("x-syncthing-id")) {
        throw Exception("no x-syncthing-id key");
      }
      final serverId = res.headers["x-syncthing-id"];
      if (_cachedId != serverId) {
        _cachedId = serverId;
        await save();
      }
    }
    catch (_) {
    }
    return _cachedId;
  }

  SyncthingServerEntry({@required this.address, @required this.apiKey, String name, this.hiveKey, String cachedName, String cachedId})
    : assert(address != null),
        assert(apiKey != null),
        this._name = name,
        this._cachedName = cachedName,
        this._cachedId = cachedId;

  SyncthingServerOnlineInterface get onlineInterface => SyncthingServerOnlineInterface(this);

  SyncthingServerEntry copyWith({String address, String name, String apiKey, int hiveKey}) {
    return SyncthingServerEntry(
      address: address ?? this.address,
      apiKey: apiKey ?? this.apiKey,
      name: name ?? this._name,
      hiveKey: hiveKey ?? this.hiveKey,
      cachedName: name == null ? this._cachedName : null,
      cachedId: address == null ? this._cachedId : null,
    );
  }

  Future<SyncthingServerEntry> save() async {
    final hiveKey = await addServerToDb(this);
    return this.copyWith(hiveKey: hiveKey);
  }

  Future<SyncthingServerEntry> refresh() {
    return getServerFromDb(this.hiveKey);
  }

  factory SyncthingServerEntry.fromJson(Map<dynamic, dynamic> json, {int hiveKey}) {
    final cache = json.containsKey('_cache') ? json['_cache'] as Map<dynamic, dynamic> : null;
    return SyncthingServerEntry(
      address: json["address"],
      apiKey: json["apiKey"],
      name: json.containsKey("name") ? json["name"] : null,
      hiveKey: hiveKey,
      cachedName: cache != null && cache.containsKey("name") ? cache["name"] : null,
      cachedId: cache != null && cache.containsKey("id") ? cache["id"] : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'apiKey': apiKey,
    'name': _name,
    '_cache': {
      'id': _cachedId,
      'name': _cachedName,
    },
  };
}

class SyncthingServerEntryFactory {
  String address;
  String name;
  String apiKey;
  final Function gotChanged;

  SyncthingServerEntryFactory({this.gotChanged})
    : address = "", name = "", apiKey = "";

  SyncthingServerEntry build() => SyncthingServerEntry(
    address: address,
    name: name.length > 0 ? name : null,
    apiKey: apiKey
  );

  _changeMade() {
    if (gotChanged != null) {
      gotChanged();
    }
  }

  SyncthingServerEntryFactory withAddress(String newAddress) {
    address = newAddress;
    _changeMade();
    return this;
  }

  SyncthingServerEntryFactory withApiKey(String newApiKey) {
    apiKey = newApiKey;
    _changeMade();
    return this;
  }

  SyncthingServerEntryFactory withName(String newName) {
    name = newName;
    _changeMade();
    return this;
  }
}

class SyncthingServerOnlineInterface {
  final SyncthingServerEntry entry;

  SyncthingServerOnlineInterface(this.entry);

  Future restSystemShutdown() async {
    await http.post(entry.addressUri.replace(path: "/rest/system/shutdown"), headers: {
      "X-API-Key": entry.apiKey,
    });
  }
  Future restSystemRestart() async {
    await http.post(entry.addressUri.replace(path: "/rest/system/restart"), headers: {
      "X-API-Key": entry.apiKey,
    });
  }

  Future restSystemPause({String device}) async {
    final queryParams = <String, dynamic>{};
    if (device != null) {
      queryParams["device"] = device;
    }

    await http.post(entry.addressUri.replace(
      path: "/rest/system/pause",
      queryParameters: queryParams,
    ), headers: {
      "X-API-Key": entry.apiKey,
    });
  }

  Future restSystemResume({String device}) async {
    final queryParams = <String, dynamic>{};
    if (device != null) {
      queryParams["device"] = device;
    }

    await http.post(entry.addressUri.replace(
      path: "/rest/system/resume",
      queryParameters: queryParams,
    ), headers: {
      "X-API-Key": entry.apiKey,
    });
  }

  Future<Map<String, dynamic>> get restSystemStatus async {
    final res = await http.get(entry.address + "/rest/system/status", headers: {
      "X-API-Key": entry.apiKey,
    });
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> get restSystemVersion async {
    final res = await http.get(
        entry.address + "/rest/system/version", headers: {
      "X-API-Key": entry.apiKey,
    });
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> get restSystemConnections async {
    final res = await http.get(
        entry.address + "/rest/system/connections", headers: {
      "X-API-Key": entry.apiKey,
    });
    return jsonDecode(res.body);
  }

  Future<List<Map<String, dynamic>>> get restConfigFolders async {
    final res = await http.get(
        entry.address + "/rest/config/folders", headers: {
      "X-API-Key": entry.apiKey,
    });
    return (jsonDecode(res.body) as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(growable: false);
  }

  Future<List<dynamic>> get restConfigDevices async {
    final res = await http.get(
        entry.address + "/rest/config/devices", headers: {
      "X-API-Key": entry.apiKey,
    });
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> restDbStatus({@required String folder}) async {
    final res = await http.get(entry.addressUri.replace(
      path: "/rest/db/status",
      queryParameters: {
        "folder": folder,
      },
    ), headers: {
      "X-API-Key": entry.apiKey,
    });
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> restDbCompletion({String folder, String device}) async {
    final queryParams = <String, dynamic>{};
    if (folder != null) {
      queryParams["folder"] = folder;
    }
    if (device != null) {
      queryParams["device"] = device;
    }

    final res = await http.get(entry.addressUri.replace(
      path: "/rest/db/completion",
      queryParameters: queryParams,
    ), headers: {
      "X-API-Key": entry.apiKey,
    });
    return jsonDecode(res.body);
  }
}
