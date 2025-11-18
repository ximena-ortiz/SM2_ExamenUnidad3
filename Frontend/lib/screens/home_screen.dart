import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lives_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_icons.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_banner.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'quiz_screen.dart';
import 'chapter_episodes_screen.dart';
import 'chapter_results_screen.dart';
import 'favorites_screen.dart';
import 'vocabulary_chapters_screen.dart';
import 'reading_screen.dart';
import 'reading_chapters_screen.dart';
import 'interview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  
  final List<int> _navigableIndices = [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Fetch lives status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final livesProvider = Provider.of<LivesProvider>(context, listen: false);
        livesProvider.fetchLivesStatus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animationController.forward().then((_) {
      _animationController.reset();
    });
  }

  void _navigateToIndex(int index) {
    if (_navigableIndices.contains(index)) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 100) {
            _swipeToNext();
          }
          else if (details.velocity.pixelsPerSecond.dx < -100) {
            _swipeToPrevious();
          }
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: _navigableIndices.length,
          itemBuilder: (context, index) {
            return _getCurrentScreenByIndex(_navigableIndices[index]);
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          } else {
            _navigateToIndex(index);
          }
        },
      ),
    );
  }

  void _swipeToNext() {
    final currentIndexInNavigable = _navigableIndices.indexOf(_currentIndex);
    final nextIndex = (currentIndexInNavigable + 1) % _navigableIndices.length;
    _navigateToIndex(_navigableIndices[nextIndex]);
  }

  void _swipeToPrevious() {
    final currentIndexInNavigable = _navigableIndices.indexOf(_currentIndex);
    final previousIndex = (currentIndexInNavigable - 1 + _navigableIndices.length) % _navigableIndices.length;
    _navigateToIndex(_navigableIndices[previousIndex]);
  }

  Widget _getCurrentScreenByIndex(int index) {
    switch (index) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const VocabularyChaptersScreen();
      case 2:
        return const ReadingChaptersScreen();
      case 3:
        return const QuizScreen();
      default:
        return _buildHomeContent();
    }
  }



  Widget _buildHomeContent() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Theme.of(context).colorScheme.primary,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: Theme.of(context).brightness,
        ),
      ),
      body: Column(
        children: [
          // Header - AppBanner
          Consumer2<AuthProvider, LivesProvider>(
            builder: (context, authProvider, livesProvider, child) {
              return AppBanner(
                title: '${AppLocalizations.of(context)!.hi}, ${authProvider.user?.name ?? AppLocalizations.of(context)!.user}',
                subtitle: AppLocalizations.of(context)!.welcomeBack,
                livesText: AppLocalizations.of(context)!.livesRemaining(livesProvider.currentLives),
              );
            },
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.yourLearningPath,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cards
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Vocabulary Card
                          CustomCard(
                            title: AppLocalizations.of(context)!.chapterProgress,
                            subtitle: AppLocalizations.of(context)!.continueText,
                            description: AppLocalizations.of(context)!.vocabulary,
                            icon: CustomIcons.vocabularyIcon(),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ChapterEpisodesScreen(
                                  chapterTitle: "English Basics",
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Reading Card
                          CustomCard(
                            title: AppLocalizations.of(context)!.software,
                            subtitle: AppLocalizations.of(context)!.continueText,
                            description: AppLocalizations.of(context)!.reading,
                            icon: CustomIcons.readingIcon(),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ReadingChaptersScreen(),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Interview Card
                          CustomCard(
                            title: AppLocalizations.of(context)!.databases,
                            subtitle: AppLocalizations.of(context)!.continueText,
                            description: AppLocalizations.of(context)!.interview,
                            icon: CustomIcons.interviewIcon(),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const InterviewScreen(),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Chapter Results Card
                          CustomCard(
                            title: AppLocalizations.of(context)!.chapterResults,
                            subtitle: AppLocalizations.of(context)!.progress,
                            description: AppLocalizations.of(context)!.evaluationDetails,
                            icon: Icon(
                              Icons.analytics,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ChapterResultsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


}