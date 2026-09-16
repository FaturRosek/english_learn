import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GrammarLesson } from './entities/grammar-lesson.entity.js';
import { AiService } from '../ai/ai.service.js';
import { LearningProfileService } from '../learning-profile/learning-profile.service.js';
import { EnglishLevel } from '../learning-profile/entities/learning-profile.entity.js';

@Injectable()
export class GrammarService {
  constructor(
    @InjectRepository(GrammarLesson)
    private lessonRepo: Repository<GrammarLesson>,
    private aiService: AiService,
    private profileService: LearningProfileService,
  ) {}

  async getLessonsForLevel(level: EnglishLevel): Promise<GrammarLesson[]> {
    return this.lessonRepo.find({
      where: { level },
      order: { orderIndex: 'ASC' },
    });
  }

  async getWeaknessLessons(userId: string): Promise<GrammarLesson[]> {
    const profile = await this.profileService.findByUserId(userId);
    if (!profile || profile.weaknesses.length === 0) return [];

    const topicMap: Record<string, string> = {
      past_tense: 'Simple Past Tense',
      present_perfect: 'Present Perfect',
      subject_verb_agreement: 'Subject-Verb Agreement',
      article_usage: 'Articles (a, an, the)',
      preposition: 'Prepositions',
      tense_consistency: 'Tense Consistency',
    };

    const lessons: GrammarLesson[] = [];
    for (const weakness of profile.weaknesses) {
      const topic = topicMap[weakness];
      if (topic) {
        const lesson = await this.lessonRepo.findOne({
          where: { topic: weakness, level: profile.currentLevel },
        });
        if (lesson) lessons.push(lesson);
      }
    }
    return lessons;
  }

  async explainTopic(userId: string, topic: string): Promise<string> {
    const profile = await this.profileService.findByUserId(userId);
    return this.aiService.explainGrammar(topic, profile?.currentLevel ?? 'A2');
  }

  async getRecommendedTopics(userId: string): Promise<{
    weakTopics: string[];
    recommendedLessons: string[];
  }> {
    const profile = await this.profileService.findByUserId(userId);
    if (!profile) return { weakTopics: [], recommendedLessons: [] };

    const weakTopics = profile.weaknesses;
    const recommendedLessons = weakTopics.map((w) =>
      w.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
    );

    return { weakTopics, recommendedLessons };
  }

  async seedLessons(): Promise<void> {
    const lessonsData = [
      {
        title: 'To Be Verbs',
        topic: 'to_be',
        level: EnglishLevel.A1,
        explanation: 'The verb "to be" (am, is, are) is used to describe states, identities, and characteristics.',
        examples: [
          { sentence: 'I am a student.', explanation: 'Use "am" with I' },
          { sentence: 'She is happy.', explanation: 'Use "is" with he/she/it' },
          { sentence: 'They are friends.', explanation: 'Use "are" with we/you/they' },
        ],
        exercises: [
          {
            type: 'fill_blank' as const,
            question: 'She ___ a teacher.',
            answer: 'is',
            explanation: 'Use "is" with she',
          },
        ],
        orderIndex: 1,
      },
      {
        title: 'Simple Past Tense',
        topic: 'past_tense',
        level: EnglishLevel.A2,
        explanation: 'Use Simple Past to talk about completed actions in the past. Add -ed for regular verbs.',
        examples: [
          { sentence: 'I went to school yesterday.', explanation: '"went" is the past of "go"' },
          { sentence: 'She watched a movie last night.', explanation: '"watched" = watch + ed' },
        ],
        exercises: [
          {
            type: 'multiple_choice' as const,
            question: 'Yesterday, I ___ to the store.',
            options: ['go', 'went', 'going', 'goes'],
            answer: 'went',
            explanation: '"went" is the past form of "go"',
          },
        ],
        orderIndex: 1,
      },
      {
        title: 'Present Perfect',
        topic: 'present_perfect',
        level: EnglishLevel.B1,
        explanation: 'Present Perfect connects the past to the present. Use have/has + past participle.',
        examples: [
          { sentence: 'I have lived here for 5 years.', explanation: 'Ongoing situation that started in the past' },
          { sentence: 'She has finished her homework.', explanation: 'Completed action with present relevance' },
        ],
        exercises: [
          {
            type: 'fill_blank' as const,
            question: 'I ___ never been to Paris.',
            answer: 'have',
            explanation: 'Use "have" with I',
          },
        ],
        orderIndex: 1,
      },
    ];

    for (const data of lessonsData) {
      const exists = await this.lessonRepo.findOne({
        where: { topic: data.topic, level: data.level },
      });
      if (!exists) {
        await this.lessonRepo.save(this.lessonRepo.create(data));
      }
    }
  }
}
