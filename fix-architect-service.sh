#!/bin/bash

# Create backup
echo "Creating backup..."
cp src/lib/services/architect.service.ts ./backups/architect.service.ts.bak 2>/dev/null || true

# Update the architect service
echo "Updating architect service..."
cat > src/lib/services/architect.service.ts << 'EOF'
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3 } from '../types/architect';

class ArchitectService {
  private static instance: ArchitectService;
  private readonly MODEL = 'claude-3-5-sonnet-latest';
  private apiKey: string;

  private constructor() {
    this.apiKey = process.env.CLAUDE_API_KEY || '';
    if (!this.apiKey) {
      throw new Error('CLAUDE_API_KEY environment variable is required');
    }
  }

  public static getInstance(): ArchitectService {
    if (!ArchitectService.instance) {
      ArchitectService.instance = new ArchitectService();
    }
    return ArchitectService.instance;
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

  private async callClaude(systemPrompt: string, userMessage: string) {
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
        messages: [{ role: 'user', content: userMessage }]
      })
    });

    if (!response.ok) {
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }

    try {
      const cleanedText = this.cleanJsonString(data.content[0].text);
      console.log('Cleaned Claude response:', cleanedText);
      return JSON.parse(cleanedText);
    } catch (e) {
      console.error('Failed to parse Claude response:', {
        error: e,
        rawResponse: data.content[0].text,
        cleanedResponse: this.cleanJsonString(data.content[0].text)
      });
      throw new Error(`Failed to parse Claude response: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  async generateLevel1(requirements: string[]): Promise<ArchitectLevel1> {
    const systemPrompt = `You are an expert software architect with decades of experience. Analyze the provided requirements and create a comprehensive architectural vision.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format (no markdown, no backticks):
{
  "visionText": "Your complete architectural analysis here"
}

Your analysis should cover:
1. System Architecture Overview
2. Implementation Strategy
3. Technical Considerations
4. Best Practices & Patterns
5. Potential Challenges
6. Integration Points
7. Scalability Considerations
8. Security Measures

Keep the response format exactly as specified - a single JSON object with one field "visionText".`;

    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }

  async generateLevel2(requirements: string[], visionText: string): Promise<ArchitectLevel2> {
    const systemPrompt = `You are an expert software architect. Based on the requirements and architectural vision, create a detailed folder structure for the project.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format (no markdown, no backticks):
{
  "rootFolder": {
    "name": "root directory name",
    "description": "root directory description",
    "purpose": "root directory purpose",
    "subfolders": [
      {
        "name": "subdirectory name",
        "description": "subdirectory description",
        "purpose": "subdirectory purpose",
        "subfolders": []
      }
    ]
  }
}

Focus on creating a clean, maintainable structure that follows best practices and the architectural vision.`;

    return this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}`);
  }

  async generateLevel3(
    requirements: string[],
    visionText: string,
    folderStructure: ArchitectLevel2
  ): Promise<ArchitectLevel3> {
    const systemPrompt = `You are an expert software architect. Create a detailed implementation plan for all required files in the project.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format (no markdown, no backticks):
{
  "implementationOrder": [
    {
      "name": "filename",
      "path": "file path",
      "type": "file type",
      "description": "file description",
      "purpose": "file purpose",
      "dependencies": ["dependency1", "dependency2"],
      "components": [
        {
          "name": "component name",
          "type": "component type",
          "purpose": "component purpose",
          "dependencies": ["dependency1"],
          "details": "implementation details"
        }
      ],
      "implementations": [
        {
          "name": "function/method name",
          "type": "function type",
          "description": "implementation description",
          "parameters": [
            {
              "name": "parameter name",
              "type": "parameter type",
              "description": "parameter description"
            }
          ],
          "returnType": "return type",
          "logic": "detailed implementation logic"
        }
      ],
      "additionalContext": "any additional implementation context"
    }
  ]
}

Order files based on dependencies, starting with the most independent files.`;

    return this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}

Folder Structure:
${JSON.stringify(folderStructure, null, 2)}`);
  }
}

export const architectService = ArchitectService.getInstance();
EOF
