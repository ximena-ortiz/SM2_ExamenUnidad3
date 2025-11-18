// Base practice entity
export { PracticeSession, PracticeType, PracticeStatus } from './practice-session.entity';

// Specific practice entities
export { VocabularyPractice } from './vocabulary-practice.entity';
export { QuizPractice } from './quiz-practice.entity';
export { ReadingPractice } from './reading-practice.entity';
export { InterviewPractice, InterviewType, ResponseQuality } from './interview-practice.entity';

// Approval entities
export { ApprovalRule } from './approval-rule.entity';
export { ApprovalEvaluation } from './approval-evaluation.entity';
export { ApprovalMetrics } from './approval-metrics.entity';

// Re-export all practice entities as a collection
export const PRACTICE_ENTITIES = [
  'PracticeSession',
  'VocabularyPractice',
  'QuizPractice',
  'ReadingPractice',
  'InterviewPractice',
];

// Re-export all approval entities as a collection
export const APPROVAL_ENTITIES = ['ApprovalRule', 'ApprovalEvaluation', 'ApprovalMetrics'];
