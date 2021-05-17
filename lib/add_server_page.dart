import 'dart:convert';

import 'database.dart' as db;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:syncthing_monitor/models/syncthing_server_entry.dart';

import 'package:http/http.dart' as http;
import 'package:syncthing_monitor/syncthing_computer_avatar.dart';

class AddServerPage extends StatefulWidget {
  @override
  _AddServerPageState createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  SyncthingServerEntryFactory factory;
  bool _addedToDb = false;

  Future<http.Response> checkSyncthingServer(String address, String apiKey) async {
    if (!address.contains("://")) {
      address = "http://" + address;
    }

    final res = await http.get(address + "/rest/system/ping", headers: {
      "X-API-Key": apiKey,
    });
    
    return res;
  }

  addServer(BuildContext context) async {
    if (!factory.address.contains("://")) {
      factory.address = "http://" + factory.address;
    }
    await db.addServerToDb(factory.build());
    _addedToDb = true;
    Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    super.initState();

    factory = SyncthingServerEntryFactory(
      gotChanged: () {
        setState(() {});
      }
    );

    gotData = false;
  }

  final nameFocusNode = FocusNode();
  final apiKeyFocusNode = FocusNode();


  final addressTextController = TextEditingController();
  final nameTextController = TextEditingController();
  final apiKeyTextController = TextEditingController();

  bool gotData = false;

  acceptData() {
    setState(() {
      gotData = true;
//      checkSyncthingServer(factory.address, factory.apiKey);
    });
  }

  Widget get pageContents {
    if (!gotData) {
      return _TextFields(
        factory: factory,
        nameFocusNode: nameFocusNode,
        apiKeyFocusNode: apiKeyFocusNode,
        addressController: addressTextController,
        apiKeyController: apiKeyTextController,
        nameController: nameTextController,
      );
    }
    else {
      return WillPopScope(
        child: _ConfirmData(this, addServer),
        onWillPop: () {
          if (_addedToDb) {
            return Future.value(true);
          }
          else {
            setState(() {
              gotData = false;
            });
            return Future.value(false);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Syncthing Server"),
        actions: <Widget>[
          if (!gotData) IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              acceptData();
            },
          )
        ],
      ),
      body: pageContents,
    );
  }
}

class _TextFields extends StatelessWidget {
  final SyncthingServerEntryFactory factory;
  final FocusNode nameFocusNode;
  final FocusNode apiKeyFocusNode;
  final TextEditingController addressController;
  final TextEditingController nameController;
  final TextEditingController apiKeyController;

  _TextFields({
    @required this.factory,
    @required this.nameFocusNode,
    @required this.apiKeyFocusNode,
    this.addressController,
    this.nameController,
    this.apiKeyController,
    Key key
  }) : super(key: key);
  
