#!/bin/bash

# Script to implement the correct architect concept
# Run this from your syntax-main directory

set -e  # Exit on error

echo "=== Implementing the correct architect concept ==="

# Create backup
mkdir -p ./backups/correct-architect-$(date +%Y%m%d%H%M%S)
BACKUP_DIR="./backups/correct-architect-$(date +%Y%m%d%H%M%S)"
cp ./src/components/conversation/ArchitectOutput.tsx "$BACKUP_DIR/ArchitectOutput.tsx.bak"
cp ./src/lib/stores/conversation.ts "$BACKUP_DIR/conversation.ts.bak"
cp ./src/lib/services/architect.service.ts "$BACKUP_DIR/architect.service.ts.bak"
cp ./src/app/api/architect/route.ts "$BACKUP_DIR/route.ts.bak"

echo "Backed up original files to $BACKUP_DIR"

# Update the architect service with the correct level prompts
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
    console.log('Generating architectural vision with requirements:', requirements);
    const systemPrompt = `You are a supremely experienced software architect with decades of experience across all domains of software engineering. 
    
You are tasked with creating a comprehensive architectural vision based on the user requirements provided.

Think deeply about the requirements as if accessing your subconscious. Your vision should be extremely detailed and precise, covering all aspects of the system including:

1. Overall architectural pattern and approach
2. Technology stack recommendations
3. Data modeling and storage
4. API design principles
5. Security considerations
6. Scalability aspects
7. User experience guidelines
8. Performance requirements
9. Cross-cutting concerns
10. System boundaries and integration points

Your vision should be thorough enough that another experienced developer could use it as a comprehensive blueprint. Don't limit yourself to surface-level details - go deep into the architectural considerations and design decisions, explaining why each choice makes sense given the requirements.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "visionText": "Your detailed architectural vision here (can be multiple paragraphs with detailed thinking)"
}`;

    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }

  async generateLevel2(requirements: string[], visionText: string): Promise<ArchitectLevel2> {
    console.log('Generating project structure based on vision');
    const systemPrompt = `You are a highly experienced software architect with a deep understanding of project organization and code structure. 

Your task is to create a comprehensive project folder structure based on the architectural vision and requirements provided.

This structure should be a complete skeleton of the project, organizing files and directories in a logical manner that reflects both the functional requirements and the architectural decisions explained in the vision.

For each folder in the structure:
1. Provide a descriptive name that follows standard naming conventions
2. Include a clear description of its purpose
3. Explain why this component is needed
4. Consider dependencies between components

Think carefully about:
- Proper separation of concerns
- Maintainability and scalability
- Following design patterns appropriate for the project
- Industry best practices for the relevant technology stack

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
    console.log('Generating file context implementation details');
    
    // Validate folder structure before using
    if (!folderStructure || !folderStructure.rootFolder) {
      console.error('Invalid folderStructure provided to generateLevel3:', folderStructure);
      throw new Error('Invalid folder structure: missing rootFolder property');
    }
    
    const systemPrompt = `You are a master software engineer with extraordinary attention to detail.

Your task is to create detailed implementation instructions for each file in the project structure, based on the architectural vision and the folder structure provided.

For each file identified in the project structure, provide:
1. A comprehensive description of what the file should contain in plain English
2. Detailed implementation guidance including function signatures, parameters, return values
3. Specific technologies, libraries, frameworks that should be used
4. Exact imports that will be needed
5. How this file interacts with other components
6. Error handling considerations
7. Performance optimization suggestions

Analyze the dependencies between files and create an implementation order that minimizes circular dependencies and follows a logical build sequence.

Write as if you are guiding a junior developer through implementing each file, leaving no ambiguity about what needs to be done.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "implementationOrder": [
    {
      "name": "filename",
      "path": "file path",
      "type": "file type",
      "description": "Comprehensive file description in plain English",
      "purpose": "What this file accomplishes",
      "dependencies": ["list of dependencies"],
      "components": [
        {
          "name": "component name",
          "type": "component type",
          "purpose": "component purpose",
          "dependencies": ["component dependencies"],
          "details": "detailed implementation instructions"
        }
      ],
      "implementations": [
        {
          "name": "function/method name",
          "type": "function/class/constant/etc",
          "description": "what this implements",
          "parameters": [
            {
              "name": "param name",
              "type": "param type",
              "description": "param description"
            }
          ],
          "returnType": "return type if applicable",
          "logic": "step by step implementation details in plain English"
        }
      ],
      "additionalContext": "any other implementation details that the developer should know"
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

echo "Updated architect service with correct prompts"

# Update the ArchitectOutput component to correctly display the levels
cat > ./src/components/conversation/ArchitectOutput.tsx << 'EOF'
import React from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon, BrainIcon } from 'lucide-react';
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
        return 'Create Project Structure';
      case 2:
        return 'Generate Implementation Plan';
      case 3:
        return 'Build Project';
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
    <div className="w-full architect-card p-5 mb-5">
      <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center">
        <BrainIcon className="w-4 h-4 mr-2 text-blue-500" />
        AI Architect - Level {currentLevel}
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
            {currentLevel === 1 && "Creating architectural vision..."}
            {currentLevel === 2 && "Designing project structure..."}
            {currentLevel === 3 && "Developing implementation plan..."}
          </span>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Level 1: Architectural Vision */}
          {currentLevel === 1 && level1Output && (
            <div>
              <div className="flex items-center mb-3">
                <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                  <BrainIcon className="w-4 h-4" />
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Architectural Vision
                </h3>
              </div>
              
              <div className="text-sm text-gray-700 bg-gray-50 rounded-lg p-4 ml-10 max-h-[400px] overflow-y-auto border border-gray-200">
                {level1Output.visionText}
              </div>
            </div>
          )}

          {/* Level 2: Project Structure */}
          {currentLevel === 2 && level2Output && level2Output.rootFolder && (
            <div>
              <div className="flex items-center mb-3">
                <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                  <FolderIcon className="w-4 h-4" />
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Project Structure
                </h3>
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4 ml-10 max-h-[400px] overflow-y-auto border border-gray-200">
                {renderFolderStructure(level2Output.rootFolder)}
              </div>
            </div>
          )}

          {/* Level 3: Implementation Plan */}
          {currentLevel === 3 && level3Output && level3Output.implementationOrder && (
            <div>
              <div className="flex items-center mb-3">
                <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                  <FileIcon className="w-4 h-4" />
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Implementation Plan
                </h3>
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4 ml-10 max-h-[400px] overflow-y-auto border border-gray-200">
                {level3Output.implementationOrder.map((file, index) => (
                  <div key={index} className="mb-5 last:mb-0 text-sm border-b border-gray-200 pb-4 last:border-b-0">
                    <div className="flex items-start">
                      <FileIcon className="w-4 h-4 mt-1 text-blue-500 mr-2 flex-shrink-0" />
                      <div>
                        <p className="font-medium text-gray-800">{file.path}/{file.name}</p>
                        <p className="text-xs text-gray-500 mt-1">Type: {file.type} | Purpose: {file.purpose}</p>
                      </div>
                    </div>
                    <div className="mt-2 ml-6">
                      <p className="text-sm text-gray-600">{file.description}</p>
                      
                      {file.dependencies && file.dependencies.length > 0 && (
                        <div className="mt-2">
                          <p className="text-xs font-medium text-gray-700">Dependencies:</p>
                          <ul className="list-disc ml-4 text-xs text-gray-600">
                            {file.dependencies.map((dep, idx) => (
                              <li key={idx}>{dep}</li>
                            ))}
                          </ul>
                        </div>
                      )}
                      
                      {file.components && file.components.length > 0 && (
                        <div className="mt-2">
                          <p className="text-xs font-medium text-gray-700">Components:</p>
                          <div className="space-y-2 mt-1">
                            {file.components.map((component, idx) => (
                              <div key={idx} className="text-xs text-gray-600 bg-gray-100 p-2 rounded">
                                <p className="font-medium">{component.name} ({component.type})</p>
                                <p>{component.details}</p>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                      
                      {file.additionalContext && (
                        <div className="mt-2 text-xs text-gray-600 italic">
                          {file.additionalContext}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

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
          {folder.purpose && (
            <p className="text-xs text-gray-500 mt-1 italic">Purpose: {folder.purpose}</p>
          )}
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

echo "Updated ArchitectOutput component to match concept"

# Update the conversation store for correct level handling
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
      // Reset and start at level 1
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
        throw new Error(`Failed to generate architectural vision: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Architectural vision generated successfully');
      
      if (!data.visionText) {
        throw new Error('Invalid response from architect: missing vision text');
      }
      
      // Success - save the vision and stay at level 1
      set(state => ({
        architect: {
          ...state.architect,
          level1Output: data,
          currentLevel: 1,  // Stay at level 1
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
    
    console.log('Starting project structure generation');
    
    // Check if we have the vision from level 1
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
      // Move to level 2
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 2,  // Now at level 2
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
        throw new Error(`Failed to generate project structure: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Project structure generated successfully');
      
      if (!data.rootFolder) {
        throw new Error('Invalid project structure response: missing rootFolder');
      }
      
      // Success - save the structure and stay at level 2
      set(state => ({
        architect: {
          ...state.architect,
          level2Output: data,
          currentLevel: 2,  // Stay at level 2
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('Error generating project structure:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate project structure',
          isThinking: false,
          currentLevel: 1  // Go back to level 1 on error
        }
      }));
    }
  },
  
  generateArchitectLevel3: async () => {
    const state = get();
    const { level1Output, level2Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting implementation plan generation');
    
    // Check if we have the vision and structure from previous levels
    if (!level1Output?.visionText || !level2Output?.rootFolder || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!level2Output?.rootFolder) missing.push('project structure');
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
      // Move to level 3
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          currentLevel: 3,  // Now at level 3
          level3Output: null
        }
      }));
      
      // Ensure the folder structure has a rootFolder property
      const folderStructureToSend = level2Output;
      
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
      console.log('Implementation plan generated successfully');
      
      if (!data.implementationOrder || !Array.isArray(data.implementationOrder)) {
        throw new Error('Invalid implementation plan: missing or invalid implementationOrder');
      }
      
      // Success - save the implementation plan and stay at level 3
      set(state => ({
        architect: {
          ...state.architect,
          level3Output: data,
          currentLevel: 3,  // Stay at level 3
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('Error generating implementation plan:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate implementation plan',
          isThinking: false,
          currentLevel: 2  // Go back to level 2 on error
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
      
      // Check that we have all required inputs
      if (!requirements?.length || !level1Output?.visionText || !level2Output?.rootFolder || !implementationPlan?.implementationOrder) {
        const missing = [];
        if (!requirements?.length) missing.push('requirements');
        if (!level1Output?.visionText) missing.push('architectural vision');
        if (!level2Output?.rootFolder) missing.push('project structure');
        if (!implementationPlan?.implementationOrder) missing.push('implementation plan');
        
        throw new Error(`Missing required inputs for project construction: ${missing.join(', ')}`);
      }
      
      // Ensure folder structure has rootFolder property
      const folderStructureForRequest = level2Output;
      
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
        throw new Error(`Failed to construct project: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Project structure successfully generated');
      
      // Reset the architect state after successful project generation
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
        error: null
      },
    });
  },
}));
EOF

# Update the API route.ts for better handling
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
        // Level 1: Generate architectural vision
        console.log('Generating level 1: Architectural Vision');
        result = await architectService.generateLevel1(requirements);
        break;
        
      case 2:
        // Level 2: Generate project structure based on vision
        console.log('Generating level 2: Project Structure');
        if (!visionText) {
          console.log('ERROR: Vision text is required for level 2');
          return NextResponse.json({ error: 'Vision text is required for level 2' }, { status: 400 });
        }
        result = await architectService.generateLevel2(requirements, visionText);
        break;
        
      case 3:
        // Level 3: Generate implementation plan based on vision and structure
        console.log('Generating level 3: Implementation Plan');
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
        
        // Ensure folder structure has a rootFolder property
        const normalizedFolderStructure = typeof folderStructure === 'object' && 'rootFolder' in folderStructure && folderStructure.rootFolder
          ? folderStructure
          : { 
              rootFolder: typeof folderStructure === 'object' ? folderStructure : {
                name: "project-root",
                description: "Root directory for the project",
                purpose: "Main project folder",
                subfolders: []
              }
            };
        
        console.log('Proceeding with normalized folder structure');
        
        result = await architectService.generateLevel3(requirements, visionText, normalizedFolderStructure);
        break;
        
      default:
        console.log('ERROR: Invalid architect level:', level);
        return NextResponse.json({ error: 'Invalid architect level' }, { status: 400 });
    }
    
    console.log(`Architect API level ${level} completed successfully`);
    
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

echo "=== Architect Implementation Complete ==="
echo "The architect has been reimplemented according to the correct concept:"
echo "1. Level 1: Creates a detailed architectural vision from requirements"
echo "2. Level 2: Generates a project structure skeleton based on the vision"
echo "3. Level 3: Produces detailed file-by-file implementation instructions"
echo ""
echo "The implementation ensures proper sequential progression between levels,"
echo "with each level depending on the output of previous levels."
echo ""
echo "The UI now focuses on one level at a time, showing the appropriate"
echo "details for the current level of architecture."