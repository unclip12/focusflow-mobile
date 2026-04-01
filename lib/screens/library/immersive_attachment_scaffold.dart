import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImmersiveAttachmentScaffold extends StatefulWidget {
  final Color backgroundColor;
  final Widget child;

  const ImmersiveAttachmentScaffold({
    super.key,
    required this.child,
    this.backgroundColor = Colors.black,
  });

  @override
  State<ImmersiveAttachmentScaffold> createState() =>
      _ImmersiveAttachmentScaffoldState();
}

class _ImmersiveAttachmentScaffoldState
    extends State<ImmersiveAttachmentScaffold> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SizedBox.expand(child: widget.child),
    );
  }
}
