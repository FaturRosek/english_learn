import {
  Injectable,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { UsersService } from '../users/users.service.js';
import { LearningProfileService } from '../learning-profile/learning-profile.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private learningProfileService: LearningProfileService,
  ) {}

  async register(registerDto: RegisterDto) {
    const existingUser = await this.usersService.findByEmail(registerDto.email);
    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    const hashedPassword = await bcrypt.hash(registerDto.password, 12);
    const user = await this.usersService.create({
      ...registerDto,
      password: hashedPassword,
    });

    // Create empty learning profile
    await this.learningProfileService.createForUser(user.id);

    const tokens = await this.generateTokens(user.id, user.email);
    await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        onboardingCompleted: false,
      },
      ...tokens,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByEmailWithPassword(
      loginDto.email,
    );
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      user.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account is inactive');
    }

    const tokens = await this.generateTokens(user.id, user.email);
    await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);

    const profile = await this.learningProfileService.findByUserId(user.id);

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        onboardingCompleted: profile?.onboardingCompleted ?? false,
      },
      ...tokens,
    };
  }

  async refreshTokens(userId: string, refreshToken: string) {
    const user = await this.usersService.findById(userId);
    if (!user?.refreshToken) {
      throw new UnauthorizedException('Access denied');
    }

    const isRefreshValid = await bcrypt.compare(
      refreshToken,
      user.refreshToken,
    );
    if (!isRefreshValid) {
      throw new UnauthorizedException('Access denied');
    }

    const tokens = await this.generateTokens(user.id, user.email);
    await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);
    return tokens;
  }

  async refreshTokensWithToken(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync<{ sub: string; email: string }>(
        refreshToken,
        {
          secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        },
      );
      return this.refreshTokens(payload.sub, refreshToken);
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  async logout(userId: string) {
    await this.usersService.updateRefreshToken(userId, null);
    return { message: 'Logged out successfully' };
  }

  private async generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };

    // expiresIn expects seconds (number) — convert "7d"→604800, "30d"→2592000
    const toSeconds = (val: string): number => {
      const match = val.match(/^(\d+)([smhd])$/);
      if (!match) return 604800; // default 7d
      const n = parseInt(match[1], 10);
      const unit = match[2];
      const multiplier = { s: 1, m: 60, h: 3600, d: 86400 }[unit] ?? 1;
      return n * multiplier;
    };

    const accessExpiresIn = toSeconds(
      this.configService.get<string>('JWT_EXPIRES_IN') ?? '7d',
    );
    const refreshExpiresIn = toSeconds(
      this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '30d',
    );

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_SECRET'),
        expiresIn: accessExpiresIn,
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: refreshExpiresIn,
      }),
    ]);

    const hashedRefresh = await bcrypt.hash(refreshToken, 10);
    return { accessToken, refreshToken, hashedRefreshToken: hashedRefresh };
  }
}
