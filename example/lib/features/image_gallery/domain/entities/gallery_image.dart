import 'package:equatable/equatable.dart';

final class GalleryImage extends Equatable {
  const GalleryImage({required this.id, required this.imageUrl});

  final int id;
  final String imageUrl;

  @override
  List<Object> get props => [id, imageUrl];
}
