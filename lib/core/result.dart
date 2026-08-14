//
//  result.dart
//  Turing Lab
//
//  Defines the sealed Result type with Success and Failure variants to standardize return
//  flows and error messages in the application, exposing mapping utilities and
//  callbacks to handle successes or failures in a composable way.
//  Also adds extensions, typed aliases and static factories that simplify
//  result collections and frequent conversions between entities and messages.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'entities/grammar_entity.dart';

/// Standardized Result type for consistent error handling across the application
sealed class Result<T> {
  const Result();

  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T>;

  /// Returns true if the result is a failure
  bool get isFailure => this is Failure<T>;

  /// Returns the data if success, null otherwise
  T? get data => isSuccess ? (this as Success<T>).data : null;

  /// Returns the error message if failure, null otherwise
  String? get error => isFailure ? (this as Failure<T>).message : null;

  /// Maps the result to another type
  Result<R> map<R>(R Function(T) mapper) {
    return switch (this) {
      Success<T>(data: final data) => Success(mapper(data)),
      Failure<T>(message: final message) => Failure(message),
    };
  }

  /// Maps the result to another type, handling both success and failure
  Result<R> mapOrElse<R>(
    R Function(T) onSuccess,
    String Function(String) onFailure,
  ) {
    return switch (this) {
      Success<T>(data: final data) => Success(onSuccess(data)),
      Failure<T>(message: final message) => Failure(onFailure(message)),
    };
  }

  /// Executes a function if the result is a success
  Result<T> onSuccess(void Function(T) callback) {
    if (isSuccess) {
      callback(data as T);
    }
    return this;
  }

  /// Executes a function if the result is a failure
  Result<T> onFailure(void Function(String) callback) {
    if (isFailure) {
      callback(error!);
    }
    return this;
  }
}

/// Success result containing data
class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Failure result containing an error message
class Failure<T> extends Result<T> {
  final String message;

  const Failure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'Failure($message)';
}

/// Convenience functions for creating results
extension ResultExtensions<T> on T {
  /// Creates a success result
  Result<T> toSuccess() => Success(this);
}

extension StringResultExtensions on String {
  /// Creates a failure result
  Result<T> toFailure<T>() => Failure<T>(this);
}

/// Convenience functions for working with lists of results
extension ResultListExtension<T> on List<Result<T>> {
  /// Returns true if all results are successful
  bool get allSuccessful => every((result) => result.isSuccess);

  /// Returns true if any result is a failure
  bool get anyFailure => any((result) => result.isFailure);

  /// Collects all successful data
  List<T> get successfulData => where(
        (result) => result.isSuccess,
      ).map((result) => result.data!).toList();

  /// Collects all error messages
  List<String> get errorMessages => where(
        (result) => result.isFailure,
      ).map((result) => result.error!).toList();

  /// Returns the first failure, or success if all are successful
  Result<List<T>> collect() {
    final failures = where((result) => result.isFailure).toList();
    if (failures.isNotEmpty) {
      return Failure(failures.first.error!);
    }
    return Success(successfulData);
  }
}

/// Specific result types for common operations
typedef GrammarResult = Result<GrammarEntity>;
typedef StringResult = Result<String>;
typedef BoolResult = Result<bool>;
typedef ListResult<T> = Result<List<T>>;

/// Static factory methods for creating results
class ResultFactory {
  /// Creates a success result
  static Result<T> success<T>(T data) => Success(data);

  /// Creates a failure result
  static Result<T> failure<T>(String message) => Failure(message);
}
