#!/bin/bash

# Create new API endpoint file
mkdir -p src/app/api/project-structure
cat > src/app/api/project-structure/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { ClaudeService } from '../../../lib/claude';

const claudeService = ClaudeService.getInstance();

export async function POST(req: NextRequest) {
  try {
    const { requirements } = await req.json();

    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }

    const systemPrompt = `You are an experienced software architect tasked with creating a project structure. Based on the provided requirements, generate a comprehensive project structure that follows best practices.

Requirements:
${requirements.join('\n')}

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
        model: 'claude-3-sonnet-20240229',
        max_tokens: 1024,
        temperature: 0.7,
        system: systemPrompt,
        messages: [{ role: 'user', content: 'Generate project structure' }]
      })
    });

    if (!response.ok) {
      throw new Error(`Claude API error: ${response.statusText}`);
    }

    const data = await response.json();
    const structureResponse = JSON.parse(data.content[0].text);

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

# Create ProjectStructure component
mkdir -p src/components/conversation
cat > src/components/conversation/ProjectStructure.tsx << 'EOF'
import React from 'react';
import { FolderIcon, FileIcon } from 'lucide-react';

interface StructureItem {
  name: string;
  type: 'file' | 'directory';
  description: string;
  tech?: string;
}

interface Directory {
  name: string;
  description: string;
  contents: StructureItem[];
}

interface ProjectStructure {
  description: string;
  directories: Directory[];
}

interface ProjectStructureProps {
  structure: ProjectStructure;
}

export function ProjectStructure({ structure }: ProjectStructureProps) {
  return (
    <div className="fixed right-4 top-[400px] w-96 bg-white rounded-lg shadow-lg border border-gray-200 p-4 transition-all duration-300 ease-in-out">
      <h2 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
        <FolderIcon className="w-4 h-4 mr-1" />
        Project Structure
      </h2>
      <p className="text-xs text-gray-600 mb-4">{structure.description}</p>
      <div className="max-h-[60vh] overflow-y-auto">
        {structure.directories.map((dir) => (
          <div key={dir.name} className="mb-4">
            <div className="flex items-start">
              <FolderIcon className="w-4 h-4 mr-2 mt-1 text-blue-500" />
              <div>
                <h3 className="text-sm font-medium text-gray-900">{dir.name}</h3>
                <p className="text-xs text-gray-600 mb-2">{dir.description}</p>
              </div>
            </div>
            <div className="ml-6">
              {dir.contents.map((item, index) => (
                <div key={`${dir.name}-${item.name}-${index}`} className="flex items-start my-2">
                  {item.type === 'directory' ? (
                    <FolderIcon className="w-4 h-4 mr-2 text-blue-500" />
                  ) : (
                    <FileIcon className="w-4 h-4 mr-2 text-gray-500" />
                  )}
                  <div className="flex-1">
                    <p className="text-xs font-medium text-gray-900">{item.name}</p>
                    <p className="text-xs text-gray-600">{item.description}</p>
                    {item.tech && (
                      <span className="inline-block mt-1 px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-xs">
                        {item.tech}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
EOF

# Update conversation store
cat > src/lib/stores/conversation.ts << 'EOF'
import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';
import type { ConversationContext, ConversationPhase, ExtractedContext } from '../claude';
import { conversationService } from '../services/conversation.service';

interface DbMessage {
  id: string;
  conversationId: string;
  role: string;
  content: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Message {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

interface ProjectStructure {
  description: string;
  directories: {
    name: string;
    description: string;
    contents: Array<{
      name: string;
      type: 'file' | 'directory';
      description: string;
      tech?: string;
    }>;
  }[];
}

interface ConversationStore {
  messages: Message[];
  context: ConversationContext;
  isLoading: boolean;
  error: string | null;
  projectId: string | null;
  conversationId: string | null;
  projectStructure: ProjectStructure | null;
  isGeneratingStructure: boolean;
  initializeProject: () => Promise<void>;
  loadConversation: (conversationId: string) => Promise<void>;
  sendMessage: (content: string) => Promise<void>;
  generateProjectStructure: () => Promise<void>;
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

  generateProjectStructure: async () => {
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
        body: JSON.stringify({ requirements }),
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
    });
  },
}));
EOF


# Continuing ConversationUI.tsx content
cat > src/components/conversation/ConversationUI.tsx << 'EOF'
"use client";

import { useRef, useEffect, useState } from 'react';
import { useConversationStore } from '../../lib/stores/conversation';
import { ProjectStructure } from './ProjectStructure';
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
    generateProjectStructure
  } = useConversationStore();

  const [inputText, setInputText] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    if (context.overallUnderstanding === 100 && !projectStructure && !isGeneratingStructure) {
      generateProjectStructure();
    }
  }, [context.overallUnderstanding, projectStructure, isGeneratingStructure, generateProjectStructure]);

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

  const getMetricChangeColor = (current: number, previous: number): string => {
    const diff = current - previous;
    if (diff > 20) return 'text-green-600';
    if (diff > 10) return 'text-green-500';
    if (diff > 0) return 'text-green-400';
    return 'text-gray-600';
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

  const requirements = context.extractedInfo.requirements || [];

  return (
    <div className="flex flex-col h-screen bg-gray-50">
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

      {/* Requirements Panel */}
      {requirements.length > 0 && (
        <div className="fixed right-4 top-24 w-64 bg-white rounded-lg shadow-lg border border-gray-200 p-4 transition-all duration-300 ease-in-out">
          <h2 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
            <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
            Extracted Requirements ({requirements.length})
          </h2>
          <div className="max-h-[60vh] overflow-y-auto">
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

      {/* Project Structure Panel */}
      {projectStructure && <ProjectStructure structure={projectStructure} />}

      {/* Loading State for Project Structure Generation */}
      {isGeneratingStructure && (
        <div className="fixed right-4 top-[400px] w-96 bg-white rounded-lg shadow-lg border border-gray-200 p-4">
          <div className="flex items-center justify-center space-x-2">
            <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
            <span className="text-sm text-gray-600">Generating project structure...</span>
          </div>
        </div>
      )}
    </div>
  );
}

function getMetricDescription(metric: string): string {
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
chmod +x update-project.sh

echo "Project update completed successfully!"
EOF

# Make the update script executable
chmod +x update-project.sh