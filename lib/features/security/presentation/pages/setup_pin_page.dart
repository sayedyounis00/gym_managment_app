import 'package:flutter/material.dart';
import '../widgets/change_pin_dialog.dart';

class SetupPinPage extends StatelessWidget {
  const SetupPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: ChangePinDialog(),
      ),
    );
  }
}
