import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sevasetu/services/ai/groq_client.dart';

class MockHttpClient extends http.BaseClient {
  MockHttpClient(this._handler);
  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final httpRequest = request as http.Request;
    final response = await _handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('GroqClient Unit Tests', () {
    test('Throws GroqMissingKeyException when apiKey is empty', () async {
      final client = GroqClient();
      expect(
        () => client.chatCompletion(
          messages: [
            {'role': 'user', 'content': 'hi'}
          ],
          overrideApiKey: '',
        ),
        throwsA(isA<GroqMissingKeyException>()),
      );
    });

    test('Parses valid JSON chat completion successfully', () async {
      final mock = MockHttpClient((req) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"agent":"scheme_recommendation","headline":"Found 1 scheme"}'
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = GroqClient(client: mock);
      final res = await client.chatCompletion(
        messages: [
          {'role': 'user', 'content': 'find scheme'}
        ],
        overrideApiKey: 'test-key',
      );

      expect(res['agent'], 'scheme_recommendation');
      expect(res['headline'], 'Found 1 scheme');
    });

    test('Throws GroqAuthException on 401 response', () async {
      final mock = MockHttpClient((req) async {
        return http.Response('Unauthorized', 401);
      });

      final client = GroqClient(client: mock);
      expect(
        () => client.chatCompletion(
          messages: [
            {'role': 'user', 'content': 'test'}
          ],
          overrideApiKey: 'invalid-key',
        ),
        throwsA(isA<GroqAuthException>()),
      );
    });

    test('Strips markdown code fences automatically', () async {
      final mock = MockHttpClient((req) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '```json\n{"summary":"Test Answer"}\n```'
                }
              }
            ]
          }),
          200,
        );
      });

      final client = GroqClient(client: mock);
      final res = await client.chatCompletion(
        messages: [
          {'role': 'user', 'content': 'test'}
        ],
        overrideApiKey: 'test-key',
      );

      expect(res['summary'], 'Test Answer');
    });
  });
}
