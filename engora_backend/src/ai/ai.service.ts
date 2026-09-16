import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';

export interface AIMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export interface SpeakingFeedback {
  overallScore: number;
  grammarScore: number;
  vocabularyScore: number;
  fluencyScore: number;
  naturalnessScore: number;
  corrections: Array<{
    original: string;
    corrected: string;
    explanation: string;
    type: string;
  }>;
  detectedMistakes: Record<string, number>;
  newVocabulary: string[];
  strengths: string[];
  improvements: string[];
  summary: string;
}

export interface WritingFeedback {
  overallScore: number;
  grammarScore: number;
  vocabularyScore: number;
  clarityScore: number;
  spellingScore: number;
  correctedText: string;
  corrections: Array<{
    original: string;
    corrected: string;
    explanation: string;
    type: string;
  }>;
  detectedMistakes: Record<string, number>;
  newVocabulary: string[];
  strengths: string[];
  improvements: string[];
  summary: string;
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private openai: OpenAI;
  private gemini: GoogleGenerativeAI;
  private defaultProvider: string;

  constructor(private configService: ConfigService) {
    this.openai = new OpenAI({
      apiKey: this.configService.get<string>('OPENAI_API_KEY'),
    });
    this.gemini = new GoogleGenerativeAI(
      this.configService.get<string>('GEMINI_API_KEY') ?? '',
    );
    this.defaultProvider =
      this.configService.get<string>('DEFAULT_AI_PROVIDER') ?? 'openai';
  }

  async chat(
    messages: AIMessage[],
    systemPrompt?: string,
    provider?: string,
  ): Promise<string> {
    const useProvider = provider ?? this.defaultProvider;
    try {
      if (useProvider === 'gemini') {
        return await this.chatWithGemini(messages, systemPrompt);
      }
      return await this.chatWithOpenAI(messages, systemPrompt);
    } catch (error) {
      this.logger.error(`AI chat error with ${useProvider}:`, error);
      // Fallback to other provider
      if (useProvider === 'openai') {
        return await this.chatWithGemini(messages, systemPrompt);
      }
      return await this.chatWithOpenAI(messages, systemPrompt);
    }
  }

