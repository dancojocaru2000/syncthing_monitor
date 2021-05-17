import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:syncthing_monitor/server_page.dart';
import 'package:syncthing_monitor/syncthing_computer_avatar.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncthing_monitor/add_server_page.dart';
import 'package:syncthing_monitor/database.dart' as db;
import 'package:syncthing_monitor/models/syncthing_server_entry.dart';
import 'package:syncthing_monitor/fixes/shift_right_fixer.dart';

void main() async {
  runApp(ShiftRightFixer(child: SyncthingMonitorApp()));
}

bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}

class SyncthingMonitorApp extends StatelessWidget {
  ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.lightGreen,
    brightness: Brightness.light,
  );

  ThemeData get darkTheme => ThemeData(
    primarySwatch: Colors.lightGreen,
    primaryColor: Colors.lightGreen.shade800,
    primaryColorLight: Colors.lightGreen.shade500,
    toggleableActiveColor: Colors.lightGreen.shade200,
    accentColor: Colors.lightGreen.shade200,
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syncthing Monitor',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: ServersPage(),
      routes: {
        "/add_server": (context) {
          return AddServerPage();
        }
      },
    );
  }
}

class _ServersPageController extends InheritedWidget {
  final _ServersPageState _state;

  Future refreshServersList() => _state.refreshServersList();

  const _ServersPageController({
    Key key,
    @required Widget child,
    @required _ServersPageState state
  })  : assert(child != null),
        this._state = state,
        super(key: key, child: child);

  static _ServersPageController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ServersPageController>();
  }

  @override
  bool updateShouldNotify(_ServersPageController old) {
    return _state != old._state;
  }
}

class ServersPage extends StatefulWidget {
  static _ServersPageController of(BuildContext context)
    => _ServersPageController.of(context);

  @override
  _ServersPageState createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  addServer(BuildContext context) async {
    final createdNewServer = await Navigator.of(context).pushNamed("/add_server");
    if (createdNewServer != null) {
      refreshServersList();
    }
  }

  onServerSelection(BuildContext context, SyncthingServerEntry server) async {
    await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return ServerPage(
              server: server,
            );
          },
        )
    );
    await refreshServersList();
  }

  List<SyncthingServerEntry> servers;
  StreamSubscription<List<SyncthingServerEntry>> serversStreamSubscription;
  Timer periodicRefreshTimer;

  Future refreshServersList() async {
    servers = [];
    // setState(() { });
    servers = await db.getServersFromDb();

    // Check if new subscription is required
    if (serversStreamSubscription == null) {
      listenToChangeStream(await db.streamServers());
    }

    setState(() { });
  }

  onDebugTools(BuildContext context) async {
    final action = await showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text("Reset Database"),
                      onTap: () async {
                        await db.resetDb();
                        Navigator.of(context).pop("reset");
                      },
                    ),
                    ListTile(
                      title: Text("Refresh"),
                      onTap: () async {
                        Navigator.of(context).pop("refresh");
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
    if (action == "reset") {
      await refreshServersList();
      await showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: Material(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0
                  ),
                  child: Text("Database reset", style: Theme
                    .of(context
                  )
                    .textTheme
                    .headline6
                  ),
                ),
              ),
            ),
          );
        }
      );
    }
    else if (action == "refresh") {
      await refreshServersList();
    }
    setState(() {});
  }

  listenToChangeStream(Stream<List<SyncthingServerEntry>> serversChangeStream) {
    serversStreamSubscription = serversChangeStream.listen(
      (event) {
        servers = event;
        setState(() {});
      },
      onDone: () {
        serversStreamSubscription = null;
      }
    );
  }

  @override
  void initState() {
    super.initState();
    refreshServersList();
    db.streamServers().then((value) {
      listenToChangeStream(value);
    });
    // Periodically refresh the page
    periodicRefreshTimer = Timer.periodic(
      Duration(seconds: 5),
      (timer) {
        refreshServersList();
      },
    );
  }


  @override
  void dispose() {
    periodicRefreshTimer?.cancel();
    serversStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Syncthing Monitor"),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.refresh),
          //   tooltip: "Refresh",
          //   onPressed: () {
          //     refreshServersList().then((value) => setState(() {}));
          //   },
          // ),
          if (isInDebugMode) IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: "Debug Tools",
            onPressed: () => onDebugTools(context),
          ),
        ],
      ),
      floatingActionButton: servers.isNotEmpty ? FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          addServer(context);
        },
      ) : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () {
            return refreshServersList().then((value) => setState(() {}));
          },
          child: Builder(
            builder: (context) {
              if (servers.isNotEmpty) {
                return CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final server = servers[index];
                          return _ServersPageController(
                            state: this,
                            child: ServerCard(
                              server: server,
                              onServerSelection: (SyncthingServerEntry server)
                                => onServerSelection(context, server),
                            ),
                          );
                        },
                        childCount: servers?.length ?? 0,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: MediaQuery
                            .of(context)
                            .viewInsets
                            .bottom,
                      ),
                    ),
                  ],
                );
              }
              else {
                return SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("No Servers Added", style: Theme.of(context).textTheme.headline4,),
                        ),
                        Text("Please add a new server.", style: Theme.of(context).textTheme.bodyText1,),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () => addServer(context),
                            child: Text("Add Server"),
                          ),
                        ),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                    ),
                  ),
                );
              }
            }
          ),
        ),
      ),
    );
  }
}

