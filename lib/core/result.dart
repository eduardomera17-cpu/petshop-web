// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/result.dart
// Propósito: Tipo monádico sellado Result<T> para la gestión funcional y tipada de operaciones asíncronas exitosas (Ok) o fallidas (Err).
// =========================================================================

import 'failures.dart';

/// {@template result}
/// Tipo de retorno funcional y sellado para operaciones que pueden fallar (TRD §1.2).
///
/// Modela explícitamente el resultado de repositorios y casos de uso, obligando a manejar
/// exhaustivamente el valor exitoso [Ok] o la falla tipada [Err] sin lanzar excepciones no controladas.
/// {@endtemplate}
sealed class Result<T> {
  const Result();

  /// Indica si la operación concluyó con éxito.
  bool get isOk => this is Ok<T>;

  /// Indica si la operación concluyó con una falla.
  bool get isErr => this is Err<T>;

  /// Retorna el dato contenido si es [Ok], o `null` si es [Err].
  T? get dataOrNull => switch (this) {
        Ok<T>(value: final v) => v,
        Err<T>() => null,
      };

  /// Retorna la falla contenida si es [Err], o `null` si es [Ok].
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(failure: final f) => f,
      };

  /// Ejecuta [ok] o [err] según la variante concreta del resultado.
  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) =>
      switch (this) {
        Ok<T>(value: final v) => ok(v),
        Err<T>(failure: final f) => err(f),
      };
}

/// {@template result_ok}
/// Variante exitosa de un [Result], portadora del valor procesado [value].
/// {@endtemplate}
final class Ok<T> extends Result<T> {
  /// Valor retornado por la operación exitosa.
  final T value;

  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T> && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

/// {@template result_err}
/// Variante con falla de un [Result], portadora del objeto [failure].
/// {@endtemplate}
final class Err<T> extends Result<T> {
  /// Falla de dominio o infraestructura reportada.
  final Failure failure;

  const Err(this.failure);

  @override
  String toString() => 'Err($failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;
}
