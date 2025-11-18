import { DataSource } from 'typeorm';
import { Person } from './src/domain/entities/person.entity';
import { User } from './src/domain/entities/user.entity';
import { RefreshToken } from './src/domain/entities/refresh-token.entity';
import { UserProgress } from './src/domain/entities/user-progress.entity';
import { DailyLives } from './src/domain/entities/daily-lives.entity';
import { Chapter } from './src/domain/entities/chapter.entity';
import { VocabularyItem } from './src/domain/entities/vocabulary-item.entity';
import { ReadingChapter } from './src/domain/entities/reading-chapter.entity';
import { ReadingContent } from './src/domain/entities/reading-content.entity';
import { QuizQuestion } from './src/domain/entities/quiz-question.entity';
import { ApprovalRule } from './src/domain/entities/approval-rule.entity';
import { ApprovalEvaluation } from './src/domain/entities/approval-evaluation.entity';
import { ApprovalMetrics } from './src/domain/entities/approval-metrics.entity';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  username: process.env.DATABASE_USERNAME || 'postgres',
  password: process.env.DATABASE_PASSWORD || 'password',
  database: process.env.DATABASE_NAME || 'english_learn_db',
  ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false,
  synchronize: false,
  logging: process.env.NODE_ENV === 'development',
  entities: [
    Person,
    User,
    RefreshToken,
    UserProgress,
    DailyLives,
    Chapter,
    VocabularyItem,
    ReadingChapter,
    ReadingContent,
    QuizQuestion,
    ApprovalRule,
    ApprovalEvaluation,
    ApprovalMetrics,
  ],
  migrations: ['src/infrastructure/database/migrations/*.ts'],
  subscribers: ['src/infrastructure/database/subscribers/*.ts'],
  migrationsTableName: 'migrations',
  migrationsRun: false,
});

export default AppDataSource;
