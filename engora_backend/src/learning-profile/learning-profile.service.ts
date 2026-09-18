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

  async getLearningPath(userId: string) {
    const profile = await this.findByUserId(userId);
    if (!profile) throw new NotFoundException('Profile not found');

    const level = profile.currentLevel;
    const goal = profile.learningGoal;
    const skills = {
      speaking: Math.round(profile.speakingProgress),
      writing: Math.round(profile.writingProgress),
      listening: Math.round(profile.listeningProgress),
      vocabulary: Math.round(profile.vocabularyProgress),
      grammar: Math.round(profile.grammarProgress),
    };

    const steps = [
      {
        id: 'step_1',
        title: `Level ${level} Assessment & Foundations`,
        subtitle: 'Core principles and initial evaluation',
        category: 'milestone',
        done: true,
      },
    ];

    if (goal === LearningGoal.JOB_INTERVIEW || goal === LearningGoal.WORK) {
      steps.push(
        {
          id: 'step_2',
          title: 'Workplace & Professional Vocabulary',
          subtitle: 'Essential business terminology and idioms',
          category: 'vocabulary',
          done: skills.vocabulary >= 35,
        },
        {
          id: 'step_3',
          title: 'Professional Writing & Email Correspondence',
          subtitle: 'Clear, concise, and polite business messages',
          category: 'writing',
          done: skills.writing >= 45,
        },
        {
          id: 'step_4',
          title: 'Job Interview Speaking & Fluency',
          subtitle: 'Answering common interview questions with confidence',
          category: 'speaking',
          done: skills.speaking >= 55,
        },
        {
          id: 'step_5',
          title: 'Full AI Mock Interview Simulation',
          subtitle: 'Interactive real-time interview roleplay',
          category: 'simulation',
          done: skills.speaking >= 75 && skills.grammar >= 60,
        },
      );
    } else if (goal === LearningGoal.TRAVEL) {
      steps.push(
        {
          id: 'step_2',
          title: 'Essential Travel Phrases & Customs',
          subtitle: 'Greetings, directions, and emergencies',
          category: 'vocabulary',
          done: skills.vocabulary >= 30,
        },
        {
          id: 'step_3',
          title: 'Listening to Native Accents & Announcements',
          subtitle: 'Train your ears for stations, airports, and hotels',
          category: 'listening',
          done: skills.listening >= 40,
        },
        {
          id: 'step_4',
          title: 'Real-Life Situation Conversations',
          subtitle: 'Roleplay checking into hotels and ordering food',
          category: 'speaking',
          done: skills.speaking >= 50,
        },
      );
    } else {
      steps.push(
        {
          id: 'step_2',
          title: 'Everyday Daily Conversation',
          subtitle: 'Casual conversations, hobbies, and routines',
          category: 'speaking',
          done: skills.speaking >= 30,
        },
        {
          id: 'step_3',
          title: 'Core Grammar & Tense Mastery',
          subtitle: 'Past, present, and future consistency',
          category: 'grammar',
          done: skills.grammar >= 40,
        },
        {
          id: 'step_4',
          title: 'Vocabulary Expansion (500+ Words)',
          subtitle: 'Collocations, phrasal verbs, and synonyms',
          category: 'vocabulary',
          done: skills.vocabulary >= 50,
        },
        {
          id: 'step_5',
          title: 'Fluent & Natural Speaking Flow',
          subtitle: 'Confidence and natural phrasing without pauses',
          category: 'speaking',
          done: skills.speaking >= 70,
        },
      );
    }

    return {
      currentLevel: level,
      goal,
      steps,
    };
  }
}
