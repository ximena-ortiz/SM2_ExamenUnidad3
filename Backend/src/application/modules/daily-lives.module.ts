import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DailyLives } from '../../domain/entities/daily-lives.entity';
import { DailyLivesRepository } from '../../infrastructure/repositories/daily-lives.repository';
import { ConsumeLifeUseCase } from '../use-cases/daily-lives/consume-life.use-case';
import { GetLivesStatusUseCase } from '../use-cases/daily-lives/get-lives-status.use-case';

@Module({
  imports: [TypeOrmModule.forFeature([DailyLives])],
  providers: [
    {
      provide: 'IDailyLivesRepository',
      useClass: DailyLivesRepository,
    },
    ConsumeLifeUseCase,
    GetLivesStatusUseCase,
  ],
  exports: ['IDailyLivesRepository', ConsumeLifeUseCase, GetLivesStatusUseCase],
})
export class DailyLivesModule {}
