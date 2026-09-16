import { Entity, Column, OneToOne, JoinColumn } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity.js';
import type { User } from '../../users/entities/user.entity.js';

export enum EnglishLevel {
  A1 = 'A1',
  A2 = 'A2',
  B1 = 'B1',
  B2 = 'B2',
  C1 = 'C1',
}

export enum LearningGoal {
  DAILY_CONVERSATION = 'daily_conversation',
  WORK = 'work',
  JOB_INTERVIEW = 'job_interview',
  TRAVEL = 'travel',
  ACADEMIC = 'academic',
  GENERAL = 'general',
}

@Entity('learning_profiles')
export class LearningProfile extends BaseEntity {
  @OneToOne('User', (user: User) => user.learningProfile)
  @JoinColumn()
  user: User;

  @Column({ type: 'enum', enum: EnglishLevel, default: EnglishLevel.A1 })
  currentLevel: EnglishLevel;

  @Column({ type: 'enum', enum: LearningGoal, default: LearningGoal.GENERAL })
  learningGoal: LearningGoal;

  // Skill progress (0-100)
  @Column({ type: 'float', default: 0 })
  speakingProgress: number;

  @Column({ type: 'float', default: 0 })
  writingProgress: number;

  @Column({ type: 'float', default: 0 })
  listeningProgress: number;

  @Column({ type: 'float', default: 0 })
  vocabularyProgress: number;

  @Column({ type: 'float', default: 0 })
  grammarProgress: number;

  // Weaknesses & strengths (JSON arrays)
  @Column({ type: 'jsonb', default: [] })
  weaknesses: string[];

  @Column({ type: 'jsonb', default: [] })
  strengths: string[];

  // Grammar mistakes tracking
  @Column({ type: 'jsonb', default: {} })
  grammarMistakes: Record<string, number>;

  // Vocabulary being learned
  @Column({ type: 'jsonb', default: [] })
  vocabularyList: string[];

  // Streak
  @Column({ default: 0 })
  currentStreak: number;

  @Column({ default: 0 })
  longestStreak: number;

  @Column({ nullable: true })
  lastPracticeDate: Date;

  // Total practice time in minutes
  @Column({ default: 0 })
  totalPracticeMinutes: number;

  @Column({ default: 0 })
  totalSessions: number;

  // AI-generated profile summary
  @Column({ type: 'text', nullable: true })
  aiProfileSummary: string;

  @Column({ default: false })
  onboardingCompleted: boolean;
}
