import 'package:flutter/material.dart';
import 'package:graphview/graphview_turing_lab.dart';

class RecordingGraphViewController extends GraphViewController {
  RecordingGraphViewController(TransformationController transformation)
      : super(transformationController: transformation);

  Matrix4? lastTarget;
  int zoomToFitCount = 0;

  @override
  void animateToMatrix(Matrix4 target) {
    lastTarget = Matrix4.copy(target);
    transformationController!.value = target;
  }

  @override
  void zoomToFit() {
    zoomToFitCount++;
    super.zoomToFit();
  }
}
