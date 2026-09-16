import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LearningProfile } from './entities/learning-profile.entity.js';
import { LearningProfileService } from './learning-profile.service.js';
import { LearningProfileController } from './learning-profile.controller.js';
import { AiModule } from '../ai/ai.module.js';

@Module({
  imports: [TypeOrmModule.forFeature([LearningProfile]), AiModule],
  providers: [LearningProfileService],
  controllers: [LearningProfileController],
  exports: [LearningProfileService],
})
export class LearningProfileModule {}
