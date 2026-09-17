import { Controller, Post, Get, Body, UseGuards, Request, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { WritingService } from './writing.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { WritingType } from './entities/writing-submission.entity.js';

class SubmitWritingDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  text?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiProperty({ enum: WritingType, default: WritingType.FREE, required: false })
  @IsOptional()
  @IsEnum(WritingType)
  type?: WritingType;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  prompt?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  promptId?: string;
}

@ApiTags('Writing')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('writing')
export class WritingController {
  constructor(private readonly writingService: WritingService) {}

  @Post('submit')
  @ApiOperation({ summary: 'Submit writing for AI correction' })
  submit(
    @Request() req: { user: { id: string } },
    @Body() dto: SubmitWritingDto,
  ) {
    const text = dto.text ?? dto.content ?? '';
    const type = dto.type ?? (dto.prompt || dto.promptId ? WritingType.GUIDED : WritingType.FREE);
    return this.writingService.submitWriting(
      req.user.id,
      text,
      type,
      dto.prompt,
    );
  }

  @Get('history')
  @ApiOperation({ summary: 'Get writing history' })
  getHistory(@Request() req: { user: { id: string } }) {
    return this.writingService.getHistory(req.user.id);
  }

  @Get('prompts')
  @ApiOperation({ summary: 'Get guided writing prompts' })
  getPrompts(@Query('goal') goal: string) {
    return this.writingService.getGuidedPrompts(goal);
  }
}
