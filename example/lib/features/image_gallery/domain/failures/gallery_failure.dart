import 'package:equatable/equatable.dart';

sealed class GalleryFailure extends Equatable {
  const GalleryFailure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

final class NetworkFailure extends GalleryFailure {
  const NetworkFailure(super.message);
}

final class ServerFailure extends GalleryFailure {
  const ServerFailure(super.message);
}

final class ParsingFailure extends GalleryFailure {
  const ParsingFailure(super.message);
}

final class CacheFailure extends GalleryFailure {
  const CacheFailure(super.message);
}

final class UnknownFailure extends GalleryFailure {
  const UnknownFailure(super.message);
}
