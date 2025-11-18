import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/providers/episode_provider.dart';
import 'package:english_app/widgets/repeat_chapter_dialog.dart';
import 'package:english_app/models/episode.dart';
import 'package:english_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('Repeat Chapter Tests', () {
    late EpisodeProvider episodeProvider;

    setUp(() {
      episodeProvider = EpisodeProvider();
    });

    testWidgets('RepeatChapterDialog displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('es')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  context.showRepeatChapterDialog(
                    chapterTitle: 'Test Chapter',
                    currentScore: 85,
                    onConfirm: () {},
                    onCancel: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog elements are present
      expect(find.text('Repeat Chapter'), findsWidgets);
      expect(find.text('Test Chapter'), findsOneWidget);
      expect(find.text('Current Score: 85 points'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('RepeatChapterDialog cancel button works', (
      WidgetTester tester,
    ) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('es')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  context.showRepeatChapterDialog(
                    chapterTitle: 'Test Chapter',
                    currentScore: 85,
                    onConfirm: () {},
                    onCancel: () {
                      cancelCalled = true;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog and tap cancel
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify cancel callback was called
      expect(cancelCalled, isTrue);
    });

    testWidgets('RepeatChapterDialog confirm button works', (
      WidgetTester tester,
    ) async {
      bool confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('es')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  context.showRepeatChapterDialog(
                    chapterTitle: 'Test Chapter',
                    currentScore: 85,
                    onConfirm: () {
                      confirmCalled = true;
                    },
                    onCancel: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog and tap confirm
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the confirm button (there might be multiple "Repeat Chapter" texts)
      final confirmButtons = find.text('Repeat Chapter');
      await tester.tap(confirmButtons.last);
      await tester.pumpAndSettle();

      // Verify confirm callback was called
      expect(confirmCalled, isTrue);
    });

    test('EpisodeProvider resetChapterForRepetition works correctly', () {
      // Get initial state
      final initialChapter = episodeProvider.currentChapter;
      final initialEpisodes = List.from(initialChapter.episodes);

      // Simulate completed chapter by setting all episodes as completed
      for (int i = 0; i < initialEpisodes.length; i++) {
        initialEpisodes[i] = Episode(
          id: initialEpisodes[i].id,
          title: initialEpisodes[i].title,
          difficulty: initialEpisodes[i].difficulty,
          status: EpisodeStatus.completed,
          description: initialEpisodes[i].description,
          progress: 1.0,
        );
      }

      // Reset chapter for repetition
      episodeProvider.resetChapterForRepetition(initialChapter.id);

      // Verify reset behavior
      final resetChapter = episodeProvider.currentChapter;

      // First episode should be current
      expect(resetChapter.episodes[0].status, EpisodeStatus.current);
      expect(resetChapter.episodes[0].progress, 0.0);

      // Other episodes should be locked
      for (int i = 1; i < resetChapter.episodes.length; i++) {
        expect(resetChapter.episodes[i].status, EpisodeStatus.locked);
        expect(resetChapter.episodes[i].progress, 0.0);
      }

      // Selected episode should be reset
      expect(episodeProvider.selectedEpisodeId, isNull);
    });

    test('EpisodeProvider maintains episode data integrity after reset', () {
      final initialChapter = episodeProvider.currentChapter;
      final initialEpisodeCount = initialChapter.episodes.length;
      final firstEpisodeTitle = initialChapter.episodes[0].title;
      final lastEpisodeTitle = initialChapter.episodes.last.title;

      // Reset chapter
      episodeProvider.resetChapterForRepetition(initialChapter.id);

      final resetChapter = episodeProvider.currentChapter;

      // Verify episode count remains the same
      expect(resetChapter.episodes.length, initialEpisodeCount);

      // Verify episode titles are preserved
      expect(resetChapter.episodes[0].title, firstEpisodeTitle);
      expect(resetChapter.episodes.last.title, lastEpisodeTitle);

      // Verify all episodes have their IDs preserved
      for (int i = 0; i < resetChapter.episodes.length; i++) {
        expect(resetChapter.episodes[i].id, initialChapter.episodes[i].id);
      }
    });
  });
}
