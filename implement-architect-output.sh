#!/bin/bash

# Create backup directory
mkdir -p ./backups

# Create backups of original files
echo "Creating backups..."
cp src/lib/stores/conversation.ts ./backups/conversation.ts.bak 2>/dev/null || true
cp src/components/conversation/ArchitectOutput.tsx ./backups/ArchitectOutput.tsx.bak 2>/dev/null || true
cp src/app/api/architect/route.ts ./backups/architect.route.ts.bak 2>/dev/null || true

# First, let's create the updated interfaces file
echo "Creating interfaces..."
mkdir -p src/lib/types
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

# Create the architect service
echo "Creating architect service..."
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

  private async callClaude(systemPrompt: string, userMessage: string) {
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
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return JSON.parse(data.content[0].text);
  }

  async generateLevel1(requirements: string[]): Promise<ArchitectLevel1> {
    const systemPrompt = `You are an expert software architect with decades of experience. Analyze the provided requirements and create a comprehensive architectural vision. Format your response as a JSON object with a single field "visionText" containing your detailed analysis.

Cover:
1. System Architecture Overview
2. Implementation Strategy
3. Technical Considerations
4. Best Practices & Patterns
5. Potential Challenges
6. Integration Points
7. Scalability Considerations
8. Security Measures`;

    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }

  async generateLevel2(requirements: string[], visionText: string): Promise<ArchitectLevel2> {
    const systemPrompt = `You are an expert software architect. Based on the requirements and architectural vision, create a detailed folder structure for the project. Your response should be a JSON object with a "rootFolder" field containing the nested folder structure.

Each folder should have:
- name: Folder name
- description: What the folder contains
- purpose: Why this folder exists
- subfolders: Array of nested folders (optional)

Focus on creating a clean, maintainable structure that follows best practices and the architectural vision.`;

    return this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}`);
  }

  async generateLevel3(
    requirements: string[],
    visionText: string,
    folderStructure: ArchitectLevel2
  ): Promise<ArchitectLevel3> {
    const systemPrompt = `You are an expert software architect. Create a detailed implementation plan for all required files in the project. Your response should be a JSON object with an "implementationOrder" array of FileContext objects.

For each file:
- List all dependencies
- Describe all components
- Detail implementation requirements
- Provide complete context for implementation
- Specify the exact order of implementation

Order files based on dependencies, starting with the most independent files.`;

    return this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}

Folder Structure:
${JSON.stringify(folderStructure, null, 2)}`);
  }
}

export const architectService = ArchitectService.getInstance();
EOF

# Update the architect API route
echo "Updating architect API route..."
cat > src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;

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
        if (!visionText || !folderStructure) {
          return NextResponse.json({ error: 'Vision text and folder structure are required for level 3' }, { status: 400 });
        }
        result = await architectService.generateLevel3(requirements, visionText, folderStructure);
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

# Update the conversation store
echo "Updating conversation store..."
cat > src/lib/stores/conversation.ts << 'EOF'
// ... (keep existing imports) ...
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, ArchitectState } from '../types/architect';

interface ConversationStore {
  // ... (keep existing properties) ...
  architect: ArchitectState;
  generateArchitectLevel1: () => Promise<void>;
  generateArchitectLevel2: () => Promise<void>;
  generateArchitectLevel3: () => Promise<void>;
}

