import {
  Controller,
  Post,
  Get,
  Put,
  Param,
  Body,
  UseGuards,
  Request,
  Logger,
  HttpStatus,
  HttpCode,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
  ApiExtraModels,
  getSchemaPath,
} from '@nestjs/swagger';
import { ThrottlerGuard } from '@nestjs/throttler';
import { EnhancedJwtGuard } from '../../../shared/guards/enhanced-jwt.guard';
import { AuthenticatedRequest } from '../../../shared/types/request.types';

// DTOs
import {
  CreateInterviewPracticeDto,
  UpdateInterviewPracticeDto,
  InterviewPracticeResponseDto,
  InterviewStatsDto,
  AnswerInterviewQuestionDto,
  ConversationFlowDto,
  AIEvaluationDto,
} from '../../../application/dtos/interview-practice.dto';

@ApiTags('Practices - Interview')
@Controller('practices/interview')
@UseGuards(ThrottlerGuard, EnhancedJwtGuard)
@ApiBearerAuth()
@ApiExtraModels(
  CreateInterviewPracticeDto,
  UpdateInterviewPracticeDto,
  InterviewPracticeResponseDto,
  InterviewStatsDto,
)
export class InterviewPracticeController {
  private readonly logger = new Logger(InterviewPracticeController.name);

