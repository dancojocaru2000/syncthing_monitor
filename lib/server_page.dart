import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:syncthing_monitor/future_refresh_builder.dart';
import 'package:syncthing_monitor/models/syncthing_server_entry.dart';
import 'package:syncthing_monitor/syncthing_computer_avatar.dart';
import 'package:syncthing_monitor/syncthing_detail_card.dart';
import 'package:syncthing_monitor/syncthing_list_tile.dart';
import 'package:syncthing_monitor/utils/iterables.dart';
import 'package:syncthing_monitor/utils/dataunits.dart';

class ServerPage extends StatefulWidget {
  final SyncthingServerEntry server;

  ServerPage({@required this.server, Key key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  int page;

  @override
  void initState() {
    page = 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<String>(
              future: widget.server.id,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                } else {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                    child: SyncthingComputerAvatar(
                      computerId: snapshot.data,
                      squareSize: 8,
                      borderWidth: 0,
                      squareColor:
                          Theme.of(context).appBarTheme?.foregroundColor ??
                              (Theme.of(context).brightness == Brightness.light
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface),
                      backgroundColor:
                          Theme.of(context).appBarTheme?.backgroundColor ??
                              Theme.of(context).primaryColor,
                    ),
                  );
                }
              },
            ),
            FutureBuilder<String>(
              future: widget.server.name,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text("Syncthing Server");
                } else {
                  return Text(snapshot.data);
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: page,
        onTap: (newIndex) {
          setState(() {
            page = newIndex;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: "Folders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: "Devices",
          ),
        ],
      ),
      body: SafeArea(
        left: true,
        right: true,
        child: CustomScrollView(
          slivers: [
            if (page == 1)
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: ThisDeviceSection(server: widget.server),
              ),
            if (page == 1)
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: RemoteDevicesSection(server: widget.server),
              ),
            if (page == 0)
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: FoldersSection(server: widget.server),
              )
            // SingleChildScrollView(
            //   child: SafeArea(
            //     bottom: true,
            //     top: false,
            //     left: false,
            //     right: false,
            //     child: Container(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class ThisDeviceSection extends StatefulWidget {
  final SyncthingServerEntry server;

  const ThisDeviceSection({@required this.server, Key key}) : super(key: key);

  @override
  _ThisDeviceSectionState createState() => _ThisDeviceSectionState();
}

class _ThisDeviceSectionState extends State<ThisDeviceSection> {
  @override
  Widget build(BuildContext context) {
    return SliverList(
        delegate: SliverChildListDelegate.fixed(<Widget>[
      Padding(
        padding: const EdgeInsets.only(
          right: 8,
        ),
        child: Text(
          "This Device",
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
      Builder(
        builder: (context) {
          final width = MediaQuery.of(context).size.width;

          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  if (await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Shutdown Server"),
                        content: Text(
                            "Are you sure you want to shut down the server? You might not to be able to start it again without manual access."),
                        actions: [
                          TextButton.icon(
                            icon: Icon(Icons.cancel_outlined),
                            label: Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          TextButtonTheme(
                            data: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                primary: Colors.red,
                              ),
                            ),
                            child: TextButton.icon(
                              icon: Icon(Icons.power_settings_new),
                              label: Text("Shutdown"),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ) == true) {
                    final serverName = await widget.server.name;
                    await widget.server.onlineInterface.restSystemShutdown();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("$serverName is shutting down"),
                    ));
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(Icons.power_settings_new),
                label: Text("Shutdown"),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final serverName = await widget.server.name;
                  await widget.server.onlineInterface.restSystemRestart();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("$serverName is restarting"),
                  ));
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.restart_alt),
                label: Text("Restart"),
              ),
              if (width > 400)
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.settings),
                  label: Text("Settings"),
                )
              else
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.settings),
                  color: Theme.of(context).accentColor,
                ),
            ],
          );
        }
      ),
      FutureBuilder<List<dynamic>>(
        future: Future.wait([widget.server.name, widget.server.id]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          else if (!snapshot.hasData) {
            return Container();
          }

          return SyncthingDetailCard(
            title: Text(snapshot.data[0]),
            icon: SyncthingComputerAvatar(
              computerId: snapshot.data[1],
              squareSize: 8,
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SyncthingListTile(
                  leading: Icon(Icons.cloud_download),
                  title: Text("Download Rate"),
                  trailing: FutureRefreshBuilder<double>(
                    futureCreator: () async {
                      final systemConnections = await widget
                          .server.onlineInterface.restSystemConnections;
                      final total =
                          systemConnections["total"]["inBytesTotal"] as int;

                      return total.toDouble();
                    },
                    refreshInterval: Duration(seconds: 5),
                    builder: (context, snapshot) {
                      if (snapshot.state == FutureRefreshBuilderState.none) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return Container();
                      }

                      final units = ["", "Ki", "Mi", "Gi", "Ti"];
                      var unit = -1;

                      var speed = snapshot.hasPreviousData
                          ? ((snapshot.data - snapshot.previousData) /
                              snapshot.deltaTime.inSeconds)
                          : 0.0;
                      var nextSpeed = speed;
                      do {
                        speed = nextSpeed;
                        unit++;
                        nextSpeed = speed / 1024;
                      } while (nextSpeed > 0.9);
                      final speedString =
                          "${speed.toStringAsFixed(2)} ${units[unit]}B/s";

                      unit = -1;

                      var downloadTotal = snapshot.data;
                      var next = downloadTotal;
                      do {
                        downloadTotal = next;
                        unit++;
                        next = downloadTotal / 1024;
                      } while (next > 0.9);

                      final downloadTotalString =
                          "${downloadTotal.toStringAsFixed(2)} ${units[unit]}B";

                      return Text("$speedString ($downloadTotalString)");
                    },
                  ),
                ),
                SyncthingListTile(
                  leading: Icon(Icons.cloud_upload),
                  title: Text("Upload Rate"),
                  trailing: FutureRefreshBuilder<double>(
                    futureCreator: () async {
                      final connections = await widget
                          .server.onlineInterface.restSystemConnections;
                      final total =
                          connections["total"]["outBytesTotal"] as int;

                      return total.toDouble();
                    },
                    refreshInterval: Duration(seconds: 5),
                    builder: (context, snapshot) {
                      if (snapshot.state == FutureRefreshBuilderState.none) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return Container();
                      }

                      final speed = snapshot.hasPreviousData
                          ? ((snapshot.data - snapshot.previousData) /
                              snapshot.deltaTime.inSeconds)
                          : 0.0;
                      final speedUnitResult = speed.toDataUnit();
                      final speedString =
                          "${speedUnitResult.value.toStringAsFixed(2)} ${speedUnitResult.unit.toBinaryString()}B/s";

                      var uploadTotal = snapshot.data;

                      final uploadTotalDataUnit = uploadTotal.toDataUnit();
                      final uploadTotalString =
                          "${uploadTotalDataUnit.value.toStringAsFixed(2)} ${uploadTotalDataUnit.unit.toBinaryString()}B";

                      return Text("$speedString ($uploadTotalString)");
                    },
                  ),
                ),
                SyncthingListTile(
                  leading: Icon(Icons.house),
                  title: Text("Local State (Total)"),
                  trailing: FutureRefreshBuilder<List<int>>(
                    refreshInterval: Duration(
                      minutes: 1,
                    ),
                    futureCreator: () async {
                      final folders =
                          await widget.server.onlineInterface.restConfigFolders;
                      final folderIds = folders.map((e) => e["id"] as String);
                      final dbStatuses = await Future.wait(folderIds.map((id) =>
                          widget.server.onlineInterface
                              .restDbStatus(folder: id)));

                      List<int> extractState(Map<String, dynamic> dbStatus) {
                        return [
                          dbStatus["localFiles"],
                          dbStatus["localDirectories"],
                          dbStatus["localBytes"],
                        ];
                      }

                      final states =
                          dbStatuses.map((status) => extractState(status));
                      return states.fold<List<int>>(
                          List.filled(3, 0),
                          (prev, item) => zip([prev, item])
                              .map((nums) => nums.sum())
                              .toList(growable: false));
                    },
                    builder: (context, snapshot) {
                      if (snapshot.state == FutureRefreshBuilderState.none) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return Container();
                      }

                      final stateSize =
                          snapshot.data[2].toDouble().toDataUnit();

                      final width = MediaQuery.of(context).size.width;
                      final children = [
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(Icons.file_copy),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(snapshot.data[0].toString()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.folder),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(snapshot.data[1].toString()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.devices),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                              "${stateSize.value.toStringAsFixed(2)} ${stateSize.unit.toBinaryString()}B"),
                        ),
                      ];

                      if (width < 450) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  children[0],
                                  children[1],
                                ],
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  children[2],
                                  children[3],
                                ],
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  children[4],
                                  children[5],
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: children,
                      );
                    },
                  ),
                ),
                SyncthingListTile(
                  leading: Icon(Icons.account_tree),
                  title: Text("Listeners"),
                  trailing: FutureRefreshBuilder<Map<String, dynamic>>(
                    refreshInterval: Duration(
                      seconds: 5,
                    ),
                    futureCreator: () =>
                        widget.server.onlineInterface.restSystemStatus,
                    builder: (context, snapshot) {
                      if (snapshot.state == FutureRefreshBuilderState.none) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return Container();
                      }

                      final connectionServiceStatus =
                          snapshot.data["connectionServiceStatus"]
                              as Map<String, dynamic>;
                      final totalListeners = connectionServiceStatus.length;
                      final errorListeners = connectionServiceStatus.values
                          .map((e) => e["error"] != null)
                          .fold<int>(
                              0,
                              (previousValue, element) =>
                                  previousValue + (element ? 1 : 0));
                      final goodListeners = totalListeners - errorListeners;

                      return Text(
                        "$goodListeners/$totalListeners",
                        style: errorListeners == 0
                            ? DefaultTextStyle.of(context).style.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.green.shade600
                                    : Colors.green.shade300)
                            : null,
                      );
                    },
                  ),
                ),
                SyncthingListTile(
                  leading: Icon(Icons.directions),
                  title: Text("Discovery"),
                  trailing: FutureRefreshBuilder<Map<String, dynamic>>(
                    futureCreator: () =>
                        widget.server.onlineInterface.restSystemStatus,
                    refreshInterval: Duration(seconds: 5),
                    builder: (context, snapshot) {
                      if (snapshot.state == FutureRefreshBuilderState.none) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return Container();
                      }

                      final discoveryMethods =
                          snapshot.data["discoveryMethods"] as int;
                      final discoveryErrors = snapshot.data["discoveryErrors"]
                          as Map<String, dynamic>;
                      final discoveryGood =
                          discoveryMethods - discoveryErrors.length;
                      return Text(
                        "$discoveryGood/$discoveryMethods",
                        style: discoveryErrors.isEmpty
                            ? DefaultTextStyle.of(context).style.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.green.shade600
                                    : Colors.green.shade300)
                            : null,
                      );
                    },
                  ),
                ),
                SyncthingListTile(
                  leading: Icon(Icons.access_time),
                  title: Text("Uptime"),
                  trailing: FutureRefreshBuilder<Map<String, dynamic>>(
                    futureCreator: () =>
                        widget.server.onlineInterface.restSystemStatus,
                    refreshInterval: Duration(seconds: 30),
                    builder: (context, snapshot) {
                      if (snapshot.state == FutureRefreshBuilderState.none) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return Container();
                      }

                      final totalSeconds = snapshot.data["uptime"] as int;
                      final totalMinutes = totalSeconds ~/ 60;
                      final totalHours = totalMinutes ~/ 60;
                      final totalDays = totalHours ~/ 24;
                      final hours = totalHours - totalDays * 24;
                      final minutes = totalMinutes - totalHours * 60;
                      final seconds = totalSeconds - totalMinutes * 60;

                      var result = [];
                      if (totalDays != 0) {
                        result.add("${totalDays}d");
                      }
                      if (hours != 0) {
                        result.add("${hours}h");
                      }
                      if (minutes != 0) {
                        result.add("${minutes}m");
                      }
                      if (result.isEmpty) {
                        result.add("${seconds}s");
                        FutureRefreshBuilder.of<Map<String, dynamic>>(context)
                          .changeRefreshInterval(Duration(milliseconds: 450));
                      }
                      else {
                        FutureRefreshBuilder.of<Map<String, dynamic>>(context)
                          .changeRefreshInterval(Duration(seconds: 30));
                      }
                      // Ignore seconds

                      return Text(result.join(" "));
                    },
                  ),
                ),
                SyncthingListTile(
                  leading: Icon(Icons.tag),
                  title: Text("Version"),
                  trailing: FutureRefreshBuilder<Map<String, dynamic>>(
                    futureCreator: () =>
                        widget.server.onlineInterface.restSystemVersion,
                    refreshInterval: Duration(minutes: 2),
                    builder: (context, snapshot) {
                      if (snapshot.state == FutureRefreshBuilderState.none) {
                        return Container(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return Container();
                      }

                      final arch = snapshot.data["arch"] as String;
                      final os = snapshot.data["os"] as String;
                      final version = snapshot.data["version"] as String;

                      return Text("$version, $os ($arch)");
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ]));
  }
}

