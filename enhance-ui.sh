#!/bin/bash

# Script to enhance UI aesthetics and fix specific issues
# Run this from your syntax-main directory

set -e  # Exit on error

echo "=== Enhancing UI aesthetics and fixing specific issues ==="

# Create backup directory
mkdir -p ./backups/ui-enhancement-$(date +%Y%m%d%H%M%S)
BACKUP_DIR="./backups/ui-enhancement-$(date +%Y%m%d%H%M%S)"

# Backup existing files
cp ./src/components/conversation/ArchitectOutput.tsx "$BACKUP_DIR/ArchitectOutput.tsx.bak"
cp ./src/components/conversation/ConversationUI.tsx "$BACKUP_DIR/ConversationUI.tsx.bak"
cp ./src/app/globals.css "$BACKUP_DIR/globals.css.bak"

echo "Backed up original files to $BACKUP_DIR"

# Update the globals.css file for better aesthetics and to fix the text input color
cat > ./src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --background: #f8fafc;
  --foreground: #334155;
  --primary: #3b82f6;
  --primary-hover: #2563eb;
  --secondary: #64748b;
  --accent: #f59e0b;
  --border: #e2e8f0;
  --card: #ffffff;
  --input-bg: #ffffff;
  --input-text: #1e293b;
  --success: #22c55e;
  --warning: #f59e0b;
  --error: #ef4444;
  --header-bg: #ffffff;
  --footer-bg: #ffffff;
}

body {
  color: var(--foreground);
  background: var(--background);
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

textarea, 
input[type="text"], 
input[type="email"], 
input[type="password"] {
  color: var(--input-text) !important;
}

.card-shadow {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
}

.architect-card {
  border-radius: 0.75rem;
  border: 1px solid var(--border);
  background-color: var(--card);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
  transition: all 0.2s ease-in-out;
}

.architect-card:hover {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.07), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

.progress-indicator {
  display: flex;
  align-items: center;
  margin-bottom: 1.5rem;
}

.progress-indicator .step {
  width: 2rem;
  height: 2rem;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: white;
  position: relative;
  z-index: 10;
}

.progress-indicator .step.active {
  background-color: var(--primary);
}

.progress-indicator .step.completed {
  background-color: var(--success);
}

.progress-indicator .step.inactive {
  background-color: var(--secondary);
  opacity: 0.5;
}

.progress-indicator .line {
  height: 2px;
  flex: 1;
  background-color: var(--border);
}

.progress-indicator .line.active {
  background-color: var(--primary);
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
EOF

echo "Updated CSS with improved styles and fixed text input color"

# Update the ArchitectOutput component for better aesthetics
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
          {/* Level 1: Architectural Vision */}
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

          {/* Level 2: Folder Structure */}
          {(currentLevel >= 2 || level2Output) && (
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

          {/* Level 3: Implementation Plan */}
          {(currentLevel >= 3 || level3Output) && (
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

echo "Updated ArchitectOutput component with improved visual design"

# Update the ConversationUI component for better aesthetics
cat > ./src/components/conversation/ConversationUI.tsx << 'EOF'
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

echo "Updated ConversationUI component with refined visual design"

echo "=== UI Enhancements Complete ==="
echo "The following UI improvements have been made:"
echo "1. Fixed text color in the input field to be black"
echo "2. Enhanced the overall visual design with better spacing and colors"
echo "3. Improved the architect progress visualization"
echo "4. Added proper disabled state styling for the 'Create Implementation Plan' button"
echo "5. Refined shadows, borders, and colors for a more polished look"
echo "6. Added custom scrollbars for a better scrolling experience"
echo "7. Enhanced the visual hierarchy of information"
echo ""
echo "Your changes have been applied successfully!"