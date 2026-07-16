import 'package:flutter/material.dart';

void main() {
  runApp(const ImageCacheExampleApp());
}

class ImageCacheExampleApp extends StatelessWidget {
  const ImageCacheExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Image Cache Plugin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Gallery features will be added in a later milestone.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
