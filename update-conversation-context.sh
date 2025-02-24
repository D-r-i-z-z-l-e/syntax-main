#!/bin/bash

# Create backup directory
mkdir -p ./backups

# Backup original file
echo "Creating backup..."
cp src/lib/claude/index.ts ./backups/index.ts.bak 2>/dev/null || true

# Update the Claude service with improved conversation context
echo "Updating Claude service..."
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

  private formatConversationHistory(messages: Message[]): string {
    if (!messages.length) return 'No previous conversation.';
    
    return messages.map((msg, index) => {
      const role = msg.role.toUpperCase();
      const timestamp = new Date(msg.timestamp).toLocaleTimeString();
      return `Message ${index + 1} (${timestamp})\n${role}: ${msg.content}`;
    }).join('\n\n');
  }

  private cleanJsonString(str: string): string {
    // Remove any markdown code block indicators
    str = str.replace(/^```json\s*|\s*```$/g, '');
    str = str.replace(/^`|`$/g, '');
    
    // Handle escape sequences and control characters
    str = str.replace(/[\n\r\t]/g, ' '); // Replace newlines, returns, tabs with space
    str = str.replace(/\s+/g, ' '); // Collapse multiple spaces
    str = str.replace(/\\([^"\\\/bfnrt])/g, '$1'); // Remove invalid escape sequences
    
    return str;
  }

  private generateSystemPrompt(context: ConversationContext, messages: Message[]): string {
    const conversationHistory = this.formatConversationHistory(messages);
    const existingRequirements = context.extractedInfo.requirements?.length 
      ? context.extractedInfo.requirements.map(req => `- ${req}`).join('\n')
      : 'No requirements extracted yet';
    const technicalDetails = context.extractedInfo.technicalDetails?.length
      ? context.extractedInfo.technicalDetails.map(detail => `- ${detail}`).join('\n')
      : 'No technical details extracted yet';

    return `You are an experienced software architect having a conversation with a client about their project requirements. Your role is to understand their needs, extract clear requirements, and provide architectural guidance. Consider the entire conversation history when providing responses.

CONVERSATION HISTORY:
${conversationHistory}

CURRENT PROJECT STATUS:
Phase: ${context.currentPhase}

Understanding Metrics:
- Core Concept: ${context.understanding.coreConcept}%
- Requirements: ${context.understanding.requirements}%
- Technical: ${context.understanding.technical}%
- Constraints: ${context.understanding.constraints}%
- User Context: ${context.understanding.userContext}%

Extracted Requirements:
${existingRequirements}

Technical Details:
${technicalDetails}

RESPONSE GUIDELINES:

1. Response Format:
You MUST respond with ONLY a valid JSON object in this format:
{
  "response": "Your response message here",
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

2. Response Strategy:
- Review the entire conversation history for context
- Build upon previously gathered requirements
- Maintain consistency with earlier discussions
- Only increase understanding metrics for new information
- Ask specific questions about unclear points
- Reference previous messages when relevant
- Acknowledge existing understanding before asking new questions

3. Requirements Extraction:
- Mark source of requirements (explicit, implicit, suggested)
- Include implementation approach
- Reference dependencies
- Maintain traceability to conversation

Remember:
- Keep responses focused and specific
- Validate JSON structure
- Ensure consistent requirement references
- Consider full conversation context
- Track requirement dependencies
- Build upon existing knowledge`;
  }

  public async continueConversation(
    messages: Message[],
    context: ConversationContext
  ): Promise<{
    response: string;
    extractedContext?: ExtractedContext;
  }> {
    try {
      const systemPrompt = this.generateSystemPrompt(context, messages);
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
        // Clean and parse the response
        const cleanedText = this.cleanJsonString(data.content[0].text);
        parsedResponse = JSON.parse(cleanedText);

        // Validate response structure
        if (!parsedResponse || !parsedResponse.response || !parsedResponse.extractedContext) {
          throw new Error('Invalid response structure');
        }

        // Ensure requirements is an array if it exists
        if (parsedResponse.extractedContext.requirements) {
          // Convert requirements to formatted strings if they're objects
          const formattedRequirements = parsedResponse.extractedContext.requirements.map((req: any) => {
            if (typeof req === 'object') {
              return `${req.category} - What: ${req.what} | Why: ${req.why} | How: ${req.how} | Status: ${req.status} | Dependencies: ${req.dependencies}`;
            }
            return req;
          });
          parsedResponse.extractedContext.requirements = formattedRequirements;
        }

        // Ensure technicalDetails is an array
        if (!Array.isArray(parsedResponse.extractedContext.technicalDetails)) {
          parsedResponse.extractedContext.technicalDetails = [];
        }

        // Process metrics
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
            requirements: parsedResponse.extractedContext.requirements || [],
            technicalDetails: parsedResponse.extractedContext.technicalDetails || [],
            nextPhase: parsedResponse.extractedContext.nextPhase || context.currentPhase,
            understandingUpdate: validatedMetrics,
            overallUnderstanding: this.calculateOverallUnderstanding(validatedMetrics)
          }
        };

      } catch (e: unknown) {
        const error = e instanceof Error ? e : new Error(String(e));
        console.error('Parse error details:', {
          error: error.message,
          rawResponse: data.content[0].text,
          cleanedResponse: this.cleanJsonString(data.content[0].text)
        });
        throw new Error(`Failed to parse response from Claude: ${error.message}`);
      }

    } catch (error) {
      console.error('Error in Claude conversation:', error);
      throw error;
    }
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
