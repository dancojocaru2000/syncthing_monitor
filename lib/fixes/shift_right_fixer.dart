import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ShiftRightFixer extends StatefulWidget {
  ShiftRightFixer({this.child});
  final Widget child;
  @override
  State<StatefulWidget> createState() => _ShiftRightFixerState();
}

class _ShiftRightFixerState extends State<ShiftRightFixer> {
  final FocusNode focus = FocusNode(skipTraversal: true, canRequestFocus: false);
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focus,
      onKey: (_, RawKeyEvent event) {
        return event.physicalKey == PhysicalKeyboardKey.shiftRight ?
        KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}