class RemoteDevicesSection extends StatelessWidget {
  final SyncthingServerEntry server;

  const RemoteDevicesSection({Key key, @required this.server}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              "Remote Devices",
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;

                onAddFolder() async {

                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.pause),
                      label: Text("Pause All"),
                      onPressed: () async {
                        await server.onlineInterface.restSystemPause();
                      },
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.play_arrow),
                      label: Text("Resume All"),
                      onPressed: () async {
                        await server.onlineInterface.restSystemResume();
                      },
                    ),
                    if (width > 400)
                      OutlinedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text("Add Folder"),
                        onPressed: onAddFolder,
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: onAddFolder,
                        color: Theme.of(context).accentColor,
                      ),
                  ],
                );
              }
          ),
        ),
        FutureRefreshBuilder<List<List<Map<String, dynamic>>>>(
          refreshInterval: Duration(seconds: 5),
          futureCreator: () async {
            final myId = await server.id;
            final systemConnections = (await server.onlineInterface.restSystemConnections)["connections"];
            final configDevices = await server.onlineInterface.restConfigDevices;
            final result = cartesianProduct<dynamic>([configDevices, systemConnections.entries])
              .where((element) {
                final deviceConfig = element[0] as Map<String, dynamic>;
                final deviceConfigId = deviceConfig["deviceID"] as String;
                final systemConfig = element[1] as MapEntry<String, dynamic>;
                final systemConfigId = systemConfig.key;
                return deviceConfigId == systemConfigId && deviceConfigId != myId;
              })
              .map((element) => [
                element[0] as Map<String, dynamic>,
                (element[1] as MapEntry<String, dynamic>).value as Map<String, dynamic>
              ])
              .toList(growable: false);
            result.sort((e1, e2) => (e1[0]["name"] as String).compareTo(e2[0]["name"]));
            return result;
          },
          builder: (context, snapshot) {
            if (snapshot.state == FutureRefreshBuilderState.none) {
              return SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            else if (!snapshot.hasData) {
              return SliverToBoxAdapter(child: Container());
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final connection = snapshot.data[index];
                  final configDevice = connection[0];
                  final systemConnection = connection[1];

                  final deviceName = configDevice["name"] as String;
                  final deviceId = configDevice["deviceID"] as String;

                  return SyncthingDetailCard(
                    title: Text(deviceName),
                    icon: SyncthingComputerAvatar(
                      computerId: deviceId,
                      squareSize: 8,
                    ),
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (systemConnection["paused"])
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Paused", style: Theme.of(context).textTheme.headline6,),
                          )
                        else if (!systemConnection["connected"])
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Disconnected",
                              style: Theme.of(context).textTheme.headline6.copyWith(
                                color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.purple.shade500
                                  : Colors.purple.shade300,
                              ),
                            ),
                          )
                        else
                          FutureRefreshBuilder(
                            refreshInterval: Duration(seconds: 5),
                            futureCreator: () => server.onlineInterface.restDbCompletion(device: deviceId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final completion = snapshot.data["completion"] as double;

                              if (completion == 100.0) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "Up to Date",
                                    style: Theme.of(context).textTheme.headline6.copyWith(
                                      color: Theme.of(context).brightness == Brightness.light
                                          ? Colors.green.shade500
                                          : Colors.green.shade300,
                                    ),
                                  ),
                                );
                              }
                              else {
                                final needBytesDataUnit = (snapshot.data["needBytes"] as int).toDouble().toDataUnit();
                                final fixedDigits = needBytesDataUnit.unit == DataUnit.b ? 0 : 2;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "Syncing (${completion.truncate()}%, ${needBytesDataUnit.value.toStringAsFixed(fixedDigits)} ${needBytesDataUnit.unit.toBinaryString()}B)",
                                        style: Theme.of(context).textTheme.headline6.copyWith(
                                          color: Theme.of(context).brightness == Brightness.light
                                              ? Colors.cyan.shade500
                                              : Colors.cyan.shade300,
                                        ),
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                      child: LinearProgressIndicator(
                                        value: completion,
                                        color: Theme.of(context).brightness == Brightness.light
                                          ? Colors.cyan.shade500
                                          : Colors.cyan.shade300,
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  );
                },
                childCount: snapshot.data.length,
              ),
            );
          }
        ),
      ],
    );
  }
}

