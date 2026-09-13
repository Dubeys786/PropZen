import 'dart:io';

void main() async {
  final buildDir = Directory('build/web');
  if (!await buildDir.exists()) {
    print('Error: build/web does not exist!');
    exit(1);
  }

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 3000;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Serving build/web on http://localhost:$port');

  final mimeTypes = {
    'html': 'text/html; charset=utf-8',
    'js': 'application/javascript; charset=utf-8',
    'json': 'application/json; charset=utf-8',
    'css': 'text/css; charset=utf-8',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'svg': 'image/svg+xml',
    'ico': 'image/x-icon',
    'wasm': 'application/wasm',
    'ttf': 'font/ttf',
    'otf': 'font/otf',
    'woff': 'font/woff',
    'woff2': 'font/woff2',
  };

  await for (final HttpRequest request in server) {
    try {
      var path = request.uri.path;
      if (path == '/' || path.isEmpty) {
        path = '/index.html';
      }

      var file = File('${buildDir.path}$path');
      if (!await file.exists()) {
        // Fallback for SPA routing
        file = File('${buildDir.path}/index.html');
      }

      final ext = file.path.split('.').last.toLowerCase();
      final mime = mimeTypes[ext] ?? 'application/octet-stream';

      request.response.headers.set('Content-Type', mime);
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Cache-Control', 'no-cache');

      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Server Error: $e');
        await request.response.close();
      } catch (_) {}
    }
  }
}
