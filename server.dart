import 'dart:convert';
import 'dart:io';

class N8nEnvConfig {
  static String bookSiteVisitUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/site-visit';
  static String propertyEnquiryUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/enquiry';
  static String propertyDataUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/property';
  static String servicesUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/services';
  static String verifyDocumentUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/verify-document';
  static String officialSourceCheckUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/verify-source';
  static String questionGeneratorUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/verification-question';
  static String propertyMonitorUrl = 'https://propzen.app.n8n.cloud/webhook/propzen/property-monitor';
  static String apiKey = Platform.environment['N8N_API_KEY'] ?? '';

  static void load() {
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final lines = envFile.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final splitIdx = trimmed.indexOf('=');
          if (splitIdx != -1) {
            final key = trimmed.substring(0, splitIdx).trim();
            final value = trimmed.substring(splitIdx + 1).trim();
            if (key == 'N8N_BOOK_SITE_VISIT_URL') bookSiteVisitUrl = value;
            if (key == 'N8N_PROPERTY_ENQUIRY_URL') propertyEnquiryUrl = value;
            if (key == 'N8N_PROPERTY_DATA_URL') propertyDataUrl = value;
            if (key == 'N8N_SERVICES_URL') servicesUrl = value;
            if (key == 'N8N_VERIFY_DOCUMENT_URL') verifyDocumentUrl = value;
            if (key == 'N8N_OFFICIAL_SOURCE_CHECK_URL') officialSourceCheckUrl = value;
            if (key == 'N8N_QUESTION_GENERATOR_URL') questionGeneratorUrl = value;
            if (key == 'N8N_PROPERTY_MONITOR_URL') propertyMonitorUrl = value;
            if (key == 'N8N_API_KEY') apiKey = value;
          }
        }
      }
    } catch (e) {
      print('Warning loading .env: $e');
    }

    if (Platform.environment.containsKey('N8N_BOOK_SITE_VISIT_URL')) {
      bookSiteVisitUrl = Platform.environment['N8N_BOOK_SITE_VISIT_URL']!;
    }
    if (Platform.environment.containsKey('N8N_PROPERTY_ENQUIRY_URL')) {
      propertyEnquiryUrl = Platform.environment['N8N_PROPERTY_ENQUIRY_URL']!;
    }
    if (Platform.environment.containsKey('N8N_PROPERTY_DATA_URL')) {
      propertyDataUrl = Platform.environment['N8N_PROPERTY_DATA_URL']!;
    }
    if (Platform.environment.containsKey('N8N_SERVICES_URL')) {
      servicesUrl = Platform.environment['N8N_SERVICES_URL']!;
    }
    if (Platform.environment.containsKey('N8N_VERIFY_DOCUMENT_URL')) {
      verifyDocumentUrl = Platform.environment['N8N_VERIFY_DOCUMENT_URL']!;
    }
    if (Platform.environment.containsKey('N8N_OFFICIAL_SOURCE_CHECK_URL')) {
      officialSourceCheckUrl = Platform.environment['N8N_OFFICIAL_SOURCE_CHECK_URL']!;
    }
    if (Platform.environment.containsKey('N8N_QUESTION_GENERATOR_URL')) {
      questionGeneratorUrl = Platform.environment['N8N_QUESTION_GENERATOR_URL']!;
    }
    if (Platform.environment.containsKey('N8N_PROPERTY_MONITOR_URL')) {
      propertyMonitorUrl = Platform.environment['N8N_PROPERTY_MONITOR_URL']!;
    }
    if (Platform.environment.containsKey('N8N_API_KEY')) {
      apiKey = Platform.environment['N8N_API_KEY']!;
    }

    print('[n8n Proxy] Initialized with Production Endpoints:');
    print(' - Site Visit:        $bookSiteVisitUrl');
    print(' - Enquiry:           $propertyEnquiryUrl');
    print(' - Property:          $propertyDataUrl');
    print(' - Services:          $servicesUrl');
    print(' - Verify Document:   $verifyDocumentUrl');
    print(' - Official Source:   $officialSourceCheckUrl');
    print(' - Question Gen:      $questionGeneratorUrl');
    print(' - Property Monitor:  $propertyMonitorUrl');
  }
}

