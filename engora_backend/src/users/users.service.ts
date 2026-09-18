import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User } from './entities/user.entity.js';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async create(data: Partial<User>): Promise<User> {
    const user = this.userRepository.create(data);
    return this.userRepository.save(user);
  }

  async findById(id: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id } });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { email } });
  }

  async findByEmailWithPassword(email: string): Promise<User | null> {
    return this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('user.email = :email', { email })
      .getOne();
  }

  async updateRefreshToken(userId: string, refreshToken: string | null) {
    if (refreshToken) {
      const hashed = await bcrypt.hash(refreshToken, 10);
      await this.userRepository.update(userId, { refreshToken: hashed });
    } else {
      await this.userRepository.update(userId, { refreshToken: null as any });
    }
  }

  async updateFcmToken(userId: string, fcmToken: string) {
    await this.userRepository.update(userId, { fcmToken });
  }

  async updateProfile(userId: string, data: Partial<User>) {
    await this.userRepository.update(userId, data);
    return this.findById(userId);
  }
}
