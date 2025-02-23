#!/bin/bash

# Create backup directory
mkdir -p ./backups

# Create backup of original files
echo "Creating backups..."
cp src/lib/claude/index.ts ./backups/index.ts.bak 2>/dev/null || true
cp src/lib/stores/conversation.ts ./backups/conversation.ts.bak 2>/dev/null || true
cp src/components/conversation/ConversationUI.tsx ./backups/ConversationUI.tsx.bak 2>/dev/null || true

# Create ArchitectOutput component
echo "Creating ArchitectOutput component..."
cat > src/components/conversation/ArchitectOutput.tsx << 'EOF'
import React from 'react';
import { CodeIcon, Send } from 'lucide-react';

interface ArchitectOutputProps {
  architectOutput: string | null;
  onPassToConstructor: () => void;
  isLoading: boolean;
}

export function ArchitectOutput({ architectOutput, onPassToConstructor, isLoading }: ArchitectOutputProps) {
  if (!architectOutput && !isLoading) return null;

  return (
    <div className="fixed bottom-4 right-4 w-96 bg-white rounded-lg shadow-lg border border-gray-200 p-4 transition-all duration-300 ease-in-out">
      <h2 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
        <CodeIcon className="w-4 h-4 mr-1" />
        Architect's Vision
      </h2>
      
      {isLoading ? (
        <div className="flex items-center justify-center space-x-2 py-4">
          <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600">Architect is thinking...</span>
        </div>
      ) : (
        <>
          <div className="max-h-[60vh] overflow-y-auto">
            <div className="text-sm text-gray-600 whitespace-pre-wrap">
              {architectOutput}
            </div>
          </div>
          
          <button
            onClick={onPassToConstructor}
            className="mt-4 w-full bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg px-4 py-2 flex items-center justify-center transition-colors"
          >
            <Send className="w-4 h-4 mr-2" />
            Pass to Constructor
          </button>
        </>
      )}
    </div>
  );
}
EOF

# Create/update architect API route
echo "Creating architect API route..."
mkdir -p src/app/api/architect
cat > src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { requirements } = await req.json();

    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }

    const systemPrompt = `You are an exceptionally experienced software architect with decades of experience in designing and implementing complex systems. A development team has provided you with a set of requirements, and your task is to create a comprehensive, highly detailed architectural vision for implementing these requirements.

As a master architect, provide an in-depth analysis and implementation strategy that covers:

1. System Architecture Overview
   - High-level system design
   - Component interactions
   - Data flow patterns

2. Implementation Strategy
   - Technology stack recommendations
   - Development approach
   - Project phases and milestones

3. Technical Considerations
   - Performance optimization strategies
   - Scalability considerations
   - Security measures
   - Error handling approaches

4. Best Practices and Patterns
   - Design patterns to be used
   - Code organization principles
   - Testing strategies
   - Documentation requirements

5. Potential Challenges and Solutions
   - Identified technical risks
   - Mitigation strategies
   - Alternative approaches

6. Integration Points
   - External system interactions
   - API design principles
   - Service communication patterns

7. Deployment and DevOps
   - Infrastructure requirements
   - CI/CD pipeline recommendations
   - Monitoring and logging strategies

Be extremely specific and detailed in your response. Write as if you're guiding senior developers through implementation. Include concrete technical recommendations and justify your architectural decisions.

Requirements:
${requirements.join('\n')}

Focus on providing actionable insights and practical implementation guidance. The response should be comprehensive yet clear and structured.

Respond with a JSON object in this format:
{
  "architectOutput": "Your detailed architectural vision here"
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
        messages: [{ role: 'user', content: 'Provide architectural vision' }]
      })
    });

    if (!response.ok) {
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }

    let parsedResponse;
    try {
      parsedResponse = JSON.parse(data.content[0].text);
    } catch (e: unknown) {
      const error = e instanceof Error ? e : new Error(String(e));
      console.error('Failed to parse Claude response:', error);
      throw new Error(`Failed to parse architect response: ${error.message}`);
    }

    return NextResponse.json({ architectOutput: parsedResponse.architectOutput });
  } catch (error) {
    console.error('Error in architect API:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate architect output' },
      { status: 500 }
    );
  }
}
EOF

# Update project structure API
echo "Updating project structure API..."
cat > src/app/api/project-structure/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { requirements, architectOutput } = await req.json();

    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }

    const systemPrompt = `You are an experienced software architect tasked with creating a project structure. Based on the provided requirements and architectural vision, generate a comprehensive project structure that follows best practices.

Requirements:
${requirements.join('\n')}

Architectural Vision:
${architectOutput || 'No additional architectural guidance provided.'}