export const useConversationStore = create<ConversationStore>((set, get) => ({
  // ... (keep existing properties) ...
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
      set({ error: 'No requirements available for the architect' });
      return;
    }

    try {
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null
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

    if (!level1Output || !requirements?.length) {
      set(state => ({
        architect: {
          ...state.architect,
          error: 'Missing required input for level 2'
        }
      }));
      return;
    }

    try {
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null
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

    if (!level1Output || !level2Output || !requirements?.length) {
      set(state => ({
        architect: {
          ...state.architect,
          error: 'Missing required input for level 3'
        }
      }));
      return;
    }

    try {
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null
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
        throw new Error(`Failed to generate implementation plan: ${response.statusText}`);
      }

      const data = await response.json();
      set(state => ({
        architect: {
          ...state.architect,
          level3Output: data,
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

  // ... (keep existing methods) ...
}));
EOF

cat > src/components/conversation/ArchitectOutput.tsx << 'EOF'
import React from 'react';
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

const FolderStructureDisplay = ({ structure }: { structure: ArchitectLevel2['rootFolder'] }) => (
  <div className="ml-4">
    <div className="flex items-start gap-2">
      <FolderIcon className="w-4 h-4 mt-1 text-blue-500" />
      <div>
        <p className="text-sm font-medium text-gray-900">{structure.name}</p>
        <p className="text-xs text-gray-600">{structure.description}</p>
        <p className="text-xs text-gray-500 italic">{structure.purpose}</p>
      </div>
    </div>
    {structure.subfolders && (
      <div className="ml-4 mt-2 border-l-2 border-gray-200 pl-4">
        {structure.subfolders.map((subfolder, index) => (
          <FolderStructureDisplay key={index} structure={subfolder} />
        ))}
      </div>
    )}
  </div>
);

const FileContextDisplay = ({ file }: { file: FileContext }) => (
  <div className="border-b border-gray-200 py-2 last:border-0">
    <div className="flex items-start gap-2">
      <FileIcon className="w-4 h-4 mt-1 text-gray-500" />
      <div>
        <p className="text-sm font-medium text-gray-900">{file.name}</p>
        <p className="text-xs text-gray-600">{file.path}</p>
        <p className="text-xs text-gray-700 mt-1">{file.description}</p>
        <div className="mt-2">
          <p className="text-xs font-medium text-gray-700">Dependencies:</p>
          <ul className="text-xs text-gray-600 list-disc list-inside ml-2">
            {file.dependencies.map((dep, index) => (
              <li key={index}>{dep}</li>
            ))}
          </ul>
        </div>
        {file.components.length > 0 && (
          <div className="mt-2">
            <p className="text-xs font-medium text-gray-700">Components:</p>
            <ul className="text-xs text-gray-600 ml-2">
              {file.components.map((comp, index) => (
                <li key={index} className="mt-1">
                  <p className="font-medium">{comp.name} ({comp.type})</p>
                  <p className="text-xs">{comp.details}</p>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  </div>
);

export function ArchitectOutput({
  level1Output,
  level2Output,
  level3Output,
  currentLevel,
  isThinking,
  error,
  onProceedToNextLevel
}: ArchitectOutputProps) {
  if (error) {
    return (
      <div className="fixed bottom-4 right-4 w-96 bg-red-50 rounded-lg shadow-lg border border-red-200 p-4">
        <h2 className="text-sm font-semibold text-red-900 mb-2">Error</h2>
        <p className="text-sm text-red-700">{error}</p>
      </div>
    );
  }

  if (isThinking) {
    return (
      <div className="fixed bottom-4 right-4 w-96 bg-white rounded-lg shadow-lg border border-gray-200 p-4">
        <div className="flex items-center justify-center space-x-2">
          <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600">
            {currentLevel === 1 && "Architect is analyzing requirements..."}
            {currentLevel === 2 && "Designing folder structure..."}
            {currentLevel === 3 && "Planning implementation details..."}
          </span>
        </div>
      </div>
    );
  }

  const renderLevel1 = () => {
    if (!level1Output) return null;
    return (
      <div className="mb-4">
        <h3 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
          <CodeIcon className="w-4 h-4 mr-1" />
          Architectural Vision
        </h3>
        <div className="text-sm text-gray-600 whitespace-pre-wrap bg-gray-50 rounded-lg p-3">
          {level1Output.visionText}
        </div>
        <button
          onClick={onProceedToNextLevel}
          className="mt-4 w-full bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg px-4 py-2 flex items-center justify-center transition-colors"
        >
          <ArrowRightIcon className="w-4 h-4 mr-2" />
          Design Folder Structure
        </button>
      </div>
    );
  };

  const renderLevel2 = () => {
    if (!level2Output) return null;
    return (
      <div className="mb-4">
        <h3 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
          <FolderIcon className="w-4 h-4 mr-1" />
          Project Structure
        </h3>
        <div className="bg-gray-50 rounded-lg p-3">
          <FolderStructureDisplay structure={level2Output.rootFolder} />
        </div>
        <button
          onClick={onProceedToNextLevel}
          className="mt-4 w-full bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg px-4 py-2 flex items-center justify-center transition-colors"
        >
          <ArrowRightIcon className="w-4 h-4 mr-2" />
          Plan Implementation Details
        </button>
      </div>
    );
  };

  const renderLevel3 = () => {
    if (!level3Output) return null;
    return (
      <div>
        <h3 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
          <FileIcon className="w-4 h-4 mr-1" />
          Implementation Plan
        </h3>
        <div className="bg-gray-50 rounded-lg p-3 max-h-[400px] overflow-y-auto">
          {level3Output.implementationOrder.map((file, index) => (
            <FileContextDisplay key={index} file={file} />
          ))}
        </div>
        <button
          onClick={onProceedToNextLevel}
          className="mt-4 w-full bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg px-4 py-2 flex items-center justify-center transition-colors"
        >
          <ArrowRightIcon className="w-4 h-4 mr-2" />
          Generate Project Structure
        </button>
      </div>
    );
  };

  return (
    <div className="fixed bottom-4 right-4 w-96 bg-white rounded-lg shadow-lg border border-gray-200 p-4 max-h-[80vh] overflow-y-auto">
      {renderLevel1()}
      {currentLevel >= 2 && renderLevel2()}
      {currentLevel >= 3 && renderLevel3()}
    </div>
  );
}
EOF

# Update the ConversationUI component to use the new architect output
echo "Updating ConversationUI component..."
sed -i.bak '
/import { ArchitectOutput } from/a\
import { useConversationStore } from '\''../../lib/stores/conversation'\'';
' src/components/conversation/ConversationUI.tsx

# Update the architect button section in ConversationUI
sed -i.bak '
/{requirements.length > 0 && !projectStructure && !isGeneratingStructure/c\
      {/* Architect Output */}\
      <ArchitectOutput\
        level1Output={architect.level1Output}\
        level2Output={architect.level2Output}\
        level3Output={architect.level3Output}\
        currentLevel={architect.currentLevel}\
        isThinking={architect.isThinking}\
        error={architect.error}\
        onProceedToNextLevel={() => {\
          switch (architect.currentLevel) {\
            case 1:\
              generateArchitectLevel2();\
              break;\
            case 2:\
              generateArchitectLevel3();\
              break;\
            case 3:\
              generateProjectStructure(architect.level3Output!);\
              break;\
          }\
        }}\
      />
' src/components/conversation/ConversationUI.tsx

chmod +x implement-architect-output.sh

echo "Implementation completed successfully!"
echo "Changes made:"
echo "1. Created ArchitectOutput component with three-level display"
echo "2. Added FolderStructureDisplay component"
echo "3. Added FileContextDisplay component"
echo "4. Updated ConversationUI integration"
echo "5. Added level transition handling"