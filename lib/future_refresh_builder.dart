import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum FutureRefreshBuilderState {
  none,
  initial,
  receivedData,
  receivedError,
}

class FutureRefreshSnapshot<T> {
  final T data;
  final T previousData;
  final Object error;
  final StackTrace stackTrace;
  final FutureRefreshBuilderState state;
  final Duration deltaTime;

  const FutureRefreshSnapshot._(
    this.state,
    this.data,
    this.error,
    this.stackTrace,
    this.previousData,
    this.deltaTime)
    : assert(state != null),
      assert(stackTrace == null || error != null);

  const FutureRefreshSnapshot.first() : this._(
    FutureRefreshBuilderState.none,
    null,
    null,
    null,
    null,
    Duration.zero,
  );

  const FutureRefreshSnapshot.initial(T data) : this._(
    FutureRefreshBuilderState.initial,
    data,
    null,
    null,
    null,
    Duration.zero,
  );

  FutureRefreshSnapshot<T> copyWithData(T data, Duration deltaTime) => FutureRefreshSnapshot._(
    FutureRefreshBuilderState.receivedData,
    data,
    error,
    stackTrace,
    this.data,
    deltaTime,
  );

  FutureRefreshSnapshot<T> copyWithError(
    Object error,
    Duration deltaTime,
    [StackTrace stackTrace]
  ) => FutureRefreshSnapshot._(
    FutureRefreshBuilderState.receivedError,
    data,
    error,
    stackTrace,
    null,
    deltaTime,
  );

  bool get hasData => data != null;
  bool get hasPreviousData => previousData != null;
  bool get hasError => error != null;
  bool get updateIsData => state == FutureRefreshBuilderState.receivedData || state == FutureRefreshBuilderState.initial;
  bool get updateIsError => state == FutureRefreshBuilderState.receivedError;
}

typedef Widget FutureRefreshBuilderCallback<T>(
  BuildContext context,
  FutureRefreshSnapshot<T> snapshot,
);

typedef Future<T> FutureCreatorCallback<T>();

class _FutureRefreshBuilderConfig<T> extends InheritedWidget {
  final _FutureRefreshBuilderState<T> _state;

  void changeRefreshInterval(Duration newInterval) {
    final oldIntervalBigger = _state.refreshInterval > newInterval;
    final hasLessThanNewIntervalRemaining = (_state.refreshInterval - DateTime.now().difference(_state.lastStateRefresh)) < newInterval;
    final needsRestart = oldIntervalBigger && !hasLessThanNewIntervalRemaining;
    _state.refreshInterval = newInterval;
    if (needsRestart) {
      _state.startTimer();
    }
  }

  void refreshNow() {
    _state.refreshNow();
  }

  const _FutureRefreshBuilderConfig({
    Key key,
    @required Widget child,
    @required _FutureRefreshBuilderState<T> state,
  })  : assert(child != null),
        this._state = state,
        super(key: key, child: child);

  static _FutureRefreshBuilderConfig<T> of<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_FutureRefreshBuilderConfig<T>>();
  }

  @override
  bool updateShouldNotify(_FutureRefreshBuilderConfig old) {
    return _state != old._state;
  }
}

class FutureRefreshBuilder<T> extends StatefulWidget {
  final FutureRefreshBuilderCallback<T> builder;
  final FutureCreatorCallback<T> futureCreator;
  final T initialData;
  final Duration refreshInterval;

  const FutureRefreshBuilder({
    Key key,
    @required this.builder,
    @required this.futureCreator,
    @required this.refreshInterval,
    this.initialData,
  }) : super(key: key);

  static _FutureRefreshBuilderConfig<T> of<T>(BuildContext context)
    => _FutureRefreshBuilderConfig.of<T>(context);

  @override
  _FutureRefreshBuilderState<T> createState() => _FutureRefreshBuilderState<T>();
}

class _FutureRefreshBuilderState<T> extends State<FutureRefreshBuilder<T>> {
  Timer refreshTimer;
  Future refreshFuture;
  FutureRefreshSnapshot<T> snapshot;
  DateTime lastStateRefresh;
  bool disposed = false;
  Duration refreshInterval;

  @override
  void initState() {
    refreshInterval = widget.refreshInterval;
    if (widget.initialData != null) {
      snapshot = FutureRefreshSnapshot.initial(widget.initialData);
    }
    else {
      snapshot = FutureRefreshSnapshot.first();
    }
    lastStateRefresh = DateTime.now();

    super.initState();

    runFuture();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    refreshTimer = null;
    disposed = true;

    super.dispose();
  }

  void startTimer() {
    refreshTimer?.cancel();
    refreshTimer = Timer(refreshInterval, runFuture);
  }

  void runFuture() async {
    DateTime newTime;
    try {
      final data = await widget.futureCreator();
      newTime = DateTime.now();
      snapshot = snapshot.copyWithData(data, newTime.difference(lastStateRefresh));
    } catch(e, st) {
      newTime = DateTime.now();
      snapshot = snapshot.copyWithError(e, newTime.difference(lastStateRefresh), st);
    }
    lastStateRefresh = newTime;

    if (disposed) {
      return;
    }

    setState(() {});
    startTimer();
  }

  void refreshNow() {
    refreshTimer?.cancel();
    refreshTimer = null;
    runFuture();
  }

  @override
  Widget build(BuildContext context) {
    if (disposed) return Container();
    return _FutureRefreshBuilderConfig<T>(
      state: this,
      child: Builder(builder: (context) => widget.builder(context, snapshot)),
    );
  }
}
