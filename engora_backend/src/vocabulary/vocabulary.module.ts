import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VocabularyItem } from './entities/vocabulary.entity.js';
import { VocabularyService } from './vocabulary.service.js';
import { VocabularyController } from './vocabulary.controller.js';
import { AiModule } from '../ai/ai.module.js';
import { LearningProfileModule } from '../learning-profile/learning-profile.module.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([VocabularyItem]),
    AiModule,
    LearningProfileModule,
  ],
  providers: [VocabularyService],
  controllers: [VocabularyController],
  exports: [VocabularyService],
})
export class VocabularyModule {}
