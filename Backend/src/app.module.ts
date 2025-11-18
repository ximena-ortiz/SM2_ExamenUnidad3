import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { appConfig } from './infrastructure/config/app.config';
import { databaseConfig } from './infrastructure/config/database.config';
import { jwtConfig } from './infrastructure/config/jwt.config';
import { securityConfig } from './infrastructure/config/security/security.config';
import { Person } from './domain/entities/person.entity';
import { User } from './domain/entities/user.entity';
import { RefreshToken } from './domain/entities/refresh-token.entity';
import { UserProgress } from './domain/entities/user-progress.entity';
import { DailyLives } from './domain/entities/daily-lives.entity';
import { Chapter } from './domain/entities/chapter.entity';
import { VocabularyItem } from './domain/entities/vocabulary-item.entity';
import { ApprovalRule } from './domain/entities/approval-rule.entity';
import { ApprovalEvaluation } from './domain/entities/approval-evaluation.entity';
import { ApprovalMetrics } from './domain/entities/approval-metrics.entity';
import { Translation } from './domain/entities/translation.entity';
import { ReadingChapter } from './domain/entities/reading-chapter.entity';
import { ReadingContent } from './domain/entities/reading-content.entity';
import { QuizQuestion } from './domain/entities/quiz-question.entity';
import { AuthModule } from './presentation/modules/auth.module';
import { ApprovalModule } from './presentation/modules/approval.module';
import { ProgressModule } from './presentation/modules/progress.module';
import { LivesModule } from './presentation/modules/lives.module';
import { ChaptersModule } from './presentation/modules/chapters.module';
import { ReadingModule } from './presentation/modules/reading.module';
import { AdminModule } from './presentation/modules/admin.module';
import { TranslationModule } from './application/modules/translation.module';
import { CronModule } from './application/modules/cron.module';
import { SecurityModule } from './shared/security.module';
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig, jwtConfig, securityConfig],
      envFilePath: ['.env.local', '.env'],
    }),

    // Rate Limiting
    ThrottlerModule.forRoot([
      // Global rate limiting
      {
        ttl: 60, // Time window in seconds
        limit: 100, // maximum number of requests within the time window
      },
    ]),

    // Database
    TypeOrmModule.forRootAsync({
      useFactory: () => ({
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
          Translation,
        ],
        migrations: ['dist/infrastructure/database/migrations/*{.ts,.js}'],
        migrationsTableName: 'migrations',
        migrationsRun: false,
      }),
    }),

    // Security
    SecurityModule,

    // Feature modules
    AuthModule,
    ProgressModule,
    LivesModule,
    ChaptersModule,
    ReadingModule,
    AdminModule,
    ApprovalModule,
    TranslationModule,
    CronModule,
  ],
})
export class AppModule {}
