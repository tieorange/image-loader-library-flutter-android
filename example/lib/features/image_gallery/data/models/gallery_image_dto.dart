import '../../domain/entities/gallery_image.dart';
import '../sources/gallery_data_exception.dart';

final class GalleryImageDto {
  const GalleryImageDto({required this.id, required this.imageUrl});

  factory GalleryImageDto.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const GalleryParsingException('An image item must be an object');
    }
    final Object? id = value['id'];
    final Object? imageUrl = value['imageUrl'];
    if (id is! int || imageUrl is! String || imageUrl.trim().isEmpty) {
      throw const GalleryParsingException('An image item is malformed');
    }
    final Uri? uri = Uri.tryParse(imageUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.hasAuthority) {
      throw const GalleryParsingException('An image URL is invalid');
    }
    return GalleryImageDto(id: id, imageUrl: imageUrl);
  }

  final int id;
  final String imageUrl;

  GalleryImage toEntity() => GalleryImage(id: id, imageUrl: imageUrl);
}
