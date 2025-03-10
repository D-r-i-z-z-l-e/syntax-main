#!/bin/bash

# Enhanced architect implementation with comprehensive thought chain
# Run this from your syntax-main directory

set -e  # Exit on error

echo "=== Implementing advanced architect blueprint system ==="

# Create backup
mkdir -p ./backups/advanced-architect-$(date +%Y%m%d%H%M%S)
BACKUP_DIR="./backups/advanced-architect-$(date +%Y%m%d%H%M%S)"
cp ./src/lib/services/architect.service.ts "$BACKUP_DIR/architect.service.ts.bak"
cp ./src/components/conversation/ArchitectOutput.tsx "$BACKUP_DIR/ArchitectOutput.tsx.bak"

echo "Backed up original files to $BACKUP_DIR"

# Update the architect service with significantly enhanced prompts
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
      const parsedResponse = JSON.parse(cleanedText);
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
    console.log('Generating comprehensive architectural vision');
    const systemPrompt = `You are the world's most elite software architect with decades of experience across all domains, technology stacks, and architectural patterns.

Your task is to create an extraordinarily comprehensive and detailed architectural vision based on the user requirements provided. This vision will serve as the foundation for a complete software blueprint.

APPROACH THIS AS A MULTI-STEP DEEP THINKING PROCESS:

STEP 1: REQUIREMENTS ANALYSIS
- Extract core functional requirements, non-functional requirements, and implicit needs
- Identify stakeholders and their priorities
- Analyze technical constraints and assumptions
- Identify potential edge cases and risks
- Consider security, scalability, and performance implications from day one

STEP 2: DOMAIN MODEL CONCEPTUALIZATION
- Identify core domain entities, relationships, and business rules
- Create conceptual data model with key entities and relationships
- Define system boundaries and integration points
- Establish domain-specific terminology and concepts
- Identify invariants, business rules, and domain constraints

STEP 3: ARCHITECTURAL PATTERN SELECTION
- Evaluate multiple architectural patterns (microservices, layered, hexagonal, etc.)
- Consider tradeoffs between different architectural approaches
- Select appropriate patterns for different system components
- Justify architectural decisions with clear reasoning
- Address cross-cutting concerns systematically

STEP 4: TECHNOLOGY STACK RECOMMENDATION
- Recommend specific technologies, frameworks, and tools with justifications
- Consider frontend, backend, database, infrastructure, and development tools
- Evaluate proprietary vs. open-source options
- Consider team capabilities and learning curves
- Address compatibility and integration concerns

STEP 5: DETAILED COMPONENT DESIGN
- Design high-level components with clear responsibilities
- Define communication patterns between components
- Establish clear interfaces and contracts
- Address error handling and failure scenarios
- Consider monitoring, observability, and operational concerns

STEP 6: DATA ARCHITECTURE & MANAGEMENT
- Design database schema and data access patterns
- Address data validation, consistency, and integrity
- Consider caching strategies and performance optimizations
- Plan for data migration, backup, and recovery
- Address data security and privacy requirements

STEP 7: SECURITY ARCHITECTURE
- Design authentication and authorization mechanisms
- Address data encryption and protection
- Plan for security monitoring and incident response
- Consider compliance requirements (GDPR, HIPAA, etc.)
- Design for principle of least privilege

STEP 8: DEPLOYMENT & DEVOPS STRATEGY
- Plan CI/CD pipeline and practices
- Design deployment architecture (containerization, orchestration)
- Consider infrastructure-as-code approaches
- Plan for environment management (dev, staging, production)
- Address monitoring, logging, and observability

STEP 9: QUALITY ATTRIBUTES & TRADEOFFS
- Analyze quality attributes (performance, scalability, maintainability)
- Identify and resolve architectural tradeoffs
- Plan for testability and test automation
- Consider performance optimization strategies
- Address technical debt management

STEP 10: IMPLEMENTATION ROADMAP
- Create prioritized implementation sequence
- Identify technical risks and mitigation strategies
- Consider incremental delivery and feature rollout
- Plan for future extensibility and maintenance
- Suggest development team organization and collaboration

Your vision should be extraordinarily detailed, covering every aspect of the system's architecture. It should reflect the deep thinking of an elite architect who has considered all angles, risks, and opportunities. This vision will guide the entire software development process, so be thorough and precise.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "visionText": "Your extremely detailed and comprehensive architectural vision here"
}`;

    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }

  async generateLevel2(requirements: string[], visionText: string): Promise<ArchitectLevel2> {
    console.log('Generating complete project skeleton with all files');
    const systemPrompt = `You are a world-class software architect with extraordinary attention to detail and organization.

Your task is to create a COMPLETE project skeleton based on the architectural vision and requirements provided. This skeleton must include EVERY file needed for a production-ready implementation, not just folders.

APPROACH THIS AS A MULTI-STEP DETAILED CREATION PROCESS:

STEP 1: ANALYZE THE ARCHITECTURE
- Thoroughly understand the architectural vision in all its details
- Identify all components, modules, and layers described
- Note specific technical requirements and constraints
- Understand data flows and component interactions
- Identify cross-cutting concerns that will affect multiple files

STEP 2: PLAN THE PROJECT STRUCTURE
- Select appropriate project structure based on the architecture and best practices
- Determine appropriate directory organization principles
- Identify standard directories needed for the chosen technologies
- Plan configuration and environment-specific structures
- Consider future extensibility and maintenance

STEP 3: DEFINE ALL DIRECTORIES AND FILES
This is critical - you must create a complete file tree including:
- All source code files WITH PROPER EXTENSIONS (.js, .ts, .py, .java, etc.)
- Configuration files (.env, .config.js, etc.)
- Build/package files (package.json, requirements.txt, pom.xml, etc.)
- Documentation files (README.md, etc.)
- Test files (matching the structure of source files)
- Static assets (if applicable)
- Deployment configuration files (Dockerfile, docker-compose.yml, k8s manifests, etc.)
- Database migration/schema files
- CI/CD configuration files (.github/workflows, etc.)

STEP 4: DETAILED FILE ANNOTATIONS
For each file, provide:
- Precise name with correct extension
- Detailed description of the file's purpose
- What functionality the file will implement
- Its relationships to other files
- Any special considerations for this file
- Expected size/complexity of implementation

YOUR OUTPUT MUST BE COMPREHENSIVE AND COMPLETE. Do not create a partial skeleton - include EVERY file needed for a fully production-ready implementation. Be specific with file names and extensions - use proper naming conventions for the technologies involved.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "rootFolder": {
    "name": "project-root",
    "description": "Root directory description",
    "purpose": "Main project folder",
    "files": [
      {
        "name": "filename.ext",
        "description": "Detailed description of this file",
        "purpose": "What this file accomplishes",
        "expectedSize": "small|medium|large",
        "dependencies": ["other files this depends on"]
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
            "purpose": "What this file accomplishes",
            "expectedSize": "small|medium|large",
            "dependencies": ["other files this depends on"]
          }
        ],
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
    console.log('Generating comprehensive file implementation contexts');
    
    // Validate folder structure before using
    if (!folderStructure || !folderStructure.rootFolder) {
      console.error('Invalid folderStructure provided to generateLevel3:', folderStructure);
      throw new Error('Invalid folder structure: missing rootFolder property');
    }
    
    // Extract all files from the folder structure
    const allFiles = this.extractAllFiles(folderStructure.rootFolder);
    console.log(`Found ${allFiles.length} files in the project structure`);
    
    const systemPrompt = `You are a master software engineer with both architectural vision and implementation expertise.

Your task is to create detailed implementation contexts for EVERY file in the project structure. This will serve as a comprehensive implementation guide for developers.

APPROACH THIS AS A SYSTEMATIC FILE ANALYSIS PROCESS:

STEP 1: ANALYZE THE ARCHITECTURE & PROJECT STRUCTURE
- Thoroughly understand the architectural vision and its implications
- Comprehend the full project structure and how files relate to each other
- Understand the technology stack and implementation patterns
- Identify dependencies between files
- Recognize the role of each file in the overall system

STEP 2: DETERMINE OPTIMAL IMPLEMENTATION ORDER
- Analyze dependencies between files
- Identify foundation files that should be implemented first
- Create a logical sequence that minimizes dependency issues
- Group related files that should be implemented together
- Consider ease of testing when sequencing implementation

STEP 3: FOR EACH FILE, CREATE DETAILED IMPLEMENTATION CONTEXT
- Write comprehensive implementation instructions in plain English
- Specify exact imports needed, including versions where important
- Detail all functions, classes, and other constructs needed
- Provide parameter names, types, and descriptions
- Include expected return values and error handling
- Describe algorithms and business logic in detail
- Note any performance considerations or optimizations
- Explain integration points with other files
- Include sample code snippets as guidance when helpful
- Describe any configuration needed
- Add testing recommendations

YOUR OUTPUT MUST BE EXTREMELY COMPREHENSIVE. Include implementation contexts for EVERY file in the project structure, not just a few key files. Each file context should be detailed enough that a competent developer could implement it without further guidance.

IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "implementationOrder": [
    {
      "name": "filename.ext",
      "path": "file path",
      "type": "file type (e.g., JavaScript, Python, Configuration)",
      "description": "Comprehensive file description",
      "purpose": "What this file accomplishes",
      "dependencies": ["list of files this depends on"],
      "components": [
        {
          "name": "component name (class/function/etc.)",
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
      "imports": ["all required imports"],
      "configuration": "any configuration details",
      "testingStrategy": "how to test this file",
      "additionalContext": "any other implementation details"
    }
  ]
}`;

    const response = await this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}

Project Structure:
${JSON.stringify(this.simplifyStructureForPrompt(folderStructure), null, 2)}

Files to Implement:
${this.formatFilesForPrompt(allFiles)}
`);
    
    if (!response.implementationOrder || !Array.isArray(response.implementationOrder)) {
      console.error('Invalid implementation plan response:', response);
      throw new Error('Invalid implementation plan response: missing or invalid implementationOrder');
    }
    
    // Verify that all files have implementation contexts
    const implementedFiles = response.implementationOrder.map(item => item.name);
    const allFileNames = allFiles.map(file => file.name);
    
    // Check for missing files and log them
    const missingFiles = allFileNames.filter(file => !implementedFiles.includes(file));
    if (missingFiles.length > 0) {
      console.warn(`Warning: Some files are missing implementation contexts: ${missingFiles.join(', ')}`);
    }
    
    return response;
  }
  
  // Helper methods to process the folder structure
  private extractAllFiles(folder: any, path: string = ""): any[] {
    let files: any[] = [];
    
    // Add files from current folder
    if (folder.files && Array.isArray(folder.files)) {
      files = folder.files.map(file => ({ 
        ...file, 
        path: path || folder.name 
      }));
    }
    
    // Add files from subfolders
    if (folder.subfolders && Array.isArray(folder.subfolders)) {
      for (const subfolder of folder.subfolders) {
        const subfolderPath = path ? `${path}/${subfolder.name}` : subfolder.name;
        files = [...files, ...this.extractAllFiles(subfolder, subfolderPath)];
      }
    }
    
    return files;
  }
  
  private simplifyStructureForPrompt(structure: any): any {
    // Create a simplified version to avoid token limits
    return {
      rootFolder: this.simplifyFolder(structure.rootFolder)
    };
  }
  
  private simplifyFolder(folder: any): any {
    const result: any = {
      name: folder.name,
      description: folder.description,
      purpose: folder.purpose
    };
    
    if (folder.files && Array.isArray(folder.files)) {
      result.files = folder.files.map((file: any) => ({
        name: file.name,
        description: file.description,
        purpose: file.purpose
      }));
    }
    
    if (folder.subfolders && Array.isArray(folder.subfolders)) {
      result.subfolders = folder.subfolders.map((subfolder: any) => 
        this.simplifyFolder(subfolder)
      );
    }
    
    return result;
  }
  
  private formatFilesForPrompt(files: any[]): string {
    return files.map(file => 
      `- ${file.path}/${file.name}: ${file.description}`
    ).join('\n');
  }
}

