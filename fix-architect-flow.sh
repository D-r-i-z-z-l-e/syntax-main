#!/bin/bash

# Script to fix the architect flow to ensure proper sequential progression
# Run this from your syntax-main directory

set -e  # Exit on error

echo "=== Fixing the architect level progression ==="

# Create backup
mkdir -p ./backups/level-flow-fix-$(date +%Y%m%d%H%M%S)
BACKUP_DIR="./backups/level-flow-fix-$(date +%Y%m%d%H%M%S)"
cp ./src/components/conversation/ArchitectOutput.tsx "$BACKUP_DIR/ArchitectOutput.tsx.bak"
cp ./src/lib/stores/conversation.ts "$BACKUP_DIR/conversation.ts.bak"

echo "Backed up original files to $BACKUP_DIR"

# Update the ArchitectOutput component for proper level progression
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
    // Disable the button when thinking
    if (isThinking) return false;
    
    // Check correct progression based on levels and available data
    switch (currentLevel) {
      case 1:
        // Can only proceed from level 1 if we have the vision text
        return !!level1Output?.visionText;
      case 2:
        // Can only proceed from level 2 if we have the folder structure
        return !!level2Output && !!level2Output.rootFolder;
      case 3:
        // Can only proceed from level 3 if we have the implementation plan
        return !!level3Output && Array.isArray(level3Output.implementationOrder);
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

  if (!level1Output && !isThinking && currentLevel === 1) return null;

  return (
    <div className="w-full architect-card p-5 mb-5">
      <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center">
        <CodeIcon className="w-4 h-4 mr-2 text-blue-500" />
        AI Architect Progress
      </h2>
      
      {/* Progress Indicator */}
      <div className="progress-indicator mb-6">
        <div className={`step ${currentLevel >= 1 ? (currentLevel > 1 ? 'completed' : 'active') : 'inactive'}`}>
          {currentLevel > 1 ? <CheckIcon className="w-4 h-4" /> : 1}
        </div>
        <div className={`line ${currentLevel > 1 ? 'active' : ''}`}></div>
        <div className={`step ${currentLevel >= 2 ? (currentLevel > 2 ? 'completed' : 'active') : 'inactive'}`}>
          {currentLevel > 2 ? <CheckIcon className="w-4 h-4" /> : 2}
        </div>
        <div className={`line ${currentLevel > 2 ? 'active' : ''}`}></div>
        <div className={`step ${currentLevel >= 3 ? 'active' : 'inactive'}`}>
          3
        </div>
      </div>
      
      {isThinking ? (
        <div className="flex items-center justify-center space-x-3 py-8">
          <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600 font-medium">
            {currentLevel === 1 && "Analyzing requirements..."}
            {currentLevel === 2 && "Designing folder structure..."}
            {currentLevel === 3 && "Planning implementation details..."}
          </span>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Only show the current level and completed levels */}
          
          {/* Level 1: Architectural Vision */}
          {(currentLevel >= 1) && (
            <div className={`transition-all duration-300 ${currentLevel === 1 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-3">
                <div className={`w-7 h-7 rounded-full ${currentLevel === 1 ? 'bg-blue-500' : 'bg-green-500'} text-white flex items-center justify-center mr-3`}>
                  {currentLevel > 1 ? <CheckIcon className="w-4 h-4" /> : '1'}
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Architectural Vision
                </h3>
              </div>
              
              {level1Output && (
                <div className="text-sm text-gray-700 bg-gray-50 rounded-lg p-4 ml-10 max-h-[200px] overflow-y-auto border border-gray-200">
                  {level1Output.visionText}
                </div>
              )}
            </div>
          )}

          {/* Level 2: Folder Structure - Only show if we're at level 2 or higher */}
          {(currentLevel >= 2) && (
            <div className={`transition-all duration-300 ${currentLevel === 2 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-3">
                <div className={`w-7 h-7 rounded-full ${currentLevel === 2 ? 'bg-blue-500' : currentLevel > 2 ? 'bg-green-500' : 'bg-gray-300'} text-white flex items-center justify-center mr-3`}>
                  {currentLevel > 2 ? <CheckIcon className="w-4 h-4" /> : '2'}
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Project Structure
                </h3>
              </div>
              
              {level2Output && level2Output.rootFolder && (
                <div className="bg-gray-50 rounded-lg p-4 ml-10 max-h-[250px] overflow-y-auto border border-gray-200">
                  {renderFolderStructure(level2Output.rootFolder)}
                </div>
              )}
            </div>
          )}

          {/* Level 3: Implementation Plan - Only show if we're at level 3 */}
          {(currentLevel >= 3) && (
            <div className={`transition-all duration-300 ${currentLevel === 3 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-3">
                <div className={`w-7 h-7 rounded-full ${currentLevel === 3 ? 'bg-blue-500' : 'bg-gray-300'} text-white flex items-center justify-center mr-3`}>
                  3
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Implementation Plan
                </h3>
              </div>
              
              {level3Output && level3Output.implementationOrder && (
                <div className="bg-gray-50 rounded-lg p-4 ml-10 max-h-[250px] overflow-y-auto border border-gray-200">
                  {level3Output.implementationOrder.map((file, index) => (
                    <div key={index} className="mb-4 last:mb-0 text-sm">
                      <p className="font-medium text-gray-800">{file.path}/{file.name}</p>
                      <p className="text-xs text-gray-600 mt-1">{file.description}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Button to proceed to next level - only visible for the current level */}
          <button
            onClick={onProceedToNextLevel}
            disabled={!canProceedToNextLevel()}
            className={`w-full mt-6 ${canProceedToNextLevel() 
              ? 'bg-blue-600 hover:bg-blue-700 text-white' 
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
            } font-medium rounded-lg px-5 py-3 flex items-center justify-center transition-colors`}
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
    <div className={`${depth > 0 ? 'ml-5' : ''} text-sm`}>
      <div className="flex items-start gap-3 mb-2">
        <FolderIcon className="w-4 h-4 mt-1 text-blue-500 flex-shrink-0" />
        <div>
          <p className="font-medium text-gray-800">{folder.name}</p>
          <p className="text-xs text-gray-600 mt-1">{folder.description}</p>
        </div>
      </div>
      {folder.subfolders?.map((subfolder, index) => (
        <div key={index} className="ml-3 mt-3 border-l-2 border-gray-100 pl-3">
          {renderFolderStructure(subfolder, depth + 1)}
        </div>
      ))}
    </div>
  );
}
EOF

# Update the conversation store to ensure proper level progression
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
      // Reset all architect outputs to ensure proper sequence
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
      
      if (!data.visionText) {
        throw new Error('Invalid response from architect level 1: missing visionText');
      }
      
      // After successful level 1, stay at level 1
      set(state => ({
        architect: {
          ...state.architect,
          level1Output: data,
          currentLevel: 1,  // Stay at level 1 until user explicitly moves to level 2
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
      // Mark as thinking and move to level 2
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 2,  // Now we're working on level 2
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
      
      // After successfully completing level 2, stay at level 2
      set(state => ({
        architect: {
          ...state.architect,
          level2Output: data,
          currentLevel: 2,  // Stay at level 2 until user explicitly moves to level 3
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('Error generating architect level 2:', error);
      
      // If error, go back to level 1
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate folder structure',
          isThinking: false,
          currentLevel: 1  // Return to level 1 on error
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
      // Mark as thinking and move to level 3
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 3,  // Now we're working on level 3
          level3Output: null
        }
      }));
      
      // Ensure the folder structure properly has a rootFolder property
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
      
      if (!data.implementationOrder || !Array.isArray(data.implementationOrder)) {
        throw new Error('Invalid implementation plan response: missing or invalid implementationOrder');
      }
      
      // After successfully completing level 3, stay at level 3
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
      
      // If error, go back to level 2
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate implementation plan',
          isThinking: false,
          currentLevel: 2  // Return to level 2 on error
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

echo "=== Architect level flow fix applied successfully ==="
echo "The changes include:"
echo "1. Better sequential progression through architect levels"
echo "2. Each level is now dependent on the previous level's output"
echo "3. The UI now shows only the current and completed levels"
echo "4. Better validation to ensure all required data is available"
echo "5. Proper handling of level transitions including error cases"
echo ""
echo "This implementation ensures each level is properly completed before proceeding to the next."