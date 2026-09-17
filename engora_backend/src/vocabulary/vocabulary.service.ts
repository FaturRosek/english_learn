import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { VocabularyItem, VocabularyStatus } from './entities/vocabulary.entity.js';
import { AiService } from '../ai/ai.service.js';
import { LearningProfileService } from '../learning-profile/learning-profile.service.js';

@Injectable()
export class VocabularyService {
  constructor(
    @InjectRepository(VocabularyItem)
    private vocabRepo: Repository<VocabularyItem>,
    private aiService: AiService,
    private profileService: LearningProfileService,
  ) {}

  async addWord(userId: string, word: string, source?: string): Promise<VocabularyItem> {
    const existing = await this.vocabRepo.findOne({
      where: { user: { id: userId }, word: word.toLowerCase() },
    });
    if (existing) return existing;

    const profile = await this.profileService.findByUserId(userId);
    const explanation = await this.aiService.explainVocabulary(
      word,
      profile?.currentLevel ?? 'A2',
    );

    const item = this.vocabRepo.create({
      user: { id: userId },
      word: word.toLowerCase(),
      definition: explanation.definition,
      partOfSpeech: explanation.partOfSpeech,
      exampleSentence: explanation.examples[0],
      indonesianMeaning: explanation.indonesianMeaning,
      source: source ?? 'manual',
    });

    return this.vocabRepo.save(item);
  }

  async getUserVocabulary(
    userId: string,
    status?: VocabularyStatus,
  ): Promise<VocabularyItem[]> {
    const where: Record<string, unknown> = { user: { id: userId } };
    if (status) where['status'] = status;
    return this.vocabRepo.find({
      where,
      order: { createdAt: 'DESC' },
    });
  }

  async getWordsToReview(userId: string, limit = 10): Promise<VocabularyItem[]> {
    return this.vocabRepo.find({
      where: [
        { user: { id: userId }, status: VocabularyStatus.NEW },
        { user: { id: userId }, status: VocabularyStatus.LEARNING },
      ],
      order: { reviewCount: 'ASC', createdAt: 'ASC' },
      take: limit,
    });
  }

  async markReviewed(vocabId: string, userId: string, mastered: boolean) {
    const item = await this.vocabRepo.findOne({
      where: { id: vocabId, user: { id: userId } },
    });
    if (!item) return null;

    item.reviewCount += 1;
    item.lastReviewedAt = new Date();
    if (mastered || item.reviewCount >= 5) {
      item.status = VocabularyStatus.MASTERED;
    } else {
      item.status = VocabularyStatus.LEARNING;
    }

    return this.vocabRepo.save(item);
  }

  async addWordsFromMistakes(userId: string, words: string[], source: string) {
    for (const word of words) {
      await this.addWord(userId, word, source).catch(() => null);
    }
  }
}
