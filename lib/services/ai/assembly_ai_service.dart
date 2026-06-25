import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AssemblyAiService {
  static const String _apiKeyPref = 'assembly_ai_api_key';

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  Future<String> transcribeAudio(String filePath) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('AssemblyAI API Key not set in Settings');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found');
    }

    // Step 1: Upload the file
    final uploadResponse = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/upload'),
      headers: {
        'authorization': apiKey,
        'transfer-encoding': 'chunked',
      },
      body: await file.readAsBytes(),
    );

    if (uploadResponse.statusCode != 200) {
      throw Exception('Failed to upload audio: ${uploadResponse.body}');
    }

    final uploadUrl = jsonDecode(uploadResponse.body)['upload_url'];

    // Step 2: Request transcription
    final transcriptResponse = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/transcript'),
      headers: {
        'authorization': apiKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'audio_url': uploadUrl,
      }),
    );

    if (transcriptResponse.statusCode != 200) {
      throw Exception('Failed to request transcription: ${transcriptResponse.body}');
    }

    final transcriptId = jsonDecode(transcriptResponse.body)['id'];

    // Step 3: Poll for completion
    while (true) {
      final pollingResponse = await http.get(
        Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
        headers: {'authorization': apiKey},
      );

      final pollingData = jsonDecode(pollingResponse.body);
      final status = pollingData['status'];

      if (status == 'completed') {
        return pollingData['text'];
      } else if (status == 'error') {
        throw Exception('Transcription failed: ${pollingData['error']}');
      }

      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