enum _ServerStatus {
  LOADING,
  ONLINE,
  OFFLINE,
  UNKNOWN,
}

class ServerCard extends StatelessWidget {
  final SyncthingServerEntry server;
  final Function onServerSelection;

  ServerCard({@required this.server, @required this.onServerSelection});

  Future<_ServerStatus> getServerStatus() async {
    try {
      final res = await http.get(server.address + "/rest/system/ping",
        headers: {"X-API-Key": server.apiKey}
      );
      final resData = jsonDecode(res.body) as Map<dynamic, dynamic>;
      if (!resData.containsKey("ping")) { return _ServerStatus.UNKNOWN; }
      if (resData["ping"] != "pong") { return _ServerStatus.UNKNOWN; }
      return _ServerStatus.ONLINE;
    }
    catch (e) {
      return _ServerStatus.OFFLINE;
    }
  }

  Future<String> getServerName(_ServerStatus status) async {
    if (status == _ServerStatus.ONLINE) {
      return await server.name ?? "";
    }
    else {
      return await server.cachedName ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<_ServerStatus>(
        future: getServerStatus(),
        initialData: _ServerStatus.LOADING,
        builder: (context, statusSnapshot) {
          if (!statusSnapshot.hasData || statusSnapshot.data == _ServerStatus.LOADING) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          Color cardColor;
          if (Theme.of(context).brightness == Brightness.dark) {
            if (statusSnapshot.data == _ServerStatus.OFFLINE) {
              cardColor = Colors.red.shade900;
            }
            else if (statusSnapshot.data == _ServerStatus.ONLINE) {
              cardColor = Colors.green.shade900;
            }
          }
          else {
            if (statusSnapshot.data == _ServerStatus.OFFLINE) {
              cardColor = Colors.red.shade100;
            }
            else if (statusSnapshot.data == _ServerStatus.ONLINE) {
              cardColor = Colors.green.shade100;
            }
          }

          return Card(
            color: cardColor,
            child: InkWell(
              onTap: statusSnapshot.data != _ServerStatus.OFFLINE ? () {
                onServerSelection(server);
              } : null,
              child: Stack(
                children: [
                  FutureBuilder<String>(
                    future: server.id,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }

                      return PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Opacity(
                          opacity: 1,
                          // opacity: 0.4,
                          child: SyncthingComputerAvatar(
                            computerId: snapshot.data,
                            squareSize: 12,
                            squareColor: Theme.of(context).textTheme.headline5.color,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NameText(future: getServerName(statusSnapshot.data),),
                      AddressText(address: server.address),
                      ConnectionIndicator(status: statusSnapshot.data,),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class NameText extends StatelessWidget {
  final Future<String> future;

  NameText({@required this.future, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container();
        }
        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Container();
        }

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            snapshot.data,
            style: Theme.of(context).textTheme.headline5,
          ),
        );
      },
    );
  }
}

class AddressText extends StatelessWidget {
  final String address;

  AddressText({@required this.address, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(address),
    );
  }
}

class ConnectionIndicator extends StatelessWidget {
  final _ServerStatus status;

  ConnectionIndicator({@required this.status, Key key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Builder(
          builder: (context) {
            if (status == _ServerStatus.OFFLINE) {
              return Text(
                "OFFLINE",
                style: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade300 : Colors.red.shade700,
                ),
              );
            }
            else if (status == _ServerStatus.ONLINE) {
              return Text(
                "ONLINE",
                style: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade700,
                ),
              );
            }
            else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}