  String getMonospaceFontFamily(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
        return "monospace";
        break;
//      case TargetPlatform.fuchsia:
//        // TODO: Handle this case.
//        break;
      case TargetPlatform.iOS:
        return "Menlo";
        break;
//      case TargetPlatform.linux:
//        // TODO: Handle this case.
//        break;
      case TargetPlatform.macOS:
        return "Menlo";
        break;
//      case TargetPlatform.windows:
//        // TODO: Handle this case.
//        break;
      default:
        return "Courier";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: addressController,
              keyboardType: TextInputType.url,
              onChanged: (newAddress) {
                factory.withAddress(newAddress);
              },
              decoration: InputDecoration(
                  labelText: "Address"
              ),
              onSubmitted: (_) {
                nameFocusNode.requestFocus();
              },
              textInputAction: TextInputAction.next,
              autocorrect: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: nameController,
              onChanged: (newName) {
                factory.withName(newName);
              },
              decoration: InputDecoration(
                  labelText: "Name",
                  hintText: "Optional"
              ),
              focusNode: nameFocusNode,
              onSubmitted: (_) {
                apiKeyFocusNode.requestFocus();
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: apiKeyController,
              onChanged: (newApiKey) {
                factory.withApiKey(newApiKey);
              },
              decoration: InputDecoration(
                  labelText: "API Key"
              ),
              focusNode: apiKeyFocusNode,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              style: Theme.of(context).textTheme.subtitle1.copyWith(
                fontFamily: getMonospaceFontFamily(context),
              ),
              autocorrect: false,
            ),
          ),
          Container(height: 8,),
          if (factory.name.length == 0) Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                "If the name is left empty, it will be determined from the server."
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmData extends StatelessWidget {
  final _AddServerPageState parentState;

  final Function addServerCallback;

  _ConfirmData(this.parentState, this.addServerCallback);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<http.Response>(
        future: parentState.checkSyncthingServer(
            parentState.factory.address,
            parentState.factory.apiKey
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Error",
                      style: Theme.of(context).textTheme.headline4.copyWith(
                        color: Theme.of(context).brightness == Brightness.light ? Colors.red.shade800 : Colors.red.shade300,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(snapshot.error.toString()),
                  ),
                ],
              ),
            );
          }
          else if (snapshot.data.statusCode / 100 != 2) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${snapshot.data.statusCode} ${snapshot.data.reasonPhrase}",
                    style: Theme.of(context).textTheme.headline3.copyWith(color: Colors.red),
                  ),
                  Text(snapshot.data.body)
                ],
              )
            );
          }
          else {
            return Center(
              child: Column(
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _SyncthingServerNameLabelCompute(parentState.factory),
                          Text("Syncthing ${snapshot.data.headers["x-syncthing-version"]}"),
                          Container(height: 4,),
                          Text(
                            snapshot.data.headers["x-syncthing-id"],
                            style: Theme.of(context).textTheme.caption.copyWith(
                              fontFamily: "monospace",
                            ),
                          ),
                          Container(height: 4,),
                          SyncthingComputerAvatar(
                            computerId: snapshot.data.headers["x-syncthing-id"],
                            squareSize: 8,
                            backgroundColor: Theme.of(context).cardColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 8,),
                  ElevatedButton(
                    child: Text("Add"),
                    style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      addServerCallback(context);
                    },
                  ),
                ],
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
            );
          }
        },
      ),
    );
  }
}

class _SyncthingServerNameLabelCompute extends StatelessWidget {
  final SyncthingServerEntryFactory factory;

  _SyncthingServerNameLabelCompute([this.factory]);
  
  Future<String> getServerName() async {
    var address = factory.address;

    if (!address.contains("://")) {
      address = "http://" + address;
    }

    final res = await http.get(address + "/rest/system/config", headers: {
      "X-API-Key": factory.apiKey,
    });

    final serverDeviceID = res.headers["x-syncthing-id"];

    final config = jsonDecode(res.body) as Map<String, dynamic>;
    final devices = config["devices"] as List<dynamic>;

    for (Map<String, dynamic> device in devices) {
      if (device["deviceID"] == serverDeviceID) {
        return device["name"];
      }
    }

    throw null;
  }

  @override
  Widget build(BuildContext context) {
    if (factory.name.isNotNullOrEmpty) {
      return _SyncthingServerNameLabel(factory.name);
    }
    else {
      return FutureBuilder<String>(
        future: getServerName(),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            return _SyncthingServerNameLabel(snapshot.data);
          }
          else if (snapshot.hasError) {
            return Text("Error!");
          }
          else {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: CircularProgressIndicator(),
            );
          }
        },
      );
    }
  }
}

class _SyncthingServerNameLabel extends StatelessWidget {
  final String name;

  _SyncthingServerNameLabel(this.name);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Text(
        name,
        style: Theme.of(context).textTheme.headline,
      ),
    );
  }


}

extension StringNullChecking on String {
  bool get isNullOrEmpty {
    return this == null || this.isEmpty;
  }

  bool get isNotNullOrEmpty {
    return !this.isNullOrEmpty;
  }
}
