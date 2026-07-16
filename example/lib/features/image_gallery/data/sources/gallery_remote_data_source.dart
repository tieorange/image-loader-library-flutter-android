import 'dart:convert';
import 'dart:io';

import '../models/gallery_image_dto.dart';
import 'gallery_data_exception.dart';

abstract interface class GalleryRemoteDataSource {
  Future<List<GalleryImageDto>> getImages();
}

final class HttpGalleryRemoteDataSource implements GalleryRemoteDataSource {
  HttpGalleryRemoteDataSource(this._client, {Uri? endpoint})
    : _endpoint = endpoint ?? _defaultEndpoint;

  static final Uri _defaultEndpoint = Uri.parse(
    'https://zipoapps-storage-test.nyc3.digitaloceanspaces.com/image_list.json',
  );

  final HttpClient _client;
  final Uri _endpoint;

  @override
  Future<List<GalleryImageDto>> getImages() async {
    try {
      final HttpClientRequest request = await _client.getUrl(_endpoint);
      final HttpClientResponse response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw GalleryServerException(
          'The image service returned HTTP ${response.statusCode}',
        );
      }
      final String body = await utf8.decoder.bind(response).join();
      return parseResponse(body);
    } on GalleryDataException {
      rethrow;
    } on FormatException {
      throw const GalleryParsingException('The image response is invalid');
    } on IOException {
      throw const GalleryNetworkException('Unable to reach the image service');
    }
  }

  List<GalleryImageDto> parseResponse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const GalleryParsingException('The image response is invalid');
    }
    if (decoded is! List<Object?>) {
      throw const GalleryParsingException('The image response must be a list');
    }
    return decoded.map(GalleryImageDto.fromJson).toList(growable: false);
  }
}