export const architectService = ArchitectService.getInstance();
EOF

echo "Updated architect service with enhanced prompts"

# Update the ArchitectOutput component to display files in the structure
cat > ./src/components/conversation/ArchitectOutput.tsx << 'EOF'
import React, { useState } from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon, BrainIcon, SearchIcon, LayersIcon, TerminalIcon } from 'lucide-react';
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
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedFile, setExpandedFile] = useState<string | null>(null);
  
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

  const getTotalFileCount = (rootFolder: any): number => {
    let count = 0;
    
    // Count files in current folder
    if (rootFolder.files && Array.isArray(rootFolder.files)) {
      count += rootFolder.files.length;
    }
    
    // Count files in subfolders
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

  if (!level1Output && !isThinking) return null;

  return (
    <div className="w-full architect-card p-5 mb-5">
      <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center">
        {currentLevel === 1 && <BrainIcon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 2 && <FolderIcon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 3 && <TerminalIcon className="w-5 h-5 mr-2 text-blue-500" />}
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
            {currentLevel === 1 && "Creating comprehensive architectural vision..."}
            {currentLevel === 2 && "Designing complete project structure..."}
            {currentLevel === 3 && "Developing detailed implementation plans..."}
          </span>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Phase Title */}
          <div className="text-center mb-4">
            <h3 className="text-lg font-semibold text-blue-700">
              {currentLevel === 1 && "Architectural Vision"}
              {currentLevel === 2 && "Complete Project Structure"}
              {currentLevel === 3 && "Implementation Blueprint"}
            </h3>
            <p className="text-sm text-gray-500">
              {currentLevel === 1 && "A comprehensive blueprint of the software architecture"}
              {currentLevel === 2 && `Complete project skeleton with ${level2Output?.rootFolder ? getTotalFileCount(level2Output.rootFolder) : 0} files`}
              {currentLevel === 3 && `Detailed implementation instructions for ${level3Output?.implementationOrder?.length || 0} files`}
            </p>
          </div>
          
          {/* Level 1: Architectural Vision */}
          {currentLevel === 1 && level1Output && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <BrainIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Comprehensive Architecture
                  </h3>
                </div>
              </div>
              
              <div className="text-sm text-gray-700 bg-gray-50 rounded-lg p-5 max-h-[600px] overflow-y-auto border border-gray-200 prose prose-sm">
                {level1Output.visionText.split('\n\n').map((paragraph, idx) => (
                  <p key={idx} className="mb-4">{paragraph}</p>
                ))}
              </div>
            </div>
          )}

          {/* Level 2: Project Structure */}
          {currentLevel === 2 && level2Output && level2Output.rootFolder && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <LayersIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Project Files & Directories
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {getTotalFileCount(level2Output.rootFolder)} files
                </div>
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4 max-h-[600px] overflow-y-auto border border-gray-200">
                {renderFolderStructure(level2Output.rootFolder)}
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
EOF

echo "=== Enhanced Architect Implementation Complete ==="
echo "The following enhancements have been made:"
echo "1. Level 1: Now generates a significantly more comprehensive architectural vision"
echo "   - Follows a 10-step deep thinking process"
echo "   - Produces extremely detailed architecture specifications"
echo ""
echo "2. Level 2: Now includes ALL files, not just directories"
echo "   - Creates a complete project skeleton with proper file extensions"
echo "   - Includes detailed descriptions for each file"
echo "   - Provides purpose and dependency information"
echo ""
echo "3. Level 3: Generates comprehensive implementation details for ALL files"
echo "   - Includes imports, components, functions, and parameters"
echo "   - Provides implementation logic in natural language"
echo "   - Includes testing strategies and other context"
echo ""
echo "4. UI Improvements:"
echo "   - Better visualization of the project structure with files"
echo "   - Expandable file details in the implementation plan"
echo "   - Search functionality for finding specific files"
echo ""
echo "This implementation should fully address your requirements for a comprehensive"
echo "architect system that creates complete software blueprints."