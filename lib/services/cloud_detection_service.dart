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
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const int _maxRetries = 2;
  CloudDetectionService({required this.settings});

  Future<List<DetectionResult>> detect(Uint8List frameData, {int width = 0, int height = 0}) async => [];
  Future<CloudResponse> analyzeRoi(Uint8List frameData, Rect boundingBox, {String label = ''}) async {
    try { final cropBytes = await _cropRoi(frameData, boundingBox); return await _sendToCloud(cropBytes, label: label); } catch (e) { debugPrint('[CloudDetectionService] ROI analysis error: $e'); return const CloudResponse(verified: false, description: 'Analysis failed'); }
  }

  Future<Uint8List> _cropRoi(Uint8List frameData, Rect box) async => compute(_cropRoiIsolate, _CropParams(frameData, box));
  Future<CloudResponse> _sendToCloud(Uint8List cropBytes, {String label = ''}) async { switch (settings.cloudProvider) { case CloudProvider.openai: return _sendToOpenAI(cropBytes, label: label); case CloudProvider.anthropic: return _sendToAnthropic(cropBytes, label: label); case CloudProvider.custom: return _sendToCustomEndpoint(cropBytes, label: label);} }

  Future<http.Response> _postWithRetry(Uri uri, {required Map<String, String> headers, required Object body}) async {
    Object? lastError;
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final response = await http.post(uri, headers: headers, body: body).timeout(_requestTimeout);
        if (response.statusCode < 500) return response;
      } catch (e) { lastError = e; }
      await Future<void>.delayed(Duration(milliseconds: 250 * (i + 1)));
    }
    throw Exception('Request failed after retries: $lastError');
  }

  CloudResponse _parseSchemaResponse(Map<String, dynamic> payload) {
    return CloudResponse(
      verified: payload['verified'] == true,
      brand: payload['brand']?.toString(),
      model: payload['model']?.toString(),
      condition: payload['condition']?.toString(),
      description: payload['description']?.toString() ?? 'No description',
    );
  }

  Future<CloudResponse> _sendToOpenAI(Uint8List cropBytes, {String label = ''}) async {
    if (settings.openaiApiKey.isEmpty) return const CloudResponse(verified: false, description: 'No OpenAI API key configured');
    final response = await _postWithRetry(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {'Authorization': 'Bearer ${settings.openaiApiKey}', 'Content-Type': 'application/json'},
      body: jsonEncode({'model':'gpt-4o','messages':[{'role':'user','content':'Analyze image label "$label"'}], 'response_format': {'type': 'json_object'}, 'max_tokens':200}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return _parseSchemaResponse(jsonDecode(content) as Map<String, dynamic>);
    }
    return CloudResponse(verified: false, description: 'OpenAI response error: ${response.statusCode}');
  }

  Future<CloudResponse> _sendToAnthropic(Uint8List cropBytes, {String label = ''}) async {
    if (settings.anthropicApiKey.isEmpty) return const CloudResponse(verified: false, description: 'No Anthropic API key configured');
    final base64Image = base64Encode(cropBytes);
    final response = await _postWithRetry(Uri.parse('https://api.anthropic.com/v1/messages'), headers: {'x-api-key': settings.anthropicApiKey,'anthropic-version':'2023-06-01','Content-Type':'application/json'}, body: jsonEncode({'model':'claude-3-5-sonnet-20241022','max_tokens':200,'messages':[{'role':'user','content':[{'type':'image','source':{'type':'base64','media_type':'image/jpeg','data':base64Image}},{'type':'text','text':'Return strict JSON object with keys verified,brand,model,condition,description for "$label".'}]}]}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'][0]['text'] as String;
      return _parseSchemaResponse(jsonDecode(content) as Map<String, dynamic>);
    }
    return CloudResponse(verified: false, description: 'Anthropic response error: ${response.statusCode}');
  }

  Future<CloudResponse> _sendToCustomEndpoint(Uint8List cropBytes, {String label = ''}) async {
    final parsed = Uri.tryParse(settings.customEndpointUrl);
    if (parsed == null || !parsed.hasAuthority || parsed.scheme != 'https') {
      return const CloudResponse(verified: false, description: 'Custom endpoint must be valid HTTPS URL');
    }
    final base64Image = base64Encode(cropBytes);
    final response = await _postWithRetry(parsed, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'image': base64Image, 'label': label, 'format': 'jpeg'}));
    if (response.statusCode == 200) return _parseSchemaResponse(jsonDecode(response.body) as Map<String, dynamic>);
    return CloudResponse(verified: false, description: 'Custom endpoint error: ${response.statusCode}');
  }
}

class _CropParams { final Uint8List frameData; final Rect box; _CropParams(this.frameData, this.box); }
Uint8List _cropRoiIsolate(_CropParams params) { try { final decoded = img.decodeImage(params.frameData); if (decoded == null) return params.frameData; final x = params.box.left.round().clamp(0, decoded.width - 1); final y = params.box.top.round().clamp(0, decoded.height - 1); final w = params.box.width.round().clamp(1, decoded.width - x); final h = params.box.height.round().clamp(1, decoded.height - y); final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h); return Uint8List.fromList(img.encodeJpg(cropped, quality: 85)); } catch (_) { return params.frameData; } }
