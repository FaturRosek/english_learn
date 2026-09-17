import { Entity, Column, ManyToOne, JoinColumn } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity.js';
import type { User } from '../../users/entities/user.entity.js';

export enum WritingType {
  FREE = 'free',
  GUIDED = 'guided',
}

@Entity('writing_submissions')
export class WritingSubmission extends BaseEntity {
  @ManyToOne('User')
  @JoinColumn()
  user: User;

  @Column({ type: 'enum', enum: WritingType, default: WritingType.FREE })
  type: WritingType;

  @Column({ nullable: true })
  prompt: string;

  @Column({ type: 'text' })
  originalText: string;

  @Column({ type: 'text', nullable: true })
  correctedText: string;

  @Column({ type: 'jsonb', nullable: true })
  feedback: {
    overallScore: number;
    grammarScore: number;
    vocabularyScore: number;
    clarityScore: number;
    corrections: Array<{
      original: string;
      corrected: string;
      explanation: string;
      type: 'grammar' | 'vocabulary' | 'spelling' | 'sentence_structure' | 'naturalness';
    }>;
    strengths: string[];
    improvements: string[];
    summary: string;
  };

  @Column({ type: 'jsonb', default: {} })
  detectedMistakes: Record<string, number>;

  @Column({ type: 'jsonb', default: [] })
  newVocabulary: string[];
}