void main() async {
  N8nEnvConfig.load();
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080, shared: true);
  final httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  print('SERVER_RUNNING: http://localhost:8080');

  await for (HttpRequest request in server) {
    var path = request.uri.path;

    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization, X-PropZen-Key, X-Requested-With');
    request.response.headers.add('X-Content-Type-Options', 'nosniff');
    request.response.headers.add('X-Frame-Options', 'SAMEORIGIN');
    request.response.headers.add('Referrer-Policy', 'strict-origin-when-cross-origin');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    if (path.startsWith('/api/n8n/')) {
      final proxySubPath = path.replaceFirst('/api/n8n/', '');
      String? targetUrl;

      switch (proxySubPath) {
        case 'site-visit':
          targetUrl = N8nEnvConfig.bookSiteVisitUrl;
          break;
        case 'enquiry':
          targetUrl = N8nEnvConfig.propertyEnquiryUrl;
          break;
        case 'property':
          targetUrl = N8nEnvConfig.propertyDataUrl;
          if (request.uri.hasQuery) {
            targetUrl = '$targetUrl?${request.uri.query}';
          }
          break;
        case 'services':
          targetUrl = N8nEnvConfig.servicesUrl;
          break;
        case 'verify-document':
          targetUrl = N8nEnvConfig.verifyDocumentUrl;
          break;
        case 'verify-source':
          targetUrl = N8nEnvConfig.officialSourceCheckUrl;
          if (request.uri.hasQuery) {
            targetUrl = '$targetUrl?${request.uri.query}';
          }
          break;
        case 'verification-question':
          targetUrl = N8nEnvConfig.questionGeneratorUrl;
          break;
        case 'property-monitor':
          targetUrl = N8nEnvConfig.propertyMonitorUrl;
          break;
        case 'health':
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({
            'status': 'healthy',
            'proxy': 'PropZen Secure Production Proxy',
          }));
          await request.response.close();
          continue;
      }

      if (targetUrl == null) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'error': 'Unknown n8n proxy endpoint: $proxySubPath',
          'status': 404,
        }));
        await request.response.close();
        continue;
      }

      try {
        final bodyBytes = await request.fold<List<int>>([], (previous, element) => previous..addAll(element));
        final targetUri = Uri.parse(targetUrl);

        HttpClientRequest proxyReq;
        if (request.method == 'GET') {
          proxyReq = await httpClient.getUrl(targetUri);
        } else {
          proxyReq = await httpClient.postUrl(targetUri);
        }

        proxyReq.headers.set('X-PropZen-Key', N8nEnvConfig.apiKey);
        proxyReq.headers.set('Content-Type', 'application/json');
        proxyReq.headers.set('Accept', 'application/json');

        if (bodyBytes.isNotEmpty && request.method != 'GET') {
          proxyReq.add(bodyBytes);
        }

        final proxyRes = await proxyReq.close();
        request.response.statusCode = proxyRes.statusCode;
        request.response.headers.contentType = ContentType.json;

        final resBytes = await proxyRes.fold<List<int>>([], (previous, element) => previous..addAll(element));
        if (resBytes.isNotEmpty) {
          request.response.add(resBytes);
        } else {
          request.response.write(jsonEncode({
            'status': proxyRes.statusCode >= 200 && proxyRes.statusCode < 300 ? 'success' : 'response_received',
            'statusCode': proxyRes.statusCode,
          }));
        }
      } catch (e) {
        print('[n8n Proxy Error] Failed forwarding to $targetUrl: $e');
        request.response.statusCode = HttpStatus.badGateway;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'error': 'Failed connecting to n8n workflow: $e',
          'status': 502,
        }));
      }

      await request.response.close();
      continue;
    }

    if (path == '/' || path.isEmpty) path = '/index.html';

    var file = File('.$path');

    if (!await file.exists() && !path.contains('.')) {
      file = File('./index.html');
      path = '/index.html';
    }

    if (await file.exists()) {
      request.response.headers.add('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
      request.response.headers.add('Pragma', 'no-cache');
      request.response.headers.add('Expires', '0');

      if (file.path.endsWith('.html')) {
        request.response.headers.contentType = ContentType.html;
      } else if (file.path.endsWith('.js')) {
        request.response.headers.contentType = ContentType('application', 'javascript', charset: 'utf-8');
      } else if (file.path.endsWith('.css')) {
        request.response.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
      } else if (file.path.endsWith('.json')) {
        request.response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      } else if (file.path.endsWith('.png')) {
        request.response.headers.contentType = ContentType('image', 'png');
      } else if (file.path.endsWith('.jpg') || file.path.endsWith('.jpeg')) {
        request.response.headers.contentType = ContentType('image', 'jpeg');
      } else if (file.path.endsWith('.svg')) {
        request.response.headers.contentType = ContentType('image', 'svg+xml');
      } else if (file.path.endsWith('.wasm')) {
        request.response.headers.contentType = ContentType('application', 'wasm');
      } else if (file.path.endsWith('.ttf') || file.path.endsWith('.otf')) {
        request.response.headers.contentType = ContentType('font', 'ttf');
      }

      await request.response.addStream(file.openRead());
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('404 Not Found');
    }
    await request.response.close();
  }
}
