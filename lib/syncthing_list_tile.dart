import 'package:flutter/widgets.dart';

class SyncthingListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget trailing;

  const SyncthingListTile(
      {this.leading, @required this.title, this.trailing, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: leading ?? Container(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: title,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: trailing ?? Container(),
            ),
          ),
        ),
      ],
    );
  }
}
