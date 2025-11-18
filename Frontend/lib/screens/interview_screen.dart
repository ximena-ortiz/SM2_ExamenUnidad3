import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import '../providers/progress_provider.dart';
import '../l10n/app_localizations.dart';

class InterviewScreen extends StatelessWidget {
  final String chapterId;
  
  const InterviewScreen({super.key, this.chapterId = 'interview-chapter-1'});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InterviewProvider(
        progressProvider: Provider.of<ProgressProvider>(context, listen: false),
        chapterId: chapterId,
      ),
      child: const _InterviewScreenContent(),
    );
  }
}

class _InterviewScreenContent extends StatefulWidget {
  const _InterviewScreenContent();

  @override
  State<_InterviewScreenContent> createState() => _InterviewScreenContentState();
}

class _InterviewScreenContentState extends State<_InterviewScreenContent> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.interview),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Consumer<InterviewProvider>(
            builder: (context, interviewProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${interviewProvider.completionPercentage.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<InterviewProvider>(
        builder: (context, interviewProvider, child) {
          // Update text controller when question changes
          if (_answerController.text != interviewProvider.currentAnswer) {
            _answerController.text = interviewProvider.currentAnswer;
            _answerController.selection = TextSelection.fromPosition(
              TextPosition(offset: _answerController.text.length),
            );
          }

          return Column(
            children: [
              // Progress Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Question ${interviewProvider.currentQuestionIndex + 1} of ${interviewProvider.questions.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      interviewProvider.currentQuestion.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: interviewProvider.progress,
                      backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Question Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Card
                      Card(
                        elevation: 4,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.quiz,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Interview Question',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                interviewProvider.currentQuestion.question,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Answer Input
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: interviewProvider.isRecording
                                        ? Colors.red
                                        : Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Answer',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (interviewProvider.currentQuestionAnswered)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _answerController,
                                maxLines: 6,
                                enabled: !interviewProvider.isAnswerSubmitted,
                                decoration: InputDecoration(
                                  hintText: 'Type your answer here... (minimum 10 characters)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: interviewProvider.isAnswerSubmitted
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Theme.of(context).colorScheme.surface,
                                ),
                                onChanged: (value) {
                                  interviewProvider.updateAnswer(value);
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Recording Controls & Submit
                              Row(
                                children: [
                                  if (!interviewProvider.isAnswerSubmitted) ...[
                                    IconButton.filled(
                                      onPressed: interviewProvider.isRecording
                                          ? interviewProvider.stopRecording
                                          : interviewProvider.startRecording,
                                      icon: Icon(
                                        interviewProvider.isRecording ? Icons.stop : Icons.mic,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: interviewProvider.isRecording
                                            ? Colors.red
                                            : Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: interviewProvider.currentAnswer.trim().length >= 10
                                            ? interviewProvider.submitAnswer
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                        child: Text('Submit Answer'),
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check, color: Colors.green),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Answer Submitted',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sample Answer (Hint)
                      if (!interviewProvider.isAnswerSubmitted) ...[
                        ExpansionTile(
                          title: Text(
                            'Need inspiration? View sample answer',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          leading: Icon(
                            Icons.lightbulb_outline,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  interviewProvider.randomSampleAnswer,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Interview Complete Message
                      if (interviewProvider.isInterviewComplete) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.celebration,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Interview Complete! 🎉',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Great job completing all ${interviewProvider.questions.length} questions!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Navigation Controls
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: interviewProvider.currentQuestionIndex > 0
                          ? interviewProvider.previousQuestion
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                    
                    Text(
                      '${interviewProvider.submittedAnswers.length}/${interviewProvider.questions.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    ElevatedButton.icon(
                      onPressed: !interviewProvider.isLastQuestion
                          ? interviewProvider.nextQuestion
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}