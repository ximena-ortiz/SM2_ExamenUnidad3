import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../services/quiz_practice_service.dart';
import 'progress_provider.dart';

class QuizProvider with ChangeNotifier {
  final List<QuizQuestion> _questions = QuizQuestion.getSampleQuestions();
  final ProgressProvider? _progressProvider;
  final QuizPracticeService _quizService = QuizPracticeService();
  final String _chapterId;
  
  int _currentQuestionIndex = 0;
  int? _selectedOption;
  int _score = 100;
  bool _hasAnswered = false;
  bool _showResult = false;
  QuizPracticeSession? _currentSession;
  bool _isLoading = false;
  
  QuizProvider({
    ProgressProvider? progressProvider,
    String chapterId = 'default-chapter',
  }) : _progressProvider = progressProvider,
       _chapterId = chapterId;

  List<QuizQuestion> get questions => _questions;
  QuizQuestion get currentQuestion => _questions[_currentQuestionIndex];
  int get currentQuestionIndex => _currentQuestionIndex;
  int? get selectedOption => _selectedOption;
  int get score => _score;
  bool get hasAnswered => _hasAnswered;
  bool get showResult => _showResult;
  bool get canSubmit => _selectedOption != null && !_hasAnswered;
  QuizPracticeSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;

  void selectOption(int optionIndex) {
    if (!_hasAnswered) {
      _selectedOption = optionIndex;
      notifyListeners();
    }
  }

  void submitAnswer() {
    if (_selectedOption != null && !_hasAnswered) {
      _hasAnswered = true;
      _showResult = true;
      
      // Check if answer is correct
      if (_selectedOption == currentQuestion.correctAnswer) {
        // Keep current score for correct answer
      } else {
        // Deduct points for wrong answer (optional)
        _score = (_score - 20).clamp(0, 100);
      }
      
      // Auto-save progress after answering
      _progressProvider?.onQuizAnswered(_chapterId, _score.toDouble(), _currentQuestionIndex);
      
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _resetQuestionState();
      
      // Auto-save progress when moving to next question
      _progressProvider?.onQuizAnswered(_chapterId, _score.toDouble(), _currentQuestionIndex);
    } else {
      // Quiz completed - save final progress
      _progressProvider?.onChapterCompleted(_chapterId, _score.toDouble());
    }
  }

  void resetQuiz() {
    _currentQuestionIndex = 0;
    _score = 100;
    _resetQuestionState();
  }

  void _resetQuestionState() {
    _selectedOption = null;
    _hasAnswered = false;
    _showResult = false;
    notifyListeners();
  }

  bool isCorrectAnswer(int optionIndex) {
    return optionIndex == currentQuestion.correctAnswer;
  }

  bool isWrongAnswer(int optionIndex) {
    return _hasAnswered && 
           _selectedOption == optionIndex && 
           optionIndex != currentQuestion.correctAnswer;
  }
  
  // Create a new quiz practice session
  Future<void> createQuizSession({
    required String userId,
    required String token,
    String? episodeId,
    String quizCategory = 'general',
    String difficultyLevel = 'beginner',
    int totalQuestions = 10,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentSession = await _quizService.createQuizSession(
        token: token,
        userId: userId,
        chapterId: _chapterId,
        episodeId: episodeId,
        quizCategory: quizCategory,
        difficultyLevel: difficultyLevel,
        totalQuestions: totalQuestions,
      );
      
      if (_currentSession != null) {
        // Update local state based on session data
        _currentQuestionIndex = 0;
        _score = _currentSession!.score.toInt();
      }
    } catch (e) {
      print('Error creating quiz session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Submit answer using the service
  Future<void> submitAnswerToService({
    required String token,
    required int timeSpentSeconds,
  }) async {
    if (_currentSession == null || _selectedOption == null) return;
    
    try {
      _currentSession = await _quizService.answerQuestion(
        sessionId: _currentSession!.id,
        token: token,
        questionNumber: _currentQuestionIndex + 1,
        userAnswer: _selectedOption!,
        timeSpentSeconds: timeSpentSeconds,
      );
      
      if (_currentSession != null) {
        _score = _currentSession!.score.toInt();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error submitting answer: $e');
    }
  }
  
  // Complete quiz session
  Future<void> completeQuizSession({
    required String token,
    required int totalTimeSpent,
  }) async {
    if (_currentSession == null) return;
    
    try {
      _currentSession = await _quizService.completeQuiz(
        sessionId: _currentSession!.id,
        token: token,
        totalTimeSpent: totalTimeSpent,
      );
      
      if (_currentSession != null) {
        // Save final progress
        _progressProvider?.onChapterCompleted(_chapterId, _currentSession!.score);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error completing quiz: $e');
    }
  }
  
  // Get user quiz statistics
  Future<QuizStats?> getUserStats({
    required String userId,
    required String token,
    String? timeframe,
    String? category,
    String? difficultyLevel,
  }) async {
    try {
      return await _quizService.getUserQuizStats(
        userId: userId,
        token: token,
        timeframe: timeframe,
        category: category,
        difficultyLevel: difficultyLevel,
      );
    } catch (e) {
      print('Error getting quiz stats: $e');
      return null;
    }
  }
}