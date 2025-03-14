#!/bin/bash

# Create a backup of the files we're going to modify
echo "Creating backups of the files to be modified..."
cp src/app/api/architect/route.ts src/app/api/architect/route.ts.bak
cp src/lib/stores/conversation.ts src/lib/stores/conversation.ts.bak

# Update architect/route.ts with additional logging
echo "Updating src/app/api/architect/route.ts with logging..."
cat > src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;
    
    // Add detailed logging
    console.log('Architect API request:', {
      level,
      requirementsLength: requirements?.length,
      hasVisionText: !!visionText,
      hasFolderStructure: !!folderStructure,
      folderStructureDetails: folderStructure ? 
        {
          hasRootFolder: !!folderStructure.rootFolder,
          rootFolderName: folderStructure.rootFolder?.name
        } : 'No folder structure'
    });
    
    if (!requirements || !Array.isArray(requirements)) {
      console.error('Missing requirements array');
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }
    
    let result;
    switch (level) {
      case 1:
        result = await architectService.generateLevel1(requirements);
        break;
      case 2:
        if (!visionText) {
          console.error('Missing vision text for level 2');
          return NextResponse.json({ error: 'Vision text is required for level 2' }, { status: 400 });
        }
        result = await architectService.generateLevel2(requirements, visionText);
        break;
      case 3:
        if (!visionText) {
          console.error('Missing vision text for level 3');
          return NextResponse.json({ error: 'Vision text is required for level 3' }, { status: 400 });
        }
        
        console.log('Level 3 folderStructure check:', {
          folderStructure: JSON.stringify(folderStructure, null, 2),
          type: typeof folderStructure,
          hasRootFolder: folderStructure && typeof folderStructure === 'object' && 'rootFolder' in folderStructure
        });
        
        if (!folderStructure || !folderStructure.rootFolder) {
          console.error('Missing folder structure for level 3', { folderStructure });
          return NextResponse.json({ error: 'Missing required input for level 3: folder structure' }, { status: 400 });
        }
        
        result = await architectService.generateLevel3(requirements, visionText, folderStructure);
        break;
      default:
        console.error('Invalid architect level:', level);
        return NextResponse.json({ error: 'Invalid architect level' }, { status: 400 });
    }
    
    console.log('Architect API success result:', { 
      resultType: typeof result,
      hasResult: !!result 
    });
    
    return NextResponse.json(result);
  } catch (error) {
    console.error('Error in architect API:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate architect output' },
      { status: 500 }
    );
  }
}
EOF

