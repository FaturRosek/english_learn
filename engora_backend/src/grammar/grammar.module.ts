import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GrammarLesson } from './entities/grammar-lesson.entity.js';
import { GrammarService } from './grammar.service.js';
import { GrammarController } from './grammar.controller.js';
import { AiModule } from '../ai/ai.module.js';
import { LearningProfileModule } from '../learning-profile/learning-profile.module.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([GrammarLesson]),
    AiModule,
    LearningProfileModule,
  ],
  providers: [GrammarService],
  controllers: [GrammarController],
  exports: [GrammarService],
})
export class GrammarModule {}
