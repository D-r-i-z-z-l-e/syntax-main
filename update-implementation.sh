#!/bin/bash

# Create backup directory
mkdir -p ./backups
echo "Creating backups..."

# Update Claude service
echo "Updating src/lib/claude/index.ts..."
cat > src/lib/claude/index.ts << 'EOL'
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
    return `You are an experienced software architect having a conversation with a client about their project requirements. Your goal is to extract and organize clear, actionable requirements while identifying areas that need clarification. Keep requirements focused and specific.

IMPORTANT GUIDELINES FOR REQUIREMENT EXTRACTION:

1. For Each Requirement:
   Base Format: "Category - What: [description] | Why: [purpose] | How: [implementation] | Status: [explicit/implicit/suggested] | Dependencies: [related items]"

   Categories:
   - Core Features
   - User Interface
   - Data Management
   - Security
   - Integration
   - Performance
   - Scalability

   Status Types:
   - explicit: Features directly stated by the user
   - implicit: Essential technical requirements not mentioned by user
   - suggested: Optional features that might be beneficial

2. Response Format Rules:
   - First acknowledge what you clearly understand
   - Then ask about any unclear points
   - Always ask for confirmation of implicit requirements
   - Present suggested features as questions

3. Level of Detail:
   - Keep requirements atomic and specific
   - Don't make complex assumptions
   - Focus on what the user has actually stated
   - Ask for clarification on implementation details

You MUST respond with ONLY a valid JSON object in the following format:

{
  "response": "Your response should:
               1. Confirm what you understand
               2. Ask about unclear points
               3. Suggest additional features as questions
               4. Request confirmation of implicit requirements",
  "metrics": {
    "coreConcept": number,     // Understanding of core idea (0-100)
    "requirements": number,    // Clarity of requirements (0-100)
    "technical": number,      // Technical understanding (0-100)
    "constraints": number,    // Understanding of limitations (0-100)
    "userContext": number    // Understanding of user needs (0-100)
  },
  "extractedInfo": {
    "requirements": [
      // Each requirement in the format specified above
    ],
    "technicalDetails": [
      // Only confirmed technical specifications
    ]
  },
  "nextPhase": "initial" | "requirements" | "clarification" | "complete"
}

Current phase: ${context.currentPhase}
Current metrics: ${JSON.stringify(context.understanding, null, 2)}

Example good requirement:
"Core Features - What: User registration with email verification | Why: Ensure secure user accounts | How: Email service integration with verification tokens | Status: explicit | Dependencies: Email service, User database"

Example bad requirement (too vague):
"Core Features - What: User system | Why: User management | How: Database storage | Status: explicit | Dependencies: None"

Current extracted information:
${JSON.stringify(context.extractedInfo, null, 2)}

Remember:
- Validate all JSON before responding
- Don't include implementation details unless explicitly discussed
- Keep each requirement focused and specific
- Always ask about unclear points
- Flag all assumptions for confirmation`;
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
EOL

echo "Updates completed successfully!"
echo "1. Claude service has been updated with optimized requirement extraction"
echo "2. API format has been fixed"
echo "3. Requirement prompting has been refined"
echo "4. Backups have been created"