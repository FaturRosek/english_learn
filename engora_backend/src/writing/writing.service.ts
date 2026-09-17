import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WritingSubmission, WritingType } from './entities/writing-submission.entity.js';
import { AiService } from '../ai/ai.service.js';
import { LearningProfileService } from '../learning-profile/learning-profile.service.js';

@Injectable()
export class WritingService {
  constructor(
    @InjectRepository(WritingSubmission)
    private submissionRepo: Repository<WritingSubmission>,
    private aiService: AiService,
    private profileService: LearningProfileService,
  ) {}

  async submitWriting(
    userId: string,
    text: string,
    type: WritingType,
    prompt?: string,
  ): Promise<WritingSubmission> {
    const profile = await this.profileService.findByUserId(userId);
    const feedback = await this.aiService.analyzeWriting(
      text,
      profile?.currentLevel ?? 'A2',
      prompt,
    );

    const submission = this.submissionRepo.create({
      user: { id: userId },
      type,
      prompt,
      originalText: text,
      correctedText: feedback.correctedText,
      feedback: {
        overallScore: feedback.overallScore,
        grammarScore: feedback.grammarScore,
        vocabularyScore: feedback.vocabularyScore,
        clarityScore: feedback.clarityScore,
        corrections: feedback.corrections.map((c) => ({
          original: c.original,
          corrected: c.corrected,
          explanation: c.explanation,
          type: c.type as
            | 'grammar'
            | 'vocabulary'
            | 'spelling'
            | 'sentence_structure'
            | 'naturalness',
        })),
        strengths: feedback.strengths,
        improvements: feedback.improvements,
        summary: feedback.summary,
      },
      detectedMistakes: feedback.detectedMistakes,
      newVocabulary: feedback.newVocabulary,
    });

    await this.submissionRepo.save(submission);

    // Update learning profile
    await this.profileService.updateFromPractice(
      userId,
      feedback.detectedMistakes,
      feedback.newVocabulary,
      'writing',
      feedback.overallScore,
      5,
    );

    return submission;
  }

  async getHistory(userId: string, limit = 10): Promise<any[]> {
    const submissions = await this.submissionRepo.find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC' },
      take: limit,
    });
    return submissions.map((s) => ({
      ...s,
      content: s.originalText,
    }));
  }

  async getGuidedPrompts(goal?: string): Promise<Array<{
    id: string;
    title: string;
    description: string;
    guidePoints: string[];
    level: string;
  }>> {
    const prompts = [
      {
        id: '1',
        title: 'Introduce Yourself',
        description: 'Write a short introduction about yourself.',
        guidePoints: [
          'Your name and where you are from',
          'Your occupation or studies',
          'Your hobbies and interests',
          'Your goals for learning English',
        ],
        level: 'A1',
      },
      {
        id: '2',
        title: 'My Weekend',
        description: 'Write about what you did last weekend.',
        guidePoints: [
          'Where you went or what you did at home',
          'Who you were with',
          'What you enjoyed the most',
          'How you felt about it',
        ],
        level: 'A2',
      },
      {
        id: '3',
        title: 'My Dream Job',
        description: 'Describe your dream job and why you want it.',
        guidePoints: [
          'What the job is',
          'What skills are required',
          'Why you are interested in it',
          'What steps you are taking to achieve it',
        ],
        level: 'B1',
      },
      {
        id: '4',
        title: 'A Challenge I Overcame',
        description: 'Write about a difficult situation you faced and how you dealt with it.',
        guidePoints: [
          'What was the situation',
          'What obstacles did you face',
          'How did you solve it',
          'What did you learn',
        ],
        level: 'B1',
      },
      {
        id: '5',
        title: 'Technology in Daily Life',
        description: 'How has technology changed your daily life? Discuss the positives and negatives.',
        guidePoints: [
          'How technology helps you daily',
          'Potential downsides or distractions',
          'How you balance screen time',
        ],
        level: 'B2',
      },
      {
        id: '6',
        title: 'Professional Email to Your Manager',
        description: 'Write a formal email requesting feedback on a recent project.',
        guidePoints: [
          'Clear subject line',
          'Formal greeting and statement of purpose',
          'Key project achievements to review',
          'Polite call to action and closing',
        ],
        level: 'B2',
      },
    ];

    return prompts;
  }
}
