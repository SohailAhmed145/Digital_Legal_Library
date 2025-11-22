import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../config/ai_config.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isInitialized = false;

  // Legal keywords to validate queries
  static const List<String> _legalKeywords = [
    'law', 'legal', 'contract', 'case', 'court', 'judge', 'attorney', 'lawyer',
    'litigation', 'trial', 'evidence', 'witness', 'plaintiff', 'defendant',
    'jurisdiction', 'statute', 'regulation', 'compliance', 'liability', 'damages',
    'settlement', 'appeal', 'verdict', 'sentence', 'probation', 'parole',
    'constitutional', 'civil', 'criminal', 'administrative', 'family law',
    'property law', 'tax law', 'corporate law', 'employment law', 'intellectual property',
    'trademark', 'copyright', 'patent', 'bankruptcy', 'estate planning',
    'real estate', 'business law', 'commercial law', 'international law',
    'human rights', 'environmental law', 'health law', 'education law',
    'immigration', 'criminal procedure', 'civil procedure', 'evidence law',
    'constitutional law', 'administrative law', 'regulatory law', 'antitrust',
    'securities law', 'banking law', 'insurance law', 'labor law', 'wills',
    'trusts', 'probate', 'divorce', 'custody', 'adoption', 'guardianship',
    'eminent domain', 'zoning', 'land use', 'construction law', 'medical malpractice',
    'personal injury', 'workers compensation', 'social security', 'veterans benefits',
    'military law', 'taxation', 'audit', 'investigation', 'subpoena', 'deposition',
    'mediation', 'arbitration', 'negotiation', 'due diligence', 'mergers',
    'acquisitions', 'joint ventures', 'partnerships', 'corporations', 'llc',
    'nonprofit', 'charitable organizations', 'government contracts', 'public law',
    'election law', 'campaign finance', 'lobbying', 'ethics', 'professional responsibility'
  ];

  // Initialize the AI service with Gemini API
  Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;

    try {
      final key = apiKey ?? AIConfig.geminiApiKey;
      
      _model = GenerativeModel(
        model: AIConfig.geminiModel,
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: AIConfig.temperature,
          topK: AIConfig.topK,
          topP: AIConfig.topP,
          maxOutputTokens: AIConfig.maxOutputTokens,
        ),
        // Safety settings removed for compatibility
      );

      _chatSession = _model.startChat();
      _isInitialized = true;
      print('AI Service initialized successfully with Gemini API');
    } catch (e) {
      print('Error initializing AI service: $e');
      rethrow;
    }
  }

  // Validate if a query is legal-related
  bool _isLegalQuery(String query) {
    final queryLower = query.toLowerCase();
    
    // Check if query contains legal keywords
    for (final keyword in _legalKeywords) {
      if (queryLower.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    // Check for legal question patterns
    final legalPatterns = [
      'what is the law',
      'how to file',
      'legal requirements',
      'legal process',
      'legal rights',
      'legal obligations',
      'legal consequences',
      'legal procedure',
      'legal document',
      'legal advice',
      'legal case',
      'legal issue',
      'legal matter',
      'legal question',
      'legal help',
      'legal support',
      'legal guidance',
      'legal information',
      'legal research',
      'legal analysis'
    ];
    
    for (final pattern in legalPatterns) {
      if (queryLower.contains(pattern)) {
        return true;
      }
    }
    
    return false;
  }

  // Send a message to the AI and get a response
  Future<String> sendMessage(String message, {String? context}) async {
    if (!_isInitialized) {
      // Try to initialize with default key if not already initialized
      await initialize();
    }

    try {
      // Validate if the query is legal-related
      if (!_isLegalQuery(message)) {
        return '''I'm a specialized legal AI assistant and can only help with legal matters. 

Please ask me about:
• Legal questions and concepts
• Contract law and drafting  
• Case law and precedents
• Legal procedures and processes
• Legal research and analysis
• Legal document preparation
• Legal terminology and definitions
• Legal compliance and regulations
• Legal risk assessment
• Legal strategy and planning

How can I assist you with a legal matter?''';
      }

      String prompt = message;
      
      // Add legal context if provided
      if (context != null && context.isNotEmpty) {
        prompt = '''
Legal Context: $context

User Question: $message

Please provide a professional legal response based on the context provided. If the context doesn't contain enough information, please indicate what additional information would be needed for a complete legal assessment.
''';
      }

      // Add the legal assistant prompt for all messages
      prompt = '''
${AIConfig.legalAssistantPrompt}

User Question: $message

Please provide a helpful and professional legal response.
''';

      final response = await _chatSession.sendMessage(Content.text(prompt));
      return response.text ?? 'I apologize, but I was unable to generate a response. Please try again.';
    } catch (e) {
      print('Error sending message to AI: $e');
      return 'I apologize, but I encountered an error while processing your request. Please try again later.';
    }
  }

  // Generate legal document draft
  Future<String> generateLegalDocument({
    required String documentType,
    required String caseDetails,
    required String jurisdiction,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    try {
      String prompt = '''
Generate a professional legal document of type: $documentType

Case Details: $caseDetails
Jurisdiction: $jurisdiction

Additional Parameters: ${additionalParams != null ? jsonEncode(additionalParams) : 'None'}

Please generate a complete, professional legal document that follows standard legal formatting and includes all necessary sections. The document should be ready for review by a legal professional.
''';

      final response = await _chatSession.sendMessage(Content.text(prompt));
      return response.text ?? 'Unable to generate document. Please try again.';
    } catch (e) {
      print('Error generating legal document: $e');
      return 'Error generating document. Please try again later.';
    }
  }

  // Analyze legal case
  Future<Map<String, dynamic>> analyzeLegalCase({
    required String caseSummary,
    required String legalQuestion,
    String? jurisdiction,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    try {
      String prompt = '''
Analyze the following legal case and provide a comprehensive analysis:

Case Summary: $caseSummary
Legal Question: $legalQuestion
Jurisdiction: ${jurisdiction ?? 'Not specified'}

Please provide:
1. Key legal issues identified
2. Relevant laws and precedents
3. Potential arguments for both sides
4. Risk assessment
5. Recommended next steps
6. Any additional considerations

Format your response as a structured analysis.
''';

      final response = await _chatSession.sendMessage(Content.text(prompt));
      final analysis = response.text ?? 'Unable to analyze case. Please try again.';
      
      // Try to parse the response into structured format
      try {
        // Look for structured patterns in the response
        final lines = analysis.split('\n');
        final structuredAnalysis = <String, dynamic>{};
        
        String currentSection = '';
        List<String> currentContent = [];
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          if (line.contains('1.') || line.contains('2.') || line.contains('3.') ||
              line.contains('4.') || line.contains('5.') || line.contains('6.') ||
              line.contains('Key legal issues') || line.contains('Relevant laws') ||
              line.contains('Potential arguments') || line.contains('Risk assessment') ||
              line.contains('Recommended next steps') || line.contains('Additional considerations')) {
            
            if (currentSection.isNotEmpty) {
              structuredAnalysis[currentSection] = currentContent.join('\n').trim();
            }
            
            currentSection = line.trim();
            currentContent = [];
          } else {
            currentContent.add(line.trim());
          }
        }
        
        if (currentSection.isNotEmpty) {
          structuredAnalysis[currentSection] = currentContent.join('\n').trim();
        }
        
        return structuredAnalysis;
      } catch (e) {
        // If parsing fails, return the raw analysis
        return {
          'analysis': analysis,
          'raw_response': true,
        };
      }
    } catch (e) {
      print('Error analyzing legal case: $e');
      return {
        'error': 'Error analyzing case. Please try again later.',
        'raw_response': true,
      };
    }
  }

  // Generate legal research summary
  Future<String> generateLegalResearchSummary({
    required String researchTopic,
    required List<String> keyPoints,
    String? jurisdiction,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    try {
      String prompt = '''
Generate a comprehensive legal research summary on: $researchTopic

Key Points to Cover: ${keyPoints.join(', ')}
Jurisdiction: ${jurisdiction ?? 'General'}

Please provide:
1. Executive Summary
2. Key Legal Principles
3. Relevant Case Law
4. Statutory Framework
5. Practical Implications
6. Recommendations

Format as a professional legal memorandum.
''';

      final response = await _chatSession.sendMessage(Content.text(prompt));
      return response.text ?? 'Unable to generate research summary. Please try again.';
    } catch (e) {
      print('Error generating legal research summary: $e');
      return 'Error generating research summary. Please try again later.';
    }
  }

  // Check if the service is initialized
  bool get isInitialized => _isInitialized;

  // Reset chat session
  void resetChat() {
    if (_isInitialized) {
      _chatSession = _model.startChat();
    }
  }

  // Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
