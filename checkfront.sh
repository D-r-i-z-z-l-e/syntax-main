#!/bin/bash

echo "Creating a complete reimplementation of the architect feature..."

# 1. First, let's update the architect types
cp src/lib/types/architect.ts src/lib/types/architect.ts.bak
cat > src/lib/types/architect.ts << 'EOF'
export interface ArchitectLevel1 {
  visionText: string;
}

export interface FolderStructure {
  name: string;
  description: string;
  purpose: string;
  subfolders?: FolderStructure[];
}

export interface ArchitectLevel2 {
  rootFolder: FolderStructure;
}

export interface FileContext {
  name: string;
  path: string;
  type: string;
  description: string;
  purpose: string;
  dependencies: string[];
  components: {
    name: string;
    type: string;
    purpose: string;
    dependencies: string[];
    details: string;
  }[];
  implementations: {
    name: string;
    type: string;
    description: string;
    parameters?: {
      name: string;
      type: string;
      description: string;
    }[];
    returnType?: string;
    logic: string;
  }[];
  additionalContext: string;
}

export interface ArchitectLevel3 {
  implementationOrder: FileContext[];
}

export interface ArchitectState {
  level1Output: ArchitectLevel1 | null;
  level2Output: ArchitectLevel2 | null;
  level3Output: ArchitectLevel3 | null;
  currentLevel: 1 | 2 | 3;
  isThinking: boolean;
  error: string | null;
}
EOF

