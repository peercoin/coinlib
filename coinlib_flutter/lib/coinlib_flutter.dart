import 'package:flutter/widgets.dart';
import 'package:coinlib/coinlib.dart';
export 'package:coinlib/coinlib.dart';

/// A widget that ensures the coinlib library is loaded before use. This is
/// currently only necessary on web but it is good practice to use in any case.
///
/// Whilst the library is loading, the [loadChild] widget will be displayed.
/// If there is an error, the [errorBuilder] will be called with the error to
/// obtain a widget to display. If the library loads successfully, [builder]
/// will be called instead.
class const CoinlibLoader({
  super.key,

  /// The widget to show whilst coinlib is loading
  required final Widget loadChild,

  /// The builder for a library load error
  required final Widget Function(BuildContext context, Object? error)
  errorBuilder,

  /// The builder called once the library has loaded
  required final WidgetBuilder builder,
}) extends StatefulWidget {
  @override
  State<CoinlibLoader> createState() => _CoinlibLoaderState();
}

class _CoinlibLoaderState extends State<CoinlibLoader> {
  late Future<void> loadResult;

  @override
  void initState() {
    super.initState();
    loadResult = loadCoinlib();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasError) {
          return widget.errorBuilder(context, snapshot.error);
        }
        return widget.builder(context);
      }

      return widget.loadChild;
    },
    future: loadResult,
  );
}