  constructor() {} // TODO: Inject use cases when implemented

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create new interview practice session',
    description: 'Start a new interview practice session for the authenticated user',
  })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: 'Interview practice session created successfully',
    schema: {
      $ref: getSchemaPath(InterviewPracticeResponseDto),
    },
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid input data',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async createInterviewPractice(
    @Request() req: AuthenticatedRequest,
    @Body() _createDto: CreateInterviewPracticeDto,
  ): Promise<InterviewPracticeResponseDto> {
    this.logger.log(`Creating interview practice for user: ${req.user.userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get interview practice session',
    description: 'Retrieve a specific interview practice session by ID',
  })
  @ApiParam({
    name: 'id',
    description: 'Practice session ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Interview practice session retrieved successfully',
    schema: {
      $ref: getSchemaPath(InterviewPracticeResponseDto),
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Practice session not found',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async getInterviewPractice(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<InterviewPracticeResponseDto> {
    this.logger.log(`Getting interview practice ${id} for user: ${req.user.userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Update interview practice session',
    description: 'Update progress and data for an interview practice session',
  })
  @ApiParam({
    name: 'id',
    description: 'Practice session ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Interview practice session updated successfully',
    schema: {
      $ref: getSchemaPath(InterviewPracticeResponseDto),
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Practice session not found',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async updateInterviewPractice(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() _updateDto: UpdateInterviewPracticeDto,
  ): Promise<InterviewPracticeResponseDto> {
    this.logger.log(`Updating interview practice ${id} for user: ${req.user.userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Post(':id/answer-question')
  @ApiOperation({
    summary: 'Answer interview question',
    description: 'Record an answer to an interview question with AI evaluation',
  })
  @ApiParam({
    name: 'id',
    description: 'Practice session ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Interview answer recorded successfully',
    schema: {
      $ref: getSchemaPath(InterviewPracticeResponseDto),
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Practice session not found',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async answerInterviewQuestion(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() _answerDto: AnswerInterviewQuestionDto,
  ): Promise<InterviewPracticeResponseDto> {
    this.logger.log(`Recording interview answer for practice ${id}, user: ${req.user.userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Post(':id/update-conversation')
  @ApiOperation({
    summary: 'Update conversation flow',
    description: 'Update the conversation flow and interaction data',
  })
  @ApiParam({
    name: 'id',
    description: 'Practice session ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Conversation flow updated successfully',
    schema: {
      $ref: getSchemaPath(InterviewPracticeResponseDto),
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Practice session not found',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async updateConversationFlow(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() _conversationDto: ConversationFlowDto,
  ): Promise<InterviewPracticeResponseDto> {
    this.logger.log(`Updating conversation flow for practice ${id}, user: ${req.user.userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Post(':id/ai-evaluation')
  @ApiOperation({
    summary: 'Request AI evaluation',
    description: 'Request AI evaluation of the interview performance',
  })
  @ApiParam({
    name: 'id',
    description: 'Practice session ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'AI evaluation completed successfully',
    schema: {
      $ref: getSchemaPath(AIEvaluationDto),
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Practice session not found',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async requestAIEvaluation(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<AIEvaluationDto> {
    this.logger.log(`Requesting AI evaluation for practice ${id}, user: ${req.user.userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Get('user/:userId/sessions')
  @ApiOperation({
    summary: 'Get user interview practice sessions',
    description: 'Retrieve all interview practice sessions for a specific user',
  })
  @ApiParam({
    name: 'userId',
    description: 'User ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiQuery({
    name: 'interviewType',
    description: 'Filter by interview type',
    type: 'string',
    required: false,
  })
  @ApiQuery({
    name: 'completed',
    description: 'Filter by completion status',
    type: 'boolean',
    required: false,
  })
  @ApiQuery({
    name: 'minScore',
    description: 'Filter by minimum overall score',
    type: 'number',
    required: false,
  })
  @ApiQuery({
    name: 'limit',
    description: 'Number of sessions to retrieve',
    type: 'number',
    required: false,
    example: 10,
  })
  @ApiQuery({
    name: 'offset',
    description: 'Number of sessions to skip',
    type: 'number',
    required: false,
    example: 0,
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'User interview practice sessions retrieved successfully',
    schema: {
      type: 'array',
      items: {
        $ref: getSchemaPath(InterviewPracticeResponseDto),
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async getUserInterviewSessions(
    @Request() _req: AuthenticatedRequest,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query('interviewType') _interviewType?: string,
    @Query('completed') _completed?: boolean,
    @Query('minScore') _minScore?: number,
    @Query('limit') _limit?: number,
    @Query('offset') _offset?: number,
  ): Promise<InterviewPracticeResponseDto[]> {
    this.logger.log(`Getting interview sessions for user: ${userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Get('user/:userId/stats')
  @ApiOperation({
    summary: 'Get user interview statistics',
    description: 'Retrieve comprehensive interview performance statistics for a user',
  })
  @ApiParam({
    name: 'userId',
    description: 'User ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiQuery({
    name: 'timeframe',
    description: 'Time frame for statistics (7d, 30d, 90d, all)',
    type: 'string',
    required: false,
    example: '30d',
  })
  @ApiQuery({
    name: 'interviewType',
    description: 'Filter by interview type',
    type: 'string',
    required: false,
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'User interview statistics retrieved successfully',
    schema: {
      $ref: getSchemaPath(InterviewStatsDto),
    },
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async getUserInterviewStats(
    @Request() _req: AuthenticatedRequest,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query('timeframe') _timeframe?: string,
    @Query('interviewType') _interviewType?: string,
  ): Promise<InterviewStatsDto> {
    this.logger.log(`Getting interview stats for user: ${userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }

  @Get(':id/performance-summary')
  @ApiOperation({
    summary: 'Get interview performance summary',
    description: 'Get detailed performance summary for a completed interview session',
  })
  @ApiParam({
    name: 'id',
    description: 'Practice session ID',
    type: 'string',
    format: 'uuid',
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Performance summary retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        overallScore: { type: 'number' },
        fluencyScore: { type: 'number' },
        grammarScore: { type: 'number' },
        vocabularyScore: { type: 'number' },
        pronunciationScore: { type: 'number' },
        confidenceScore: { type: 'number' },
        strengths: { type: 'array', items: { type: 'string' } },
        areasForImprovement: { type: 'array', items: { type: 'string' } },
        recommendations: { type: 'array', items: { type: 'string' } },
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Practice session not found',
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'User not authenticated',
  })
  async getPerformanceSummary(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    this.logger.log(`Getting performance summary for practice ${id}, user: ${req.user.userId}`);

    // TODO: Implement use case
    throw new Error('Not implemented yet');
  }
}
