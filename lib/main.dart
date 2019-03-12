import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

Future<void> main() async {
  camera = await availableCameras();
  runApp(HomeWidget());
}

class HomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Digitizer",
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Digitizer"),
        ),
        body: CameraWidget(),
      ),
    );
  }
}

List<CameraDescription> camera;

class CameraWidget extends StatefulWidget {
  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  dynamic _frame;

  String detectedText = "A";
  CameraController _cameraController;
  final TextRecognizer textRecognizer =
      FirebaseVision.instance.textRecognizer();

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(camera[0], ResolutionPreset.medium);
    _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }

      _cameraController.startImageStream((CameraImage image) {
        FirebaseVisionImage firebaseVisionImage = FirebaseVisionImage.fromBytes(
            concatenatePlanes(image.planes), buildMetaData(image));

        /*StringBuffer stringBuffer = StringBuffer();
        textRecognizer.processImage(firebaseVisionImage).then((visionText) {
          for (TextBlock blocks in visionText.blocks) {
            for (TextLine lines in blocks.lines) {
              stringBuffer.write(lines.text.toString());
            }
          }
          detectedText = stringBuffer.toString();
        });*/
      });

      setState(() {});
    });
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }

  FirebaseVisionImageMetadata buildMetaData(CameraImage image) =>
      FirebaseVisionImageMetadata(
        rawFormat: image.format.raw,
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: ImageRotation.rotation270,
        planeData: image.planes.map(
          (Plane plane) {
            return FirebaseVisionImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            );
          },
        ).toList(),
      );

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Container(
        child: const Text("Unable to start camera"),
      );
    }

    return Column(
      children: <Widget>[
        Center(
          child: Container(
            height: 250.0,
            child: AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            ),
          ),
        ),
        Text(
          detectedText,
          style: TextStyle(fontSize: 16.0, color: Colors.blue),
        )
      ],
    );
  }
}
