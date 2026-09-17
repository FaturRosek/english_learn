import { Controller, Post, Get, Patch, Body, Param, UseGuards, Request, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsOptional, IsBoolean, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { VocabularyService } from './vocabulary.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { VocabularyStatus } from './entities/vocabulary.entity.js';

class AddWordDto {
  @ApiProperty()
  @IsString()
  word: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  source?: string;
}

class MarkReviewedDto {
  @ApiProperty()
  @IsBoolean()
  mastered: boolean;
}

@ApiTags('Vocabulary')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('vocabulary')
export class VocabularyController {
  constructor(private readonly vocabularyService: VocabularyService) {}

  @Post('add')
  @ApiOperation({ summary: 'Add a word to vocabulary list' })
  addWord(
    @Request() req: { user: { id: string } },
    @Body() dto: AddWordDto,
  ) {
    return this.vocabularyService.addWord(req.user.id, dto.word, dto.source);
  }

  @Get()
  @ApiOperation({ summary: 'Get user vocabulary list' })
  getVocabulary(
    @Request() req: { user: { id: string } },
    @Query('status') status?: VocabularyStatus,
  ) {
    return this.vocabularyService.getUserVocabulary(req.user.id, status);
  }

  @Get('review')
  @ApiOperation({ summary: 'Get words to review' })
  getWordsToReview(@Request() req: { user: { id: string } }) {
    return this.vocabularyService.getWordsToReview(req.user.id);
  }

  @Patch(':id/review')
  @ApiOperation({ summary: 'Mark word as reviewed' })
  markReviewed(
    @Param('id') id: string,
    @Request() req: { user: { id: string } },
    @Body() dto: MarkReviewedDto,
  ) {
    return this.vocabularyService.markReviewed(id, req.user.id, dto.mastered);
  }

  @Patch(':id/mastered')
  @Post(':id/mastered')
  @ApiOperation({ summary: 'Mark word as mastered' })
  markMastered(
    @Param('id') id: string,
    @Request() req: { user: { id: string } },
  ) {
    return this.vocabularyService.markReviewed(id, req.user.id, true);
  }
}
