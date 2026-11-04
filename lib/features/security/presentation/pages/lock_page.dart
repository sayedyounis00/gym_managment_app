import 'package:flutter/material.dart';
import '../widgets/floating_pin_dialog.dart';

class LockPage extends StatelessWidget {
  const LockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FloatingPinDialog(),
      ),
    );
  }
}
