import 'dart:math';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:collection/collection.dart';

class MeasurePage extends StatefulWidget {
  const MeasurePage({Key? key}) : super(key: key);

  @override
  _MeasurePageState createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> {
  late ARKitController arkitController;
  vector.Vector3? firstNode, lastNode, firstNode2, lastNode2;
  double? _objectLength1, _objectLength2, _weight;
  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  double? get weight {
    if (_objectLength1 != null && _objectLength2 != null) {
      final l = _objectLength1! > _objectLength2! ? _objectLength1 : _objectLength2;
      final w = _objectLength1! < _objectLength2! ? _objectLength1 : _objectLength2;
      _weight = (pow(cmToIn(w!), 4) * cmToIn(l!)) / 300;
    }
    return _weight;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ARKitSceneView(enableTapRecognizer: true, onARKitViewCreated: onARKitViewCreated),
          if (_objectLength1 != null)
            Positioned(
              top: 10,
              width: width,
              child: FittedBox(
                child: Container(
                  width: width,
                  color: Colors.white,
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_objectLength1 != null)
                        Text(
                          "(${_objectLength1! > (_objectLength2 ?? 0) ? 'Length' : 'Width'} )   =  ( ${cmToIn(_objectLength1!).toStringAsFixed(2)} IN )  , ${_objectLength1?.toStringAsFixed(2)} cm  ",
                        ),
                      const SizedBox(height: 5),
                      if (_objectLength2 != null)
                        Text(
                          "(${_objectLength2! > (_objectLength1 ?? 0) ? 'Length' : 'Width'} ) =   ( ${cmToIn(_objectLength2!).toStringAsFixed(2)} IN )   , ${_objectLength2?.toStringAsFixed(2)}  cm ",
                        ),
                      const SizedBox(height: 10),
                      if (weight != null)
                        Text("Sheep Weight =  ( ${weight!.toStringAsFixed(2)} Pounds )   , ${poundsToKG(weight!).toStringAsFixed(2)} kg "),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (lastNode != null || firstNode != null)
                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    child: const Text("Rest"),
                    onPressed: () {
                      lastNode = null;
                      firstNode = null;
                      lastNode2 = null;
                      firstNode2 = null;
                      _objectLength1 = null;
                      _objectLength2 = null;
                      _weight = null;
                      arkitController
                        ..remove('first1')
                        ..remove('line1')
                        ..remove('text1')
                        ..remove('last1')
                        ..remove('first2')
                        ..remove('line2')
                        ..remove('text2')
                        ..remove('last2');
                      setState(() {});
                    },
                  ),
                // if (lastNode != null && firstNode != null)
                //   ElevatedButton(
                //     child: const Text("Next"),
                //     onPressed: () {
                //       debugPrint('================= Nav To Next');
                //     },
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController arkitController) {
    debugPrint('=================  onARKitViewCreated ');
    this.arkitController = arkitController;
    this.arkitController.onARTap = (ar) {
      final point = ar.firstWhereOrNull((o) => o.type == ARKitHitTestResultType.featurePoint);
      if (point != null) {
        if (_objectLength1 == null) {
          _onARTapHandler(point);
        } else if (_objectLength2 == null) {
          _onARTapHandler2(point);
        }
      }
    };
  }

  void _onARTapHandler(ARKitTestResult point) {
    // if (lastNode != null && firstNode != null) {
    //   setState(() {});
    // }
    debugPrint('=================  _onARTapHandler ');
    final position = vector.Vector3(point.worldTransform.getColumn(3).x, point.worldTransform.getColumn(3).y, point.worldTransform.getColumn(3).z);
    final material = ARKitMaterial(lightingModelName: ARKitLightingModel.constant, diffuse: ARKitMaterialProperty.color(Colors.blue));
    final sphere = ARKitSphere(radius: 0.006, materials: [material]);
    final node = ARKitNode(geometry: sphere, position: position, name: firstNode == null ? "first1" : "last1");

    if (firstNode != null) {
      arkitController.add(node);

      final line = ARKitLine(fromVector: firstNode!, toVector: position);
      final lineNode = ARKitNode(geometry: line, name: 'line1');
      arkitController.add(lineNode);

      final distance = _calculateDistanceBetweenPoints(position, firstNode!);
      final point = _getMiddleVector(position, firstNode!);
      _drawText(distance, point);
      lastNode = position;
      _objectLength1 ??= position.distanceTo(firstNode!) * 100;
    } else {
      arkitController.add(node);

      firstNode = position;
    }
    setState(() {});
  }

  void _onARTapHandler2(ARKitTestResult point) {
    debugPrint('=================  _onARTapHandler 2 ');
    final position = vector.Vector3(point.worldTransform.getColumn(3).x, point.worldTransform.getColumn(3).y, point.worldTransform.getColumn(3).z);
    final material = ARKitMaterial(lightingModelName: ARKitLightingModel.constant, diffuse: ARKitMaterialProperty.color(Colors.blue));
    final sphere = ARKitSphere(radius: 0.006, materials: [material]);
    final node = ARKitNode(geometry: sphere, position: position, name: firstNode2 == null ? "first2" : "last2");

    if (firstNode2 != null) {
      arkitController.add(node);

      final line = ARKitLine(fromVector: firstNode2!, toVector: position);
      final lineNode = ARKitNode(geometry: line, name: 'line2');
      arkitController.add(lineNode);

      final distance = _calculateDistanceBetweenPoints(position, firstNode2!);
      final point = _getMiddleVector(position, firstNode2!);
      _drawText(distance, point);
      lastNode = position;
      _objectLength2 ??= position.distanceTo(firstNode2!) * 100;
    } else {
      arkitController.add(node);

      firstNode2 = position;
    }
    if (_objectLength1 != null && _objectLength2 != null) {
      debugPrint('================= Calc Wight For Object  :$_objectLength1  , $_objectLength2');
      //_objectLength1 = _objectLength1! > _objectLength2! ? _objectLength1 : _objectLength2;
    }
    setState(() {});
  }

  String _calculateDistanceBetweenPoints(vector.Vector3 A, vector.Vector3 B) {
    debugPrint('=================  _calculateDistanceBetweenPoints ');
    final length = A.distanceTo(B);
    return '${(length * 100).toStringAsFixed(2)} cm';
  }

  vector.Vector3 _getMiddleVector(vector.Vector3 A, vector.Vector3 B) {
    debugPrint('================= _getMiddleVector ');

    return vector.Vector3((A.x + B.x) / 2, (A.y + B.y) / 2, (A.z + B.z) / 2);
  }

  void _drawText(String text, vector.Vector3 point) {
    debugPrint('================= _drawText ');
    final textGeometry = ARKitText(
      text: text,
      extrusionDepth: 1,
      materials: [ARKitMaterial(diffuse: ARKitMaterialProperty.color(Colors.red))],
    );
    const scale = 0.001;
    final vectorScale = vector.Vector3(scale, scale, scale);
    final node = ARKitNode(geometry: textGeometry, position: point, scale: vectorScale, name: 'text${_objectLength1 != null ? 2 : 1}');
    arkitController.add(node);
  }
}

double cmToIn(double cm) => cm * 0.393701;
double gramToPounds(double g) => g * 0.00220462;
double poundsToKG(double lb) => lb * 0.453592;
