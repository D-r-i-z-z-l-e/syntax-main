#!/bin/bash

# Script to reimagine and fix the architect implementation
# Run this from your syntax-main directory

set -e  # Exit on error

echo "=== Starting Architect System Reimplementation ==="

# Create backup directory
mkdir -p ./backups/architect-reimplementation-$(date +%Y%m%d%H%M%S)
BACKUP_DIR="./backups/architect-reimplementation-$(date +%Y%m%d%H%M%S)"

# Backup existing files
cp ./src/app/api/architect/route.ts "$BACKUP_DIR/route.ts.bak"
cp ./src/lib/services/architect.service.ts "$BACKUP_DIR/architect.service.ts.bak"
cp ./src/lib/stores/conversation.ts "$BACKUP_DIR/conversation.ts.bak"
cp ./src/components/conversation/ArchitectOutput.tsx "$BACKUP_DIR/ArchitectOutput.tsx.bak"
cp ./src/components/conversation/ConversationUI.tsx "$BACKUP_DIR/ConversationUI.tsx.bak"

echo "Backed up original files to $BACKUP_DIR"

# Fix the API route for better error handling and folder structure normalization
cat > ./src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';

export async function POST(req: NextRequest) {
  try {
    console.log('=== ARCHITECT API REQUEST RECEIVED ===');
    
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;
    
    console.log(`Architect API level ${level} request received`);
    console.log(`Request body:`, JSON.stringify({
      level,
      requirementsCount: requirements?.length,
      hasVisionText: !!visionText,
      hasFolderStructure: !!folderStructure,
      folderStructureType: folderStructure ? typeof folderStructure : 'undefined'
    }));
    
    if (!requirements || !Array.isArray(requirements)) {
      console.log('ERROR: Valid requirements array is required');
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }
    
    let result;
    switch (level) {
      case 1:
        result = await architectService.generateLevel1(requirements);
        break;
      case 2:
        if (!visionText) {
          console.log('ERROR: Vision text is required for level 2');
          return NextResponse.json({ error: 'Vision text is required for level 2' }, { status: 400 });
        }
        result = await architectService.generateLevel2(requirements, visionText);
        break;
      case 3:
        console.log('=== PROCESSING LEVEL 3 REQUEST ===');
        if (!visionText) {
          console.log('ERROR: Vision text is required for level 3');
          return NextResponse.json({ error: 'Vision text is required for level 3' }, { status: 400 });
        }
        
        if (!folderStructure) {
          console.log('ERROR: Missing folder structure for level 3');
          return NextResponse.json({ 
            error: 'Missing required inputs for level 3: ["folder structure"]' 
          }, { status: 400 });
        }
        
        // Always ensure folder structure has rootFolder properly defined
        let normalizedFolderStructure;
        
        if (typeof folderStructure === 'object' && 'rootFolder' in folderStructure && folderStructure.rootFolder) {
          console.log('Using provided folder structure with rootFolder');
          normalizedFolderStructure = folderStructure;
        } else {
          console.log('Creating normalized folder structure with rootFolder');
          normalizedFolderStructure = { 
            rootFolder: typeof folderStructure === 'object' ? folderStructure : {
              name: "project-root",
              description: "Root directory for the project",
              purpose: "Main project folder",
              subfolders: []
            }
          };
        }
        
        console.log('Normalized folder structure has rootFolder:', 'rootFolder' in normalizedFolderStructure);
        
        result = await architectService.generateLevel3(requirements, visionText, normalizedFolderStructure);
        break;
      default:
        console.log('ERROR: Invalid architect level:', level);
        return NextResponse.json({ error: 'Invalid architect level' }, { status: 400 });
    }
    
    console.log('API call completed successfully with result:', 
                result ? 'Result has data' : 'No result data');
    
    return NextResponse.json(result);
  } catch (error) {
    console.error('=== ERROR IN ARCHITECT API ===');
    console.error(error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate architect output' },
      { status: 500 }
    );
  }
}
EOF

echo "Updated API route with better folder structure handling"

# Update the service with improved error handling
cat > ./src/lib/services/architect.service.ts << 'EOF'
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
    
    // Validate folder structure before using
    if (!folderStructure || !folderStructure.rootFolder) {
      console.error('Invalid folderStructure provided to generateLevel3:', folderStructure);
      throw new Error('Invalid folder structure: missing rootFolder property');
    }
    
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
    
    if (!response.implementationOrder || !Array.isArray(response.implementationOrder)) {
      console.error('Invalid implementation plan response:', response);
      throw new Error('Invalid implementation plan response: missing or invalid implementationOrder');
    }
    return response;
  }
}