# 2. Now update the architect service
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
    
    str = str.replace(/[\n\r\t]/g, ' ');
    str = str.replace(/\s+/g, ' ');
    str = str.replace(/\\([^"\\\/bfnrt])/g, '$1');
    
    return str;
  }

  private async callClaude(systemPrompt: string, userMessage: string) {
    console.log('Calling Claude with system prompt:', systemPrompt.substring(0, 500) + '...');
    console.log('User message:', userMessage.substring(0, 200) + '...');

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
      console.log('Cleaned response:', cleanedText.substring(0, 200) + '...');
      const parsedResponse = JSON.parse(cleanedText);
      console.log('Parsed response:', JSON.stringify(parsedResponse).substring(0, 200) + '...');
      return parsedResponse;
    } catch (e) {
      console.error('Failed to parse Claude response:', {
        error: e,
        rawResponse: data.content[0].text.substring(0, 200) + '...',
        cleanedResponse: this.cleanJsonString(data.content[0].text).substring(0, 200) + '...'
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
    console.log('Generating level 2 with vision text and requirements');
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
    console.log('Generating level 3 with folder structure');
    console.log('Folder structure for level 3:', JSON.stringify(folderStructure).substring(0, 200) + '...');
    
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

# 3. Update the API route to handle the architect levels correctly
cp src/app/api/architect/route.ts src/app/api/architect/route.ts.bak
cat > src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;
    
    console.log(`Architect API level ${level} request received`);
    console.log(`Request body:`, JSON.stringify({
      level,
      requirementsCount: requirements?.length,
      hasVisionText: !!visionText,
      hasFolderStructure: !!folderStructure,
    }));
    
    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }
    
    let result;
    switch (level) {
      case 1:
        result = await architectService.generateLevel1(requirements);
        break;
      case 2:
        if (!visionText) {
          return NextResponse.json({ error: 'Vision text is required for level 2' }, { status: 400 });
        }
        result = await architectService.generateLevel2(requirements, visionText);
        break;
      case 3:
        if (!visionText) {
          return NextResponse.json({ error: 'Vision text is required for level 3' }, { status: 400 });
        }
        
        if (!folderStructure) {
          return NextResponse.json({ error: 'Missing required input for level 3: folder structure' }, { status: 400 });
        }
        
        // Make sure folderStructure has the expected format
        const normalizedFolderStructure = folderStructure.rootFolder 
          ? folderStructure 
          : { rootFolder: folderStructure };
          
        console.log('Using normalized folder structure:', JSON.stringify(normalizedFolderStructure).substring(0, 200) + '...');
        
        result = await architectService.generateLevel3(requirements, visionText, normalizedFolderStructure);
        break;
      default:
        return NextResponse.json({ error: 'Invalid architect level' }, { status: 400 });
    }
    
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

# 4. Update the store implementation
cp src/lib/stores/conversation.ts src/lib/stores/conversation.ts.bak
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
  
  // Level 1: Generate architectural vision
  generateArchitectLevel1: async () => {
    const state = get();
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting Level 1 generation with requirements count:', requirements?.length);
    
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
        const errorText = await response.text();
        throw new Error(`Failed to generate architect output: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Level 1 response data:', data);
      
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
  
  // Level 2: Generate folder structure
  generateArchitectLevel2: async () => {
    const state = get();
    const { level1Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting Level 2 generation, has level1Output:', !!level1Output);
    
    if (!level1Output?.visionText || !requirements?.length) {
      const missing = [];
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
        const errorText = await response.text();
        throw new Error(`Failed to generate folder structure: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Level 2 response data:', data);
      
      if (!data.rootFolder) {
        throw new Error('Invalid folder structure response: missing rootFolder');
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
  
  // Level 3: Generate implementation plan
  generateArchitectLevel3: async () => {
    const state = get();
    const { level1Output, level2Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting Level 3 generation:');
    console.log('- Has level1Output:', !!level1Output);
    console.log('- Has level2Output:', !!level2Output);
    
    if (level2Output) {
      console.log('- Level2Output structure:', JSON.stringify(level2Output).substring(0, 100) + '...');
    }
    
    if (!level1Output?.visionText || !level2Output || !requirements?.length) {
      const missing = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!level2Output) missing.push('folder structure');
      if (!requirements?.length) missing.push('requirements');
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required inputs for level 3: ${JSON.stringify(missing)}`
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
      
      // Clone level2Output to avoid mutations
      const folderStructure = JSON.parse(JSON.stringify(level2Output));
      
      console.log('Sending level 3 request with folderStructure:', 
        JSON.stringify(folderStructure).substring(0, 100) + '...');
      
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          level: 3,
          requirements,
          visionText: level1Output.visionText,
          folderStructure
        }),
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Level 3 API error:', {
          status: response.status,
          text: errorText
        });
        throw new Error(`Failed to generate implementation plan: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Level 3 response data:', data);
      
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
  
  // Generate final project structure
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
        const errorText = await response.text();
        throw new Error(`Failed to generate project structure: ${response.statusText} - ${errorText}`);
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

# Continuing the ArchitectOutput component implementation
cat > src/components/conversation/ArchitectOutput.tsx << 'EOF'
import React, { useEffect } from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon } from 'lucide-react';
import { ArchitectLevel2, FileContext } from '../../lib/types/architect';

interface ArchitectOutputProps {
  level1Output: { visionText: string } | null;
  level2Output: ArchitectLevel2 | null;
  level3Output: { implementationOrder: FileContext[] } | null;
  currentLevel: 1 | 2 | 3;
  isThinking: boolean;
  error: string | null;
  onProceedToNextLevel: () => void;
}

export function ArchitectOutput({
  level1Output,
  level2Output,
  level3Output,
  currentLevel,
  isThinking,
  error,
  onProceedToNextLevel
}: ArchitectOutputProps) {
  // Debug logging
  useEffect(() => {
    console.log('ArchitectOutput component rendered with:', {
      level1: !!level1Output,
      level2: !!level2Output,
      level2Details: level2Output ? `Has rootFolder: ${!!level2Output.rootFolder}` : 'No level2Output',
      level3: !!level3Output,
      currentLevel,
      isThinking,
      error
    });
  }, [level1Output, level2Output, level3Output, currentLevel, isThinking, error]);

  const getButtonText = () => {
    switch (currentLevel) {
      case 1:
        return 'Design Folder Structure';
      case 2:
        return 'Create Implementation Plan';
      case 3:
        return 'Generate Project Structure';
      default:
        return 'Proceed';
    }
  };

  // Always enabled for testing - this ensures we can proceed
  const canProceedToNextLevel = () => {
    return !isThinking;
  };

  if (error) {
    return (
      <div className="fixed bottom-4 right-4 w-96 bg-red-50 rounded-lg shadow-lg border border-red-200 p-4">
        <h2 className="text-sm font-semibold text-red-900 mb-2">Error</h2>
        <p className="text-sm text-red-700">{error}</p>
      </div>
    );
  }

  if (!level1Output && !isThinking) return null;

  return (
    <div className="fixed bottom-4 right-4 w-96 bg-white rounded-lg shadow-lg border border-gray-200 p-4 max-h-[80vh] overflow-y-auto">
      {isThinking ? (
        <div className="flex items-center justify-center space-x-2">
          <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600">
            {currentLevel === 1 && "Analyzing requirements..."}
            {currentLevel === 2 && "Designing folder structure..."}
            {currentLevel === 3 && "Planning implementation details..."}
          </span>
        </div>
      ) : (
        <>
          {/* Level 1: Architectural Vision */}
          {level1Output && (
            <div className="mb-4">
              <h3 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
                <CodeIcon className="w-4 h-4 mr-1" />
                Architectural Vision
              </h3>
              <div className="text-sm text-gray-600 whitespace-pre-wrap bg-gray-50 rounded-lg p-3 max-h-[300px] overflow-y-auto">
                {level1Output.visionText}
              </div>
            </div>
          )}

          {/* Level 2: Folder Structure */}
          {level2Output && level2Output.rootFolder && (
            <div className="mb-4">
              <h3 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
                <FolderIcon className="w-4 h-4 mr-1" />
                Project Structure
              </h3>
              <div className="bg-gray-50 rounded-lg p-3 max-h-[300px] overflow-y-auto">
                {renderFolderStructure(level2Output.rootFolder)}
              </div>
            </div>
          )}

          {/* Level 3: Implementation Plan */}
          {level3Output && level3Output.implementationOrder && (
            <div className="mb-4">
              <h3 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
                <FileIcon className="w-4 h-4 mr-1" />
                Implementation Plan
              </h3>
              <div className="bg-gray-50 rounded-lg p-3 max-h-[300px] overflow-y-auto">
                {level3Output.implementationOrder.map((file, index) => (
                  <div key={index} className="mb-3 last:mb-0">
                    <p className="text-xs font-medium">{file.path}/{file.name}</p>
                    <p className="text-xs text-gray-600">{file.description}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          <button
            onClick={onProceedToNextLevel}
            disabled={!canProceedToNextLevel()}
            className={`mt-4 w-full ${canProceedToNextLevel() 
              ? 'bg-blue-600 hover:bg-blue-700 text-white' 
              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
            } font-medium rounded-lg px-4 py-2.5 flex items-center justify-center transition-colors`}
          >
            <ArrowRightIcon className="w-4 h-4 mr-2" />
            {getButtonText()}
          </button>
        </>
      )}
    </div>
  );
}

function renderFolderStructure(folder: any, depth = 0) {
  if (!folder) {
    console.error('Trying to render null/undefined folder structure');
    return <div className="text-red-500">Error: Invalid folder structure</div>;
  }
  
  return (
    <div className={`${depth > 0 ? 'ml-4' : ''}`}>
      <div className="flex items-start gap-2">
        <FolderIcon className="w-4 h-4 mt-1 text-blue-500" />
        <div>
          <p className="text-xs font-medium">{folder.name}</p>
          <p className="text-xs text-gray-600">{folder.description}</p>
        </div>
      </div>
      {folder.subfolders?.map((subfolder: any, index: number) => (
        <div key={index} className="ml-2 mt-2 border-l-2 border-gray-200 pl-2">
          {renderFolderStructure(subfolder, depth + 1)}
        </div>
      ))}
    </div>
  );
}
EOF

# 6. Create a debug utility file
mkdir -p src/lib/utils
cat > src/lib/utils/debug.ts << 'EOF'
/**
 * Debug utility for logging structured data with truncation for large values
 */
export function debugLog(component: string, action: string, data: any, maxLength = 200) {
  console.log(`[${component}] ${action}:`, 
    JSON.stringify(data, (key, value) => {
      if (typeof value === 'string' && value.length > maxLength) {
        return value.substring(0, maxLength) + '...';
      }
      return value;
    }, 2)
  );
}

/**
 * Helper to truncate strings for debugging
 */
export function truncate(str: string, maxLength = 100) {
  if (!str) return str;
  return str.length > maxLength ? str.substring(0, maxLength) + '...' : str;
}
EOF