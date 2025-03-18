# Update ConversationUI component
echo "Updating ConversationUI component..."
cat > src/components/conversation/ConversationUI.tsx << 'EOF'
"use client";

import { useRef, useEffect, useState } from 'react';
import { useConversationStore } from '../../lib/stores/conversation';
import { ProjectStructure } from './ProjectStructure';
import { ArchitectOutput } from './ArchitectOutput';
import { FolderIcon, LayoutIcon, SendIcon, RefreshCwIcon } from 'lucide-react';

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
        <div className="w-96 bg-white border-r border-gray-200 shadow-sm">
          {isGeneratingStructure ? (
            <div className="p-6 flex flex-col items-center justify-center h-full">
              <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-4" />
              <span className="text-base text-gray-700 font-medium">Generating project structure...</span>
              <p className="text-sm text-gray-500 mt-2 text-center">This may take a moment as we create your complete project blueprint</p>
            </div>
          ) : (
            <ProjectStructure structure={projectStructure!} />
          )}
        </div>
      )}

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-center shadow-sm">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">Syntax AI Architect</h1>
            <p className={`text-sm ${getPhaseColor(context.currentPhase)} font-medium mt-1`}>
              {getPhaseDescription(context.currentPhase)}
            </p>
          </div>
          <button
            onClick={reset}
            className="px-4 py-2 text-sm text-gray-600 hover:text-gray-900 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors flex items-center"
          >
            <RefreshCwIcon className="w-4 h-4 mr-2" />
            New Conversation
          </button>
        </div>

        {/* Understanding Metrics */}
        <div className="bg-white border-b border-gray-200 px-6 py-4 shadow-sm">
          <div className="max-w-4xl mx-auto">
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm font-medium text-gray-700">Project Understanding:</span>
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
            <div className="grid grid-cols-2 gap-6">
              {Object.entries(context.understanding).map(([key, value]) => (
                <div key={key} className={`${key === 'userContext' ? 'col-span-2' : ''}`}>
                  <div className="flex items-center justify-between group relative">
                    <span className="text-xs font-medium text-gray-700 capitalize">
                      {key.replace(/([A-Z])/g, ' $1').trim()}
                    </span>
                    <span className={`text-xs font-medium transition-colors duration-500 ${
                      value >= 80 ? 'text-green-600' :
                      value >= 60 ? 'text-green-500' :
                      value >= 40 ? 'text-yellow-500' :
                      value >= 20 ? 'text-yellow-400' :
                      'text-red-500'
                    }`}>
                      {value}%
                    </span>
                    <div className="absolute invisible group-hover:visible bg-gray-900 text-white text-xs rounded py-1 px-2 right-0 top-6 w-52 z-10">
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
          <div className="max-w-6xl mx-auto px-6 py-6 flex flex-col lg:flex-row gap-8">
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
                    className={`max-w-[85%] rounded-lg px-5 py-3 ${
                      message.role === 'assistant'
                        ? 'bg-white border border-gray-200 text-gray-900 shadow-sm'
                        : 'bg-blue-600 text-white shadow-sm'
                    }`}
                  >
                    <p className="text-sm leading-relaxed whitespace-pre-wrap">{message.content}</p>
                    <span className="text-xs opacity-60 mt-2 block">
                      {new Date(message.timestamp).toLocaleTimeString()}
                    </span>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
            
            {/* Right Side - Requirements and Architect */}
            <div className="w-full lg:w-96 space-y-6">
              {/* Requirements Panel */}
              {requirements.length > 0 && (
                <div className="architect-card p-5">
                  <h2 className="text-base font-semibold text-gray-900 mb-3 flex items-center">
                    <LayoutIcon className="w-4 h-4 mr-2 text-blue-500" />
                    Extracted Requirements ({requirements.length})
                  </h2>
                  <div className="max-h-[35vh] overflow-y-auto pr-1">
                    <ul className="space-y-3">
                      {requirements.map((req, index) => (
                        <li 
                          key={index} 
                          className="text-xs text-gray-600 bg-gray-50 p-3 rounded-lg border border-gray-100 hover:bg-blue-50 hover:border-blue-100 transition-colors"
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
                      className="w-full mt-4 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg px-4 py-2.5 flex items-center justify-center transition-colors"
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
                  completedFiles={architect.completedFiles}
                  totalFiles={architect.totalFiles}
                  currentSpecialist={architect.currentSpecialist}
                  totalSpecialists={architect.totalSpecialists}
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
          <div className="bg-red-50 border-l-4 border-red-400 p-4 mx-6 mb-4 rounded-r-lg">
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
        <div className="border-t border-gray-200 bg-white px-6 py-5 shadow-[0_-1px_2px_rgba(0,0,0,0.03)]">
          <form onSubmit={handleSubmit} className="max-w-4xl mx-auto">
            <div className="flex space-x-4">
              <textarea
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                className="flex-1 min-h-[85px] p-4 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none shadow-sm text-gray-900"
                placeholder="Describe your project idea..."
                disabled={isLoading}
              />
              <button
                type="submit"
                disabled={isLoading || !inputText.trim()}
                className={`px-6 py-3 bg-blue-600 text-white rounded-lg font-medium transition-all duration-200 flex items-center ${
                  isLoading || !inputText.trim()
                    ? 'opacity-50 cursor-not-allowed'
                    : 'hover:bg-blue-700 shadow-sm hover:shadow'
                }`}
              >
                {isLoading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                    Thinking...
                  </>
                ) : (
                  <>
                    <SendIcon className="w-4 h-4 mr-2" />
                    Send
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
EOF

# Update project-structure API route
echo "Updating project-structure API route..."
cat > src/app/api/project-structure/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { requirements, architectVision, folderStructure, implementationPlan } = await req.json();

    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }

    const systemPrompt = `You are an experienced software architect tasked with creating a project structure. Based on the provided requirements, architectural vision, folder structure, and implementation plan, generate a comprehensive project structure that follows best practices.

Requirements:
${requirements.join('\n')}

Architectural Vision:
${architectVision || 'No architectural vision provided.'}

Folder Structure:
${JSON.stringify(folderStructure.rootFolder || {}, null, 2)}

Dependency Tree:
${JSON.stringify(folderStructure.dependencyTree || {}, null, 2)}

Implementation Plan:
${JSON.stringify(implementationPlan || {}, null, 2)}

Respond with ONLY a JSON object in this format:
{
  "structure": {
    "description": "Brief overview of the architecture",
    "directories": [
      {
        "name": "directory-name",
        "description": "Purpose of this directory",
        "contents": [
          {
            "name": "file-or-subdirectory",
            "type": "file|directory",
            "description": "Purpose of this item",
            "tech": "Technology/framework used (if applicable)"
          }
        ]
      }
    ]
  }
}`;

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
        'x-api-key': process.env.CLAUDE_API_KEY!,
        'Authorization': `Bearer ${process.env.CLAUDE_API_KEY}`
      },
      body: JSON.stringify({
        model: 'claude-3-5-sonnet-latest',
        max_tokens: 4096,
        temperature: 0.7,
        system: systemPrompt,
        messages: [{ role: 'user', content: 'Generate project structure' }]
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Claude API error:', errorText);
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }
    
    const cleanText = data.content[0].text
      .replace(/^```json\s*|\s*```$/g, '')
      .replace(/^`|`$/g, '')
      .replace(/[\n\r\t]/g, ' ')
      .replace(/\s+/g, ' ');
    
    const structureResponse = JSON.parse(cleanText);

    return NextResponse.json(structureResponse);
  } catch (error) {
    console.error('Error generating project structure:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate project structure' },
      { status: 500 }
    );
  }
}
EOF

# Make the script executable and complete
chmod +x ./specialist-revamp.sh
echo "Implementation script completed successfully!"
echo ""
echo "Run this script to implement the multi-specialist approach for the architect system."
echo "All necessary files have been modified to support the new specialist-based generation flow."
echo ""
echo "Usage: ./specialist-revamp.sh"
#!/bin/bash

echo "Starting implementation of multi-specialist architect approach..."

# Create a backup directory
mkdir -p ./backups

# Backup current files
echo "Creating backups of current files..."
cp src/lib/types/architect.ts ./backups/architect.ts.bak 2>/dev/null || true
cp src/lib/services/architect.service.ts ./backups/architect.service.ts.bak 2>/dev/null || true
cp src/app/api/architect/route.ts ./backups/architect-route.ts.bak 2>/dev/null || true
cp src/lib/stores/conversation.ts ./backups/conversation.ts.bak 2>/dev/null || true
cp src/components/conversation/ArchitectOutput.tsx ./backups/ArchitectOutput.tsx.bak 2>/dev/null || true

# Update architect types
echo "Updating architect types..."
cat > src/lib/types/architect.ts << 'EOF'
export interface SpecialistVision {
  role: string;
  expertise: string;
  visionText: string;
  projectStructure: {
    rootFolder: FolderStructure;
  };
}

export interface ArchitectLevel1 {
  specialists: SpecialistVision[];
  roles: string[];
}

export interface FileNode {
  name: string;
  path: string;
  description: string;
  purpose: string;
  dependencies: string[];
  dependents: string[];
  implementationOrder: number;
  type: string;
}

export interface FolderStructure {
  name: string;
  description: string;
  purpose: string;
  files?: {
    name: string;
    description: string;
    purpose: string;
  }[];
  subfolders?: FolderStructure[];
}

export interface ArchitectLevel2 {
  integratedVision: string;
  rootFolder: FolderStructure;
  dependencyTree: {
    files: FileNode[];
  };
  resolutionNotes: string[];
}

export interface ComponentInfo {
  name: string;
  type: string;
  purpose: string;
  dependencies: string[];
  details: string;
}

export interface ParameterInfo {
  name: string;
  type: string;
  description: string;
  validation?: string;
  defaultValue?: string;
}

export interface ImplementationInfo {
  name: string;
  type: string;
  description: string;
  parameters?: ParameterInfo[];
  returnType?: string;
  logic: string;
}

export interface FileContext {
  name: string;
  path: string;
  type: string;
  description: string;
  purpose: string;
  dependencies: string[];
  imports: string[];
  components: ComponentInfo[];
  implementations: ImplementationInfo[];
  styling?: string;
  configuration?: string;
  stateManagement?: string;
  dataFlow?: string;
  errorHandling?: string;
  testingStrategy?: string;
  integrationPoints?: string;
  edgeCases?: string;
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
  completedFiles: number;
  totalFiles: number;
  currentSpecialist: number;
  totalSpecialists: number;
}
EOF

# Update architect service
echo "Updating architect service..."
cat > src/lib/services/architect.service.ts << 'EOF'
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, FileContext, FileNode, FolderStructure, SpecialistVision } from '../types/architect';

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
    // First try to extract JSON content if wrapped in backticks
    const startIndex = str.indexOf('{');
    const endIndex = str.lastIndexOf('}');
    
    if (startIndex === -1 || endIndex === -1 || endIndex <= startIndex) {
      console.error('Cannot find valid JSON object in the string');
      throw new Error('Cannot find valid JSON object in the response');
    }
    
    // Extract the JSON part
    let jsonPart = str.substring(startIndex, endIndex + 1);
    
    // Clean it up
    jsonPart = jsonPart.replace(/[\n\r\t]/g, ' ');
    jsonPart = jsonPart.replace(/\s+/g, ' ');
    jsonPart = jsonPart.replace(/\\([^"\\\/bfnrt])/g, '$1');
    
    return jsonPart;
  }

  private extractJsonFromText(text: string): string {
    try {
      // First attempt to extract JSON from code blocks
      const jsonRegex = /```json\s*([\s\S]*?)\s*```/;
      const match = text.match(jsonRegex);
      
      if (match && match[1]) {
        return match[1];
      }
      
      // If no code block found, try to extract raw JSON
      return this.cleanJsonString(text);
    } catch (error) {
      console.error('Error extracting JSON from text:', error);
      throw new Error('Failed to extract JSON from response');
    }
  }

  private async callClaude(systemPrompt: string, userMessage: string) {
    console.log('Calling Claude with system prompt:', systemPrompt.substring(0, 500) + '...');

    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
          'x-api-key': this.apiKey,
          'Authorization': `Bearer ${this.apiKey}`
        }
}));
EOF

# Update ArchitectOutput component
echo "Updating ArchitectOutput component..."
cat > src/components/conversation/ArchitectOutput.tsx << 'EOF'
import React, { useState } from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon, BrainIcon, SearchIcon, LayersIcon, TerminalIcon, Users2Icon } from 'lucide-react';
import { ArchitectLevel1, ArchitectLevel2, FileContext, SpecialistVision } from '../../lib/types/architect';

interface ArchitectOutputProps {
  level1Output: ArchitectLevel1 | null;
  level2Output: ArchitectLevel2 | null;
  level3Output: { implementationOrder: FileContext[] } | null;
  currentLevel: 1 | 2 | 3;
  isThinking: boolean;
  error: string | null;
  completedFiles: number;
  totalFiles: number;
  currentSpecialist: number;
  totalSpecialists: number;
  onProceedToNextLevel: () => void;
}

export function ArchitectOutput({
  level1Output,
  level2Output,
  level3Output,
  currentLevel,
  isThinking,
  error,
  completedFiles,
  totalFiles,
  currentSpecialist,
  totalSpecialists,
  onProceedToNextLevel
}: ArchitectOutputProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedFile, setExpandedFile] = useState<string | null>(null);
  const [selectedSpecialist, setSelectedSpecialist] = useState<number | null>(null);
  
  const getButtonText = () => {
    switch (currentLevel) {
      case 1:
        return 'Integrate Specialist Visions';
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
        return !!level1Output?.specialists && level1Output.specialists.length > 0;
      case 2:
        return !!level2Output?.rootFolder && !!level2Output?.integratedVision;
      case 3:
        return !!level3Output?.implementationOrder;
      default:
        return false;
    }
  };

  const getTotalFileCount = (rootFolder: any): number => {
    let count = 0;
    
    // Count files in this folder
    if (rootFolder.files && Array.isArray(rootFolder.files)) {
      count += rootFolder.files.length;
    }
    
    // Recursively count files in subfolders
    if (rootFolder.subfolders && Array.isArray(rootFolder.subfolders)) {
      for (const subfolder of rootFolder.subfolders) {
        count += getTotalFileCount(subfolder);
      }
    }
    
    return count;
  };
  
  const filteredImplementationOrder = level3Output?.implementationOrder?.filter(file => 
    file.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    file.path.toLowerCase().includes(searchTerm.toLowerCase()) ||
    file.description.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (error) {
    return (
      <div className="w-full bg-red-50 rounded-lg border border-red-200 p-4 mb-4">
        <h2 className="text-sm font-semibold text-red-900 mb-2">Error</h2>
        <p className="text-sm text-red-700">{error}</p>
      </div>
    );
  }

  if ((!level1Output && !isThinking) || (!level1Output?.specialists && !isThinking && currentLevel === 1)) return null;

  return (
    <div className="w-full architect-card p-5 mb-5">
      <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center">
        {currentLevel === 1 && <Users2Icon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 2 && <BrainIcon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 3 && <CodeIcon className="w-5 h-5 mr-2 text-blue-500" />}
        AI Architect - Phase {currentLevel}
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
            {currentLevel === 1 && (
              <div className="flex flex-col items-center">
                <span>Consulting with specialists...</span>
                {totalSpecialists > 0 && (
                  <div className="mt-2 w-full max-w-xs">
                    <div className="flex justify-between text-xs mb-1">
                      <span>{currentSpecialist} of {totalSpecialists} specialists</span>
                      <span>{Math.round((currentSpecialist / totalSpecialists) * 100)}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="h-2 rounded-full bg-blue-500"
                        style={{ width: `${(currentSpecialist / totalSpecialists) * 100}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
            )}
            {currentLevel === 2 && "CTO is integrating specialist visions..."}
            {currentLevel === 3 && (
              <div className="flex flex-col items-center">
                <span>Generating implementation plans...</span>
                {totalFiles > 0 && (
                  <div className="mt-2 w-full max-w-xs">
                    <div className="flex justify-between text-xs mb-1">
                      <span>{completedFiles} of {totalFiles} files</span>
                      <span>{Math.round((completedFiles / totalFiles) * 100)}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="h-2 rounded-full bg-blue-500"
                        style={{ width: `${(completedFiles / totalFiles) * 100}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
            )}
          </span>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Phase Title */}
          <div className="text-center mb-4">
            <h3 className="text-lg font-semibold text-blue-700">
              {currentLevel === 1 && "Specialist Visions"}
              {currentLevel === 2 && "Integrated Architecture"}
              {currentLevel === 3 && "Implementation Blueprint"}
            </h3>
            <p className="text-sm text-gray-500">
              {currentLevel === 1 && `${level1Output?.specialists?.length || 0} specialists have provided their expert insights`}
              {currentLevel === 2 && `CTO's unified architecture with dependency tree (${level2Output?.dependencyTree?.files?.length || 0} files)`}
              {currentLevel === 3 && `Detailed implementation instructions for ${level3Output?.implementationOrder?.length || 0} files`}
            </p>
          </div>
          
          {/* Level 1: Specialist Visions */}
          {currentLevel === 1 && level1Output?.specialists && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <Users2Icon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Specialist Team
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {level1Output.specialists.length} specialists
                </div>
              </div>
              
              {/* Specialist selector tabs */}
              <div className="flex flex-wrap gap-2 mb-4">
                {level1Output.specialists.map((specialist, idx) => (
                  <button
                    key={idx}
                    className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                      selectedSpecialist === idx 
                        ? 'bg-blue-600 text-white' 
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                    onClick={() => setSelectedSpecialist(idx)}
                  >
                    {specialist.role}
                  </button>
                ))}
                <button
                  className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                    selectedSpecialist === null 
                      ? 'bg-blue-600 text-white' 
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                  onClick={() => setSelectedSpecialist(null)}
                >
                  All Specialists
                </button>
              </div>
              
              {/* Selected specialist detail or all specialists */}
              {selectedSpecialist !== null ? (
                // Single specialist detail view
                <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
                  <div className="mb-3">
                    <h4 className="text-base font-medium text-gray-900">{level1Output.specialists[selectedSpecialist].role}</h4>
                    <p className="text-sm text-gray-600">{level1Output.specialists[selectedSpecialist].expertise}</p>
                  </div>
                  
                  <div className="mb-4">
                    <h5 className="text-sm font-medium text-gray-800 mb-2">Vision</h5>
                    <div className="text-sm text-gray-700 bg-white rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200 prose prose-sm">
                      {level1Output.specialists[selectedSpecialist].visionText.split('\n\n').map((paragraph, idx) => (
                        <p key={idx} className="mb-4">{paragraph}</p>
                      ))}
                    </div>
                  </div>
                  
                  <div>
                    <h5 className="text-sm font-medium text-gray-800 mb-2">Proposed Structure</h5>
                    <div className="bg-white rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200">
                      {renderFolderStructure(level1Output.specialists[selectedSpecialist].projectStructure.rootFolder)}
                    </div>
                  </div>
                </div>
              ) : (
                // All specialists summary view
                <div className="space-y-4">
                  {level1Output.specialists.map((specialist, idx) => (
                    <div key={idx} className="bg-gray-50 rounded-lg p-4 border border-gray-200">
                      <div className="flex justify-between items-start">
                        <div>
                          <h4 className="text-base font-medium text-gray-900">{specialist.role}</h4>
                          <p className="text-sm text-gray-600">{specialist.expertise}</p>
                        </div>
                        <button
                          className="text-xs bg-blue-50 hover:bg-blue-100 text-blue-700 px-3 py-1 rounded-full transition-colors"
                          onClick={() => setSelectedSpecialist(idx)}
                        >
                          Full Details
                        </button>
                      </div>
                      
                      <div className="mt-3">
                        <h5 className="text-xs font-medium text-gray-800 mb-1">Key Points</h5>
                        <div className="text-xs text-gray-700 bg-white rounded p-3 border border-gray-100 line-clamp-3">
                          {specialist.visionText.substring(0, 180)}...
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Level 2: Integrated Vision */}
          {currentLevel === 2 && level2Output && (
            <div className="space-y-6">
              {/* Integrated Vision */}
              <div>
                <div className="mb-3 flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <BrainIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      CTO's Integrated Vision
                    </h3>
                  </div>
                </div>
                
                <div className="text-sm text-gray-700 bg-gray-50 rounded-lg p-5 max-h-[300px] overflow-y-auto border border-gray-200 prose prose-sm">
                  {level2Output.integratedVision.split('\n\n').map((paragraph, idx) => (
                    <p key={idx} className="mb-4">{paragraph}</p>
                  ))}
                </div>
              </div>
              
              {/* Resolution Notes */}
              {level2Output.resolutionNotes && level2Output.resolutionNotes.length > 0 && (
                <div className="mt-4">
                  <h4 className="text-sm font-medium text-gray-800 mb-2">Resolution Notes</h4>
                  <div className="bg-yellow-50 rounded-lg p-4 border border-yellow-100">
                    <ul className="list-disc pl-5 space-y-2">
                      {level2Output.resolutionNotes.map((note, idx) => (
                        <li key={idx} className="text-sm text-gray-700">{note}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              )}
              
              {/* Project Structure */}
              <div>
                <div className="mb-3 flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <LayersIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      Integrated Project Structure
                    </h3>
                  </div>
                  <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                    {level2Output.dependencyTree?.files?.length || 0} files
                  </div>
                </div>
                
                <div className="bg-gray-50 rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200">
                  {renderFolderStructure(level2Output.rootFolder)}
                </div>
              </div>
              
              {/* Dependency Tree */}
              <div>
                <div className="mb-3 flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <CodeIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Implementation Order
                  </h3>
                </div>
                
                <div className="bg-gray-50 rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200">
                  <div className="space-y-2">
                    {level2Output.dependencyTree?.files?.sort((a, b) => a.implementationOrder - b.implementationOrder)
                      .map((file, index) => (
                        <div key={index} className="flex items-start">
                          <div className="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center mr-2 flex-shrink-0 text-xs font-medium">
                            {file.implementationOrder}
                          </div>
                          <div>
                            <div className="flex items-center">
                              <FileIcon className="h-4 w-4 mr-2 text-gray-500" />
                              <span className="font-medium text-gray-900">{file.path}/{file.name}</span>
                            </div>
                            <p className="text-xs text-gray-600 mt-1">{file.description}</p>
                            {file.dependencies.length > 0 && (
                              <div className="mt-1">
                                <span className="text-xs text-gray-500">Depends on: </span>
                                <div className="flex flex-wrap gap-1 mt-1">
                                  {file.dependencies.map((dep, idx) => (
                                    <span key={idx} className="text-xs bg-gray-100 px-2 py-0.5 rounded text-gray-600">
                                      {dep}
                                    </span>
                                  ))}
                                </div>
                              </div>
                            )}
                          </div>
                        </div>
                      ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Level 3: Implementation Plan */}
          {currentLevel === 3 && level3Output && level3Output.implementationOrder && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <CodeIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Implementation Details
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {level3Output.implementationOrder.length} files
                </div>
              </div>
              
              {/* Search bar */}
              <div className="relative mb-4">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <SearchIcon className="h-4 w-4 text-gray-400" />
                </div>
                <input
                  type="text"
                  className="bg-white border border-gray-300 rounded-md py-2 pl-10 pr-4 w-full text-sm text-gray-900 focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Search files..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4 max-h-[600px] overflow-y-auto border border-gray-200">
                {filteredImplementationOrder && filteredImplementationOrder.length > 0 ? (
                  <div className="space-y-4">
                    {filteredImplementationOrder.map((file, index) => (
                      <div 
                        key={index} 
                        className={`mb-4 last:mb-0 text-sm border-b border-gray-200 pb-4 last:border-b-0 ${
                          expandedFile === `${file.path}/${file.name}` ? 'bg-blue-50 p-2 rounded' : ''
                        }`}
                      >
                        <div 
                          className="flex items-start cursor-pointer"
                          onClick={() => setExpandedFile(expandedFile === `${file.path}/${file.name}` ? null : `${file.path}/${file.name}`)}
                        >
                          <FileIcon className="w-4 h-4 mt-1 text-blue-500 mr-2 flex-shrink-0" />
                          <div className="flex-1">
                            <p className="font-medium text-gray-800">
                              {file.path}/{file.name}
                            </p>
                            <p className="text-xs text-gray-500 mt-1">
                              Type: {file.type} | Purpose: {file.purpose}
                            </p>
                          </div>
                          <div className="text-xs bg-gray-100 rounded-md px-2 py-0.5 text-gray-500">
                            {expandedFile === `${file.path}/${file.name}` ? 'Hide' : 'Details'}
                          </div>
                        </div>
                        
                        {expandedFile === `${file.path}/${file.name}` && (
                          <div className="mt-3 ml-6 text-sm">
                            <div className="bg-white p-3 rounded border border-gray-200 mb-3">
                              <p className="text-gray-600">{file.description}</p>
                            </div>
                            
                            {file.dependencies && file.dependencies.length > 0 && (
                              <div className="mt-2 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Dependencies:</p>
                                <div className="flex flex-wrap gap-1">
                                  {file.dependencies.map((dep, idx) => (
                                    <span key={idx} className="text-xs bg-gray-100 px-2 py-0.5 rounded text-gray-600">
                                      {dep}
                                    </span>
                                  ))}
                                </div>
                              </div>
                            )}

                            {file.imports && file.imports.length > 0 && (
                              <div className="mt-2 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Imports:</p>
                                <div className="bg-gray-50 p-2 rounded text-xs font-mono text-gray-600">
                                  {file.imports.map((imp, idx) => (
                                    <div key={idx}>{imp}</div>
                                  ))}
                                </div>
                              </div>
                            )}
                            
                            {file.components && file.components.length > 0 && (
                              <div className="mt-3 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Components:</p>
                                <div className="space-y-2">
                                  {file.components.map((component, idx) => (
                                    <div key={idx} className="text-xs bg-gray-100 p-2 rounded border border-gray-200">
                                      <p className="font-medium text-gray-800">{component.name} ({component.type})</p>
                                      <p className="text-gray-600 mt-1">{component.details}</p>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                            
                            {file.implementations && file.implementations.length > 0 && (
                              <div className="mt-3 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Implementations:</p>
                                <div className="space-y-3">
                                  {file.implementations.map((impl, idx) => (
                                    <div key={idx} className="bg-white p-2 rounded border border-gray-200">
                                      <p className="font-medium text-gray-800 text-xs">{impl.name}: {impl.type}</p>
                                      <p className="text-gray-600 text-xs mt-1">{impl.description}</p>
                                      
                                      {impl.parameters && impl.parameters.length > 0 && (
                                        <div className="mt-2">
                                          <p className="text-xs font-medium text-gray-600">Parameters:</p>
                                          <ul className="text-xs pl-4 list-disc">
                                            {impl.parameters.map((param, pidx) => (
                                              <li key={pidx}>
                                                <span className="font-mono">{param.name}</span> ({param.type}): {param.description}
                                              </li>
                                            ))}
                                          </ul>
                                        </div>
                                      )}
                                      
                                      {impl.returnType && (
                                        <p className="text-xs text-gray-600 mt-1">
                                          Returns: <span className="font-mono">{impl.returnType}</span>
                                        </p>
                                      )}
                                      
                                      {impl.logic && (
                                        <div className="mt-2 border-t border-gray-100 pt-2">
                                          <p className="text-xs font-medium text-gray-600">Implementation:</p>
                                          <p className="text-xs text-gray-600">{impl.logic}</p>
                                        </div>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                            
                            {file.testingStrategy && (
                              <div className="mt-2 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Testing Strategy:</p>
                                <p className="text-xs bg-gray-100 p-2 rounded text-gray-600">{file.testingStrategy}</p>
                              </div>
                            )}
                            
                            {file.additionalContext && (
                              <div className="mt-2 text-xs italic bg-yellow-50 p-2 rounded text-gray-600 border border-yellow-100">
                                <p className="font-medium text-yellow-700 mb-1">Additional Notes:</p>
                                {file.additionalContext}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-4 text-gray-500">
                    {searchTerm ? "No files match your search" : "No implementation details found"}
                  </div>
                )}
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

function renderFolderStructure(folder: any, depth = 0) {
  if (!folder) {
    return <div className="text-red-500 text-xs">Error: Invalid folder structure</div>;
  }
  
  return (
    <div className={`${depth > 0 ? 'ml-4' : ''} text-sm`}>
      <div className="flex items-start mb-2">
        <FolderIcon className="w-4 h-4 mt-1 text-blue-500 flex-shrink-0" />
        <div className="ml-2">
          <p className="font-medium text-gray-800">{folder.name}</p>
          <p className="text-xs text-gray-600">{folder.description}</p>
          {folder.purpose && (
            <p className="text-xs text-gray-500 italic">Purpose: {folder.purpose}</p>
          )}
        </div>
      </div>
      
      {/* Files */}
      {folder.files && folder.files.length > 0 && (
        <div className="ml-4 space-y-2 mt-2">
          {folder.files.map((file: any, fileIndex: number) => (
            <div key={fileIndex} className="flex items-start">
              <FileIcon className="w-4 h-4 mt-1 text-gray-500 flex-shrink-0" />
              <div className="ml-2">
                <p className="font-medium text-gray-700 text-xs">{file.name}</p>
                <p className="text-xs text-gray-500">{file.description}</p>
              </div>
            </div>
          ))}
        </div>
      )}
      
      {/* Subfolders */}
      {folder.subfolders?.map((subfolder: any, index: number) => (
        <div key={index} className="ml-4 mt-3 border-l-2 border-gray-100 pl-3">
          {renderFolderStructure(subfolder, depth + 1)}
        </div>
      ))}
    </div>
  );
}
  
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
        totalFiles: 0,
        currentSpecialist: 0,
        totalSpecialists: 0
      },
    });
  },
        body: JSON.stringify({
          model: this.MODEL,
          max_tokens: 4096,
          temperature: 0.2,
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
        const rawText = data.content[0].text;
        const jsonText = this.extractJsonFromText(rawText);
        console.log('Extracted JSON (first 200 chars):', jsonText.substring(0, 200) + '...');
        
        const parsedResponse = JSON.parse(jsonText);
        return parsedResponse;
      } catch (e) {
        console.error('Failed to parse Claude response:', {
          error: e,
          rawResponse: data.content[0].text.substring(0, 200) + '...'
        });
        
        throw new Error(`Failed to parse Claude response: ${e instanceof Error ? e.message : String(e)}`);
      }
    } catch (error) {
      console.error('Error in Claude API call:', error);
      throw error;
    }
  }

  private determineSpecialistsNeeded(requirements: string[]): string[] {
    const requirementsText = requirements.join('\n').toLowerCase();
    
    // Base specialists that are almost always needed
    const specialists = ['Backend Developer', 'Frontend Developer'];
    
    // Conditionally add specialists based on requirements
    if (requirementsText.includes('ui') || 
        requirementsText.includes('user interface') || 
        requirementsText.includes('design') || 
        requirementsText.includes('user experience') || 
        requirementsText.includes('ux')) {
      specialists.push('UI/UX Designer');
    }
    
    if (requirementsText.includes('database') || 
        requirementsText.includes('data') || 
        requirementsText.includes('storage') || 
        requirementsText.includes('sql') || 
        requirementsText.includes('nosql')) {
      specialists.push('Database Architect');
    }
    
    if (requirementsText.includes('security') || 
        requirementsText.includes('authentication') || 
        requirementsText.includes('authorization') || 
        requirementsText.includes('encrypt') || 
        requirementsText.includes('privacy')) {
      specialists.push('Security Specialist');
    }
    
    if (requirementsText.includes('scale') || 
        requirementsText.includes('performance') || 
        requirementsText.includes('load balancing') || 
        requirementsText.includes('cloud') || 
        requirementsText.includes('aws') || 
        requirementsText.includes('azure') || 
        requirementsText.includes('containerization') || 
        requirementsText.includes('docker') || 
        requirementsText.includes('kubernetes')) {
      specialists.push('DevOps Engineer');
    }
    
    if (requirementsText.includes('mobile') || 
        requirementsText.includes('ios') || 
        requirementsText.includes('android') || 
        requirementsText.includes('app')) {
      specialists.push('Mobile Developer');
    }
    
    if (requirementsText.includes('test') || 
        requirementsText.includes('quality') || 
        requirementsText.includes('qa')) {
      specialists.push('QA Engineer');
    }
    
    if (requirementsText.includes('ml') || 
        requirementsText.includes('machine learning') || 
        requirementsText.includes('ai') || 
        requirementsText.includes('artificial intelligence') || 
        requirementsText.includes('model') || 
        requirementsText.includes('prediction') || 
        requirementsText.includes('neural') || 
        requirementsText.includes('data science')) {
      specialists.push('Machine Learning Engineer');
    }
    
    if (requirementsText.includes('blockchain') || 
        requirementsText.includes('crypto') || 
        requirementsText.includes('smart contract') || 
        requirementsText.includes('web3')) {
      specialists.push('Blockchain Developer');
    }

    // Add CTO/System Architect as the "owner" role that will later integrate everything
    specialists.push('Chief Technology Officer');
    
    return specialists;
  }

  async generateSpecialistVision(requirements: string[], role: string, specialistIndex: number, totalSpecialists: number): Promise<SpecialistVision> {
    console.log(`Generating vision for specialist ${specialistIndex + 1}/${totalSpecialists}: ${role}`);
    
    const systemPrompt = `You are an expert ${role} with extensive experience in software development.

Your task is to create a comprehensive vision and project structure for a software project based on the provided requirements, focusing specifically on your area of expertise as a ${role}.

Consider the following aspects in your area of expertise:
1. Technology recommendations specific to your role
2. Architecture patterns you would apply
3. Best practices you would follow
4. Potential challenges and solutions
5. Project structure components relevant to your role

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "role": "${role}",
  "expertise": "Brief description of your professional role and expertise",
  "visionText": "Your detailed vision for this project, from your perspective as a ${role} (in plain text with paragraphs separated by newlines)",
  "projectStructure": {
    "rootFolder": {
      "name": "project-root",
      "description": "Root directory description",
      "purpose": "Main project folder",
      "files": [
        {
          "name": "filename.ext",
          "description": "Detailed description of this file",
          "purpose": "What this file accomplishes"
        }
      ],
      "subfolders": [
        {
          "name": "subfolder-name",
          "description": "Subfolder description",
          "purpose": "Subfolder purpose",
          "files": [
            {
              "name": "filename.ext",
              "description": "Detailed description of this file",
              "purpose": "What this file accomplishes"
            }
          ],
          "subfolders": []
        }
      ]
    }
  }
}

NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.

Remember to emphasize your specific expertise as a ${role} in your vision and structure.`;

    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }

  async generateLevel1(requirements: string[]): Promise<ArchitectLevel1> {
    console.log('Determining specialists needed for the project...');
    
    // Determine which specialists are needed based on requirements
    const roles = this.determineSpecialistsNeeded(requirements);
    console.log(`Selected specialists: ${roles.join(', ')}`);
    
    // Initialize empty specialists array
    const specialists: SpecialistVision[] = [];
    
    // For each role, generate a specialist vision
    for (let i = 0; i < roles.length - 1; i++) { // Skip the CTO for now, will be used in level 2
      const role = roles[i];
      const specialist = await this.generateSpecialistVision(requirements, role, i, roles.length - 1);
      specialists.push(specialist);
    }
    
    return {
      specialists,
      roles
    };
  }

  async generateLevel2(requirements: string[], level1Output: ArchitectLevel1): Promise<ArchitectLevel2> {
    console.log('Generating integrated project vision and structure as CTO...');
    
    if (!level1Output.specialists || level1Output.specialists.length === 0) {
      throw new Error('No specialist visions available to integrate');
    }
    
    const specialistVisions = level1Output.specialists;
    
    const systemPrompt = `You are the Chief Technology Officer (CTO) of a software company.

Your task is to integrate various specialist visions and project structures into a cohesive, comprehensive plan. You must create a unified architectural vision that addresses all aspects of the project, resolve any conflicts between specialist recommendations, and build a complete project structure.

The specialists have provided their visions and proposed structures. You need to:
1. Create an integrated vision that combines the best ideas from all specialists
2. Resolve any conflicting recommendations between specialists
3. Create a unified project structure that covers all aspects of the project
4. Generate a dependency tree for implementation order

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "integratedVision": "Your comprehensive architectural vision combining all specialist insights (in plain text with paragraphs separated by newlines)",
  "resolutionNotes": [
    "Note on how you resolved conflict/challenge #1 between specialists",
    "Note on how you resolved conflict/challenge #2 between specialists"
  ],
  "rootFolder": {
    "name": "project-root",
    "description": "Root directory description",
    "purpose": "Main project folder",
    "files": [
      {
        "name": "filename.ext",
        "description": "Detailed description of this file",
        "purpose": "What this file accomplishes"
      }
    ],
    "subfolders": [
      {
        "name": "subfolder-name",
        "description": "Subfolder description",
        "purpose": "Subfolder purpose",
        "files": [
          {
            "name": "filename.ext",
            "description": "Detailed description of this file",
            "purpose": "What this file accomplishes"
          }
        ],
        "subfolders": []
      }
    ]
  },
  "dependencyTree": {
    "files": [
      {
        "name": "filename.ext",
        "path": "/relative/path/filename.ext",
        "description": "Description of this file",
        "purpose": "What this file accomplishes",
        "dependencies": ["list of file paths this file depends on"],
        "dependents": ["list of file paths that depend on this file"],
        "implementationOrder": 1,
        "type": "file type (e.g., component, model, controller, etc.)"
      }
    ]
  }
}

The "files" array in the dependencyTree must include ALL files from the project structure.
The implementationOrder values should start from 1 (no dependencies) and increase as dependencies increase.
Files with no dependencies should have an empty dependencies array.
The dependency analysis must be thorough and accurate.

NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

    // Format specialist visions for prompt
    const specialistVisionsFormatted = specialistVisions.map((sv, i) => 
      `Specialist ${i+1}: ${sv.role}
Expertise: ${sv.expertise}
Vision:
${sv.visionText}

Project Structure:
${JSON.stringify(sv.projectStructure, null, 2)}
`).join('\n\n--------------\n\n');

    return this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Specialist Visions:
${specialistVisionsFormatted}`);
  }

  async generateLevel3(
    requirements: string[],
    level2Output: ArchitectLevel2
  ): Promise<ArchitectLevel3> {
    console.log('Generating implementation contexts based on dependency tree');
    
    if (!level2Output || !level2Output.rootFolder || !level2Output.dependencyTree) {
      console.error('Invalid level2Output provided to generateLevel3:', level2Output);
      throw new Error('Invalid level 2 output: missing rootFolder or dependencyTree property');
    }
    
    const dependencyTree = level2Output.dependencyTree;
    
    if (!dependencyTree.files || !Array.isArray(dependencyTree.files) || dependencyTree.files.length === 0) {
      throw new Error('Invalid dependency tree: no files found');
    }
    
    // Sort files by implementation order
    const sortedFiles = [...dependencyTree.files].sort((a, b) => a.implementationOrder - b.implementationOrder);
    
    // Process files in implementation order
    const implementationOrder: FileContext[] = [];
    
    for (const file of sortedFiles) {
      console.log(`Generating implementation context for ${file.path}/${file.name} (order: ${file.implementationOrder})`);
      
      // Get dependencies
      const dependencies = file.dependencies || [];
      
      // Collect context from dependencies
      const dependencyContexts = dependencyTree.files
        .filter(f => dependencies.includes(`${f.path}/${f.name}`))
        .map(f => ({
          name: f.name,
          path: f.path,
          purpose: f.purpose,
          description: f.description
        }));
      
      // Generate implementation context for this file
      const fileContext = await this.generateFileContext(file, dependencyContexts, requirements, level2Output.integratedVision);
      implementationOrder.push(fileContext);
    }
    
    return { implementationOrder };
  }
  
  private async generateFileContext(
    file: FileNode,
    dependencyContexts: any[],
    requirements: string[],
    visionText: string
  ): Promise<FileContext> {
    const systemPrompt = `You are a master software engineer. Your task is to create an EXTREMELY DETAILED implementation context for a specific file.

This implementation context must be comprehensive enough that ANY programmer could implement the file perfectly from just this description.

Your implementation context must:

1. Describe EVERY function, class, variable, and component in great detail
2. Explain ALL business logic as detailed pseudocode in natural language
3. Include EVERY import, dependency, and relationship
4. Specify ALL parameters, return types, error handling approaches
5. Describe the data flow through each function
6. Explain design patterns and principles being used
7. Cover edge cases, error states, and validation requirements
8. Include initialization, lifecycle methods, and cleanup
9. Specify file configuration, environment variables, and connection details
10. Include complete descriptions of HTML/CSS layouts where applicable

Think of this implementation context as an exhaustive guide that contains EVERY PIECE OF INFORMATION needed to build the file without additional guidance.

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "name": "${file.name}",
  "path": "${file.path}",
  "type": "${file.type}",
  "description": "${file.description}",
  "purpose": "${file.purpose}",
  "dependencies": ${JSON.stringify(file.dependencies || [])},
  "imports": ["All required imports with specific versions if applicable"],
  "components": [
    {
      "name": "component name (class/function/etc.)",
      "type": "component type (class/function/object/etc.)",
      "purpose": "what this component does",
      "dependencies": ["component dependencies"],
      "details": "EXTREMELY DETAILED implementation instructions describing every aspect of this component"
    }
  ],
  "implementations": [
    {
      "name": "function/method name",
      "type": "function/class/constant/etc.",
      "description": "what this implements",
      "parameters": [
        {
          "name": "param name",
          "type": "param type",
          "description": "detailed param description",
          "validation": "validation requirements",
          "defaultValue": "default value if applicable"
        }
      ],
      "returnType": "return type if applicable",
      "logic": "COMPREHENSIVE step-by-step implementation details in plain English, written as an extremely detailed paragraph that covers EVERY aspect of the implementation. This should be extremely extensive, describing every variable, every condition, every edge case, and the exact logic flow as if writing pseudocode in natural language. Include ALL validation, ALL error handling, ALL business logic, and EVERY step in the process."
    }
  ],
  "styling": "If applicable, detailed description of styling/CSS",
  "configuration": "Any configuration details and settings",
  "stateManagement": "How state is managed in this file",
  "dataFlow": "Comprehensive description of data flow through this file",
  "errorHandling": "Complete error handling strategy for this file",
  "testingStrategy": "Detailed approach to testing this file",
  "integrationPoints": "All integration points with other system components",
  "edgeCases": "All edge cases that need to be handled",
  "additionalContext": "Any other implementation details the developer needs to know to implement this file correctly and completely"
}

NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

    const userMessage = `
File to Implement:
Name: ${file.name}
Path: ${file.path}
Description: ${file.description}
Purpose: ${file.purpose}
Type: ${file.type}
Dependencies: ${JSON.stringify(file.dependencies || [])}
Dependents: ${JSON.stringify(file.dependents || [])}
Implementation Order: ${file.implementationOrder}

Dependency Contexts:
${JSON.stringify(dependencyContexts, null, 2)}

Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}

Please generate a COMPREHENSIVE implementation context for this specific file.
`;

    return this.callClaude(systemPrompt, userMessage);
  }
}

export const architectService = ArchitectService.getInstance();
EOF

# Update architect API route
echo "Updating architect API route..."
cat > src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';
import { ArchitectLevel1 } from '../../../lib/types/architect';

export async function POST(req: NextRequest) {
  try {
    console.log('=== ARCHITECT API REQUEST RECEIVED ===');
    
    const body = await req.json();
    const { level, requirements, level1Output, level2Output } = body;
    
    console.log(`Architect API level ${level} request received`);
    
    if (!requirements || !Array.isArray(requirements)) {
      console.log('ERROR: Valid requirements array is required');
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }
    
    let result;
    switch (level) {
      case 1:
        console.log('Generating level 1: Specialist Visions');
        result = await architectService.generateLevel1(requirements);
        break;
        
      case 2:
        console.log('Generating level 2: Integrated Vision and Structure');
        if (!level1Output || !level1Output.specialists || !Array.isArray(level1Output.specialists)) {
          console.log('ERROR: Valid level1Output with specialists array is required for level 2');
          return NextResponse.json({ 
            error: 'Valid level1Output with specialists array is required for level 2' 
          }, { status: 400 });
        }
        result = await architectService.generateLevel2(requirements, level1Output);
        break;
        
      case 3:
        console.log('Generating level 3: Implementation Plans');
        if (!level2Output || !level2Output.rootFolder || !level2Output.dependencyTree) {
          console.log('ERROR: Valid level2Output with rootFolder and dependencyTree is required for level 3');
          return NextResponse.json({ 
            error: 'Valid level2Output with rootFolder and dependencyTree is required for level 3' 
          }, { status: 400 });
        }
        
        result = await architectService.generateLevel3(requirements, level2Output);
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

# Update conversation store
echo "Updating conversation store..."
cat > src/lib/stores/conversation.ts << 'EOF'
import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, ArchitectState, FileNode, SpecialistVision } from '../types/architect';

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
    totalFiles: 0,
    currentSpecialist: 0,
    totalSpecialists: 0
  },
  
  generateArchitectLevel1: async () => {
    const state = get();
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting specialist vision generation');
    
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
          totalFiles: 0,
          currentSpecialist: 0,
          totalSpecialists: 0
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
        throw new Error(`Failed to generate specialist visions: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Specialist visions generated successfully');
      
      if (!data.specialists || !Array.isArray(data.specialists)) {
        throw new Error('Invalid response from architect: missing specialists array');