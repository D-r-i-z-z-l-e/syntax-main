#!/bin/bash

# Create backup of the original file
echo "Creating backup of Claude service..."
cp src/lib/claude/index.ts src/lib/claude/index.ts.bak 2>/dev/null || true

# Update the Claude service file with fixed API format
cat > src/lib/claude/index.ts << 'EOF'
import { Message } from '../stores/conversation';

export interface UnderstandingMetrics {
  coreConcept: number;
  requirements: number;
  technical: number;
  constraints: number;
  userContext: number;
}

export interface ConversationContext {
  currentPhase: 'initial' | 'requirements' | 'clarification' | 'complete';
  extractedInfo: {
    requirements?: string[];
    technicalDetails?: string[];
    constraints?: string[];
  };
  understanding: UnderstandingMetrics;
  overallUnderstanding: number;
}

export type ConversationPhase = ConversationContext['currentPhase'];

export interface ExtractedContext {
  requirements?: string[];
  technicalDetails?: string[];
  nextPhase?: ConversationPhase;
  understandingUpdate?: Partial<UnderstandingMetrics>;
  overallUnderstanding?: number;
}

export class ClaudeService {
  private static instance: ClaudeService;
  private apiKey: string;
  private readonly MODEL = 'claude-3-sonnet-20240229';

  private constructor() {
    this.apiKey = process.env.CLAUDE_API_KEY || '';
    if (!this.apiKey) {
      throw new Error('CLAUDE_API_KEY environment variable is required');
    }
  }

  public static getInstance(): ClaudeService {
    if (!ClaudeService.instance) {
      ClaudeService.instance = new ClaudeService();
    }
    return ClaudeService.instance;
  }

  private formatMessages(messages: Message[]): Array<{ role: string; content: string }> {
    return messages.map((msg) => ({
      role: msg.role === 'assistant' ? 'assistant' : 'user',
      content: msg.content,
    }));
  }

  public async continueConversation(
    messages: Message[],
    context: ConversationContext
  ): Promise<{
    response: string;
    extractedContext?: ExtractedContext;
  }> {
    try {
      const systemPrompt = this.generateSystemPrompt(context);
      const formattedMessages = this.formatMessages(messages);

      console.log('Sending request to Claude with system prompt:', systemPrompt);

      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
          'x-api-key': this.apiKey,
          'Authorization': `Bearer ${this.apiKey}`
        },
        body: JSON.stringify({
          model: this.MODEL,
          max_tokens: 4096,
          temperature: 0.7,
          system: systemPrompt,
          messages: formattedMessages
        })
      });

      if (!response.ok) {
        console.error('Claude API error:', {
          status: response.status,
          statusText: response.statusText,
          body: await response.text()
        });
        throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      
      if (!data.content || !data.content[0] || !data.content[0].text) {
        throw new Error('Invalid response format from Claude API');
      }

      let parsedResponse;
      try {
        parsedResponse = JSON.parse(data.content[0].text);
      } catch (e) {
        console.error('Failed to parse Claude response:', data.content[0].text);
        throw new Error('Failed to parse response from Claude');
      }

      const validatedMetrics = {
        coreConcept: Math.max(context.understanding.coreConcept, Math.min(100, parsedResponse.metrics.coreConcept)),
        requirements: Math.max(context.understanding.requirements, Math.min(100, parsedResponse.metrics.requirements)),
        technical: Math.max(context.understanding.technical, Math.min(100, parsedResponse.metrics.technical)),
        constraints: Math.max(context.understanding.constraints, Math.min(100, parsedResponse.metrics.constraints)),
        userContext: Math.max(context.understanding.userContext, Math.min(100, parsedResponse.metrics.userContext))
      };

      return {
        response: parsedResponse.response,
        extractedContext: {
          requirements: parsedResponse.extractedInfo.requirements,
          technicalDetails: parsedResponse.extractedInfo.technicalDetails,
          nextPhase: parsedResponse.nextPhase,
          understandingUpdate: validatedMetrics,
          overallUnderstanding: this.calculateOverallUnderstanding(validatedMetrics)
        }
      };

    } catch (error) {
      console.error('Error in Claude conversation:', error);
      throw error;
    }
  }

  private generateSystemPrompt(context: ConversationContext): string {
    return `You are an experienced software architect having a conversation with a client about their project requirements. Your goal is to extract and organize comprehensive, clear, and actionable requirements from the conversation.

IMPORTANT GUIDELINES FOR REQUIREMENT EXTRACTION:

1. Structure Requirements in Categories:
   - Core Features: Basic functionality that forms the foundation
   - User Interface: Specific UI components and interactions
   - User Management: Authentication, roles, permissions
   - Data Management: Storage, processing, validation rules
   - Integration Points: External services and APIs
   - Technical Constraints: Performance, security, compatibility
   - Business Rules: Domain-specific logic and workflows

2. Each Requirement Must Include:
   - What: Clear description of the feature/requirement
   - Why: Business value or purpose
   - How: Basic implementation details or constraints
   - Dependencies: Related features or prerequisites

3. Level of Detail:
   - Start with high-level features then break them down
   - Include specific acceptance criteria
   - Define clear boundaries and limitations
   - Specify any required validations or business rules
   - Include error scenarios and edge cases

4. Requirements Should Be:
   - Self-contained (understandable without context)
   - Specific and measurable
   - Technically actionable
   - Prioritized (core vs optional)
   - Cross-referenced with dependencies

You MUST respond with ONLY a valid JSON object in the following format:

{
  "response": "Your response message here",
  "metrics": {
    "coreConcept": number,       // Understanding of the main idea (0-100)
    "requirements": number,       // Clarity of requirements (0-100)
    "technical": number,         // Technical detail understanding (0-100)
    "constraints": number,       // Understanding of limitations (0-100)
    "userContext": number        // Understanding of user needs (0-100)
  },
  "extractedInfo": {
    "requirements": [
      // Each requirement should follow this format:
      "Category - What: [description] | Why: [purpose] | How: [implementation] | Dependencies: [related items]"
    ],
    "technicalDetails": [
      // Technical specifications and constraints
    ]
  },
  "nextPhase": "initial" | "requirements" | "clarification" | "complete"
}

Current phase: ${context.currentPhase}
Current metrics: ${JSON.stringify(context.understanding, null, 2)}

Example requirement format:
"User Management - What: User registration system with email verification | Why: Ensure legitimate user accounts | How: Email service integration, secure password storage, verification tokens | Dependencies: Email service, user database schema"

Current extracted information:
${JSON.stringify(context.extractedInfo, null, 2)}

Remember:
- Keep previous metric values as minimum baseline
- Only increase metrics when new information is provided
- Always include implementation details for each requirement
- Requirements must be self-contained and fully understandable
- Validate JSON before responding`;
  }

  private calculateOverallUnderstanding(metrics: UnderstandingMetrics): number {
    const weights = {
      coreConcept: 0.3,
      requirements: 0.25,
      technical: 0.2,
      constraints: 0.15,
      userContext: 0.1
    };

    return Math.round(
      weights.coreConcept * metrics.coreConcept +
      weights.requirements * metrics.requirements +
      weights.technical * metrics.technical +
      weights.constraints * metrics.constraints +
      weights.userContext * metrics.userContext
    );
  }
}
EOF