Create a detailed project structure that:
1. Follows the architectural vision
2. Implements all requirements effectively
3. Uses modern best practices
4. Is maintainable and scalable
5. Includes clear organization of components

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
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }

    let structureResponse;
    try {
      structureResponse = JSON.parse(data.content[0].text);
    } catch (e: unknown) {
      const error = e instanceof Error ? e : new Error(String(e));
      console.error('Failed to parse structure response:', error);
      throw new Error(`Failed to parse structure response: ${error.message}`);
    }

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

# Update conversation store
echo "Updating conversation store..."
cat > src/lib/stores/conversation.ts << 'EOF'
import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';

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

interface ConversationStore {
  messages: Message[];
  context: ConversationContext;
  isLoading: boolean;
  error: string | null;
  projectId: string | null;
  conversationId: string | null;
  projectStructure: any | null;
  isGeneratingStructure: boolean;
  architectOutput: string | null;
  isArchitectThinking: boolean;
  initializeProject: () => Promise<void>;
  loadConversation: (conversationId: string) => Promise<void>;
  sendMessage: (content: string) => Promise<void>;
  generateArchitectOutput: () => Promise<void>;
  generateProjectStructure: (architectOutput: string) => Promise<void>;
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
  architectOutput: null,
  isArchitectThinking: false,

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

  generateArchitectOutput: async () => {
    const state = get();
    const requirements = state.context.extractedInfo.requirements;

    if (!requirements?.length) {
      set({ error: 'No requirements available for the architect' });
      return;
    }

    try {
      set({ isArchitectThinking: true, error: null });

      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ requirements }),
      });

      if (!response.ok) {
        throw new Error(`Failed to generate architect output: ${response.statusText}`);
      }

      const data = await response.json();
      set({ architectOutput: data.architectOutput, isArchitectThinking: false });
    } catch (error) {
      console.error('Error generating architect output:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to generate architect output',
        isArchitectThinking: false,
      });
    }
  },

  generateProjectStructure: async (architectOutput: string) => {
    const state = get();
    const requirements = state.context.extractedInfo.requirements;

    if (!requirements?.length) {
      set({ error: 'No requirements available to generate project structure' });
      return;
    }

    try {
      set({ isGeneratingStructure: true, error: null });

      const response = await fetch('/api/project-structure', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ requirements, architectOutput }),
      });

      if (!response.ok) {
        throw new Error(`Failed to generate project structure: ${response.statusText}`);
      }

      const data = await response.json();
      set({ projectStructure: data.structure, isGeneratingStructure: false });
    } catch (error) {
      console.error('Error generating project structure:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to generate project structure',
        isGeneratingStructure: false,
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
      architectOutput: null,
      isArchitectThinking: false,
    });
  },
}));
EOF

# Update ConversationUI to include the architect functionality
echo "Updating ConversationUI..."
cat > src/components/conversation/ConversationUI.tsx << 'EOF'
"use client";

import { useRef, useEffect, useState } from 'react';
import { useConversationStore } from '../../lib/stores/conversation';
import { ProjectStructure } from './ProjectStructure';
import { ArchitectOutput } from './ArchitectOutput';
import { FolderIcon } from 'lucide-react';

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
    architectOutput,
    isArchitectThinking,
    generateArchitectOutput,
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

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-4 py-6">
          <div className="max-w-3xl mx-auto space-y-6">
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

      {/* Right Sidebar */}
      <div className="w-64 border-l border-gray-200 bg-white flex flex-col">
        {/* Requirements Panel */}
        {requirements.length > 0 && (
          <div className="p-4 border-b border-gray-200">
            <h2 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
              <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
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
          </div>
        )}

        {/* Architect Button */}
        {requirements.length > 0 && !architectOutput && !isArchitectThinking && (
          <div className="p-4 border-b border-gray-200">
            <button
              onClick={generateArchitectOutput}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg px-4 py-2.5 flex items-center justify-center transition-colors"
            >
              <FolderIcon className="w-4 h-4 mr-2" />
              Initiate Architect
            </button>
          </div>
        )}
      </div>

      {/* Architect Output */}
      <ArchitectOutput
        architectOutput={architectOutput}
        onPassToConstructor={() => architectOutput && generateProjectStructure(architectOutput)}
        isLoading={isArchitectThinking}
      />
    </div>
  );
}

export function getMetricDescription(metric: string): string {
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
}
EOF

# Make the script executable

echo "Complete implementation has been updated successfully!"
echo "All components have been created/updated:"
echo "1. ArchitectOutput component"
echo "2. Conversation store"
echo "3. API routes"
echo "4. ConversationUI component"
echo "5. Project structure handler"
echo "Backups of original files have been created in ./backups/"