export const architectService = ArchitectService.getInstance();
EOF

echo "Updated architect service with better validation"

# Update the conversation store
cat > ./src/lib/stores/conversation.ts << 'EOF'
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
  
  generateArchitectLevel2: async () => {
    const state = get();
    const { level1Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting Level 2 generation, has level1Output:', !!level1Output);
    
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
  
  generateArchitectLevel3: async () => {
    const state = get();
    const { level1Output, level2Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting Level 3 generation:');
    
    if (!level1Output?.visionText || !level2Output || !requirements?.length) {
      const missing: string[] = [];
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
      
      // Ensure the folder structure explicitly has a rootFolder property
      let folderStructureToSend;
      
      if ('rootFolder' in level2Output && level2Output.rootFolder) {
        folderStructureToSend = level2Output;
      } else {
        folderStructureToSend = {
          rootFolder: level2Output
        };
      }
      
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          level: 3,
          requirements,
          visionText: level1Output.visionText,
          folderStructure: folderStructureToSend
        }),
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to generate implementation plan: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      
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
      
      // Ensure folder structure has rootFolder
      const folderStructureForRequest = level2Output.rootFolder 
        ? level2Output 
        : { rootFolder: level2Output };
      
      const response = await fetch('/api/project-structure', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          requirements,
          architectVision: level1Output.visionText,
          folderStructure: folderStructureForRequest,
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

echo "Updated conversation store with improved architect implementation"

# Create improved ArchitectOutput component
cat > ./src/components/conversation/ArchitectOutput.tsx << 'EOF'
import React from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon } from 'lucide-react';
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

  const canProceedToNextLevel = () => {
    if (isThinking) return false;
    
    switch (currentLevel) {
      case 1:
        return !!level1Output?.visionText;
      case 2:
        return !!level2Output?.rootFolder;
      case 3:
        return !!level3Output?.implementationOrder;
      default:
        return false;
    }
  };

  if (error) {
    return (
      <div className="w-full bg-red-50 rounded-lg border border-red-200 p-4 mb-4">
        <h2 className="text-sm font-semibold text-red-900 mb-2">Error</h2>
        <p className="text-sm text-red-700">{error}</p>
      </div>
    );
  }

  if (!level1Output && !isThinking) return null;

  return (
    <div className="w-full bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-4">
      <h2 className="text-sm font-semibold text-gray-900 mb-4 flex items-center">
        <CodeIcon className="w-4 h-4 mr-2" />
        AI Architect Progress
        <div className="ml-auto flex items-center space-x-1">
          <div className={`w-2 h-2 rounded-full ${currentLevel >= 1 ? 'bg-blue-600' : 'bg-gray-300'}`}></div>
          <div className={`w-2 h-2 rounded-full ${currentLevel >= 2 ? 'bg-blue-600' : 'bg-gray-300'}`}></div>
          <div className={`w-2 h-2 rounded-full ${currentLevel >= 3 ? 'bg-blue-600' : 'bg-gray-300'}`}></div>
        </div>
      </h2>
      
      {isThinking ? (
        <div className="flex items-center justify-center space-x-2 p-6">
          <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600">
            {currentLevel === 1 && "Analyzing requirements..."}
            {currentLevel === 2 && "Designing folder structure..."}
            {currentLevel === 3 && "Planning implementation details..."}
          </span>
        </div>
      ) : (
        <div className="space-y-4">
          {/* Level 1: Architectural Vision */}
          <div className={`transition-all duration-300 ${currentLevel === 1 ? 'opacity-100' : 'opacity-80'}`}>
            <div className="flex items-center mb-2">
              <div className={`w-6 h-6 rounded-full ${currentLevel === 1 ? 'bg-blue-600' : 'bg-green-500'} text-white flex items-center justify-center mr-2`}>
                {currentLevel > 1 ? <CheckIcon className="w-4 h-4" /> : '1'}
              </div>
              <h3 className="text-sm font-semibold text-gray-900">
                Architectural Vision
              </h3>
            </div>
            
            {level1Output && (
              <div className="text-sm text-gray-600 whitespace-pre-wrap bg-gray-50 rounded-lg p-3 ml-8 max-h-[200px] overflow-y-auto border border-gray-200">
                {level1Output.visionText}
              </div>
            )}
          </div>

          {/* Level 2: Folder Structure */}
          {(currentLevel >= 2 || level2Output) && (
            <div className={`transition-all duration-300 ${currentLevel === 2 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-2">
                <div className={`w-6 h-6 rounded-full ${currentLevel === 2 ? 'bg-blue-600' : currentLevel > 2 ? 'bg-green-500' : 'bg-gray-300'} text-white flex items-center justify-center mr-2`}>
                  {currentLevel > 2 ? <CheckIcon className="w-4 h-4" /> : '2'}
                </div>
                <h3 className="text-sm font-semibold text-gray-900">
                  Project Structure
                </h3>
              </div>
              
              {level2Output && level2Output.rootFolder && (
                <div className="bg-gray-50 rounded-lg p-3 ml-8 max-h-[200px] overflow-y-auto border border-gray-200">
                  {renderFolderStructure(level2Output.rootFolder)}
                </div>
              )}
            </div>
          )}

          {/* Level 3: Implementation Plan */}
          {(currentLevel >= 3 || level3Output) && (
            <div className={`transition-all duration-300 ${currentLevel === 3 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-2">
                <div className={`w-6 h-6 rounded-full ${currentLevel === 3 ? 'bg-blue-600' : 'bg-gray-300'} text-white flex items-center justify-center mr-2`}>
                  3
                </div>
                <h3 className="text-sm font-semibold text-gray-900">
                  Implementation Plan
                </h3>
              </div>
              
              {level3Output && level3Output.implementationOrder && (
                <div className="bg-gray-50 rounded-lg p-3 ml-8 max-h-[200px] overflow-y-auto border border-gray-200">
                  {level3Output.implementationOrder.map((file, index) => (
                    <div key={index} className="mb-3 last:mb-0 text-sm">
                      <p className="font-medium text-gray-800">{file.path}/{file.name}</p>
                      <p className="text-xs text-gray-600">{file.description}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          <button
            onClick={onProceedToNextLevel}
            disabled={!canProceedToNextLevel()}
            className={`w-full mt-4 ${canProceedToNextLevel() 
              ? 'bg-blue-600 hover:bg-blue-700 text-white' 
              : 'bg-gray-200 text-gray-500 cursor-not-allowed'
            } font-medium rounded-lg px-4 py-2 flex items-center justify-center transition-colors`}
          >
            {getButtonText()}
            <ArrowRightIcon className="w-4 h-4 ml-2" />
          </button>
        </div>
      )}
    </div>
  );
}

function renderFolderStructure(folder: ArchitectLevel2['rootFolder'], depth = 0) {
  if (!folder) {
    return <div className="text-red-500 text-xs">Error: Invalid folder structure</div>;
  }
  
  return (
    <div className={`${depth > 0 ? 'ml-4' : ''} text-sm`}>
      <div className="flex items-start gap-2">
        <FolderIcon className="w-4 h-4 mt-1 text-blue-500 flex-shrink-0" />
        <div>
          <p className="font-medium text-gray-800">{folder.name}</p>
          <p className="text-xs text-gray-600">{folder.description}</p>
        </div>
      </div>
      {folder.subfolders?.map((subfolder, index) => (
        <div key={index} className="ml-2 mt-2 border-l-2 border-gray-100 pl-2">
          {renderFolderStructure(subfolder, depth + 1)}
        </div>
      ))}
    </div>
  );
}
EOF

echo "Created improved ArchitectOutput component"

# Update ConversationUI component to reposition and integrate the architect
cat > ./src/components/conversation/ConversationUI.tsx << 'EOF'
"use client";

import { useRef, useEffect, useState } from 'react';
import { useConversationStore } from '../../lib/stores/conversation';
import { ProjectStructure } from './ProjectStructure';
import { ArchitectOutput } from './ArchitectOutput';
import { FolderIcon, LayoutIcon } from 'lucide-react';

export function ConversationUI() {
  const {
    messages,
    context,
    isLoading,
    error,
    sendMessage,
    reset,
    projectStructure,
    isGeneratingStructure,
    architect,
    generateArchitectLevel1,
    generateArchitectLevel2,
    generateArchitectLevel3,
    generateProjectStructure
  } = useConversationStore();

  const [inputText, setInputText] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || isLoading) return;

    const message = inputText;
    setInputText('');
    await sendMessage(message);
  };

  const getMetricColor = (value: number): string => {
    if (value >= 80) return 'bg-green-500';
    if (value >= 60) return 'bg-green-400';
    if (value >= 40) return 'bg-yellow-500';
    if (value >= 20) return 'bg-yellow-400';
    return 'bg-red-500';
  };

  const getPhaseColor = (phase: string): string => {
    switch (phase) {
      case 'initial':
        return 'text-blue-500';
      case 'requirements':
        return 'text-yellow-500';
      case 'clarification':
        return 'text-green-500';
      case 'complete':
        return 'text-purple-500';
      default:
        return 'text-gray-500';
    }
  };

  const getPhaseDescription = (phase: string): string => {
    switch (phase) {
      case 'initial':
        return 'Understanding your core concept';
      case 'requirements':
        return 'Gathering detailed requirements';
      case 'clarification':
        return 'Clarifying technical details';
      case 'complete':
        return 'Requirements gathering complete';
      default:
        return '';
    }
  };

  const getMetricDescription = (metric: string): string => {
    switch (metric) {
      case 'coreConcept':
        return 'Understanding of the main project idea and its core functionality';
      case 'requirements':
        return 'Clarity of functional requirements and system capabilities';
      case 'technical':
        return 'Understanding of technical needs, architecture, and implementation details';
      case 'constraints':
        return 'Understanding of limitations, performance requirements, and system boundaries';
      case 'userContext':
        return 'Understanding of user needs, business context, and organizational requirements';
      default:
        return '';
    }
  };

  const requirements = context.extractedInfo.requirements || [];
  const showArchitect = requirements.length > 0;

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Left Sidebar - Project Structure */}
      {(projectStructure || isGeneratingStructure) && (
        <div className="w-96 bg-white border-r border-gray-200">
          {isGeneratingStructure ? (
            <div className="p-4">
              <div className="flex items-center justify-center space-x-2">
                <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
                <span className="text-sm text-gray-600">Generating project structure...</span>
              </div>
            </div>
          ) : (
            <ProjectStructure structure={projectStructure!} />
          )}
        </div>
      )}

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 px-4 py-3 flex justify-between items-center">
          <div>
            <h1 className="text-lg font-semibold text-gray-900">Syntax AI Architect</h1>
            <p className={`text-sm ${getPhaseColor(context.currentPhase)} font-medium`}>
              {getPhaseDescription(context.currentPhase)}
            </p>
          </div>
          <button
            onClick={reset}
            className="px-3 py-1 text-sm text-gray-600 hover:text-gray-900 border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
          >
            New Conversation
          </button>
        </div>

        {/* Understanding Metrics */}
        <div className="bg-white border-b border-gray-200 px-4 py-3">
          <div className="max-w-3xl mx-auto">
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm font-medium text-gray-700">Overall Understanding:</span>
              <div className="flex items-center">
                <span className={`text-sm font-semibold ${
                  context.overallUnderstanding >= 80 ? 'text-green-600' :
                  context.overallUnderstanding >= 60 ? 'text-green-500' :
                  context.overallUnderstanding >= 40 ? 'text-yellow-500' :
                  context.overallUnderstanding >= 20 ? 'text-yellow-400' :
                  'text-red-500'
                } transition-colors duration-500`}>
                  {context.overallUnderstanding}%
                </span>
                <span className="text-xs text-gray-500 ml-2">
                  ({context.currentPhase})
                </span>
              </div>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2.5 mb-4">
              <div 
                className={`h-2.5 rounded-full transition-all duration-500 ease-in-out ${getMetricColor(context.overallUnderstanding)}`}
                style={{ width: `${context.overallUnderstanding}%` }}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              {Object.entries(context.understanding).map(([key, value]) => (
                <div key={key} className={`${key === 'userContext' ? 'col-span-2' : ''}`}>
                  <div className="flex items-center justify-between group relative">
                    <span className="text-xs text-gray-600 capitalize">
                      {key.replace(/([A-Z])/g, ' $1').trim()}
                    </span>
                    <span className={`text-xs font-medium transition-colors duration-500`}>
                      {value}%
                    </span>
                    <div className="absolute invisible group-hover:visible bg-gray-900 text-white text-xs rounded py-1 px-2 right-0 top-6 w-48 z-10">
                      {getMetricDescription(key)}
                    </div>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-1.5 mt-1">
                    <div 
                      className={`h-1.5 rounded-full transition-all duration-500 ease-in-out ${getMetricColor(value)}`}
                      style={{ width: `${value}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Central Content Area */}
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-5xl mx-auto px-4 py-6 flex flex-col lg:flex-row gap-6">
            {/* Messages Column */}
            <div className="flex-1 space-y-6">
              {messages.map((message) => (
                <div
                  key={message.id}
                  className={`flex ${
                    message.role === 'assistant' ? 'justify-start' : 'justify-end'
                  }`}
                >
                  <div
                    className={`max-w-[80%] rounded-lg px-4 py-2 ${
                      message.role === 'assistant'
                        ? 'bg-white border border-gray-200 text-gray-900'
                        : 'bg-blue-600 text-white'
                    }`}
                  >
                    <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                    <span className="text-xs opacity-50 mt-1 block">
                      {new Date(message.timestamp).toLocaleTimeString()}
                    </span>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
            
            {/* Right Side - Requirements and Architect */}
            <div className="w-full lg:w-96 space-y-4">
              {/* Requirements Panel */}
              {requirements.length > 0 && (
                <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
                  <h2 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
                    <LayoutIcon className="w-4 h-4 mr-1" />
                    Extracted Requirements ({requirements.length})
                  </h2>
                  <div className="max-h-[30vh] overflow-y-auto">
                    <ul className="space-y-2">
                      {requirements.map((req, index) => (
                        <li 
                          key={index} 
                          className="text-xs text-gray-600 bg-gray-50 p-2 rounded border border-gray-100 hover:bg-gray-100 transition-colors"
                        >
                          • {req}
                        </li>
                      ))}
                    </ul>
                  </div>
                  
                  {/* Architect Button */}
                  {!architect.level1Output && !architect.isThinking && (
                    <button
                      onClick={generateArchitectLevel1}
                      className="w-full mt-4 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg px-4 py-2 flex items-center justify-center transition-colors"
                    >
                      <FolderIcon className="w-4 h-4 mr-2" />
                      Initiate Architect
                    </button>
                  )}
                </div>
              )}
              
              {/* Embedded Architect Output */}
              {showArchitect && (architect.level1Output || architect.isThinking) && (
                <ArchitectOutput
                  level1Output={architect.level1Output}
                  level2Output={architect.level2Output}
                  level3Output={architect.level3Output}
                  currentLevel={architect.currentLevel}
                  isThinking={architect.isThinking}
                  error={architect.error}
                  onProceedToNextLevel={() => {
                    switch (architect.currentLevel) {
                      case 1:
                        generateArchitectLevel2();
                        break;
                      case 2:
                        generateArchitectLevel3();
                        break;
                      case 3:
                        generateProjectStructure(architect.level3Output!);
                        break;
                    }
                  }}
                />
              )}
            </div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border-l-4 border-red-400 p-4 mx-4 mb-4">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg
                  className="h-5 w-5 text-red-400"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clipRule="evenodd"
                  />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-700">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Input Form */}
        <div className="border-t border-gray-200 bg-white px-4 py-4">
          <form onSubmit={handleSubmit} className="max-w-3xl mx-auto">
            <div className="flex space-x-4">
              <textarea
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                className="flex-1 min-h-[80px] p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                placeholder="Describe your project idea..."
                disabled={isLoading}
              />
              <button
                type="submit"
                disabled={isLoading || !inputText.trim()}
                className={`px-6 py-2 bg-blue-600 text-white rounded-lg font-medium transition-all duration-200 ${
                  isLoading || !inputText.trim()
                    ? 'opacity-50 cursor-not-allowed'
                    : 'hover:bg-blue-700'
                }`}
              >
                {isLoading ? 'Thinking...' : 'Send'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
EOF

echo "Updated ConversationUI component with better architect placement"

echo "=== Implementation Complete ==="
echo "The architectural system has been fully reimplemented with the following changes:"
echo "1. Fixed folder structure normalization to consistently handle rootFolder property"
echo "2. Repositioned architect UI to be directly under the extracted requirements"
echo "3. Added better visualization of progress through architect levels"
echo "4. Improved error handling and validation at each step"
echo "5. Enhanced the overall UI with a more intuitive flow"
echo ""
echo "Your changes have been applied successfully!"