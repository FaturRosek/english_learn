import { Entity, Column, ManyToOne, JoinColumn } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity.js';
import type { User } from '../../users/entities/user.entity.js';

export enum PracticeType {
  SPEAKING_CONVERSATION = 'speaking_conversation',
  SPEAKING_SITUATION = 'speaking_situation',
  SPEAKING_PRONUNCIATION = 'speaking_pronunciation',
  WRITING_FREE = 'writing_free',
  WRITING_GUIDED = 'writing_guided',
  LISTENING = 'listening',
  VOCABULARY = 'vocabulary',
  GRAMMAR = 'grammar',
  AI_TUTOR = 'ai_tutor',
}

export enum PracticeStatus {
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  ABANDONED = 'abandoned',
}

@Entity('practice_sessions')
export class PracticeSession extends BaseEntity {
  @ManyToOne('User')
  @JoinColumn()
  user: User;

  @Column({ type: 'enum', enum: PracticeType })
  type: PracticeType;

  @Column({ type: 'enum', enum: PracticeStatus, default: PracticeStatus.IN_PROGRESS })
  status: PracticeStatus;

  @Column({ nullable: true })
  topic: string;

  @Column({ nullable: true })
  situation: string;

  // Session data (conversation history, etc.)
  @Column({ type: 'jsonb', default: [] })
  messages: Array<{
    role: 'user' | 'ai';
    content: string;
    audioUrl?: string;
    timestamp: string;
  }>;

  // AI Feedback
  @Column({ type: 'jsonb', nullable: true })
  feedback: {
    overallScore: number;
    grammarScore?: number;
    vocabularyScore?: number;
    pronunciationScore?: number;
    fluencyScore?: number;
    naturalness?: number;
    corrections: Array<{
      original: string;
      corrected: string;
      explanation: string;
      type: string;
    }>;
    strengths: string[];
    improvements: string[];
    summary: string;
  } | null;

  // Detected mistakes for profile update
  @Column({ type: 'jsonb', default: {} })
  detectedMistakes: Record<string, number>;

  // New vocabulary encountered
  @Column({ type: 'jsonb', default: [] })
  newVocabulary: string[];

  @Column({ nullable: true })
  durationMinutes: number;

  @Column({ nullable: true })
  completedAt: Date;
}