  private async chatWithOpenAI(
    messages: AIMessage[],
    systemPrompt?: string,
  ): Promise<string> {
    const allMessages: OpenAI.ChatCompletionMessageParam[] = [];
    if (systemPrompt) {
      allMessages.push({ role: 'system', content: systemPrompt });
    }
    allMessages.push(...messages.map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content })));

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o',
      messages: allMessages,
      temperature: 0.7,
    });

    return response.choices[0].message.content ?? '';
  }

  private async chatWithGemini(
    messages: AIMessage[],
    systemPrompt?: string,
  ): Promise<string> {
    const model = this.gemini.getGenerativeModel({
      model: 'gemini-1.5-flash',
      systemInstruction: systemPrompt,
    });

    const history = messages.slice(0, -1).map((m) => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));

    const chat = model.startChat({ history });
    const lastMessage = messages[messages.length - 1];
    const result = await chat.sendMessage(lastMessage.content);
    return result.response.text();
  }

  async analyzeSpeaking(
    transcript: string,
    userLevel: string,
    context?: string,
  ): Promise<SpeakingFeedback> {
    const prompt = `You are an English language expert analyzing a learner's speech.

User Level: ${userLevel}
Context: ${context ?? 'General conversation'}
Transcript: "${transcript}"

Analyze the speech and provide feedback in the following JSON format ONLY (no markdown, no extra text):
{
  "overallScore": <0-100>,
  "grammarScore": <0-100>,
  "vocabularyScore": <0-100>,
  "fluencyScore": <0-100>,
  "naturalnessScore": <0-100>,
  "corrections": [
    {
      "original": "<wrong phrase>",
      "corrected": "<correct version>",
      "explanation": "<brief explanation>",
      "type": "grammar|vocabulary|sentence_structure|pronunciation"
    }
  ],
  "detectedMistakes": {
    "past_tense": <count>,
    "subject_verb_agreement": <count>,
    "article_usage": <count>,
    "preposition": <count>,
    "tense_consistency": <count>
  },
  "newVocabulary": ["<advanced word used>"],
  "strengths": ["<positive aspect>"],
  "improvements": ["<specific improvement tip>"],
  "summary": "<2-3 sentence overall feedback>"
}`;

    const response = await this.chat(
      [{ role: 'user', content: prompt }],
      undefined,
    );

    try {
      const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      return JSON.parse(cleaned) as SpeakingFeedback;
    } catch {
      this.logger.error('Failed to parse speaking feedback JSON');
      return this.getDefaultSpeakingFeedback();
    }
  }

  async analyzeWriting(
    text: string,
    userLevel: string,
    prompt?: string,
  ): Promise<WritingFeedback> {
    const analysisPrompt = `You are an English writing coach analyzing a learner's writing.

User Level: ${userLevel}
Writing Prompt: ${prompt ?? 'Free writing'}
Submitted Text: "${text}"

Analyze and provide feedback in JSON format ONLY (no markdown):
{
  "overallScore": <0-100>,
  "grammarScore": <0-100>,
  "vocabularyScore": <0-100>,
  "clarityScore": <0-100>,
  "spellingScore": <0-100>,
  "correctedText": "<full corrected version of the text>",
  "corrections": [
    {
      "original": "<wrong phrase>",
      "corrected": "<correct version>",
      "explanation": "<brief explanation>",
      "type": "grammar|vocabulary|spelling|sentence_structure|naturalness|clarity"
    }
  ],
  "detectedMistakes": {
    "past_tense": <count>,
    "subject_verb_agreement": <count>,
    "spelling": <count>,
    "article_usage": <count>,
    "tense_consistency": <count>
  },
  "newVocabulary": ["<word to learn>"],
  "strengths": ["<positive aspect>"],
  "improvements": ["<specific improvement>"],
  "summary": "<2-3 sentence overall feedback>"
}`;

    const response = await this.chat(
      [{ role: 'user', content: analysisPrompt }],
    );

    try {
      const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      return JSON.parse(cleaned) as WritingFeedback;
    } catch {
      this.logger.error('Failed to parse writing feedback JSON');
      return this.getDefaultWritingFeedback(text);
    }
  }

  async generateConversationResponse(
    messages: AIMessage[],
    userLevel: string,
    situation?: string,
  ): Promise<string> {
    const systemPrompt = `You are an English conversation partner for a ${userLevel} level learner.
${situation ? `Situation: ${situation}` : ''}
- Keep responses natural and conversational
- Match the user's level (don't use overly complex language for beginners)
- Gently continue the conversation with a follow-up question or comment
- If the user makes a mistake, understand their intent and respond naturally (don't correct mid-conversation)
- Keep responses concise (2-4 sentences)`;

    return this.chat(messages, systemPrompt);
  }

  async generateLearningProfile(
    level: string,
    goal: string,
    weaknesses: string[],
  ): Promise<string> {
    const prompt = `Create a personalized English learning profile summary for:
- Level: ${level}
- Goal: ${goal}
- Identified weaknesses: ${weaknesses.join(', ')}

Write 2-3 sentences describing their current English profile and what they should focus on. Be encouraging and specific.`;

    return this.chat([{ role: 'user', content: prompt }]);
  }

  async generateTodaysPractice(
    level: string,
    goal: string,
    weaknesses: string[],
    recentTopics: string[],
  ): Promise<{
    focus: string;
    topic: string;
    skills: Array<{ skill: string; minutes: number; reason: string }>;
  }> {
    const prompt = `Generate today's English practice plan for:
- Level: ${level}
- Goal: ${goal}
- Weaknesses: ${weaknesses.join(', ')}
- Recently practiced: ${recentTopics.join(', ')}

Respond in JSON only:
{
  "focus": "<today's main focus topic>",
  "topic": "<specific grammar or skill topic>",
  "skills": [
    {"skill": "Speaking", "minutes": 10, "reason": "<why>"},
    {"skill": "Writing", "minutes": 10, "reason": "<why>"},
    {"skill": "Listening", "minutes": 5, "reason": "<why>"},
    {"skill": "Vocabulary", "minutes": 5, "reason": "<why>"}
  ]
}`;

    const response = await this.chat([{ role: 'user', content: prompt }]);
    try {
      const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      return JSON.parse(cleaned);
    } catch {
      return {
        focus: 'General English',
        topic: 'Daily Conversation',
        skills: [
          { skill: 'Speaking', minutes: 10, reason: 'Practice daily conversation' },
          { skill: 'Writing', minutes: 10, reason: 'Improve writing skills' },
          { skill: 'Listening', minutes: 5, reason: 'Train your ears' },
          { skill: 'Vocabulary', minutes: 5, reason: 'Learn new words' },
        ],
      };
    }
  }

  async explainGrammar(topic: string, userLevel: string): Promise<string> {
    const prompt = `Explain "${topic}" in English grammar for a ${userLevel} level learner.
- Keep it simple and easy to understand
- Give 2-3 clear examples
- Use everyday situations the learner can relate to
- Be encouraging`;

    return this.chat([{ role: 'user', content: prompt }]);
  }

  async explainVocabulary(word: string, userLevel: string): Promise<{
    definition: string;
    partOfSpeech: string;
    examples: string[];
    indonesianMeaning: string;
  }> {
    const prompt = `Explain the English word "${word}" for a ${userLevel} level learner.
Respond in JSON only:
{
  "definition": "<clear English definition>",
  "partOfSpeech": "<noun/verb/adjective/etc>",
  "examples": ["<example 1>", "<example 2>"],
  "indonesianMeaning": "<Indonesian translation>"
}`;

    const response = await this.chat([{ role: 'user', content: prompt }]);
    try {
      const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      return JSON.parse(cleaned);
    } catch {
      return {
        definition: word,
        partOfSpeech: 'unknown',
        examples: [],
        indonesianMeaning: '',
      };
    }
  }

  async analyzePronunciation(
    word: string,
    phonemeScores: Record<string, number>,
  ): Promise<{ score: number; feedback: string; tips: string[] }> {
    const prompt = `A learner pronounced the word "${word}". Phoneme analysis: ${JSON.stringify(phonemeScores)}.
Give pronunciation feedback in JSON:
{
  "score": <0-100>,
  "feedback": "<main feedback>",
  "tips": ["<specific tip 1>", "<specific tip 2>"]
}`;

    const response = await this.chat([{ role: 'user', content: prompt }]);
    try {
      const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      return JSON.parse(cleaned);
    } catch {
      return { score: 75, feedback: 'Good attempt! Keep practicing.', tips: [] };
    }
  }

  private getDefaultSpeakingFeedback(): SpeakingFeedback {
    return {
      overallScore: 70,
      grammarScore: 70,
      vocabularyScore: 70,
      fluencyScore: 70,
      naturalnessScore: 70,
      corrections: [],
      detectedMistakes: {},
      newVocabulary: [],
      strengths: ['Good effort!'],
      improvements: ['Keep practicing!'],
      summary: 'Good job practicing your speaking skills!',
    };
  }

  private getDefaultWritingFeedback(text: string): WritingFeedback {
    return {
      overallScore: 70,
      grammarScore: 70,
      vocabularyScore: 70,
      clarityScore: 70,
      spellingScore: 70,
      correctedText: text,
      corrections: [],
      detectedMistakes: {},
      newVocabulary: [],
      strengths: ['Good effort!'],
      improvements: ['Keep practicing!'],
      summary: 'Good job with your writing practice!',
    };
  }
}
