import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';

import { AuthModule } from './auth/auth.module.js';
import { UsersModule } from './users/users.module.js';
import { LearningProfileModule } from './learning-profile/learning-profile.module.js';
import { PracticeModule } from './practice/practice.module.js';
import { WritingModule } from './writing/writing.module.js';
import { VocabularyModule } from './vocabulary/vocabulary.module.js';
import { GrammarModule } from './grammar/grammar.module.js';
import { AiModule } from './ai/ai.module.js';

// Entities
import { User } from './users/entities/user.entity.js';
import { LearningProfile } from './learning-profile/entities/learning-profile.entity.js';
import { PracticeSession } from './practice/entities/practice-session.entity.js';
import { WritingSubmission } from './writing/entities/writing-submission.entity.js';
import { VocabularyItem } from './vocabulary/entities/vocabulary.entity.js';
import { GrammarLesson } from './grammar/entities/grammar-lesson.entity.js';
import { ListeningModule } from './listening/listening.module.js';
import { ListeningExercise, ListeningResult } from './listening/entities/listening-exercise.entity.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 60,
      },
    ]),

    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST', 'localhost'),
        port: configService.get<number>('DB_PORT', 5432),
        username: configService.get<string>('DB_USERNAME', 'postgres'),
        password: configService.get<string>('DB_PASSWORD', 'password'),
        database: configService.get<string>('DB_NAME', 'engora_db'),
        entities: [
          User,
          LearningProfile,
          PracticeSession,
          WritingSubmission,
          VocabularyItem,
          GrammarLesson,
          ListeningExercise,
          ListeningResult,
        ],
        synchronize: configService.get<string>('NODE_ENV') !== 'production',
        logging: configService.get<string>('NODE_ENV') === 'development',
        ssl: configService.get<string>('NODE_ENV') === 'production'
          ? { rejectUnauthorized: false }
          : false,
      }),
      inject: [ConfigService],
    }),

    AiModule,
    AuthModule,
    UsersModule,
    LearningProfileModule,
    PracticeModule,
    WritingModule,
    VocabularyModule,
    GrammarModule,
    ListeningModule,
  ],
})
export class AppModule {}
