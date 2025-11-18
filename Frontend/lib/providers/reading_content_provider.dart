import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/reading_content.dart';
import '../models/reading_highlighted_word.dart';
import '../models/reading_quiz_question.dart';
import '../utils/environment_config.dart';
import 'auth_provider.dart';

enum ReadingContentState {
  initial,
  loading,
  loaded,
  error,
}

class ReadingContentProvider with ChangeNotifier {
  final AuthProvider _authProvider;

  ReadingContentState _state = ReadingContentState.initial;
  ReadingContent? _content;
  List<ReadingQuizQuestion> _quizQuestions = [];
  String? _errorMessage;

  // Reading progress state
  int _currentPage = 0;
  bool _isQuizMode = false;
  bool _isLoadingQuiz = false;
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  int _score = 0;

  // New quiz flow state
  bool _showHint = false; // Whether to show hint for current question
  bool _hasAttemptedOnce = false; // Whether user has attempted once (for 2-strike system)
  List<bool> _questionAnsweredCorrectly = []; // Track which questions were answered correctly
  int _wrongAnswersCount = 0; // Track wrong answers for life consumption

  ReadingContentProvider(this._authProvider);

  // Getters
  ReadingContentState get state => _state;
  ReadingContent? get content => _content;
  List<ReadingQuizQuestion> get quizQuestions => _quizQuestions;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get totalPages => _content?.totalPages ?? 0;
  bool get isQuizMode => _isQuizMode;
  bool get isLoadingQuiz => _isLoadingQuiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _quizQuestions.length;
  List<int?> get userAnswers => _userAnswers;
  int get score => _score;
  bool get showHint => _showHint;
  bool get hasAttemptedOnce => _hasAttemptedOnce;
  int get wrongAnswersCount => _wrongAnswersCount;

  bool get isLoading => _state == ReadingContentState.loading;
  bool get hasError => _state == ReadingContentState.error;
  bool get isLoaded => _state == ReadingContentState.loaded;
  bool get isLastPage => _currentPage == totalPages - 1;
  bool get isLastQuestion => _currentQuestionIndex == totalQuestions - 1;

  String get currentPageContent {
    if (_content == null || _currentPage >= _content!.content.length) {
      return '';
    }
    return _content!.content[_currentPage];
  }

  List<ReadingHighlightedWord> get currentPageHighlightedWords {
    if (_content == null) return [];
    return _content!.highlightedWords
        .where((word) => word.page == _currentPage + 1)
        .toList();
  }

  ReadingQuizQuestion? get currentQuestion {
    if (_quizQuestions.isEmpty || _currentQuestionIndex >= _quizQuestions.length) {
      return null;
    }
    return _quizQuestions[_currentQuestionIndex];
  }

