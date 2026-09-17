import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { IsObject, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { ListeningService } from './listening.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';

class SubmitAnswersDto {
  @ApiProperty({ description: 'Map of questionId to selected answer' })
  @IsObject()
  answers: Record<string, string>;
}

@ApiTags('Listening')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('listening')
export class ListeningController {
  constructor(private readonly listeningService: ListeningService) {}

  @Get('exercises')
  @ApiOperation({ summary: 'Get listening exercises (optionally filtered by level)' })
  @ApiQuery({ name: 'level', required: false, enum: ['all', 'A1', 'A2', 'B1', 'B2', 'C1'] })
  getExercises(@Query('level') level?: string) {
    return this.listeningService.getExercises(level);
  }

  @Post('exercises/:id/submit')
  @ApiOperation({ summary: 'Submit answers for a listening exercise' })
  submitAnswers(
    @Param('id') id: string,
    @Body() dto: SubmitAnswersDto,
    @Request() req: { user: { sub: string } },
  ) {
    return this.listeningService.submitAnswers(req.user.sub, id, dto.answers);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get listening practice history' })
  getHistory(@Request() req: { user: { sub: string } }) {
    return this.listeningService.getHistory(req.user.sub);
  }
}
