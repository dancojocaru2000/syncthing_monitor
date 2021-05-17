import 'package:flutter/material.dart';

class SyncthingComputerAvatar extends StatelessWidget {
  final String computerId;
  final double squareSize;
  final Color squareColor;
  final Color backgroundColor;
  final int size;
  final double borderWidth;

  bool shouldFillRectAt(String text, int row, int col) {
    return text.codeUnitAt(row + col * size) % 2 == 0;
  }

  bool shouldMirrorRectAt(int row, int col) {
    return size % 2 == 0 || col != middleCol;
  }

  int get middleCol => size ~/ 2;

  int mirrorColFor(int col) {
    return size - col - 1;
  }

  List<List<bool>> get matrix {
    final matrixId = computerId.replaceFirst("-", "");

    List<List<bool>> result = List.generate(size, (row) {
      List<bool> rList = List.filled(size, false);

      for (final col in middleCol.toInclusive(0)) {
        if (shouldFillRectAt(matrixId, row, col)) {
          rList[col] = true;

          if (shouldMirrorRectAt(row, col)) {
            rList[mirrorColFor(col)] = true;
          }
        }
      }

      return rList;
    }, growable: false);

    return result;
  }

  SyncthingComputerAvatar({
    @required this.computerId,
    this.squareSize = 16,
    this.squareColor,
    this.backgroundColor,
    this.size = 5,
    this.borderWidth = 1,
  }) : assert(computerId != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: squareSize * size + size - 1,
      height: squareSize * size + size - 1,
      child: Table(
        children: matrix.map((row) {
          return TableRow(
            children: row.map((element) {
              return Material(
                child: Container(
                  height: squareSize,
                  width: squareSize,
                ),
                color: element ? (squareColor ?? Theme.of(context).accentColor) : backgroundColor,
                type: (element || backgroundColor != null) ? MaterialType.canvas : MaterialType.transparency,
              );
            }).toList(),
          );
        }).toList(),
        defaultColumnWidth: FixedColumnWidth(squareSize),
        border: TableBorder.all(
          // color: backgroundColor ?? Theme.of(context).backgroundColor,
          color: backgroundColor ?? Colors.transparent,
          width: borderWidth,
          style: BorderStyle.solid
        ),
      ),
    );
  }
}

extension Range on int {
  Iterable<int> to(int limit) sync* {
    int step = 1;

    if (this > limit) {
      step = -1;
    }

    bool stillValid(int currentValue) {
      if (this < limit) {
        return currentValue < limit;
      }
      else if (this > limit) {
        return currentValue > limit;
      }
      else {
        return false;
      }
    }

    for (int iter = this; stillValid(iter); iter += limit) {
      yield iter;
    }
  }

  Iterable<int> toInclusive(int end) {
    if (this < end) {
      return this.to(end + 1);
    }
    else {
      return this.to(end - 1);
    }
  }
}