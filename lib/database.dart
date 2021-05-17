import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncthing_monitor/models/syncthing_server_entry.dart';

Future<String> _getDbPath() async {
  Directory appFolder = Platform.isIOS
    ? await getLibraryDirectory()
    : await getApplicationSupportDirectory();
  String dbPath = p.join(appFolder.path, "syncthingServers.db");

  return dbPath;
}

Future<void> _getDb() async {
  String dbPath = await _getDbPath();

  Hive.init(dbPath);

  await Hive.openLazyBox("servers");
}

var dbFuture = _getDb();

Future<void> resetDb() async {
  await Hive.deleteFromDisk();
  dbFuture = _getDb();
}

Future<int> addServerToDb(SyncthingServerEntry server) async {
  final db = await dbFuture;

  final serversBox = Hive.lazyBox("servers");

  int hiveKey;
  if (server.hiveKey == null) {
    hiveKey = await serversBox.add(server.toJson());
  }
  else {
    hiveKey = server.hiveKey;
    await serversBox.put(hiveKey, server.toJson());
  }

  return hiveKey;
}

Future<SyncthingServerEntry> getServerFromDb(int hiveKey) async {
  final db = await dbFuture;

  final serversBox = Hive.lazyBox("servers");

  if (!serversBox.containsKey(hiveKey)) {
    return null;
  }

  return SyncthingServerEntry.fromJson(await serversBox.get(hiveKey));
}

Future<List<SyncthingServerEntry>> getServersFromDb() async {
  final db = await dbFuture;

  final serversBox = Hive.lazyBox("servers");

  final result = <SyncthingServerEntry>[];

  for (final key in serversBox.keys) {
    result.add(
      SyncthingServerEntry.fromJson(
        await serversBox.get(key),
        hiveKey: key
      )
    );
  }

  return result;
}

Future<Stream<List<SyncthingServerEntry>>> streamServers() async {
  final db = await dbFuture;

  final serversBox = Hive.lazyBox("servers");

  return serversBox.watch().asyncMap((event) => getServersFromDb());
}
