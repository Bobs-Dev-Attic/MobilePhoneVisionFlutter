import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/app_settings.dart';
import '../models/cloud_response.dart';
import '../models/detection_result.dart';

class CloudDetectionService {
  final AppSettings settings;

  CloudDetectionService({required this.settings});

  Future<List<DetectionResult>> detect(
    Uint8List frameData, {
    int width = 0,
    int height = 0,
  }) async {
    return [];
  }

  Future<CloudResponse> analyzeRoi(
    Uint8List frameData,
    Rect boundingBox, {
    String label = '',
  }) async {
    try {
      final cropBytes = await _cropRoi(frameData, boundingBox);
      return await _sendToCloud(cropBytes, label: label);
    } catch (e) {
      debugPrint('[CloudDetectionService] ROI analysis error: $e');
      return const CloudResponse(verified: false, description: 'Analysis failed');
    }
  }

  Future<Uint8List> _cropRoi(Uint8List frameData, Rect box) async {
    return compute(_cropRoiIsolate, _CropParams(frameData, box));
  }

  Future<CloudResponse> _sendToCloud(Uint8List cropBytes, {String label = ''}) async {
    switch (settings.cloudProvider) {
      case CloudProvider.openai:
        return _sendToOpenAI(cropBytes, label: label);
      case CloudProvider.anthropic:
        return _sendToAnthropic(cropBytes, label: label);
      case CloudProvider.custom:
        return _sendToCustomEndpoint(cropBytes, label: label);
    }
  }

  Future<CloudResponse> _sendToOpenAI(Uint8List cropBytes, {String label = ''}) async {
    if (settings.openaiApiKey.isEmpty) {
      return const CloudResponse(verified: false, description: 'No OpenAI API key configured');
    }
    final base64Image = base64Encode(cropBytes);
    final prompt = 'Analyze this image of a "$label". Respond with JSON: '
        '{"verified": bool, "brand": "...", "model": "...", "condition": "...", "description": "..."}';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${settings.openaiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      try {
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          return CloudResponse.fromJson(
            jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }
    return CloudResponse(
      verified: false,
      description: 'OpenAI response error: ${response.statusCode}',
    );
  }

  Future<CloudResponse> _sendToAnthropic(Uint8List cropBytes, {String label = ''}) async {
    if (settings.anthropicApiKey.isEmpty) {
      return const CloudResponse(verified: false, description: 'No Anthropic API key configured');
    }
    final base64Image = base64Encode(cropBytes);
    final prompt = 'Analyze this image of a "$label". Respond with JSON only: '
        '{"verified": bool, "brand": "...", "model": "...", "condition": "...", "description": "..."}';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': settings.anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 200,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'][0]['text'] as String;
      try {
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          return CloudResponse.fromJson(
            jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }
    return CloudResponse(
      verified: false,
      description: 'Anthropic response error: ${response.statusCode}',
    );
  }

  Future<CloudResponse> _sendToCustomEndpoint(Uint8List cropBytes, {String label = ''}) async {
    if (settings.customEndpointUrl.isEmpty) {
      return const CloudResponse(verified: false, description: 'No custom endpoint configured');
    }
    final base64Image = base64Encode(cropBytes);
    final response = await http.post(
      Uri.parse(settings.customEndpointUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image': base64Image,
        'label': label,
        'format': 'jpeg',
      }),
    );

    if (response.statusCode == 200) {
      try {
        return CloudResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return CloudResponse(
      verified: false,
      description: 'Custom endpoint error: ${response.statusCode}',
    );
  }
}

class _CropParams {
  final Uint8List frameData;
  final Rect box;
  _CropParams(this.frameData, this.box);
}

Uint8List _cropRoiIsolate(_CropParams params) {
  try {
    final decoded = img.decodeImage(params.frameData);
    if (decoded == null) return params.frameData;
    final x = params.box.left.round().clamp(0, decoded.width - 1);
    final y = params.box.top.round().clamp(0, decoded.height - 1);
    final w = params.box.width.round().clamp(1, decoded.width - x);
    final h = params.box.height.round().clamp(1, decoded.height - y);
    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
  } catch (_) {
    return params.frameData;
  }
}
