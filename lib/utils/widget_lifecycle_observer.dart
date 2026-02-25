import 'package:flutter/widgets.dart';

/// Mixin that registers this [State] as a [WidgetsBindingObserver] in
/// [initState] and unregisters in [dispose]. Use when the screen needs to
/// react to app lifecycle (e.g. for usage metrics or pausing).
///
/// The [State] must implement [WidgetsBindingObserver] and override
/// [WidgetsBindingObserver.didChangeAppLifecycleState] (and other callbacks)
/// as needed.
mixin WidgetLifecycleObserver<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