# Update conversation.ts with additional logging
echo "Updating src/lib/stores/conversation.ts with logging..."
cat > src/lib/stores/conversation.ts << 'EOF'
import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, ArchitectState } from '../types/architect';
export interface Message {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}
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
export interface ConversationStore {
  messages: Message[];
  context: ConversationContext;
  isLoading: boolean;
  error: string | null;
  projectId: string | null;
  conversationId: string | null;
  projectStructure: any | null;
  isGeneratingStructure: boolean;
  architect: ArchitectState;
  initializeProject: () => Promise<void>;
  loadConversation: (conversationId: string) => Promise<void>;
  sendMessage: (content: string) => Promise<void>;
  generateArchitectLevel1: () => Promise<void>;
  generateArchitectLevel2: () => Promise<void>;
  generateArchitectLevel3: () => Promise<void>;
  generateProjectStructure: (implementationPlan: ArchitectLevel3) => Promise<void>;
  reset: () => void;
}
export const useConversationStore = create<ConversationStore>((set, get) => ({
  messages: [],
  context: {
    currentPhase: 'initial',
    extractedInfo: {
      requirements: [],
      technicalDetails: [],
      constraints: [],
    },
    understanding: {
      coreConcept: 0,
      requirements: 0,
      technical: 0,
      constraints: 0,
      userContext: 0,
    },
    overallUnderstanding: 0,
  },
  isLoading: false,
  error: null,
  projectId: null,
  conversationId: null,
  projectStructure: null,
  isGeneratingStructure: false,
  architect: {
    level1Output: null,
    level2Output: null,
    level3Output: null,
    currentLevel: 1,
    isThinking: false,
    error: null
  },
  generateArchitectLevel1: async () => {
    const state = get();
    const requirements = state.context.extractedInfo.requirements;
    if (!requirements?.length) {
      set(state => ({
        architect: {
          ...state.architect,
          error: 'No requirements available for the architect'
        }
      }));
      return;
    }
    try {
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 1,
          level1Output: null,
          level2Output: null,
          level3Output: null
        }
      }));
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          level: 1,
          requirements
        }),
      });
      if (!response.ok) {
        throw new Error(`Failed to generate architect output: ${response.statusText}`);
      }
      const data = await response.json();
      console.log('Level 1 response:', data);
      set(state => ({
        architect: {
          ...state.architect,
          level1Output: data,
          currentLevel: 2,
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('Error generating architect level 1:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate architect output',
          isThinking: false
        }
      }));
    }
  },
  generateArchitectLevel2: async () => {
    const state = get();
    const { level1Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    if (!level1Output?.visionText || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!requirements?.length) missing.push('requirements');
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required input for level 2: ${missing.join(', ')}`
        }
      }));
      return;
    }
    try {
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          level2Output: null,
          level3Output: null
        }
      }));
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          level: 2,
          requirements,
          visionText: level1Output.visionText
        }),
      });
      if (!response.ok) {
        throw new Error(`Failed to generate folder structure: ${response.statusText}`);
      }
      const data = await response.json();
      console.log('Level 2 response:', data);
      if (!data.rootFolder) {
        throw new Error('Invalid folder structure response');
      }
      set(state => ({
        architect: {
          ...state.architect,
          level2Output: data,
          currentLevel: 3,
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('Error generating architect level 2:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate folder structure',
          isThinking: false
        }
      }));
    }
  },
  generateArchitectLevel3: async () => {
    const state = get();
    const { level1Output, level2Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Level 3 input check:', {
      hasLevel1Output: !!level1Output,
      visionText: level1Output?.visionText?.substring(0, 50),
      hasLevel2Output: !!level2Output,
      rootFolder: level2Output?.rootFolder ? {
        name: level2Output.rootFolder.name,
        hasSubfolders: Array.isArray(level2Output.rootFolder.subfolders)
      } : 'No rootFolder',
      requirementsCount: requirements?.length
    });
    
    if (!level1Output?.visionText || !level2Output?.rootFolder || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!level2Output?.rootFolder) missing.push('folder structure');
      if (!requirements?.length) missing.push('requirements');
      
      console.error('Missing required inputs for level 3:', missing);
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required input for level 3: ${missing.join(', ')}`
        }
      }));
      return;
    }
    try {
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          level3Output: null
        }
      }));
      
      const requestBody = {
        level: 3,
        requirements,
        visionText: level1Output.visionText,
        folderStructure: level2Output
      };
      
      console.log('Level 3 request payload:', JSON.stringify(requestBody, null, 2));
      
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(requestBody),
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Level 3 API error response:', {
          status: response.status,
          statusText: response.statusText,
          body: errorText
        });
        throw new Error(`Failed to generate implementation plan: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Level 3 response:', data);
      
      set(state => ({
        architect: {
          ...state.architect,
          level3Output: data,
          currentLevel: 3,
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('Error generating architect level 3:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate implementation plan',
          isThinking: false
        }
      }));
    }
  },
  generateProjectStructure: async (implementationPlan: ArchitectLevel3) => {
    try {
      set({ isGeneratingStructure: true, error: null });
      const state = get();
      const requirements = state.context.extractedInfo.requirements;
      const { level1Output, level2Output } = state.architect;
      if (!requirements?.length || !level1Output || !level2Output || !implementationPlan) {
        throw new Error('Missing required inputs for project structure generation');
      }
      const response = await fetch('/api/project-structure', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          requirements,
          architectVision: level1Output.visionText,
          folderStructure: level2Output,
          implementationPlan
        }),
      });
      if (!response.ok) {
        throw new Error(`Failed to generate project structure: ${response.statusText}`);
      }
      const data = await response.json();
      set({ 
        projectStructure: data.structure, 
        isGeneratingStructure: false,
        architect: {
          ...state.architect,
          currentLevel: 1,
          level1Output: null,
          level2Output: null,
          level3Output: null,
          isThinking: false,
          error: null
        }
      });
    } catch (error) {
      console.error('Error generating project structure:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to generate project structure',
        isGeneratingStructure: false,
      });
    }
  },
  initializeProject: async () => {
    try {
      set({ isLoading: true, error: null });
      const response = await fetch('/api/project', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'New Project' }),
      });
      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }
      const data = await response.json();
      console.log('Project initialized:', data);
      set({
        projectId: data.project.id,
        conversationId: data.conversation.id,
        messages: [],
        isLoading: false,
      });
    } catch (error) {
      console.error('Error initializing project:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to initialize project',
        isLoading: false,
      });
    }
  },
  loadConversation: async (conversationId: string) => {
    try {
      set({ isLoading: true, error: null });
      const response = await fetch(`/api/conversation?id=${conversationId}`, {
        method: 'GET',
      });
      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }
      const data = await response.json();
      set({
        messages: data.messages.map((msg: any) => ({
          id: msg.id,
          conversationId: msg.conversationId,
          role: msg.role,
          content: msg.content,
          timestamp: new Date(msg.createdAt).getTime(),
        })),
        conversationId,
        isLoading: false,
      });
    } catch (error) {
      console.error('Error loading conversation:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to load conversation',
        isLoading: false,
      });
    }
  },
  sendMessage: async (content: string) => {
    try {
      set({ isLoading: true, error: null });
      
      const conversationId = get().conversationId || uuidv4();
      const newMessage: Message = {
        id: uuidv4(),
        conversationId,
        role: 'user',
        content,
        timestamp: Date.now(),
      };
      set(state => ({
        messages: [...state.messages, newMessage],
      }));
      const response = await fetch('/api/conversation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: [...get().messages, newMessage],
          context: get().context,
        }),
      });
      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }
      const data = await response.json();
      console.log('API Response:', data);
      if (data.error) {
        throw new Error(data.error);
      }
      const assistantMessage: Message = {
        id: uuidv4(),
        conversationId,
        role: 'assistant',
        content: data.response,
        timestamp: Date.now(),
      };
      set(state => ({
        messages: [...state.messages, assistantMessage],
        context: {
          ...state.context,
          currentPhase: data.extractedContext.nextPhase || state.context.currentPhase,
          extractedInfo: {
            requirements: [
              ...(state.context.extractedInfo.requirements || []),
              ...(data.extractedContext.requirements || []),
            ],
            technicalDetails: [
              ...(state.context.extractedInfo.technicalDetails || []),
              ...(data.extractedContext.technicalDetails || []),
            ],
            constraints: state.context.extractedInfo.constraints || [],
          },
          understanding: data.extractedContext.understandingUpdate || state.context.understanding,
          overallUnderstanding: data.extractedContext.overallUnderstanding || state.context.overallUnderstanding,
        },
        isLoading: false,
      }));
    } catch (error) {
      console.error('Error in sendMessage:', error);
      set({
        error: error instanceof Error ? error.message : 'An error occurred',
        isLoading: false,
      });
    }
  },
  reset: () => {
    set({
      messages: [],
      context: {
        currentPhase: 'initial',
        extractedInfo: {
          requirements: [],
          technicalDetails: [],
          constraints: [],
        },
        understanding: {
          coreConcept: 0,
          requirements: 0,
          technical: 0,
          constraints: 0,
          userContext: 0,
        },
        overallUnderstanding: 0,
      },
      isLoading: false,
      error: null,
      projectId: null,
      conversationId: null,
      projectStructure: null,
      isGeneratingStructure: false,
      architect: {
        level1Output: null,
        level2Output: null,
        level3Output: null,
        currentLevel: 1,
        isThinking: false,
        error: null
      },
    });
  },
}));
EOF

# Also update the architect.service.ts file to add logging
echo "Updating src/lib/services/architect.service.ts with logging..."
cp src/lib/services/architect.service.ts src/lib/services/architect.service.ts.bak
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
        str = str.replace(/^```json\s*|\s*```$/g, '');
    str = str.replace(/^`|`$/g, '');
    
        str = str.replace(/[\n\r\t]/g, ' ');     str = str.replace(/\s+/g, ' ');     str = str.replace(/\\([^"\\\/bfnrt])/g, '$1');     
    return str;
  }
  private async callClaude(systemPrompt: string, userMessage: string) {
    console.log('Calling Claude with system prompt:', systemPrompt);
    console.log('User message:', userMessage);
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
      const errorText = await response.text();
      console.error('Claude API error response:', errorText);
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }
    const data = await response.json();
    
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }
    try {
      const cleanedText = this.cleanJsonString(data.content[0].text);
      console.log('Cleaned response:', cleanedText);
      const parsedResponse = JSON.parse(cleanedText);
      console.log('Parsed response:', parsedResponse);
      return parsedResponse;
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
    console.log('Generating level 1 with requirements:', requirements);
    const systemPrompt = `You are an expert software architect. Create a comprehensive architectural vision.
IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "visionText": "Your detailed architectural vision here"
}`;
    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }
  async generateLevel2(requirements: string[], visionText: string): Promise<ArchitectLevel2> {
    console.log('Generating level 2 with vision text:', visionText.substring(0, 100) + '...');
    const systemPrompt = `You are an expert software architect. Create a folder structure based on the requirements and vision.
IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "rootFolder": {
    "name": "project-root",
    "description": "Root directory description",
    "purpose": "Main project folder",
    "subfolders": [
      {
        "name": "subfolder-name",
        "description": "Subfolder description",
        "purpose": "Subfolder purpose",
        "subfolders": []
      }
    ]
  }
}`;
    const response = await this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}
Architectural Vision:
${visionText}`);
    
    console.log('Level 2 response structure check:', {
      hasRootFolder: 'rootFolder' in response,
      rootFolderType: typeof response.rootFolder,
      rootFolderKeys: response.rootFolder ? Object.keys(response.rootFolder) : 'N/A'
    });
    
    if (!response.rootFolder) {
      console.error('Invalid folder structure response:', response);
      throw new Error('Invalid folder structure response: missing rootFolder');
    }
    return response;
  }
  async generateLevel3(
    requirements: string[],
    visionText: string,
    folderStructure: ArchitectLevel2
  ): Promise<ArchitectLevel3> {
    console.log('Generating level 3 with folder structure:', JSON.stringify(folderStructure, null, 2));
    
    const systemPrompt = `You are an expert software architect. Create a detailed implementation plan.
IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "implementationOrder": [
    {
      "name": "filename",
      "path": "file path",
      "type": "file type",
      "description": "file description",
      "purpose": "file purpose",
      "dependencies": [],
      "components": [
        {
          "name": "component name",
          "type": "component type",
          "purpose": "component purpose",
          "dependencies": [],
          "details": "implementation details"
        }
      ],
      "implementations": [],
      "additionalContext": "implementation context"
    }
  ]
}`;
    const response = await this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}
Architectural Vision:
${visionText}
Folder Structure:
${JSON.stringify(folderStructure, null, 2)}`);
    
    console.log('Level 3 response structure check:', {
      hasImplementationOrder: 'implementationOrder' in response,
      implementationOrderType: typeof response.implementationOrder,
      isArray: Array.isArray(response.implementationOrder),
      length: response.implementationOrder ? response.implementationOrder.length : 0
    });
    
    if (!response.implementationOrder || !Array.isArray(response.implementationOrder)) {
      console.error('Invalid implementation plan response:', response);
      throw new Error('Invalid implementation plan response: missing or invalid implementationOrder');
    }
    return response;
  }
}
export const architectService = ArchitectService.getInstance();
EOF

echo "All files have been successfully updated with additional logging."
echo "To apply the changes, please restart your development server."
echo "After restarting, check your server logs for detailed information that will help diagnose the issue."
echo "Done!"
