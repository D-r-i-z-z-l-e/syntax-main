import { Message } from '../stores/conversation';

export interface UnderstandingMetrics {
  coreConcept: number;      // Understanding of the main project idea (0-100)
  requirements: number;     // Clarity of functional requirements (0-100)
  technical: number;        // Understanding of technical needs (0-100)
  constraints: number;      // Understanding of limitations and constraints (0-100)
  userContext: number;      // Understanding of user/business context (0-100)
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
          max_tokens: 1024,
          temperature: 0.7,
          system: systemPrompt,
          messages: formattedMessages
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        console.error('Claude API error details:', errorData);
        throw new Error(`Claude API error: ${response.statusText}`);
      }

      const data = await response.json();
      const responseContent = data.content[0].text;
      console.log('Raw Claude response:', responseContent);

      try {
        // Parse the JSON response, handling potential control characters
        const cleanedContent = responseContent.replace(/[\n\r\t]/g, ' ').replace(/\s+/g, ' ');
        const parsedResponse = JSON.parse(cleanedContent);
        console.log('Parsed response:', parsedResponse);
        
        // Validate the response structure
        if (!parsedResponse.response || !parsedResponse.metrics || !parsedResponse.extractedInfo) {
          throw new Error('Invalid response structure');
        }

        // Ensure metrics are within bounds and at least at current levels
        const validatedMetrics = {
          coreConcept: Math.max(context.understanding.coreConcept, Math.min(100, parsedResponse.metrics.coreConcept)),
          requirements: Math.max(context.understanding.requirements, Math.min(100, parsedResponse.metrics.requirements)),
          technical: Math.max(context.understanding.technical, Math.min(100, parsedResponse.metrics.technical)),
          constraints: Math.max(context.understanding.constraints, Math.min(100, parsedResponse.metrics.constraints)),
          userContext: Math.max(context.understanding.userContext, Math.min(100, parsedResponse.metrics.userContext))
        };

        // Calculate overall understanding
        const overallUnderstanding = this.calculateOverallUnderstanding(validatedMetrics);

        return {
          response: parsedResponse.response,
          extractedContext: {
            requirements: parsedResponse.extractedInfo.requirements,
            technicalDetails: parsedResponse.extractedInfo.technicalDetails,
            nextPhase: parsedResponse.nextPhase,
            understandingUpdate: validatedMetrics,
            overallUnderstanding
          }
        };
      } catch (parseError) {
        console.error('Error parsing Claude response:', parseError);
        console.error('Invalid response content:', responseContent);
        
        // Try to extract just the response text if JSON parsing fails
        const responseMatch = responseContent.match(/"response"\s*:\s*"([^"]+)"/);
        const responseText = responseMatch ? responseMatch[1] : responseContent;
        
        return {
          response: responseText,
          extractedContext: {
            nextPhase: context.currentPhase,
            understandingUpdate: context.understanding,
            overallUnderstanding: context.overallUnderstanding
          }
        };
      }
    } catch (error) {
      console.error('Error in Claude conversation:', error);
      if (error instanceof Error) {
        if ('status' in error && error.status === 429) {
          throw new Error('Rate limit exceeded. Please try again in a few moments.');
        }
        throw new Error(`API Error: ${error.message}`);
      }
      throw error;
    }
  }

  private generateSystemPrompt(context: ConversationContext): string {
    return `You are an experienced software architect having a conversation with a client about their project requirements. Your goal is to understand their vision and help shape it into a comprehensive solution.

IMPORTANT: You MUST respond with ONLY a valid JSON object in the following format with no additional text before or after:

{
  "response": "Your response message here",
  "metrics": {
    "coreConcept": 30,      // 0-100 increase when core purpose is clarified
    "requirements": 25,     // 0-100 increase with functional requirements
    "technical": 20,       // 0-100 increase with technical details
    "constraints": 15,     // 0-100 increase with limitations/boundaries
    "userContext": 10      // 0-100 increase with business context
  },
  "extractedInfo": {
    "requirements": [
      // Each requirement should follow this format:
      // "[Core Feature]: [Detailed description explaining what it does and how it connects to the main purpose]"
      // Example:
      // "Task Management Core: A real-time collaborative system allowing teams to create, assign, and track tasks through customizable Kanban boards, serving as the central hub for team coordination"
    ],
    "technicalDetails": [
      // Each technical detail should include implementation context
      // Example:
      // "Real-time Collaboration: WebSocket-based system to enable instant updates across all connected clients"
    ]
  },
  "nextPhase": "initial"    // one of: initial, requirements, clarification, complete
}

Current phase: ${context.currentPhase}
Current metrics: ${JSON.stringify(context.understanding, null, 2)}

Guidelines for your response:
1. Ask ONE focused question about the lowest-scoring aspect
2. Acknowledge what you understand before asking
3. When extracting requirements:
   - Start with the core application type and primary purpose
   - Connect each feature to how it supports the main goal
   - Provide context for why each requirement matters
   - Group related features together in the description
4. When identifying technical details:
   - Include implementation context
   - Explain how technical choices support requirements
5. Keep previous metric values as minimum baseline
6. Only increase metrics when new information is provided

Current extracted information:
${JSON.stringify(context.extractedInfo, null, 2)}

Remember:
- Response MUST be ONLY the JSON object
- No text before or after the JSON
- All metrics must be numbers 0-100
- Keep metrics at least at current values
- Validate JSON before responding`;
  }

  private calculateOverallUnderstanding(metrics: UnderstandingMetrics): number {
    const weights = {
      coreConcept: 0.3,    // Core concept is most important
      requirements: 0.25,   // Functional requirements are next
      technical: 0.2,      // Technical understanding
      constraints: 0.15,    // Constraints and limitations
      userContext: 0.1     // User/business context
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
