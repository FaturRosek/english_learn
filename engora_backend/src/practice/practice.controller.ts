import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiBody,
} from '@nestjs/swagger';
import { IsString, IsEnum, IsOptional, IsNumber, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PracticeService } from './practice.service.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { PracticeType } from './entities/practice-session.entity.js';
import { AIMessage } from '../ai/ai.service.js';

class StartSessionDto {
  @ApiProperty({ enum: PracticeType })
  @IsEnum(PracticeType)
  type: PracticeType;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  topic?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  situation?: string;
}

class SendMessageDto {
  @ApiProperty()
  @IsString()
  message: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  audioUrl?: string;
}

class EndSessionDto {
  @ApiProperty()
  @IsNumber()
  durationMinutes: number;
}

class AiTutorChatDto {
  @ApiProperty()
  @IsArray()
  messages: AIMessage[];
}

@ApiTags('Practice')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('practice')
export class PracticeController {
  constructor(private readonly practiceService: PracticeService) {}

  @Post('sessions/start')
  @ApiOperation({ summary: 'Start a new practice session' })
  startSession(
    @Request() req: { user: { id: string } },
    @Body() dto: StartSessionDto,
  ) {
    return this.practiceService.startSession(
      req.user.id,
      dto.type,
      dto.topic,
      dto.situation,
    );
  }

  @Post('sessions/:id/message')
  @ApiOperation({ summary: 'Send message in a practice session' })
  sendMessage(
    @Param('id') id: string,
    @Request() req: { user: { id: string } },
    @Body() dto: SendMessageDto,
  ) {
    return this.practiceService.sendMessage(id, req.user.id, dto.message, dto.audioUrl);
  }

  @Post('sessions/:id/end')
  @ApiOperation({ summary: 'End session and get AI feedback' })
  endSession(
    @Param('id') id: string,
    @Request() req: { user: { id: string } },
    @Body() dto: EndSessionDto,
  ) {
    return this.practiceService.endSession(id, req.user.id, dto.durationMinutes);
  }

  @Get('sessions/:id')
  @ApiOperation({ summary: 'Get session details' })
  getSession(
    @Param('id') id: string,
    @Request() req: { user: { id: string } },
  ) {
    return this.practiceService.getSession(id, req.user.id);
  }

  @Get('sessions')
  @ApiOperation({ summary: 'Get user practice history' })
  getSessions(@Request() req: { user: { id: string } }) {
    return this.practiceService.getUserSessions(req.user.id);
  }

  @Post('ai-tutor')
  @ApiOperation({ summary: 'Chat with AI Tutor' })
  aiTutorChat(
    @Request() req: { user: { id: string } },
    @Body() dto: AiTutorChatDto,
  ) {
    return this.practiceService.aiTutorChat(req.user.id, dto.messages).then(
      (response) => ({ response }),
    );
  }
}
