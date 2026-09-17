import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  ListeningExercise,
  ListeningResult,
  ExerciseDifficulty,
} from './entities/listening-exercise.entity.js';

@Injectable()
export class ListeningService {
  constructor(
    @InjectRepository(ListeningExercise)
    private exerciseRepo: Repository<ListeningExercise>,
    @InjectRepository(ListeningResult)
    private resultRepo: Repository<ListeningResult>,
  ) {}

  async getExercises(level?: string): Promise<ListeningExercise[]> {
    const query = this.exerciseRepo.createQueryBuilder('e').where('e.isActive = :active', {
      active: true,
    });
    if (level && level !== 'all') {
      query.andWhere('e.level = :level', { level });
    }
    const exercises = await query.orderBy('e.createdAt', 'ASC').getMany();

    // If DB is empty, return default exercises
    if (exercises.length === 0) {
      return this.getDefaultExercises();
    }
    return exercises;
  }

  async submitAnswers(
    userId: string,
    exerciseId: string,
    answers: Record<string, string>,
  ): Promise<{
    score: number;
    correctCount: number;
    totalQuestions: number;
    answers: Record<string, string>;
    newVocabulary: string[];
    feedback: string;
  }> {
    // Try to find from DB, fallback to defaults
    let exercise = await this.exerciseRepo.findOne({ where: { id: exerciseId } });
    if (!exercise) {
      const defaults = this.getDefaultExercises();
      exercise = defaults.find((e) => e.id === exerciseId) ?? defaults[0];
    }

    let correctCount = 0;
    for (const q of exercise.questions) {
      if (answers[q.id] === q.correctAnswer) correctCount++;
    }
    const total = exercise.questions.length;
    const score = total > 0 ? Math.round((correctCount / total) * 100) : 0;

    const feedback =
      score >= 80
        ? 'Excellent! Great listening comprehension.'
        : score >= 60
          ? 'Good job! Keep practicing to improve.'
          : "Don't give up! Try listening again carefully.";

    // Save result
    const result = this.resultRepo.create({
      user: { id: userId },
      exerciseId,
      score,
      correctCount,
      totalQuestions: total,
      answers,
      newVocabulary: [],
      feedback,
    });
    await this.resultRepo.save(result).catch(() => {
      // Non-critical — ignore save errors
    });

    return { score, correctCount, totalQuestions: total, answers, newVocabulary: [], feedback };
  }

