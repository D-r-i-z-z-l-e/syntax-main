import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, ArchitectState, FileNode } from '../types/architect';

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
    error: null,
    completedFiles: 0,
    totalFiles: 0
  },
  
  generateArchitectLevel1: async () => {
    const state = get();
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting architectural vision generation');
    
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
      // Reset architect state and set to thinking
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 1,
          level1Output: null,
          level2Output: null,
          level3Output: null,
          completedFiles: 0,
          totalFiles: 0
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
        throw new Error(`Failed to generate architectural vision: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Architectural vision generated successfully');
      
      if (!data.visionText) {
        throw new Error('Invalid response from architect: missing vision text');
      }
      
      // Update state with level 1 output and move to level 2
      set(state => ({
        architect: {
          ...state.architect,
          level1Output: data,
          currentLevel: 1,
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('Error generating architectural vision:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate architectural vision',
          isThinking: false
        }
      }));
    }
  },
  
  generateArchitectLevel2: async () => {
    const state = get();
    const { level1Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting project structure generation with dependency tree');
    
    if (!level1Output?.visionText || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!requirements?.length) missing.push('requirements');
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required input for project structure: ${missing.join(', ')}`
        }
      }));
      return;
    }
    
    try {
      // Set to thinking for level 2
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 2,
          level2Output: null,
          level3Output: null,
          completedFiles: 0,
          totalFiles: 0
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
        throw new Error(`Failed to generate project structure: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Project structure generated successfully with dependency tree');
      
      if (!data.rootFolder || !data.dependencyTree) {
        throw new Error('Invalid project structure response: missing rootFolder or dependencyTree');
      }
      
      // Count total files in dependency tree
      const totalFiles = data.dependencyTree.files ? data.dependencyTree.files.length : 0;
      
      // Update state with level 2 output and move to level 3
      set(state => ({
        architect: {
          ...state.architect,
          level2Output: data,
          currentLevel: 2,
          isThinking: false,
          totalFiles
        }
      }));
    } catch (error) {
      console.error('Error generating project structure:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate project structure',
          isThinking: false,
          currentLevel: 1
        }
      }));
    }
  },
  
  generateArchitectLevel3: async () => {
    const state = get();
    const { level1Output, level2Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting implementation plan generation based on dependency tree');
    
    if (!level1Output?.visionText || !level2Output?.rootFolder || !level2Output?.dependencyTree || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!level2Output?.rootFolder) missing.push('project structure');
      if (!level2Output?.dependencyTree) missing.push('dependency tree');
      if (!requirements?.length) missing.push('requirements');
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required input for implementation plan: ${JSON.stringify(missing)}`
        }
      }));
      return;
    }
    
    try {
      // Set to thinking for level 3
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 3,
          level3Output: null,
          completedFiles: 0
        }
      }));
      
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          level: 3,
          requirements,
          visionText: level1Output.visionText,
          folderStructure: level2Output
        }),
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to generate implementation plan: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Implementation plan generated successfully');
      
      if (!data.implementationOrder || !Array.isArray(data.implementationOrder)) {
        throw new Error('Invalid implementation plan: missing or invalid implementationOrder');
      }
      
      // Update state with level 3 output
      set(state => ({
        architect: {
          ...state.architect,
          level3Output: data,
          currentLevel: 3,
          isThinking: false,
          completedFiles: data.implementationOrder.length
        }
      }));
    } catch (error) {
      console.error('Error generating implementation plan:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate implementation plan',
          isThinking: false,
          currentLevel: 2
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
      
      // Validate all required inputs
      if (!requirements?.length || !level1Output?.visionText || !level2Output?.rootFolder || !implementationPlan?.implementationOrder) {
        const missing = [];
        if (!requirements?.length) missing.push('requirements');
        if (!level1Output?.visionText) missing.push('architectural vision');
        if (!level2Output?.rootFolder) missing.push('project structure');
        if (!implementationPlan?.implementationOrder) missing.push('implementation plan');
        
        throw new Error(`Missing required inputs for project construction: ${missing.join(', ')}`);
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
        throw new Error(`Failed to construct project: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Project structure successfully generated');
      
      // Reset architect state and set project structure
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
          error: null,
          completedFiles: 0,
          totalFiles: 0
        }
      });
    } catch (error) {
      console.error('Error constructing project:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to construct project',
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
        error: null,
        completedFiles: 0,
        totalFiles: 0
      },
    });
  },
}));