import { Entity, Column, ManyToOne, JoinColumn } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity.js';
import type { User } from '../../users/entities/user.entity.js';

export enum ExerciseDifficulty {
  A1 = 'A1',
  A2 = 'A2',
  B1 = 'B1',
  B2 = 'B2',
  C1 = 'C1',
}

@Entity('listening_exercises')
export class ListeningExercise extends BaseEntity {
  @Column()
  title: string;

  @Column({ type: 'enum', enum: ExerciseDifficulty, default: ExerciseDifficulty.A2 })
  level: ExerciseDifficulty;

  @Column()
  topic: string;

  @Column({ nullable: true })
  audioUrl: string;

  @Column({ type: 'text' })
  transcript: string;

  @Column({ default: 60 })
  durationSeconds: number;

  @Column({ type: 'jsonb' })
  questions: Array<{
    id: string;
    question: string;
    options: string[];
    correctAnswer: string;
  }>;

  @Column({ default: true })
  isActive: boolean;
}

@Entity('listening_results')
export class ListeningResult extends BaseEntity {
  @ManyToOne('User')
  @JoinColumn()
  user: User;

  @Column()
  exerciseId: string;

  @Column()
  score: number;

  @Column()
  correctCount: number;

  @Column()
  totalQuestions: number;

  @Column({ type: 'jsonb' })
  answers: Record<string, string>;

  @Column({ type: 'jsonb', default: [] })
  newVocabulary: string[];

  @Column({ type: 'text', nullable: true })
  feedback: string;
}
