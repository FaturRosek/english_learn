import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PracticeSession,
  PracticeType,
  PracticeStatus,
} from './entities/practice-session.entity.js';
import { AiService, AIMessage } from '../ai/ai.service.js';
import { LearningProfileService } from '../learning-profile/learning-profile.service.js';

@Injectable()
export class PracticeService {
  constructor(
    @InjectRepository(PracticeSession)
    private sessionRepo: Repository<PracticeSession>,
    private aiService: AiService,
    private profileService: LearningProfileService,
  ) {}

  async startSession(
    userId: string,
    type: PracticeType,
    topic?: string,
    situation?: string,
  ): Promise<PracticeSession> {
    const session = this.sessionRepo.create({
      user: { id: userId },
      type,
      topic,
      situation,
      messages: [],
    });
    return this.sessionRepo.save(session);
  }

  async sendMessage(
    sessionId: string,
    userId: string,
    userMessage: string,
    audioUrl?: string,
  ): Promise<{ message: string; sessionId: string }> {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId, user: { id: userId } },
    });
    if (!session) throw new NotFoundException('Session not found');

    // Add user message
    session.messages.push({
      role: 'user',
      content: userMessage,
      audioUrl,
      timestamp: new Date().toISOString(),
    });

    const profile = await this.profileService.findByUserId(userId);

    // Convert session messages to AI format
    const aiMessages: AIMessage[] = session.messages.map((m) => ({
      role: m.role === 'user' ? 'user' : 'assistant',
      content: m.content,
    }));

    const aiResponse = await this.aiService.generateConversationResponse(
      aiMessages,
      profile?.currentLevel ?? 'A2',
      session.situation,
    );

    // Add AI response
    session.messages.push({
      role: 'ai',
      content: aiResponse,
      timestamp: new Date().toISOString(),
    });

    await this.sessionRepo.save(session);

    return { message: aiResponse, sessionId };
  }

  async endSession(
    sessionId: string,
    userId: string,
    durationMinutes: number,
  ): Promise<PracticeSession> {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId, user: { id: userId } },
    });
    if (!session) throw new NotFoundException('Session not found');

    const profile = await this.profileService.findByUserId(userId);

    // Get all user messages for analysis
    const userText = session.messages
      .filter((m) => m.role === 'user')
      .map((m) => m.content)
      .join(' ');

    let feedback = null;
    if (userText.trim()) {
      feedback = await this.aiService.analyzeSpeaking(
        userText,
        profile?.currentLevel ?? 'A2',
        session.situation,
      );
    }

    session.feedback = feedback ?? null;
    session.status = PracticeStatus.COMPLETED;
    session.durationMinutes = durationMinutes;
    session.completedAt = new Date();
    if (feedback) {
      session.detectedMistakes = feedback.detectedMistakes;
      session.newVocabulary = feedback.newVocabulary;
    }

    await this.sessionRepo.save(session);

    // Update learning profile
    if (feedback) {
      const skillType = session.type.startsWith('speaking')
        ? 'speaking'
        : session.type.startsWith('writing')
          ? 'writing'
          : 'speaking';

      await this.profileService.updateFromPractice(
        userId,
        feedback.detectedMistakes,
        feedback.newVocabulary,
        skillType,
        feedback.overallScore,
        durationMinutes,
      );
    }

    return session;
  }

  async getSession(sessionId: string, userId: string): Promise<PracticeSession> {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId, user: { id: userId } },
    });
    if (!session) throw new NotFoundException('Session not found');
    return session;
  }

  async getUserSessions(userId: string, limit = 10): Promise<PracticeSession[]> {
    return this.sessionRepo.find({
      where: { user: { id: userId }, status: PracticeStatus.COMPLETED },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  // AI Tutor free chat
  async aiTutorChat(
    userId: string,
    messages: AIMessage[],
  ): Promise<string> {
    const profile = await this.profileService.findByUserId(userId);
    const systemPrompt = `You are a friendly, knowledgeable English tutor for a ${profile?.currentLevel ?? 'A2'} level learner with goal: ${profile?.learningGoal ?? 'general'}.
- Answer questions about grammar, vocabulary, pronunciation, and English expressions
- Explain things at the learner's level (don't be overly technical for beginners)
- Be encouraging and supportive
- If the user makes grammar mistakes in their question, understand their intent but gently note the correction
- You can discuss any topic the user wants to talk about in English`;

    return this.aiService.chat(messages, systemPrompt);
  }
}
