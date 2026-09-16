import { Entity, Column } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity.js';
import { EnglishLevel } from '../../learning-profile/entities/learning-profile.entity.js';

@Entity('grammar_lessons')
export class GrammarLesson extends BaseEntity {
  @Column()
  title: string;

  @Column({ type: 'text' })
  explanation: string;

  @Column({
    type: 'enum',
    enum: EnglishLevel,
  })
  level: EnglishLevel;

  @Column()
  topic: string; // e.g., 'past_tense', 'present_perfect'

  @Column({ type: 'jsonb', default: [] })
  examples: Array<{ sentence: string; explanation: string }>;

  @Column({ type: 'jsonb', default: [] })
  exercises: Array<{
    type: 'multiple_choice' | 'fill_blank' | 'sentence_creation';
    question: string;
    options?: string[];
    answer: string;
    explanation: string;
  }>;

  @Column({ default: 0 })
  orderIndex: number;
}
