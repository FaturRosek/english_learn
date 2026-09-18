import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PracticeSession } from './entities/practice-session.entity.js';
import { PracticeService } from './practice.service.js';
import { PracticeController } from './practice.controller.js';
import { AiModule } from '../ai/ai.module.js';
import { LearningProfileModule } from '../learning-profile/learning-profile.module.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([PracticeSession]),
    AiModule,
    LearningProfileModule,
  ],
  providers: [PracticeService],
  controllers: [PracticeController],
  exports: [PracticeService],
})
export class PracticeModule {}
