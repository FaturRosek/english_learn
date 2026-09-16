import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LearningProfile, EnglishLevel, LearningGoal } from './entities/learning-profile.entity.js';
import { AiService } from '../ai/ai.service.js';

@Injectable()
export class LearningProfileService {
  constructor(
    @InjectRepository(LearningProfile)
    private profileRepo: Repository<LearningProfile>,
    private aiService: AiService,
  ) {}

  async createForUser(userId: string): Promise<LearningProfile> {
    const profile = this.profileRepo.create({
      user: { id: userId },
    });
    return this.profileRepo.save(profile);
  }

  async findByUserId(userId: string): Promise<LearningProfile | null> {
    return this.profileRepo.findOne({
      where: { user: { id: userId } },
    });
  }

  async completeOnboarding(
    userId: string,
    level: EnglishLevel,
    goal: LearningGoal,
  ): Promise<LearningProfile> {
    let profile = await this.findByUserId(userId);
    if (!profile) {
      throw new NotFoundException('Learning profile not found');
    }

    profile.currentLevel = level;
    profile.learningGoal = goal;
    profile.onboardingCompleted = true;

    // Generate AI profile summary
    const summary = await this.aiService.generateLearningProfile(
      level,
      goal,
      [],
    );
    profile.aiProfileSummary = summary;

    return this.profileRepo.save(profile);
  }

  async updateFromPractice(
    userId: string,
    detectedMistakes: Record<string, number>,
    newVocabulary: string[],
    skillType: 'speaking' | 'writing' | 'listening' | 'vocabulary' | 'grammar',
    score: number,
    durationMinutes: number,
  ): Promise<void> {
    const profile = await this.findByUserId(userId);
    if (!profile) return;

    // Update grammar mistakes
    for (const [key, count] of Object.entries(detectedMistakes)) {
      profile.grammarMistakes[key] = (profile.grammarMistakes[key] ?? 0) + count;
    }

    // Add new vocabulary
    const combined = [...new Set([...profile.vocabularyList, ...newVocabulary])];
    profile.vocabularyList = combined.slice(0, 500); // cap at 500

    // Update skill progress (weighted average)
    const progressKey = `${skillType}Progress` as keyof LearningProfile;
    const current = profile[progressKey] as number;
    profile[progressKey] = Math.min(100, current * 0.9 + score * 0.1) as never;

    // Update weaknesses based on mistakes
    const topMistakes = Object.entries(profile.grammarMistakes)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 3)
      .map(([key]) => key);
    profile.weaknesses = topMistakes;

    // Update streak
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const lastPractice = profile.lastPracticeDate
      ? new Date(profile.lastPracticeDate)
      : null;

    if (lastPractice) {
      lastPractice.setHours(0, 0, 0, 0);
      const diffDays = Math.floor(
        (today.getTime() - lastPractice.getTime()) / (1000 * 60 * 60 * 24),
      );
      if (diffDays === 1) {
        profile.currentStreak += 1;
        profile.longestStreak = Math.max(profile.longestStreak, profile.currentStreak);
      } else if (diffDays > 1) {
        profile.currentStreak = 1;
      }
    } else {
      profile.currentStreak = 1;
      profile.longestStreak = 1;
    }

    profile.lastPracticeDate = new Date();
    profile.totalPracticeMinutes += durationMinutes;
    profile.totalSessions += 1;

    await this.profileRepo.save(profile);
  }

  async getTodaysPractice(userId: string) {
    const profile = await this.findByUserId(userId);
    if (!profile) return null;

    return this.aiService.generateTodaysPractice(
      profile.currentLevel,
      profile.learningGoal,
      profile.weaknesses,
      [], // recent topics - could be fetched from sessions
    );
  }

  async getStats(userId: string) {
    const profile = await this.findByUserId(userId);
    if (!profile) throw new NotFoundException('Profile not found');

    return {
      level: profile.currentLevel,
      goal: profile.learningGoal,
      streak: profile.currentStreak,
      longestStreak: profile.longestStreak,
      totalSessions: profile.totalSessions,
      totalMinutes: profile.totalPracticeMinutes,
      skills: {
        speaking: Math.round(profile.speakingProgress),
        writing: Math.round(profile.writingProgress),
        listening: Math.round(profile.listeningProgress),
        vocabulary: Math.round(profile.vocabularyProgress),
        grammar: Math.round(profile.grammarProgress),
      },
      weaknesses: profile.weaknesses,
      strengths: profile.strengths,
      aiSummary: profile.aiProfileSummary,
    };
  }
}
