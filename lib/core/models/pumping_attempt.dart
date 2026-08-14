//
//  pumping_attempt.dart
//  Turing Lab
//
//  Representa uma tentativa no jogo do Lema do Bombeamento, controlando decomposição x,y,z, feedback e datação. Expõe fábricas para tentativas corretas ou incorretas, validações e utilitários para reconstruir cadeias bombeadas durante a experiência interativa.
//
//  Thales Matheus Mendonça Santos - October 2025
//

/// Represents a pumping attempt in the pumping lemma game
class PumpingAttempt {
  final String? x;
  final String? y;
  final String? z;
  final bool isCorrect;
  final String? errorMessage;
  final DateTime timestamp;

  const PumpingAttempt({
    this.x,
    this.y,
    this.z,
    required this.isCorrect,
    this.errorMessage,
    required this.timestamp,
  });

  /// Creates a correct pumping attempt
  factory PumpingAttempt.correct({
    required String x,
    required String y,
    required String z,
  }) {
    return PumpingAttempt(
      x: x,
      y: y,
      z: z,
      isCorrect: true,
      timestamp: DateTime.now(),
    );
  }

  /// Creates an incorrect pumping attempt
  factory PumpingAttempt.incorrect({
    String? x,
    String? y,
    String? z,
    String? errorMessage,
  }) {
    return PumpingAttempt(
      x: x,
      y: y,
      z: z,
      isCorrect: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  /// Gets the decomposition string
  String get decomposition {
    if (x == null || y == null || z == null) return '';
    return '$x$y$z';
  }

  /// Gets the pumped string for a given number of repetitions
  String getPumpedString(int repetitions) {
    if (x == null || y == null || z == null) return '';
    return '$x${y! * repetitions}$z';
  }

  /// Validates the attempt
  bool isValid() {
    return x != null && y != null && z != null && y!.isNotEmpty;
  }

  /// Gets the length of the xy part
  int get xyLength {
    if (x == null || y == null) return 0;
    return x!.length + y!.length;
  }

  /// Gets the length of the y part
  int get yLength {
    return y?.length ?? 0;
  }

  /// Creates a copy with updated properties
  PumpingAttempt copyWith({
    String? x,
    String? y,
    String? z,
    bool? isCorrect,
    String? errorMessage,
    DateTime? timestamp,
  }) {
    return PumpingAttempt(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      isCorrect: isCorrect ?? this.isCorrect,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PumpingAttempt &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.isCorrect == isCorrect &&
        other.errorMessage == errorMessage &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(x, y, z, isCorrect, errorMessage, timestamp);
  }

  @override
  String toString() {
    return 'PumpingAttempt(x: $x, y: $y, z: $z, correct: $isCorrect, error: $errorMessage, timestamp: $timestamp)';
  }
}
