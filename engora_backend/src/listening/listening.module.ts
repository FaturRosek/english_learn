import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ListeningExercise, ListeningResult } from './entities/listening-exercise.entity.js';
import { ListeningService } from './listening.service.js';
import { ListeningController } from './listening.controller.js';

@Module({
  imports: [TypeOrmModule.forFeature([ListeningExercise, ListeningResult])],
  providers: [ListeningService],
  controllers: [ListeningController],
  exports: [ListeningService],
})
export class ListeningModule {}
