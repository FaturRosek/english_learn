import { Entity, Column, ManyToOne, JoinColumn } from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity.js';
import type { User } from '../../users/entities/user.entity.js';

export enum VocabularyStatus {
  NEW = 'new',
  LEARNING = 'learning',
  MASTERED = 'mastered',
}

@Entity('vocabulary_items')
export class VocabularyItem extends BaseEntity {
  @ManyToOne('User')
  @JoinColumn()
  user: User;

  @Column()
  word: string;

  @Column({ nullable: true })
  partOfSpeech: string;

  @Column({ nullable: true })
  definition: string;

  @Column({ nullable: true })
  indonesianMeaning: string;

  @Column({ nullable: true })
  exampleSentence: string;

  @Column({ nullable: true })
  pronunciation: string;

  @Column({
    type: 'enum',
    enum: VocabularyStatus,
    default: VocabularyStatus.NEW,
  })
  status: VocabularyStatus;

  // Source: speaking, writing, listening, or manual
  @Column({ nullable: true })
  source: string;

  @Column({ default: 0 })
  reviewCount: number;

  @Column({ nullable: true })
  lastReviewedAt: Date;

  @Column({ nullable: true })
  nextReviewAt: Date;
}
