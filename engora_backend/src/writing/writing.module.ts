import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WritingSubmission } from './entities/writing-submission.entity.js';
import { WritingService } from './writing.service.js';
import { WritingController } from './writing.controller.js';
import { AiModule } from '../ai/ai.module.js';
import { LearningProfileModule } from '../learning-profile/learning-profile.module.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([WritingSubmission]),
    AiModule,
    LearningProfileModule,
  ],
  providers: [WritingService],
  controllers: [WritingController],
})
export class WritingModule {}
