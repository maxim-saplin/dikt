import 'dart:async';

mixin Debounce {
  Timer? _debounceTimer;

  void debounce(Function f, int milliseconds) {
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(Duration(milliseconds: milliseconds), f as void Function());
  }

  void cancel() {
    _debounceTimer?.cancel();
  }
}

class Tuple<T, U> {
  final T value1;
  final U value2;

  Tuple(this.value1, this.value2);
}

// class KeyboardVisibilityBuilder extends StatefulWidget {
//   final Widget Function(
//     BuildContext context,
//     bool isKeyboardVisible,
//   ) builder;

//   const KeyboardVisibilityBuilder({
//     Key? key,
//     required this.builder,
//   }) : super(key: key);

//   @override
//   KeyboardVisibilityBuilderState createState() =>
//       KeyboardVisibilityBuilderState();
// }

// class KeyboardVisibilityBuilderState extends State<KeyboardVisibilityBuilder>
//     with WidgetsBindingObserver {
//   var _isKeyboardVisible = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeMetrics() {
//     //final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
//     final bottomInset = View.of(context).viewInsets.bottom;
//     final newValue = bottomInset > 0.0;
//     if (newValue != _isKeyboardVisible) {
//       setState(() {
//         _isKeyboardVisible = newValue;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) => widget.builder(
//         context,
//         _isKeyboardVisible,
//       );
// }
