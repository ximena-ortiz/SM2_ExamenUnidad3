import { DataSource } from 'typeorm';
import { Person } from '../../domain/entities/person.entity';
import { User } from '../../domain/entities/user.entity';
import { RefreshToken } from '../../domain/entities/refresh-token.entity';
import { UserProgress } from '../../domain/entities/user-progress.entity';
import { DailyLives } from '../../domain/entities/daily-lives.entity';
import { Chapter } from '../../domain/entities/chapter.entity';
import { VocabularyItem } from '../../domain/entities/vocabulary-item.entity';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  username: process.env.DATABASE_USERNAME || 'postgres',
  password: process.env.DATABASE_PASSWORD || 'password',
  database: process.env.DATABASE_NAME || 'english_learn_db',
  ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false,
  synchronize: false, // ALWAYS false in production
  logging: process.env.NODE_ENV === 'development',
  entities: [Person, User, RefreshToken, UserProgress, DailyLives, Chapter, VocabularyItem],
  migrations: ['src/infrastructure/database/migrations/*{.ts,.js}'],
  subscribers: ['src/infrastructure/database/subscribers/*{.ts,.js}'],
  migrationsTableName: 'migrations',
  migrationsRun: false,
});
