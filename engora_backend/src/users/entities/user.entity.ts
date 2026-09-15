import {
  Entity,
  Column,
  OneToOne,
  OneToMany,
} from 'typeorm';
import { BaseEntity } from '../../common/entities/base.entity.js';
import type { LearningProfile } from '../../learning-profile/entities/learning-profile.entity.js';
import type { PracticeSession } from '../../practice/entities/practice-session.entity.js';
import type { WritingSubmission } from '../../writing/entities/writing-submission.entity.js';

export enum AuthProvider {
  EMAIL = 'email',
  GOOGLE = 'google',
}

@Entity('users')
export class User extends BaseEntity {
  @Column({ unique: true })
  email: string;

  @Column({ nullable: true, select: false })
  password: string;

  @Column()
  fullName: string;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({
    type: 'enum',
    enum: AuthProvider,
    default: AuthProvider.EMAIL,
  })
  provider: AuthProvider;

  @Column({ nullable: true })
  providerId: string;

  @Column({ default: false })
  isEmailVerified: boolean;

  @Column({ nullable: true })
  refreshToken: string;

  @Column({ nullable: true })
  fcmToken: string;

  @Column({ default: true })
  isActive: boolean;

  @OneToOne('LearningProfile', 'user', { cascade: true })
  learningProfile: LearningProfile;

  @OneToMany('PracticeSession', 'user')
  practiceSessions: PracticeSession[];

  @OneToMany('WritingSubmission', 'user')
  writingSubmissions: WritingSubmission[];
}