class FoldersSection extends StatelessWidget {
  final SyncthingServerEntry server;

  const FoldersSection({Key key, @required this.server}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              "Folders",
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final width = MediaQuery.of(context).size.width;

              onAddFolder() {

              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.pause),
                    label: Text("Pause All"),
                    onPressed: () {

                    },
                  ),
                  OutlinedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text("Rescan All"),
                    onPressed: () {

                    },
                  ),
                  if (width > 400)
                    OutlinedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text("Add Folder"),
                      onPressed: onAddFolder,
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: onAddFolder,
                      color: Theme.of(context).accentColor,
                    ),
                ],
              );
            }
          ),
        ),
        FutureRefreshBuilder<List<Map<String, dynamic>>>(
            refreshInterval: Duration(seconds: 5),
            futureCreator: () async {
              final configFolders = await server.onlineInterface.restConfigFolders;
              return configFolders;
            },
            builder: (context, snapshot) {
              if (snapshot.state == FutureRefreshBuilderState.none) {
                return SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              else if (!snapshot.hasData) {
                return SliverToBoxAdapter(child: Container());
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final folder = snapshot.data[index];
                    final folderId = folder["id"] as String;
                    final folderLabel = folder["label"] as String;
                    final paused = folder["paused"] as bool;

                    return SyncthingDetailCard(
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(folderLabel),
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: Text(folderId, style: Theme.of(context).textTheme.caption,),
                          ),
                        ],
                      ),
                      icon: Icon(Icons.folder),
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (paused)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Paused", style: Theme.of(context).textTheme.headline6,),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: snapshot.data.length,
                ),
              );
            }
        ),
      ],
    );
  }
}

