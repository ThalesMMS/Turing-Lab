import 'package:flutter/foundation.dart';

/// Imperative bridge between an automaton canvas and its shared toolbar.
///
/// Only editors that support document-level automaton actions receive an
/// instance. The canvas binds the production flows while the toolbar owns the
/// single visible entry point.
final class AutomatonCanvasDocumentActionsController {
  VoidCallback? _arrange;
  VoidCallback? _importAutomaton;
  VoidCallback? _documentNotes;
  Object? _arrangeOwner;
  Object? _importOwner;
  Object? _notesOwner;

  void arrange() => _arrange?.call();

  void importAutomaton() => _importAutomaton?.call();

  void showDocumentNotes() => _documentNotes?.call();

  void bindArrange(Object owner, VoidCallback action) {
    _arrangeOwner = owner;
    _arrange = action;
  }

  void bindImport(Object owner, VoidCallback action) {
    _importOwner = owner;
    _importAutomaton = action;
  }

  void bindDocumentNotes(Object owner, VoidCallback action) {
    _notesOwner = owner;
    _documentNotes = action;
  }

  void unbind(Object owner) {
    if (identical(_arrangeOwner, owner)) {
      _arrangeOwner = null;
      _arrange = null;
    }
    if (identical(_importOwner, owner)) {
      _importOwner = null;
      _importAutomaton = null;
    }
    if (identical(_notesOwner, owner)) {
      _notesOwner = null;
      _documentNotes = null;
    }
  }
}
