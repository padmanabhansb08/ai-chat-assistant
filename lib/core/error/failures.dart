import 'package:equatable/equatable.dart';

/// Typed, user-presentable errors. Thrown by the data layer, caught by Blocs.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Cannot reach the server. Check your connection and base URL.',
  ]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out. Please try again.']);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed. Check your API key in Settings.',
  ]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Rate limit reached. Wait a moment and try again.',
  ]);
}

class InvalidResponseFailure extends Failure {
  const InvalidResponseFailure([
    super.message = 'The provider returned an unexpected response.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'The provider reported an error.']);
}

class ConfigFailure extends Failure {
  const ConfigFailure([
    super.message = 'AI provider is not configured. Set a base URL and model in Settings.',
  ]);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not read or write local data.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
