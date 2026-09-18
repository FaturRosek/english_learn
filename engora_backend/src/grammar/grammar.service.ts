import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GrammarLesson } from './entities/grammar-lesson.entity.js';
import { AiService } from '../ai/ai.service.js';
import { LearningProfileService } from '../learning-profile/learning-profile.service.js';
import { EnglishLevel } from '../learning-profile/entities/learning-profile.entity.js';

@Injectable()
export class GrammarService implements OnModuleInit {
  private readonly logger = new Logger(GrammarService.name);

  constructor(
    @InjectRepository(GrammarLesson)
    private lessonRepo: Repository<GrammarLesson>,
    private aiService: AiService,
    private profileService: LearningProfileService,
  ) {}

  async onModuleInit() {
    await this.seedLessons();
  }

  async getLessonsForLevel(level?: string): Promise<GrammarLesson[]> {
    if (!level || level === 'all') {
      return this.lessonRepo.find({
        order: { orderIndex: 'ASC' },
      });
    }
    return this.lessonRepo.find({
      where: { level: level as EnglishLevel },
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

  async markLessonComplete(lessonId: string, userId: string): Promise<{ success: boolean; lessonId: string }> {
    await this.profileService.updateFromPractice(userId, {}, [], 'grammar', 95, 5);
    return { success: true, lessonId };
  }

  async seedLessons(): Promise<void> {
    const lessonsData = [
      {
        title: 'To Be Verbs (am, is, are)',
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
        title: 'Simple Present Tense',
        topic: 'simple_present',
        level: EnglishLevel.A1,
        explanation: 'Use Simple Present for habits, facts, and daily routines. Add -s or -es for third person singular (he/she/it).',
        examples: [
          { sentence: 'I eat breakfast every morning.', explanation: 'Habit or daily routine' },
          { sentence: 'He works in a hospital.', explanation: 'Fact or job statement' },
        ],
        exercises: [
          {
            type: 'multiple_choice' as const,
            question: 'John ___ coffee every morning.',
            options: ['drink', 'drinks', 'drinking', 'drank'],
            answer: 'drinks',
            explanation: 'Third person singular adds -s',
          },
        ],
        orderIndex: 2,
      },
      {
        title: 'Subject and Object Pronouns',
        topic: 'pronouns',
        level: EnglishLevel.A1,
        explanation: 'Subject pronouns (I, you, he, she, it, we, they) do the action. Object pronouns (me, you, him, her, it, us, them) receive the action.',
        examples: [
          { sentence: 'She called him yesterday.', explanation: '"She" is subject, "him" is object' },
          { sentence: 'They helped us with the luggage.', explanation: '"They" is subject, "us" is object' },
        ],
        exercises: [
          {
            type: 'fill_blank' as const,
            question: 'Can you please help ___? (I/me)',
            answer: 'me',
            explanation: 'Object pronoun after verb help',
          },
        ],
        orderIndex: 3,
      },
      {
        title: 'Simple Past Tense',
        topic: 'past_tense',
        level: EnglishLevel.A2,
        explanation: 'Use Simple Past to talk about completed actions at a specific time in the past. Regular verbs add -ed, while irregular verbs change form.',
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
        title: 'Future Tense (will / going to)',
        topic: 'future_tense',
        level: EnglishLevel.A2,
        explanation: 'Use "will" for spontaneous decisions and predictions, and "be going to" for planned future events.',
        examples: [
          { sentence: 'I will help you with that.', explanation: 'Spontaneous decision' },
          { sentence: 'We are going to visit Bali next month.', explanation: 'Planned event' },
        ],
        exercises: [
          {
            type: 'fill_blank' as const,
            question: 'I think it ___ rain tomorrow.',
            answer: 'will',
            explanation: 'Prediction with think uses will',
          },
        ],
        orderIndex: 2,
      },
      {
        title: 'Comparatives & Superlatives',
        topic: 'comparatives',
        level: EnglishLevel.A2,
        explanation: 'Comparatives compare two things (-er / more). Superlatives compare three or more (-est / most).',
        examples: [
          { sentence: 'Tokyo is bigger than Kyoto.', explanation: 'Comparative with -er' },
          { sentence: 'This is the most interesting book.', explanation: 'Superlative with most' },
        ],
        exercises: [
          {
            type: 'multiple_choice' as const,
            question: 'A plane is ___ than a train.',
            options: ['faster', 'fastest', 'more fast', 'fast'],
            answer: 'faster',
            explanation: 'Short adjective comparative uses -er',
          },
        ],
        orderIndex: 3,
      },
      {
        title: 'Present Perfect',
        topic: 'present_perfect',
        level: EnglishLevel.B1,
        explanation: 'Present Perfect connects the past to the present. Use have/has + past participle for life experiences and unfinished actions.',
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
      {
        title: 'Conditionals (Zero, First, Second)',
        topic: 'conditionals',
        level: EnglishLevel.B1,
        explanation: 'Conditionals express cause and effect. First conditional (If + present, will + verb) is for real future possibilities.',
        examples: [
          { sentence: 'If it rains, we will stay home.', explanation: 'First conditional (real situation)' },
          { sentence: 'If I had more time, I would travel more.', explanation: 'Second conditional (hypothetical)' },
        ],
        exercises: [
          {
            type: 'multiple_choice' as const,
            question: 'If you study hard, you ___ the exam.',
            options: ['pass', 'will pass', 'would pass', 'passed'],
            answer: 'will pass',
            explanation: 'First conditional result clause uses will + base verb',
          },
        ],
        orderIndex: 2,
      },
      {
        title: 'Passive Voice',
        topic: 'passive_voice',
        level: EnglishLevel.B1,
        explanation: 'Passive voice (be + past participle) is used when the focus is on the action or recipient rather than the performer.',
        examples: [
          { sentence: 'The report was submitted yesterday.', explanation: 'Focus on report rather than who submitted' },
          { sentence: 'English is spoken all over the world.', explanation: 'General fact in passive' },
        ],
        exercises: [
          {
            type: 'fill_blank' as const,
            question: 'The email ___ sent by Sarah this morning. (was/were)',
            answer: 'was',
            explanation: 'Singular subject "The email" takes "was"',
          },
        ],
        orderIndex: 3,
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
    this.logger.log(`Seeded ${lessonsData.length} grammar lessons successfully.`);
  }
}
