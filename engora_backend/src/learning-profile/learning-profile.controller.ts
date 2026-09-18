import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { LearningProfileService } from './learning-profile.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { EnglishLevel, LearningGoal } from './entities/learning-profile.entity.js';

class CompleteOnboardingDto {
  @ApiProperty({ enum: EnglishLevel })
  @IsEnum(EnglishLevel)
  level: EnglishLevel;

  @ApiProperty({ enum: LearningGoal })
  @IsEnum(LearningGoal)
  goal: LearningGoal;
}

@ApiTags('Learning Profile')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('profile')
export class LearningProfileController {
  constructor(private readonly service: LearningProfileService) {}

  @Post('onboarding')
  @ApiOperation({ summary: 'Complete onboarding - set level and goal' })
  completeOnboarding(
    @Request() req: { user: { id: string } },
    @Body() dto: CompleteOnboardingDto,
  ) {
    return this.service.completeOnboarding(req.user.id, dto.level, dto.goal);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get user progress stats' })
  getStats(@Request() req: { user: { id: string } }) {
    return this.service.getStats(req.user.id);
  }

  @Get('todays-practice')
  @ApiOperation({ summary: 'Get AI-generated today practice plan' })
  getTodaysPractice(@Request() req: { user: { id: string } }) {
    return this.service.getTodaysPractice(req.user.id);
  }

  @Get('learning-path')
  @ApiOperation({ summary: 'Get personalized learning path based on level and goal' })
  getLearningPath(@Request() req: { user: { id: string } }) {
    return this.service.getLearningPath(req.user.id);
  }
}
