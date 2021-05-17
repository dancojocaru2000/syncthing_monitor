import 'package:flutter/material.dart';

class SyncthingDetailCard extends StatelessWidget {
  final Widget title;
  final Widget icon;
  final Widget body;

  const SyncthingDetailCard(
      {@required this.title, @required this.icon, @required this.body, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: icon,
              ),
              Container(
                height: 8,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.headline5,
                    child: title,
                  ),
                ),
              )
            ],
          ),
          Flexible(
            fit: FlexFit.loose,
            child: body,
          )
        ],
      ),
    );
  }
}