  /// Fetch reading content for a chapter
  Future<void> fetchContent(String chapterId) async {
    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _state = ReadingContentState.error;
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    _state = ReadingContentState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${EnvironmentConfig.fullApiUrl}/reading/chapters/$chapterId/content'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
          'Origin': EnvironmentConfig.apiBaseUrl,
          'X-Requested-With': 'XMLHttpRequest',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final contentResponse = ReadingContentResponse.fromJson(jsonData);

        _content = contentResponse.data;
        _currentPage = 0;
        _isQuizMode = false;

        _state = ReadingContentState.loaded;
        _errorMessage = null;
      } else if (response.statusCode == 401) {
        _state = ReadingContentState.error;
        _errorMessage = 'Session expired. Please login again.';
      } else {
        _state = ReadingContentState.error;
        _errorMessage = 'Failed to load content: ${response.statusCode}';
      }
    } catch (e) {
      _state = ReadingContentState.error;
      _errorMessage = 'Network error: $e';
    }

    notifyListeners();
  }

  /// Fetch quiz questions for current content
  Future<void> fetchQuizQuestions() async {
    if (_content == null || !_authProvider.isAuthenticated || _authProvider.token == null) {
      _errorMessage = 'Content not loaded or user not authenticated';
      notifyListeners();
      return;
    }

    _isLoadingQuiz = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${EnvironmentConfig.fullApiUrl}/reading/chapters/${_content!.readingChapterId}/quiz'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
          'Origin': EnvironmentConfig.apiBaseUrl,
          'X-Requested-With': 'XMLHttpRequest',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final questionsResponse = ReadingQuizQuestionsResponse.fromJson(jsonData);

        _quizQuestions = questionsResponse.questions;
        _userAnswers = List.filled(_quizQuestions.length, null);
        _currentQuestionIndex = 0;
        _score = 0;
        _isQuizMode = true;

        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load quiz questions: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoadingQuiz = false;
      notifyListeners();
    }
  }

  /// Navigate to next page
  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  /// Navigate to previous page
  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  /// Go to specific page
  void goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < totalPages) {
      _currentPage = pageIndex;
      notifyListeners();
    }
  }

  /// Start quiz mode (called after reading all pages)
  Future<void> startQuiz() async {
    await fetchQuizQuestions();
    // Initialize question tracking
    _questionAnsweredCorrectly = List.filled(_quizQuestions.length, false);
    _showHint = false;
    _hasAttemptedOnce = false;
    _wrongAnswersCount = 0;
  }

  /// Check if answer is correct using the question's correctAnswer field
  bool checkAnswer(int answerIndex) {
    final question = currentQuestion;
    if (question == null) return false;
    return question.isCorrectAnswer(answerIndex);
  }

  /// New method: Handle answer submission with new flow
  /// Returns: 'correct', 'wrong_first_attempt', 'wrong_second_attempt'
  Future<String> submitAnswer(int answerIndex) async {
    _userAnswers[_currentQuestionIndex] = answerIndex;

    // Check if answer is correct
    final isCorrect = checkAnswer(answerIndex);

    if (isCorrect) {
      _questionAnsweredCorrectly[_currentQuestionIndex] = true;
      _showHint = false;
      _hasAttemptedOnce = false;
      notifyListeners();
      return 'correct';
    } else {
      if (!_hasAttemptedOnce) {
        // First wrong attempt - show hint
        _showHint = true;
        _hasAttemptedOnce = true;
        notifyListeners();
        return 'wrong_first_attempt';
      } else {
        // Second wrong attempt - lose life and move to next
        _wrongAnswersCount++;
        _questionAnsweredCorrectly[_currentQuestionIndex] = false;
        _showHint = false;
        _hasAttemptedOnce = false;
        notifyListeners();
        return 'wrong_second_attempt';
      }
    }
  }

  /// Move to next question (no previous button in new flow)
  void nextQuestion() {
    if (_currentQuestionIndex < totalQuestions - 1) {
      _currentQuestionIndex++;
      _showHint = false;
      _hasAttemptedOnce = false;
      notifyListeners();
    }
  }

  /// Get current question correctness
  bool isCurrentQuestionCorrect() {
    if (_currentQuestionIndex < _questionAnsweredCorrectly.length) {
      return _questionAnsweredCorrectly[_currentQuestionIndex];
    }
    return false;
  }

  /// Submit quiz and calculate score
  Future<Map<String, dynamic>> submitQuiz() async {
    if (_content == null) {
      return {
        'success': false,
        'error': 'No content loaded',
      };
    }

    // Calculate score
    int correctAnswers = 0;
    for (int i = 0; i < _quizQuestions.length; i++) {
      // Note: Backend doesn't send correctAnswer, so we need to submit answers
      // and backend will validate them
      if (_userAnswers[i] != null) {
        correctAnswers++; // Temporary - backend will validate
      }
    }

    // Submit answers to backend
    try {
      final response = await http.post(
        Uri.parse('${EnvironmentConfig.fullApiUrl}/reading/chapters/${_content!.readingChapterId}/quiz/submit'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
          'Origin': EnvironmentConfig.apiBaseUrl,
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'answers': _userAnswers,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        final data = result['data'];

        _score = data['score'] as int;
        final passed = data['passed'] as bool;

        return {
          'success': true,
          'score': _score,
          'passed': passed,
          'totalQuestions': totalQuestions,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to submit quiz: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Reset provider state
  void reset() {
    _state = ReadingContentState.initial;
    _content = null;
    _quizQuestions = [];
    _errorMessage = null;
    _currentPage = 0;
    _isQuizMode = false;
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _score = 0;
    _showHint = false;
    _hasAttemptedOnce = false;
    _questionAnsweredCorrectly = [];
    _wrongAnswersCount = 0;
    notifyListeners();
  }

  /// Reset only quiz state (for retrying)
  void resetQuiz() {
    _currentQuestionIndex = 0;
    _userAnswers = List.filled(_quizQuestions.length, null);
    _score = 0;
    _showHint = false;
    _hasAttemptedOnce = false;
    _questionAnsweredCorrectly = List.filled(_quizQuestions.length, false);
    _wrongAnswersCount = 0;
    notifyListeners();
  }
}
