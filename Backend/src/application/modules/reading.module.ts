import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

// Entities
import { ReadingChapter } from '../../domain/entities/reading-chapter.entity';
import { ReadingContent } from '../../domain/entities/reading-content.entity';
import { QuizQuestion } from '../../domain/entities/quiz-question.entity';
import { UserProgress } from '../../domain/entities/user-progress.entity';
import { DailyLives } from '../../domain/entities/daily-lives.entity';

// Repositories
import { ReadingChapterRepository } from '../../infrastructure/repositories/reading-chapter.repository';
import { ReadingContentRepository } from '../../infrastructure/repositories/reading-content.repository';
import { QuizQuestionRepository } from '../../infrastructure/repositories/quiz-question.repository';
import { DailyLivesRepository } from '../../infrastructure/repositories/daily-lives.repository';

// Use Cases
import { GetReadingChaptersStatusUseCase } from '../use-cases/reading/get-reading-chapters-status.use-case';
import { GetReadingContentUseCase } from '../use-cases/reading/get-reading-content.use-case';
import { GetQuizQuestionsUseCase } from '../use-cases/reading/get-quiz-questions.use-case';
import { SubmitQuizAnswerUseCase } from '../use-cases/reading/submit-quiz-answer.use-case';
import { CompleteReadingChapterUseCase } from '../use-cases/reading/complete-reading-chapter.use-case';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ReadingChapter,
      ReadingContent,
      QuizQuestion,
      UserProgress,
      DailyLives,
    ]),
  ],
  providers: [
    // Repositories
    ReadingChapterRepository,
    ReadingContentRepository,
    QuizQuestionRepository,
    DailyLivesRepository,
    // Use Cases
    GetReadingChaptersStatusUseCase,
    GetReadingContentUseCase,
    GetQuizQuestionsUseCase,
    SubmitQuizAnswerUseCase,
    CompleteReadingChapterUseCase,
  ],
  exports: [
    ReadingChapterRepository,
    ReadingContentRepository,
    QuizQuestionRepository,
    GetReadingChaptersStatusUseCase,
    GetReadingContentUseCase,
    GetQuizQuestionsUseCase,
    SubmitQuizAnswerUseCase,
    CompleteReadingChapterUseCase,
  ],
})
export class ReadingModule {}
