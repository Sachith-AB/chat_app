import 'package:chatapp/Screens/camera_screen.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CameraScreen(
      onImageSend: (image) {
        // TODO: Implement image send logic
      },
    );
  }
}
