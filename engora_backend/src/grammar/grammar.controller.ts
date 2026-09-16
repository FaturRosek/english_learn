import { Controller, Get, Post, Body, Param, UseGuards, Request, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { GrammarService } from './grammar.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { EnglishLevel } from '../learning-profile/entities/learning-profile.entity.js';

class ExplainTopicDto {
  @ApiProperty()
  @IsString()
  topic: string;
}

@ApiTags('Grammar')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('grammar')
export class GrammarController {
  constructor(private readonly grammarService: GrammarService) {}

  @Get('lessons')
  @ApiOperation({ summary: 'Get grammar lessons for a level' })
  getLessons(@Query('level') level: EnglishLevel) {
    return this.grammarService.getLessonsForLevel(level);
  }

  @Get('weaknesses')
  @ApiOperation({ summary: 'Get grammar lessons based on user weaknesses' })
  getWeaknessLessons(@Request() req: { user: { id: string } }) {
    return this.grammarService.getWeaknessLessons(req.user.id);
  }

  @Get('recommended')
  @ApiOperation({ summary: 'Get recommended grammar topics' })
  getRecommended(@Request() req: { user: { id: string } }) {
    return this.grammarService.getRecommendedTopics(req.user.id);
  }

  @Post('explain')
  @ApiOperation({ summary: 'AI explains a grammar topic' })
  explain(
    @Request() req: { user: { id: string } },
    @Body() dto: ExplainTopicDto,
  ) {
    return this.grammarService.explainTopic(req.user.id, dto.topic).then(
      (explanation) => ({ explanation }),
    );
  }
}
