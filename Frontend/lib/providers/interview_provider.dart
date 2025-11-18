import 'package:flutter/material.dart';
import 'progress_provider.dart';

class InterviewQuestion {
  final String question;
  final String category;
  final List<String> sampleAnswers;
  final int questionNumber;
  
  InterviewQuestion({
    required this.question,
    required this.category,
    required this.sampleAnswers,
    required this.questionNumber,
  });
}

class InterviewProvider with ChangeNotifier {
  final ProgressProvider? _progressProvider;
  final String _chapterId;
  
  final List<InterviewQuestion> _questions = [
    InterviewQuestion(
      question: 'Tell me about yourself.',
      category: 'Personal Introduction',
      sampleAnswers: [
        'I am a motivated person who enjoys learning new things.',
        'I have experience in various fields and I am eager to grow.',
      ],
      questionNumber: 1,
    ),
    InterviewQuestion(
      question: 'What are your strengths?',
      category: 'Personal Qualities',
      sampleAnswers: [
        'I am a good communicator and work well in teams.',
        'I am detail-oriented and always strive for excellence.',
      ],
      questionNumber: 2,
    ),
    InterviewQuestion(
      question: 'Where do you see yourself in 5 years?',
      category: 'Career Goals',
      sampleAnswers: [
        'I see myself in a leadership position, mentoring others.',
        'I want to be an expert in my field with expanded responsibilities.',
      ],
      questionNumber: 3,
    ),
    InterviewQuestion(
      question: 'Why should we hire you?',
      category: 'Value Proposition',
      sampleAnswers: [
        'I bring unique skills and a fresh perspective to your team.',
        'My experience and enthusiasm make me a perfect fit for this role.',
      ],
      questionNumber: 4,
    ),
    InterviewQuestion(
      question: 'Describe a challenging situation you faced and how you handled it.',
      category: 'Problem Solving',
      sampleAnswers: [
        'I once had to manage a difficult project with tight deadlines...',
        'When faced with a team conflict, I facilitated open communication...',
      ],
      questionNumber: 5,
    ),
  ];
  
  int _currentQuestionIndex = 0;
  String _currentAnswer = '';
  bool _isRecording = false;
  bool _isAnswerSubmitted = false;
  final List<String> _submittedAnswers = [];
  
  InterviewProvider({
    ProgressProvider? progressProvider,
    String chapterId = 'interview-chapter-1',
  }) : _progressProvider = progressProvider,
       _chapterId = chapterId;
  
  // Getters
  List<InterviewQuestion> get questions => _questions;
  InterviewQuestion get currentQuestion => _questions[_currentQuestionIndex];
  int get currentQuestionIndex => _currentQuestionIndex;
  String get currentAnswer => _currentAnswer;
  bool get isRecording => _isRecording;
  bool get isAnswerSubmitted => _isAnswerSubmitted;
  List<String> get submittedAnswers => _submittedAnswers;
  bool get isLastQuestion => _currentQuestionIndex >= _questions.length - 1;
  double get progress => _questions.isEmpty ? 0.0 : (_submittedAnswers.length) / _questions.length;
  bool get isInterviewComplete => _submittedAnswers.length >= _questions.length;
  
  // Actions
  void updateAnswer(String answer) {
    _currentAnswer = answer;
    notifyListeners();
  }
  
  void startRecording() {
    _isRecording = true;
    notifyListeners();
  }
  
  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }
  
  void submitAnswer() {
    if (_currentAnswer.trim().isNotEmpty && !_isAnswerSubmitted) {
      _isAnswerSubmitted = true;
      _submittedAnswers.add(_currentAnswer);
      
      // Auto-save progress when answering a question
      _progressProvider?.onInterviewAnswer(
        _chapterId,
        _currentQuestionIndex,
        _currentAnswer,
      );
      
      notifyListeners();
      
      // Check if interview is complete
      if (_submittedAnswers.length >= _questions.length) {
        final score = _calculateInterviewScore();
        _progressProvider?.onChapterCompleted(_chapterId, score);
      }
    }
  }
  
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _resetQuestionState();
      notifyListeners();
    }
  }
  
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      _resetQuestionState();
      notifyListeners();
    }
  }
  
  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      _resetQuestionState();
      notifyListeners();
    }
  }
  
  void _resetQuestionState() {
    _currentAnswer = '';
    _isRecording = false;
    _isAnswerSubmitted = _currentQuestionIndex < _submittedAnswers.length;
    
    // Load previously submitted answer if exists
    if (_isAnswerSubmitted && _currentQuestionIndex < _submittedAnswers.length) {
      _currentAnswer = _submittedAnswers[_currentQuestionIndex];
    }
  }
  
  void resetInterview() {
    _currentQuestionIndex = 0;
    _submittedAnswers.clear();
    _resetQuestionState();
    notifyListeners();
  }
  
  // Calculate interview score based on answers length and completeness
  double _calculateInterviewScore() {
    if (_submittedAnswers.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    
    for (String answer in _submittedAnswers) {
      double answerScore = 0.0;
      
      // Score based on answer length (minimum effort)
      if (answer.trim().length > 10) answerScore += 30;
      if (answer.trim().length > 50) answerScore += 30;
      if (answer.trim().length > 100) answerScore += 20;
      
      // Score based on completeness (has multiple sentences)
      if (answer.split('.').length > 1) answerScore += 20;
      
      totalScore += answerScore;
    }
    
    return (totalScore / _submittedAnswers.length).clamp(0.0, 100.0);
  }
  
  // Get completion percentage
  double get completionPercentage => progress * 100;
  
  // Get interview statistics
  Map<String, dynamic> get interviewStats => {
    'totalQuestions': _questions.length,
    'questionsAnswered': _submittedAnswers.length,
    'currentQuestion': _currentQuestionIndex + 1,
    'isComplete': isInterviewComplete,
    'score': isInterviewComplete ? _calculateInterviewScore() : 0.0,
    'progress': completionPercentage,
  };
  
  // Get sample answer for current question
  String get randomSampleAnswer {
    if (currentQuestion.sampleAnswers.isNotEmpty) {
      final index = DateTime.now().millisecond % currentQuestion.sampleAnswers.length;
      return currentQuestion.sampleAnswers[index];
    }
    return '';
  }
  
  // Check if current question has been answered
  bool get currentQuestionAnswered => _currentQuestionIndex < _submittedAnswers.length;
}