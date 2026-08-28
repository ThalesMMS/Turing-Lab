import '../core/graph_layout/graph_layout_models.dart';
import 'app_localizations.dart';

extension AutomatonLayoutLocalizations on AppLocalizations {
  String automatonLayoutAlgorithmLabel(
    GraphLayoutAlgorithmId algorithm,
  ) => switch (algorithm) {
    GraphLayoutAlgorithmId.circle => automatonLayoutCircle,
    GraphLayoutAlgorithmId.twoCircle => automatonLayoutTwoCircles,
    GraphLayoutAlgorithmId.spiral => automatonLayoutSpiral,
    GraphLayoutAlgorithmId.hierarchical => automatonLayoutHierarchical,
    GraphLayoutAlgorithmId.sugiyama => automatonLayoutSugiyama,
    GraphLayoutAlgorithmId.componentPacking => automatonLayoutPackComponents,
    GraphLayoutAlgorithmId.seededForce => automatonLayoutSeededForce,
    GraphLayoutAlgorithmId.seededRandom => automatonLayoutSeededRandom,
    GraphLayoutAlgorithmId.reflectHorizontal =>
      automatonLayoutReflectHorizontal,
    GraphLayoutAlgorithmId.reflectVertical => automatonLayoutReflectVertical,
    GraphLayoutAlgorithmId.rotate90 => automatonLayoutRotate90,
    GraphLayoutAlgorithmId.rotate180 => automatonLayoutRotate180,
    GraphLayoutAlgorithmId.rotate270 => automatonLayoutRotate270,
    GraphLayoutAlgorithmId.fit => automatonLayoutFitViewport,
    GraphLayoutAlgorithmId.fill => automatonLayoutFillViewport,
    GraphLayoutAlgorithmId.restore => automatonLayoutRestoreSaved,
  };

  String automatonLayoutScopeLabel(GraphLayoutScope scope) => switch (scope) {
    GraphLayoutScope.all => automatonLayoutAllStates,
    GraphLayoutScope.selectedComponent => automatonLayoutSelectedComponent,
    GraphLayoutScope.selectedNodes => automatonLayoutSelectedStates,
  };

  String automatonLayoutProgressStageLabel(GraphLayoutProgress progress) =>
      switch (progress.stage) {
        GraphLayoutProgressStage.preparingPreview =>
          automatonLayoutPreparingPreview,
        GraphLayoutProgressStage.validatingGraph =>
          automatonLayoutValidatingGraph,
        GraphLayoutProgressStage.computingLayout => automatonLayoutComputing,
        GraphLayoutProgressStage.forceIteration =>
          automatonLayoutForceIteration(progress.current!, progress.total!),
        GraphLayoutProgressStage.measuringResult => automatonLayoutMeasuring,
        GraphLayoutProgressStage.complete => automatonLayoutComplete,
      };

  String automatonLayoutDiagnosticMessage(GraphLayoutDiagnostic diagnostic) =>
      switch (diagnostic.code) {
        GraphLayoutDiagnosticCode.emptyGraph => automatonLayoutEmptyGraph,
        GraphLayoutDiagnosticCode.unsupportedAlgorithmVersion =>
          automatonLayoutUnsupportedVersion(diagnostic.algorithmVersion!),
        GraphLayoutDiagnosticCode.invalidTopology =>
          automatonLayoutInvalidTopology,
        GraphLayoutDiagnosticCode.missingSelection =>
          diagnostic.scope == GraphLayoutScope.selectedComponent
              ? automatonLayoutSelectComponent
              : automatonLayoutSelectNode,
        GraphLayoutDiagnosticCode.missingRestoreSnapshot =>
          automatonLayoutNoRestore,
        GraphLayoutDiagnosticCode.resourceLimit => automatonLayoutResourceLimit(
          diagnostic.nodeCount!,
          diagnostic.maximumNodes!,
          diagnostic.edgeCount!,
          diagnostic.maximumEdges!,
        ),
        GraphLayoutDiagnosticCode.invalidInputCoordinate =>
          automatonLayoutInvalidPosition,
        GraphLayoutDiagnosticCode.invalidBounds => automatonLayoutInvalidBounds,
        GraphLayoutDiagnosticCode.nonFiniteResultCoordinate =>
          automatonLayoutNonFiniteCoordinate(diagnostic.nodeId!),
        GraphLayoutDiagnosticCode.coordinateClamped =>
          automatonLayoutCoordinatesClamped,
        GraphLayoutDiagnosticCode.overlapsRemain =>
          automatonLayoutOverlapsRemain(diagnostic.overlapCount!),
        GraphLayoutDiagnosticCode.denseGraph => automatonLayoutDenseGraph,
        GraphLayoutDiagnosticCode.cancelled => automatonLayoutCancelled,
      };
}
