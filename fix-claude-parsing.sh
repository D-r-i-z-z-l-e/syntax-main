#!/bin/bash

# Create backup directory
mkdir -p ./backups

# Backup original file
echo "Creating backup..."
cp src/lib/claude/index.ts ./backups/index.ts.bak 2>/dev/null || true

# Update the Claude service file
echo "Updating Claude service..."
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

interface RequirementItem {
  category: string;
  what: string;
  why: string;
  how: string;
  status: 'explicit' | 'implicit' | 'suggested';
  dependencies: string;
}

export class ClaudeService {
  private static instance: ClaudeService;
  private apiKey: string;
  private readonly MODEL = 'claude-3-5-sonnet-latest';

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

  private formatRequirement(req: RequirementItem): string {
    return `${req.category} - What: ${req.what} | Why: ${req.why} | How: ${req.how} | Status: ${req.status} | Dependencies: ${req.dependencies}`;
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
        const contentText = data.content[0].text;
        parsedResponse = JSON.parse(contentText);

        // Validate response structure
        if (!parsedResponse.response || !parsedResponse.extractedContext) {
          throw new Error('Invalid response structure');
        }

        // Handle requirements
        let formattedRequirements: string[] = [];
        if (Array.isArray(parsedResponse.extractedContext.requirements)) {
          formattedRequirements = parsedResponse.extractedContext.requirements.map((req: RequirementItem) => 
            this.formatRequirement(req)
          );
        }

        // Process metrics, defaulting to current values if not provided
        const metrics = parsedResponse.extractedContext.understandingUpdate || {};
        const validatedMetrics = {
          coreConcept: Math.max(context.understanding.coreConcept, Math.min(100, metrics.coreConcept || 0)),
          requirements: Math.max(context.understanding.requirements, Math.min(100, metrics.requirements || 0)),
          technical: Math.max(context.understanding.technical, Math.min(100, metrics.technical || 0)),
          constraints: Math.max(context.understanding.constraints, Math.min(100, metrics.constraints || 0)),
          userContext: Math.max(context.understanding.userContext, Math.min(100, metrics.userContext || 0))
        };

        return {
          response: parsedResponse.response,
          extractedContext: {
            requirements: formattedRequirements,
            technicalDetails: parsedResponse.extractedContext.technicalDetails || [],
            nextPhase: parsedResponse.extractedContext.nextPhase || context.currentPhase,
            understandingUpdate: validatedMetrics,
            overallUnderstanding: this.calculateOverallUnderstanding(validatedMetrics)
          }
        };

      } catch (e) {
        console.error('Parse error details:', e);
        console.error('Failed to parse Claude response:', data.content[0].text);
        throw new Error(`Failed to parse response from Claude: ${e.message}`);
      }

    } catch (error) {
      console.error('Error in Claude conversation:', error);
      throw error;
    }
  }

  private generateSystemPrompt(context: ConversationContext): string {
    return `You are an experienced software architect having a conversation with a client about their project requirements. Your goal is to extract and organize clear, actionable requirements while identifying areas that need clarification.

IMPORTANT: You must respond with a JSON object in exactly this format:
{
  "response": "Your response message here with questions and clarifications",
  "extractedContext": {
    "requirements": [
      {
        "category": "Core Features|User Interface|Data Management|Security|Integration|Performance",
        "what": "Clear description of the requirement",
        "why": "Business value or purpose",
        "how": "Implementation approach",
        "status": "explicit|implicit|suggested",
        "dependencies": "Related components or requirements"
      }
    ],
    "technicalDetails": [
      "Technical specification 1",
      "Technical specification 2"
    ],
    "nextPhase": "initial|requirements|clarification|complete",
    "understandingUpdate": {
      "coreConcept": 0-100,
      "requirements": 0-100,
      "technical": 0-100,
      "constraints": 0-100,
      "userContext": 0-100
    }
  }
}

Guidelines for Response:
1. response field should:
   - Confirm what you clearly understand
   - Ask specific questions about unclear points
   - Present suggested features as questions
   - Request confirmation of implicit requirements

2. requirements should:
   - Be specific and actionable
   - Include only confirmed details
   - Mark assumptions as "implicit"
   - Include dependencies

3. Categories:
   - Core Features: Essential functionality
   - User Interface: UI/UX elements
   - Data Management: Data handling and storage
   - Security: Security features and compliance
   - Integration: External system connections
   - Performance: Speed and efficiency features

Current phase: ${context.currentPhase}
Current metrics: ${JSON.stringify(context.understanding, null, 2)}

Current requirements:
${JSON.stringify(context.extractedInfo.requirements, null, 2)}

Remember:
- Always use the exact JSON format specified
- Make each requirement self-contained
- Only increase metrics for explicit information
- Ask for clarification on unclear points`;
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
