import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:uuid/uuid.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _apiKey;

  void initialize(String apiKey) {
    if (_apiKey == apiKey && _model != null) return;
    _apiKey = apiKey;

    final logPastActivityTool = FunctionDeclaration(
      'logPastActivity',
      'Log a past study session or activity that the user has already completed.',
      Schema(
        SchemaType.object,
        properties: {
          'activityName': Schema(SchemaType.string, description: 'The name of the activity, e.g., "Pathology Study", "Prayer", "Reading FA".'),
          'durationMinutes': Schema(SchemaType.integer, description: 'How long the activity took in minutes.'),
          'timeAgoMinutes': Schema(SchemaType.integer, description: 'How many minutes ago the activity finished. Use 0 if it just finished.'),
        },
        requiredProperties: ['activityName', 'durationMinutes', 'timeAgoMinutes'],
      ),
    );

    final createFutureTaskTool = FunctionDeclaration(
      'createFutureTask',
      'Create a future task or plan for the user to complete later.',
      Schema(
        SchemaType.object,
        properties: {
          'taskName': Schema(SchemaType.string, description: 'The name of the future task.'),
          'date': Schema(SchemaType.string, description: 'The date for the task in yyyy-MM-dd format.'),
          'time': Schema(SchemaType.string, description: 'The time for the task in HH:mm format (optional).'),
        },
        requiredProperties: ['taskName', 'date'],
      ),
    );

    final startTrackingTool = FunctionDeclaration(
      'startTracking',
      'Start tracking a study session or activity right now.',
      Schema(
        SchemaType.object,
        properties: {
          'activityName': Schema(SchemaType.string, description: 'The name of the activity to start tracking.'),
        },
        requiredProperties: ['activityName'],
      ),
    );

    final getUWorldTopicsTool = FunctionDeclaration(
      'getUWorldTopics',
      'Get a list of available UWorld topics to show to the user.',
      Schema(SchemaType.object, properties: {}),
    );

    final tool = Tool(functionDeclarations: [
      logPastActivityTool,
      createFutureTaskTool,
      startTrackingTool,
      getUWorldTopicsTool,
    ]);

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      tools: [tool],
      systemInstruction: Content.system('You are FocusFlow AI, the soul of the FocusFlow medical study planner app. You are deeply integrated with the app. You can log past events, create future tasks, track current activities, and show UWorld topics. Always use tools to perform actions on behalf of the user. If you use the getUWorldTopics tool, you must respond with a special interactive list by typing [UWORLD_TOPIC_LIST] in your text response, which the app will render as an interactive UI. Keep your textual responses concise.'),
    );
    _chatSession = _model!.startChat();
  }

  Future<String> generateResponse(String prompt, {Function(String action, dynamic payload)? onAction}) async {
    if (_model == null || _chatSession == null) {
      return 'Error: Gemini AI is not initialized. Please set your API key in Settings.';
    }

    try {
      var response = await _chatSession!.sendMessage(Content.text(prompt));
      
      if (response.functionCalls.isNotEmpty) {
        final List<FunctionResponse> functionResponses = [];
        for (final functionCall in response.functionCalls) {
          final result = await _handleFunctionCall(functionCall, onAction: onAction);
          functionResponses.add(FunctionResponse(functionCall.name, result));
        }
        
        response = await _chatSession!.sendMessage(
          Content.functionResponses(functionResponses),
        );
      }
      
      return response.text ?? 'No response generated.';
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return 'Sorry, I encountered an error: $e';
    }
  }

  Future<Map<String, Object?>> _handleFunctionCall(FunctionCall functionCall, {Function(String action, dynamic payload)? onAction}) async {
    final db = DatabaseService.instance;
    final args = functionCall.args;
    
    switch (functionCall.name) {
      case 'logPastActivity':
        final activityName = args['activityName'] as String;
        final durationMinutes = (args['durationMinutes'] as num).toInt();
        final timeAgoMinutes = (args['timeAgoMinutes'] as num).toInt();
        
        final endTime = DateTime.now().subtract(Duration(minutes: timeAgoMinutes));
        final startTime = endTime.subtract(Duration(minutes: durationMinutes));
        
        final id = const Uuid().v4();
        await db.upsertTimeLog({
          'id': id,
          'date': endTime.toIso8601String().substring(0, 10),
          'category': activityName,
          'source': 'AI',
          'duration': durationMinutes * 60,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        });
        
        return {'status': 'success', 'message': 'Logged $activityName for $durationMinutes minutes.'};
        
      case 'createFutureTask':
        final taskName = args['taskName'] as String;
        final date = args['date'] as String;
        final time = args['time'] as String?;
        
        final id = const Uuid().v4();
        await db.upsertStudyPlanItem({
          'id': id,
          'date': date,
          'title': taskName,
          'time': time,
          'isCompleted': false,
          'source': 'AI',
        });
        
        return {'status': 'success', 'message': 'Created task "$taskName" for $date.'};
        
      case 'startTracking':
        final activityName = args['activityName'] as String;
        if (onAction != null) {
          onAction('NAVIGATE_TRACKER', {'activityName': activityName});
        }
        return {'status': 'success', 'message': 'Tracking started.'};
        
      case 'getUWorldTopics':
        final rows = await db.getAll('uworld_topics');
        final topics = rows.map((r) => r['subtopic'] as String).toSet().toList();
        if (onAction != null) {
          onAction('SHOW_UWORLD_TOPICS', {'topics': topics});
        }
        return {'status': 'success', 'topics': topics};
        
      default:
        return {'error': 'Unknown function call'};
    }
  }
}