  async getHistory(userId: string, limit = 10): Promise<ListeningResult[]> {
    return this.resultRepo.find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  // ─── Default exercises (seeded in-memory) ──────────────────────────────────

  private getDefaultExercises(): ListeningExercise[] {
    const make = (data: Partial<ListeningExercise>): ListeningExercise =>
      Object.assign(new ListeningExercise(), {
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true,
        ...data,
      });

    return [
      make({
        id: 'ex_1',
        title: 'A Day at the Office',
        level: ExerciseDifficulty.A2,
        topic: 'Workplace',
        audioUrl: '',
        durationSeconds: 75,
        transcript:
          "Sarah: Good morning, John. Did you finish the report?\n" +
          "John: Not yet. I'll have it done by noon.\n" +
          "Sarah: Great. The client meeting is at 2 PM.\n" +
          "John: I know. I'll bring the latest numbers.\n" +
          "Sarah: Perfect. See you in the conference room.",
        questions: [
          {
            id: 'q1',
            question: 'What did Sarah ask John about?',
            options: ['A. The client meeting', 'B. The report', 'C. The conference room', 'D. The latest numbers'],
            correctAnswer: 'B. The report',
          },
          {
            id: 'q2',
            question: 'When is the client meeting?',
            options: ['A. 9 AM', 'B. Noon', 'C. 2 PM', 'D. 3 PM'],
            correctAnswer: 'C. 2 PM',
          },
          {
            id: 'q3',
            question: 'What will John bring to the meeting?',
            options: ['A. The report', 'B. Coffee', 'C. The latest numbers', 'D. A presentation'],
            correctAnswer: 'C. The latest numbers',
          },
        ],
      }),
      make({
        id: 'ex_2',
        title: 'At the Restaurant',
        level: ExerciseDifficulty.A1,
        topic: 'Daily Life',
        audioUrl: '',
        durationSeconds: 60,
        transcript:
          "Waiter: Good evening! Are you ready to order?\n" +
          "Customer: Yes, I'd like the grilled chicken, please.\n" +
          "Waiter: Excellent choice. What would you like to drink?\n" +
          "Customer: Just water, thank you.\n" +
          "Waiter: Of course. I'll be right back.",
        questions: [
          {
            id: 'q1',
            question: 'What did the customer order?',
            options: ['A. Grilled fish', 'B. Grilled chicken', 'C. A salad', 'D. Pasta'],
            correctAnswer: 'B. Grilled chicken',
          },
          {
            id: 'q2',
            question: 'What did the customer want to drink?',
            options: ['A. Coffee', 'B. Juice', 'C. Water', 'D. Soda'],
            correctAnswer: 'C. Water',
          },
        ],
      }),
      make({
        id: 'ex_3',
        title: 'Job Interview',
        level: ExerciseDifficulty.B1,
        topic: 'Career',
        audioUrl: '',
        durationSeconds: 90,
        transcript:
          "Interviewer: Tell me about yourself.\n" +
          "Candidate: I've been working in marketing for three years. " +
          "I specialize in digital campaigns and social media strategy.\n" +
          "Interviewer: Why do you want to join our company?\n" +
          "Candidate: I admire your innovative approach to branding. " +
          "I believe my skills would contribute well to your team.\n" +
          "Interviewer: What is your greatest strength?\n" +
          "Candidate: I'm highly organized and I work well under pressure.",
        questions: [
          {
            id: 'q1',
            question: "How long has the candidate been working in marketing?",
            options: ['A. One year', 'B. Two years', 'C. Three years', 'D. Five years'],
            correctAnswer: 'C. Three years',
          },
          {
            id: 'q2',
            question: 'What does the candidate specialize in?',
            options: [
              'A. Product development',
              'B. Digital campaigns and social media',
              'C. Finance and accounting',
              'D. Customer service',
            ],
            correctAnswer: 'B. Digital campaigns and social media',
          },
          {
            id: 'q3',
            question: "What is the candidate's greatest strength?",
            options: [
              'A. Creative thinking',
              'B. Technical skills',
              'C. Being organized and working under pressure',
              'D. Public speaking',
            ],
            correctAnswer: 'C. Being organized and working under pressure',
          },
        ],
      }),
      make({
        id: 'ex_4',
        title: 'Travel Conversation',
        level: ExerciseDifficulty.A2,
        topic: 'Travel',
        audioUrl: '',
        durationSeconds: 70,
        transcript:
          "Tourist: Excuse me, how do I get to the train station?\n" +
          "Local: Take the number 5 bus. It stops right in front.\n" +
          "Tourist: How long does it take?\n" +
          "Local: About 15 minutes. The bus comes every 10 minutes.\n" +
          "Tourist: Thank you so much!\n" +
          "Local: You're welcome. Have a safe trip!",
        questions: [
          {
            id: 'q1',
            question: 'Where does the tourist want to go?',
            options: ['A. The airport', 'B. The hotel', 'C. The train station', 'D. The bus terminal'],
            correctAnswer: 'C. The train station',
          },
          {
            id: 'q2',
            question: 'Which bus should the tourist take?',
            options: ['A. Number 3', 'B. Number 5', 'C. Number 7', 'D. Number 10'],
            correctAnswer: 'B. Number 5',
          },
          {
            id: 'q3',
            question: 'How often does the bus come?',
            options: ['A. Every 5 minutes', 'B. Every 10 minutes', 'C. Every 15 minutes', 'D. Every 20 minutes'],
            correctAnswer: 'B. Every 10 minutes',
          },
        ],
      }),
    ];
  }
}
