#!/bin/bash

echo "Creating a targeted fix for the Level 3 folder structure issue..."

# Backup the files we're going to modify
cp src/app/api/architect/route.ts src/app/api/architect/route.ts.bak2
cp src/lib/stores/conversation.ts src/lib/stores/conversation.ts.bak2

# Update the API route with specific handling for folderStructure
cat > src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;
    
    console.log(`Architect API level ${level} request received`);
    
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
        
        // Special debug for level 3
        console.log('Level 3 folderStructure debugging:');
        console.log('folderStructure received:', JSON.stringify(folderStructure));
        console.log('Type:', typeof folderStructure);
        
        // Check for rootFolder - this is the key check
        if (!folderStructure || typeof folderStructure !== 'object') {
          return NextResponse.json({ error: 'Missing required input for level 3: folder structure (no object)' }, { status: 400 });
        }
        
        if (!('rootFolder' in folderStructure)) {
          return NextResponse.json({ error: 'Missing required input for level 3: folder structure (no rootFolder)' }, { status: 400 });
        }
        
        // Wrap folderStructure if needed
        let processedStructure = folderStructure;
        if (folderStructure.rootFolder) {
          processedStructure = { rootFolder: folderStructure.rootFolder };
        }
        
        console.log('Using folderStructure:', JSON.stringify(processedStructure));
        
        result = await architectService.generateLevel3(requirements, visionText, processedStructure);
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

# Update the conversation store to ensure proper folderStructure handling
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
    
    // Debug logging
    console.log('Starting Level 3 generation');
    console.log('level1Output:', level1Output ? 'present' : 'missing');
    console.log('level2Output:', level2Output ? 'present' : 'missing');
    if (level2Output) {
      console.log('level2Output structure:', JSON.stringify(level2Output));
    }
    
    if (!level1Output?.visionText || !level2Output || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!level2Output) missing.push('folder structure');
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
      
      // Ensure we have the proper structure
      const folderStructure = level2Output.rootFolder 
        ? level2Output 
        : { rootFolder: level2Output };
        
      console.log('Using folderStructure for level 3:', JSON.stringify(folderStructure));
      
      const requestBody = {
        level: 3,
        requirements,
        visionText: level1Output.visionText,
        folderStructure
      };
      
      console.log('Level 3 request body:', JSON.stringify(requestBody));
      
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

echo "All files have been updated with a targeted fix for the Level 3 folder structure issue."
echo "To apply the changes, please restart your development server."
echo "Done!"

# Make the script executable
