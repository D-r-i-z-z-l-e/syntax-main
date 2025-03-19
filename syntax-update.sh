#!/bin/bash

# Script to update the Syntax AI Software Architect project
# This script implements the following changes:
# 1. Replace code contexts with direct code generation
# 2. Enhance the CTO layer for better project structure generation
# 3. Create an IDE-like environment for viewing generated code
# 4. Support any programming language without hardcoding

set -e

echo "=== Starting Syntax AI Software Architect Update ==="
echo "This script will update your existing project with new features."

# Check if we're in the right directory
if [ ! -f "src/lib/services/architect.service.ts" ]; then
  echo "Error: Please run this script from the root of the syntax project."
  exit 1
fi

# Install new dependencies
echo "=== Installing new dependencies ==="
npm install --save react-syntax-highlighter monaco-editor @monaco-editor/react react-resizable split-pane-react file-saver jszip

# Create directory for new components if they don't exist
mkdir -p src/components/ide

# ============================
# Update Architect Types
# ============================
echo "=== Updating architect types ==="
cat > src/lib/types/architect.ts << 'EOL'
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

export interface FileImplementation {
  name: string;
  path: string;
  type: string;
  description: string;
  purpose: string;
  dependencies: string[];
  language: string;
  code: string;
  testCode?: string;
}

export interface ArchitectLevel3 {
  implementations: FileImplementation[];
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

export interface ProjectFile {
  id: string;
  name: string;
  path: string;
  content: string;
  language: string;
}

export interface ProjectFolder {
  id: string;
  name: string;
  path: string;
  description?: string;
  children: (ProjectFile | ProjectFolder)[];
}

export interface ProjectStructure {
  rootFolder: ProjectFolder;
}
EOL

# ============================
# Update Architect Service
# ============================
echo "=== Updating architect service ==="
cat > src/lib/services/architect.service.ts << 'EOL'
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, FileImplementation, FileNode, FolderStructure, SpecialistVision } from '../types/architect';

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
    // Extract the JSON part from the string
    const startIndex = str.indexOf('{');
    const endIndex = str.lastIndexOf('}');
    
    if (startIndex === -1 || endIndex === -1 || endIndex <= startIndex) {
      console.error('Cannot find valid JSON object in the string');
      throw new Error('Cannot find valid JSON object in the response');
    }
    
    // Extract the JSON portion
    let jsonPart = str.substring(startIndex, endIndex + 1);
    
    // Clean up the JSON string
    jsonPart = jsonPart.replace(/[\n\r\t]/g, ' ');
    jsonPart = jsonPart.replace(/\s+/g, ' ');
    jsonPart = jsonPart.replace(/\\([^"\\\/bfnrt])/g, '$1');
    
    return jsonPart;
  }

  private extractJsonFromText(text: string): string {
    try {
      // First try to extract JSON from markdown code blocks
      const jsonRegex = /```json\s*([\s\S]*?)\s*```/;
      const match = text.match(jsonRegex);
      
      if (match && match[1]) {
        return match[1];
      }
      
      // Fall back to trying to extract JSON directly
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
    
    // Start with essential roles
    const specialists = ['Backend Developer', 'Frontend Developer'];
    
    // Add additional specialists based on requirements
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
    
    // Always include CTO at the end
    specialists.push('Chief Technology Officer');
    
    return specialists;
  }

  async generateSpecialistVision(requirements: string[], role: string, specialistIndex: number, totalSpecialists: number): Promise<SpecialistVision> {
    console.log(`Generating detailed vision for specialist ${specialistIndex + 1}/${totalSpecialists}: ${role}`);
    
    // Role-specific instructions to guide the specialist's vision
    let roleSpecificInstructions = "";
    
    if (role === "Backend Developer") {
      roleSpecificInstructions = `
As a Backend Developer, you should focus on:
- Server-side architecture (MVC, microservices, serverless, etc.)
- Database schema design with actual table/collection structures
- API endpoints with detailed routes, parameters, and response formats
- Business logic implementation
- Authentication and authorization systems
- Performance considerations for backend operations
- Error handling and logging mechanisms
- Background processing, queues, and scheduled tasks
- Integration with third-party services and APIs
- Ensure your project structure includes EVERY backend file needed in a production application`;
    } 
    else if (role === "Frontend Developer") {
      roleSpecificInstructions = `
As a Frontend Developer, you should focus on:
- Component hierarchy and organization
- State management approach
- Routing and navigation structure
- UI component library selection and implementation
- API integration strategy
- Data fetching and caching
- Form handling and validation
- Responsive design implementation
- Asset management
- User interaction and feedback mechanisms
- Ensure your project structure includes EVERY frontend file needed in a production application`;
    }
    else if (role === "UI/UX Designer") {
      roleSpecificInstructions = `
As a UI/UX Designer, you should focus on:
- Design system architecture (tokens, components, patterns)
- Design file organization
- Component styling implementation strategy
- Theme management and customization
- Accessibility compliance implementation
- Animation and transition systems
- Design-to-code workflow
- User flow implementations
- Design asset management
- UI testing approaches
- Ensure your project structure includes EVERY design-related file needed in a production application`;
    }
    else if (role === "Database Architect") {
      roleSpecificInstructions = `
As a Database Architect, you should focus on:
- Database choice and justification (SQL, NoSQL, graph, etc.)
- Detailed schema design with all tables/collections and fields
- Data relationships and integrity constraints
- Indexing strategy
- Query optimization
- Migration and versioning approach
- Caching strategy
- Data access patterns
- Transaction management
- Database scaling approach
- Ensure your project structure includes EVERY database-related file needed in a production application`;
    }
    else if (role === "Security Specialist") {
      roleSpecificInstructions = `
As a Security Specialist, you should focus on:
- Authentication system implementation
- Authorization and permission management
- Data encryption strategies
- Input validation and sanitization
- Protection against common vulnerabilities (XSS, CSRF, SQL injection, etc.)
- API security
- Content Security Policy implementation
- Secure data storage
- Credential management
- Security testing and monitoring
- Ensure your project structure includes EVERY security-related file needed in a production application`;
    }
    else if (role === "DevOps Engineer") {
      roleSpecificInstructions = `
As a DevOps Engineer, you should focus on:
- Infrastructure as code setup
- CI/CD pipeline configuration
- Containerization strategy
- Deployment workflows
- Environment configuration management
- Monitoring and logging setup
- Scaling approaches
- Service discovery and orchestration
- Performance optimization
- Disaster recovery planning
- Ensure your project structure includes EVERY DevOps-related file needed in a production application`;
    }
    else if (role === "Mobile Developer") {
      roleSpecificInstructions = `
As a Mobile Developer, you should focus on:
- Mobile app architecture (native, hybrid, or cross-platform)
- Screen navigation and routing
- State management on mobile
- Native feature integration
- Offline capabilities
- Performance optimization for mobile
- Mobile-specific UI components
- Push notification implementation
- Deep linking strategy
- App lifecycle management
- Ensure your project structure includes EVERY mobile-related file needed in a production application`;
    }
    else if (role === "QA Engineer") {
      roleSpecificInstructions = `
As a QA Engineer, you should focus on:
- Test strategy and methodology
- Unit testing implementation
- Integration testing setup
- End-to-end testing approach
- Test fixture management
- Mocking and stubbing strategies
- Performance testing
- Accessibility testing
- Test automation infrastructure
- Continuous testing integration
- Ensure your project structure includes EVERY testing-related file needed in a production application`;
    }
    else if (role === "Machine Learning Engineer") {
      roleSpecificInstructions = `
As a Machine Learning Engineer, you should focus on:
- ML model architecture and implementation
- Data preprocessing pipeline
- Feature engineering approach
- Model training workflow
- Model deployment strategy
- Model versioning
- Experiment tracking
- Inference optimization
- ML monitoring and feedback
- Data collection and annotation
- Ensure your project structure includes EVERY ML-related file needed in a production application`;
    }
    else if (role === "Blockchain Developer") {
      roleSpecificInstructions = `
As a Blockchain Developer, you should focus on:
- Smart contract architecture
- Blockchain integration strategy
- Wallet connectivity
- Transaction management
- Consensus mechanism implementation
- Cryptographic utilities
- On-chain and off-chain data handling
- Gas optimization
- Security considerations
- Testing approaches for blockchain components
- Ensure your project structure includes EVERY blockchain-related file needed in a production application`;
    }
    
    const systemPrompt = `You are a world-class ${role} with extensive experience building enterprise production software. You've worked at top technology companies and have delivered dozens of successful commercial products.
${roleSpecificInstructions}

Your task is to create an EXTREMELY DETAILED project structure for a software project based on the provided requirements. This is for a real production application, not a demo or prototype. 
Produce a comprehensive vision and an EXHAUSTIVE project structure with every single file that would be needed to fully implement the requirements. DO NOT produce a minimal or example project structure - create a COMPLETE, PRODUCTION-READY project structure.

For each file you include:
1. Provide detailed descriptions of what each file should contain
2. Include specific implementation details that will guide development
3. Explain the purpose and significance of each file in the overall architecture

For the project structure, organize all files in a logical, maintainable manner that follows industry best practices for your domain. Don't omit files like tests, configuration, documentation, etc. Include EVERYTHING needed for a production system.

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "role": "${role}",
  "expertise": "Comprehensive description of your role and domain expertise",
  "visionText": "Your extremely detailed technical vision for this project from your specialized perspective (in plain text with paragraphs separated by newlines)",
  "projectStructure": {
    "rootFolder": {
      "name": "project-root",
      "description": "Detailed description of the project root",
      "purpose": "Purpose of this main folder",
      "files": [
        {
          "name": "filename.ext",
          "description": "DETAILED description of what this file contains and how it should be implemented",
          "purpose": "Specific purpose of this file in the overall architecture"
        },
        ...
      ],
      "subfolders": [
        {
          "name": "subfolder-name",
          "description": "Detailed description of this subfolder",
          "purpose": "Purpose of this subfolder in the architecture",
          "files": [
            {
              "name": "filename.ext",
              "description": "DETAILED description of what this file contains and how it should be implemented",
              "purpose": "Specific purpose of this file in the overall architecture"
            },
            ...
          ],
          "subfolders": [
            ...
          ]
        },
        ...
      ]
    }
  }
}

DO NOT OMIT ANY FILES. Your project structure should be COMPLETE. Include every file needed for a production-quality implementation.
NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }

  async generateLevel1(requirements: string[]): Promise<ArchitectLevel1> {
    console.log('Determining specialists needed for the project...');
    
    // Determine which specialist roles are needed for this project
    const roles = this.determineSpecialistsNeeded(requirements);
    console.log(`Selected specialists: ${roles.join(', ')}`);
    
    // Generate a vision from each specialist
    const specialists: SpecialistVision[] = [];
    
    for (let i = 0; i < roles.length - 1; i++) {      
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
    
    const systemPrompt = `You are a veteran Chief Technology Officer (CTO) with decades of experience leading architecture for enterprise systems at major tech companies. You have overseen dozens of successful large-scale commercial products from initial design through production deployment.

Your task is to create a COMPREHENSIVE, PRODUCTION-READY project structure by integrating and expanding upon the specialist visions provided. This is for a real commercial application, not a demo or prototype.

Your work will serve as the definitive implementation blueprint, so it must be EXHAUSTIVE and PRECISE. You must:

1. Create a UNIFIED, HOLISTIC architectural vision that synthesizes the best ideas from all specialists while adding your own expertise
2. Systematically identify and resolve ALL conflicts between specialist recommendations
3. Create a COMPLETE, PRODUCTION-READY project structure that includes EVERY file needed for implementation
4. Generate a detailed dependency tree that establishes the exact implementation order
5. Fill in any gaps left by the specialists to ensure the architecture is complete
6. Make technical decisions that prioritize maintainability, scalability, and best practices

DO NOT simply combine or aggregate the specialists' input. You must ANALYZE their recommendations, identify strengths and weaknesses, resolve conflicts, and create an ORIGINAL project structure that represents your own expert judgment while incorporating the best ideas from the specialists.

For the project structure:
- Include EVERY necessary file, not just examples or key files
- Provide detailed descriptions of what each file should contain
- Include implementation details that will guide development
- Organize files in a logical, production-quality structure
- Don't omit tests, configuration, documentation, utilities, or any supporting files

For the dependency tree:
- Include ALL files from the project structure
- Carefully analyze dependencies between files
- Establish a clear implementation order that minimizes dependency issues
- Consider both direct and indirect dependencies

Think like a world-class software architect designing a system that will be implemented by a large team and maintained for years.

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "integratedVision": "Your comprehensive architectural vision combining all specialist insights (in plain text with paragraphs separated by newlines)",
  "resolutionNotes": [
    "Detailed explanation of how you resolved conflict/challenge",
    "Detailed explanation of how you resolved conflict/challenge",
    ...
  ],
  "rootFolder": {
    "name": "project-root",
    "description": "Detailed description of the project root",
    "purpose": "Purpose of this main folder",
    "files": [
      {
        "name": "filename.ext",
        "description": "DETAILED description of what this file contains and how it should be implemented",
        "purpose": "Specific purpose of this file in the overall architecture"
      },
      ...
    ],
    "subfolders": [
      {
        "name": "subfolder-name",
        "description": "Detailed description of this subfolder",
        "purpose": "Purpose of this subfolder in the architecture",
        "files": [
          {
            "name": "filename.ext",
            "description": "DETAILED description of what this file contains and how it should be implemented",
            "purpose": "Specific purpose of this file in the overall architecture"
          },
          ...
        ],
        "subfolders": [
          ...
        ]
      },
      ...
    ]
  },
  "dependencyTree": {
    "files": [
      {
        "name": "filename.ext",
        "path": "/relative/path/filename.ext",
        "description": "Detailed description of this file",
        "purpose": "Specific purpose of this file",
        "dependencies": ["list of file paths this file depends on"],
        "dependents": ["list of file paths that depend on this file"],
        "implementationOrder": 1,
        "type": "file type (e.g., component, model, controller, etc.)"
      },
      ...
    ]
  }
}

The project structure should contain AT MINIMUM 100-150 files for any non-trivial application. Include ALL files necessary for a complete production implementation.

The "files" array in the dependencyTree must include EVERY file from the project structure.
The implementationOrder values should start from 1 (no dependencies) and increase as dependencies increase.
Files with no dependencies should have an empty dependencies array.
The dependency analysis must be thorough and accurate.

DO NOT OMIT ANY FILES. Your project structure should be COMPLETE for production use.
NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

    // Format specialist visions for inclusion in the prompt
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
    console.log('Generating code implementations based on dependency tree');
    
    if (!level2Output || !level2Output.rootFolder || !level2Output.dependencyTree) {
      console.error('Invalid level2Output provided to generateLevel3:', level2Output);
      throw new Error('Invalid level 2 output: missing rootFolder or dependencyTree property');
    }
    
    const dependencyTree = level2Output.dependencyTree;
    
    if (!dependencyTree.files || !Array.isArray(dependencyTree.files) || dependencyTree.files.length === 0) {
      throw new Error('Invalid dependency tree: no files found');
    }
    
    // Sort files by implementation order to ensure dependencies are generated before dependents
    const sortedFiles = [...dependencyTree.files].sort((a, b) => a.implementationOrder - b.implementationOrder);
    
    // Store all generated file implementations
    const implementations: FileImplementation[] = [];
    
    for (const file of sortedFiles) {
      console.log(`Generating implementation for ${file.path}/${file.name} (order: ${file.implementationOrder})`);
      
      // Gather information about dependencies
      const dependencies = file.dependencies || [];
      
      // Find already implemented dependencies to include in context
      const dependencyImplementations = implementations
        .filter(impl => dependencies.includes(`${impl.path}/${impl.name}`));
      
      // Generate the implementation for this file
      const fileImplementation = await this.generateFileImplementation(
        file, 
        dependencyImplementations, 
        requirements, 
        level2Output.integratedVision
      );
      
      implementations.push(fileImplementation);
    }
    
    return { implementations };
  }
  
  private async generateFileImplementation(
    file: FileNode,
    dependencyImplementations: FileImplementation[],
    requirements: string[],
    visionText: string
  ): Promise<FileImplementation> {
    // Determine file language from extension
    const fileExt = file.name.split('.').pop()?.toLowerCase() || '';
    const language = this.getLanguageFromExtension(fileExt);
    
    // Build file-specific instructions based on file type and language
    let fileTypeInstructions = this.getFileTypeInstructions(file, fileExt);
    
    const systemPrompt = `You are a world-class senior staff software engineer with 20+ years of experience. Your task is to create a complete, production-ready implementation for a specific file in a software project.

This implementation must be COMPLETE and ready to use with no placeholders, TODOs, or incomplete sections. The code should be clean, efficient, well-documented, and follow best practices for the language.

${fileTypeInstructions}

Your code must be:
1. PRODUCTION-QUALITY - not sample code or pseudo-code
2. COMPLETE - with all necessary imports, error handling, and edge case handling
3. WELL-DOCUMENTED - with clear comments explaining key sections
4. PROPERLY FORMATTED - following language-specific conventions
5. EFFICIENT - avoiding performance pitfalls
6. SECURE - following security best practices

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "name": "${file.name}",
  "path": "${file.path}",
  "type": "${file.type}",
  "description": "${file.description}",
  "purpose": "${file.purpose}",
  "dependencies": ${JSON.stringify(file.dependencies || [])},
  "language": "the programming language of this file",
  "code": "The complete, production-ready implementation with no placeholders or TODOs"
}

NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

    // Create a user message with context about the file and its dependencies
    const dependenciesContext = dependencyImplementations.length > 0 
      ? "Dependency Implementations:\n" + dependencyImplementations.map(dep => 
          `File: ${dep.path}/${dep.name}\nLanguage: ${dep.language}\nCode:\n\`\`\`${dep.language}\n${dep.code}\n\`\`\``
        ).join('\n\n')
      : "No dependencies";

    const userMessage = `
File to Implement:
Name: ${file.name}
Path: ${file.path}
Description: ${file.description}
Purpose: ${file.purpose}
Type: ${file.type}
Dependencies: ${JSON.stringify(file.dependencies || [])}

Project Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}

${dependenciesContext}

Please generate a COMPLETE, PRODUCTION-READY implementation for this file. The code must be fully functional with no placeholders or TODOs.
`;

    const implementation = await this.callClaude(systemPrompt, userMessage);
    return implementation;
  }

  private getLanguageFromExtension(fileExt: string): string {
    const extToLanguage: Record<string, string> = {
      'js': 'javascript',
      'jsx': 'javascript',
      'ts': 'typescript',
      'tsx': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'php': 'php',
      'java': 'java',
      'kt': 'kotlin',
      'swift': 'swift',
      'go': 'go',
      'rs': 'rust',
      'c': 'c',
      'cpp': 'cpp',
      'cs': 'csharp',
      'html': 'html',
      'css': 'css',
      'scss': 'scss',
      'less': 'less',
      'json': 'json',
      'yaml': 'yaml',
      'yml': 'yaml',
      'md': 'markdown',
      'sql': 'sql',
      'sh': 'bash',
      'bash': 'bash',
      'ps1': 'powershell',
      'conf': 'conf',
      'ini': 'ini',
      'env': 'plaintext',
      'gitignore': 'plaintext',
      'dockerignore': 'plaintext',
      'xml': 'xml',
      'svg': 'svg',
      'vue': 'vue',
      'dart': 'dart',
      'ex': 'elixir',
      'exs': 'elixir',
      'elm': 'elm',
      'fs': 'fsharp',
      'r': 'r',
      'gradle': 'gradle',
      'groovy': 'groovy',
      'scala': 'scala',
      'lua': 'lua',
      'coffee': 'coffeescript',
      'tf': 'terraform',
      'mod': 'go',
      'sol': 'solidity'
    };
    
    return extToLanguage[fileExt] || 'plaintext';
  }

  private getFileTypeInstructions(file: FileNode, fileExt: string): string {
    // File path in lowercase for easier matching
    const filePath = file.path.toLowerCase();
    
    // Determine type of file and provide appropriate instructions
    if (fileExt === 'js' || fileExt === 'ts' || fileExt === 'jsx' || fileExt === 'tsx') {
      // JavaScript/TypeScript files
      if (filePath.includes('component') || filePath.includes('/ui/') || fileExt === 'jsx' || fileExt === 'tsx') {
        return `
This is a UI component file. Your implementation should include:
- All necessary import statements
- Complete props interface/type definitions
- State management with hooks or state containers
- Complete component lifecycle handling
- Full JSX rendering with proper hierarchy
- Proper styling implementation
- All event handlers and business logic
- Error handling and loading states
- Performance optimization considerations`;
      } else if (filePath.includes('model') || filePath.includes('schema') || filePath.includes('entity')) {
        return `
This is a data model file. Your implementation should include:
- Complete class/interface definition
- All properties with proper types
- Field validation rules
- Relationship definitions
- Database integration (ORM/ODM configuration)
- Model methods for data operations
- Type conversions and serialization
- Business logic specific to this entity`;
      } else if (filePath.includes('controller') || filePath.includes('handler') || filePath.includes('route')) {
        return `
This is a controller/route handler file. Your implementation should include:
- Complete route definitions with HTTP methods
- Request parameter validation
- Authorization and authentication checks
- Business logic implementation
- Error handling for all cases
- Response formatting
- Middleware integration
- Logging and monitoring
- Rate limiting and security considerations`;
      } else if (filePath.includes('service') || filePath.includes('provider')) {
        return `
This is a service file. Your implementation should include:
- Service class with proper dependency injection
- All public methods with complete implementations
- Private helper methods
- External service integrations
- Error handling strategy
- Transaction management
- Retry logic where appropriate
- Logging and monitoring
- Performance optimizations`;
      } else if (filePath.includes('test') || filePath.includes('spec')) {
        return `
This is a test file. Your implementation should include:
- Complete test suite organization
- Test cases for all functionality
- Mocks and stubs for dependencies
- Setup and teardown logic
- Assertions for positive and negative cases
- Edge case testing
- Performance test cases if applicable
- Integration test scenarios`;
      } else if (filePath.includes('config') || filePath.includes('setup')) {
        return `
This is a configuration file. Your implementation should include:
- All configuration parameters
- Environment variable handling
- Type definitions for config
- Validation logic
- Default values
- Documentation for each option
- Security considerations for sensitive config`;
      }
    } else if (fileExt === 'py') {
      return `
This is a Python file. Your implementation should include:
- All necessary imports
- Complete class/function definitions
- Type hints (if applicable)
- Docstrings following PEP 257
- Error handling
- Logging
- Unit tests (if this is a test file)
- Follow PEP 8 style guidelines`;
    } else if (fileExt === 'java' || fileExt === 'kt') {
      return `
This is a Java/Kotlin file. Your implementation should include:
- Package declaration
- All necessary imports
- Complete class definition with proper access modifiers
- Method implementations with documentation
- Exception handling
- Proper resource management
- Thread safety considerations (if applicable)
- Unit tests (if this is a test file)`;
    } else if (fileExt === 'html') {
      return `
This is an HTML file. Your implementation should include:
- Complete document structure
- Semantic HTML5 markup
- Proper metadata
- Accessibility attributes
- SEO considerations
- Script and style inclusions
- Responsive design elements`;
    } else if (fileExt === 'css' || fileExt === 'scss' || fileExt === 'less') {
      return `
This is a styling file. Your implementation should include:
- Complete stylesheet organization
- Variables and mixins (for preprocessors)
- Responsive design breakpoints
- Component-specific styles
- Animation definitions
- Vendor prefixes where needed
- Performance considerations
- Browser compatibility handling`;
    } else if (fileExt === 'sql') {
      return `
This is a SQL file. Your implementation should include:
- Complete SQL statements
- Proper schema definitions
- Indexes and constraints
- Transactions if applicable
- Error handling
- Performance optimized queries
- Comments explaining complex queries`;
    } else if (fileExt === 'go') {
      return `
This is a Go file. Your implementation should include:
- Package declaration
- All necessary imports
- Complete function/struct definitions
- Error handling
- Concurrency handling (if applicable)
- Proper resource management
- Unit tests (if this is a test file)
- Follow Go style guidelines`;
    } else if (fileExt === 'rb') {
      return `
This is a Ruby file. Your implementation should include:
- All necessary requires
- Complete class/module definitions
- Error handling
- Proper resource management
- Documentation
- Unit tests (if this is a test file)
- Follow Ruby style guidelines`;
    } else if (fileExt === 'php') {
      return `
This is a PHP file. Your implementation should include:
- PHP opening tag
- Namespace declaration
- All necessary imports/requires
- Complete class/function definitions
- Error handling
- Proper resource management
- Documentation
- Unit tests (if this is a test file)
- Follow PSR style guidelines`;
    }
    
    // Default instructions for other file types
    return `
This file requires a complete, production-ready implementation. Your code should:
- Follow best practices for this file type and language
- Include all necessary imports/references
- Implement all required functionality
- Handle errors appropriately
- Be well-documented
- Be performant and secure`;
  }
}

export const architectService = ArchitectService.getInstance();
EOL

# ============================
# Update conversation store
# ============================
echo "=== Updating conversation store ==="
cat > src/lib/stores/conversation.ts << 'EOL'
import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, ArchitectState, FileImplementation, FileNode, ProjectStructure, SpecialistVision } from '../types/architect';

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
  generatedFiles: FileImplementation[];
  activeFile: FileImplementation | null;
  initializeProject: () => Promise<void>;
  loadConversation: (conversationId: string) => Promise<void>;
  sendMessage: (content: string) => Promise<void>;
  generateArchitectLevel1: () => Promise<void>;
  generateArchitectLevel2: () => Promise<void>;
  generateArchitectLevel3: () => Promise<void>;
  generateProjectStructure: (implementationPlan: ArchitectLevel3) => Promise<void>;
  setActiveFile: (file: FileImplementation | null) => void;
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
  generatedFiles: [],
  activeFile: null,
  
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
      // Reset architect state and start thinking
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
      }
      
      // Update state with the generated specialist visions
      set(state => ({
        architect: {
          ...state.architect,
          level1Output: data,
          currentLevel: 1,
          isThinking: false,
          totalSpecialists: data.specialists.length
        }
      }));
    } catch (error) {
      console.error('Error generating specialist visions:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate specialist visions',
          isThinking: false
        }
      }));
    }
  },
  
  generateArchitectLevel2: async () => {
    const state = get();
    const { level1Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting integrated vision and structure generation');
    
    if (!level1Output?.specialists || !Array.isArray(level1Output.specialists) || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.specialists) missing.push('specialist visions');
      if (!requirements?.length) missing.push('requirements');
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required input for integrated vision: ${missing.join(', ')}`
        }
      }));
      return;
    }
    
    try {
      // Reset level 2+ and start thinking
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
          level1Output
        }),
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to generate integrated vision: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Integrated vision and structure generated successfully');
      
      if (!data.rootFolder || !data.dependencyTree || !data.integratedVision) {
        throw new Error('Invalid level 2 response: missing rootFolder, dependencyTree, or integratedVision');
      }
      
      // Get the total number of files for progress tracking
      const totalFiles = data.dependencyTree.files ? data.dependencyTree.files.length : 0;
      
      // Update state with the CTO's integrated vision and structure
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
      console.error('Error generating integrated vision:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate integrated vision',
          isThinking: false,
          currentLevel: 1
        }
      }));
    }
  },
  
  generateArchitectLevel3: async () => {
    const state = get();
    const { level2Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('Starting code generation based on dependency tree');
    
    if (!level2Output?.rootFolder || !level2Output?.dependencyTree || !level2Output?.integratedVision || !requirements?.length) {
      const missing: string[] = [];
      if (!level2Output?.integratedVision) missing.push('integrated vision');
      if (!level2Output?.rootFolder) missing.push('project structure');
      if (!level2Output?.dependencyTree) missing.push('dependency tree');
      if (!requirements?.length) missing.push('requirements');
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required input for code generation: ${JSON.stringify(missing)}`
        }
      }));
      return;
    }
    
    try {
      // Reset level 3 and start thinking
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
          level2Output
        }),
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to generate code implementations: ${response.statusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Code implementations generated successfully');
      
      if (!data.implementations || !Array.isArray(data.implementations)) {
        throw new Error('Invalid code implementation response: missing or invalid implementations');
      }
      
      // Update state with the generated code implementations
      set(state => ({
        architect: {
          ...state.architect,
          level3Output: data,
          currentLevel: 3,
          isThinking: false,
          completedFiles: data.implementations.length
        },
        generatedFiles: data.implementations
      }));
    } catch (error) {
      console.error('Error generating code implementations:', error);
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate code implementations',
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
      const { level2Output } = state.architect;
      
      // Validate inputs
      if (!requirements?.length || !level2Output?.integratedVision || !level2Output?.rootFolder || !implementationPlan?.implementations) {
        const missing = [];
        if (!requirements?.length) missing.push('requirements');
        if (!level2Output?.integratedVision) missing.push('integrated vision');
        if (!level2Output?.rootFolder) missing.push('project structure');
        if (!implementationPlan?.implementations) missing.push('implementation plan');
        
        throw new Error(`Missing required inputs for project construction: ${missing.join(', ')}`);
      }
      
      const response = await fetch('/api/project-structure', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          requirements,
          architectVision: level2Output.integratedVision,
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
      
      // Update state with the project structure
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
          totalFiles: 0,
          currentSpecialist: 0,
          totalSpecialists: 0
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

  setActiveFile: (file: FileImplementation | null) => {
    set({ activeFile: file });
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
        totalFiles: 0,
        currentSpecialist: 0,
        totalSpecialists: 0
      },
      generatedFiles: [],
      activeFile: null,
    });
  },
}));
EOL

# ============================
# Update Architect API route
# ============================
echo "=== Updating architect API route ==="
cat > src/app/api/architect/route.ts << 'EOL'
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
        console.log('Generating level 3: Code Implementations');
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
EOL

# ============================
# Create new IDE components
# ============================
echo "=== Creating IDE components ==="

# File Explorer Component
cat > src/components/ide/FileExplorer.tsx << 'EOL'
import React, { useState } from 'react';
import { ChevronDown, ChevronRight, Folder, FileIcon, Code } from 'lucide-react';
import { FileImplementation } from '../../lib/types/architect';

interface FileExplorerProps {
  files: FileImplementation[];
  onSelectFile: (file: FileImplementation) => void;
  activeFile: FileImplementation | null;
}

interface FileTreeNode {
  id: string;
  name: string;
  path: string;
  type: 'file' | 'folder';
  children: FileTreeNode[];
  fileData?: FileImplementation;
}

export function FileExplorer({ files, onSelectFile, activeFile }: FileExplorerProps) {
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set());

  // Build file tree
  const buildFileTree = (): FileTreeNode => {
    const root: FileTreeNode = {
      id: 'root',
      name: 'project-root',
      path: '',
      type: 'folder',
      children: []
    };

    // Map to store folder nodes for quick lookup
    const folderMap = new Map<string, FileTreeNode>();
    folderMap.set('', root);

    // Process all files, creating folder structure as needed
    files.forEach((file) => {
      // Normalize path to not have leading or trailing slashes
      const normalizedPath = file.path.replace(/^\/|\/$/g, '');
      
      // Split path into segments
      const segments = normalizedPath.split('/');
      
      // Track current path as we build
      let currentPath = '';
      let parentNode = root;
      
      // Create or traverse folders
      for (let i = 0; i < segments.length; i++) {
        const segment = segments[i];
        if (!segment) continue;
        
        // Update current path
        currentPath = currentPath ? `${currentPath}/${segment}` : segment;
        
        // Check if folder already exists
        if (!folderMap.has(currentPath)) {
          // Create new folder node
          const newFolder: FileTreeNode = {
            id: `folder-${currentPath}`,
            name: segment,
            path: currentPath,
            type: 'folder',
            children: []
          };
          
          // Add to parent and update maps
          parentNode.children.push(newFolder);
          folderMap.set(currentPath, newFolder);
        }
        
        // Update parent for next iteration
        parentNode = folderMap.get(currentPath)!;
      }
      
      // Add file node to the appropriate folder
      const fileNode: FileTreeNode = {
        id: `file-${file.path}/${file.name}`,
        name: file.name,
        path: `${normalizedPath}/${file.name}`,
        type: 'file',
        children: [],
        fileData: file
      };
      
      parentNode.children.push(fileNode);
    });

    // Sort each folder's children: folders first, then files, both alphabetically
    const sortNode = (node: FileTreeNode) => {
      node.children.sort((a, b) => {
        // Folders before files
        if (a.type !== b.type) {
          return a.type === 'folder' ? -1 : 1;
        }
        // Alphabetical within same type
        return a.name.localeCompare(b.name);
      });
      
      // Recursively sort children
      node.children.forEach(child => {
        if (child.type === 'folder') {
          sortNode(child);
        }
      });
    };
    
    sortNode(root);
    return root;
  };

  const toggleFolder = (path: string) => {
    setExpandedFolders(prev => {
      const newSet = new Set(prev);
      if (newSet.has(path)) {
        newSet.delete(path);
      } else {
        newSet.add(path);
      }
      return newSet;
    });
  };

  const renderTree = (node: FileTreeNode, depth = 0): JSX.Element => {
    const isExpanded = expandedFolders.has(node.path);
    const isFolder = node.type === 'folder';
    const isActive = !isFolder && 
      activeFile && 
      node.fileData?.path === activeFile.path && 
      node.fileData?.name === activeFile.name;

    return (
      <div key={node.id}>
        <div 
          className={`flex items-center py-1 pl-${depth * 4} ${isActive ? 'bg-blue-100 text-blue-800' : 'hover:bg-gray-100'} cursor-pointer rounded`}
          onClick={() => {
            if (isFolder) {
              toggleFolder(node.path);
            } else if (node.fileData) {
              onSelectFile(node.fileData);
            }
          }}
        >
          <span className="mr-1">
            {isFolder ? (
              isExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />
            ) : null}
          </span>
          <span className="mr-2">
            {isFolder ? (
              <Folder className="w-4 h-4 text-yellow-500" />
            ) : (
              <FileIcon className="w-4 h-4 text-gray-500" />
            )}
          </span>
          <span className="text-sm truncate">{node.name}</span>
        </div>
        
        {isFolder && isExpanded && (
          <div className="ml-4">
            {node.children.map(child => renderTree(child, depth + 1))}
          </div>
        )}
      </div>
    );
  };

  const fileTree = buildFileTree();

  return (
    <div className="h-full overflow-auto p-2">
      <div className="flex items-center justify-between mb-4 sticky top-0 bg-white py-2 z-10">
        <div className="flex items-center">
          <Code className="w-5 h-5 mr-2 text-blue-600" />
          <h3 className="text-sm font-medium">Project Files</h3>
        </div>
        <div className="text-xs text-gray-500">{files.length} files</div>
      </div>
      {files.length > 0 ? (
        renderTree(fileTree)
      ) : (
        <div className="text-center text-gray-500 text-sm py-4">
          No files generated yet
        </div>
      )}
    </div>
  );
}
EOL

# Code Editor Component
cat > src/components/ide/CodeEditor.tsx << 'EOL'
import React from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { materialLight } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { FileImplementation } from '../../lib/types/architect';
import { FileIcon, Download, Code, Copy } from 'lucide-react';

interface CodeEditorProps {
  file: FileImplementation | null;
  onCopy: () => void;
  onDownload: () => void;
}

export function CodeEditor({ file, onCopy, onDownload }: CodeEditorProps) {
  if (!file) {
    return (
      <div className="h-full flex items-center justify-center bg-gray-50 text-gray-400">
        <div className="text-center">
          <Code className="h-12 w-12 mx-auto mb-4 opacity-20" />
          <p>Select a file to view its code</p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* File header */}
      <div className="flex items-center justify-between px-4 py-2 border-b bg-gray-50">
        <div className="flex items-center">
          <FileIcon className="w-4 h-4 mr-2 text-gray-500" />
          <span className="font-medium text-sm">{file.path}/{file.name}</span>
        </div>
        <div className="flex space-x-2">
          <button 
            onClick={onCopy}
            className="p-1.5 text-xs flex items-center bg-gray-100 hover:bg-gray-200 rounded"
            title="Copy code"
          >
            <Copy className="w-3.5 h-3.5 mr-1" />
            Copy
          </button>
          <button 
            onClick={onDownload}
            className="p-1.5 text-xs flex items-center bg-gray-100 hover:bg-gray-200 rounded"
            title="Download file"
          >
            <Download className="w-3.5 h-3.5 mr-1" />
            Download
          </button>
        </div>
      </div>

      {/* File info */}
      <div className="px-4 py-2 border-b bg-gray-50 text-xs">
        <div className="flex flex-wrap gap-x-6 gap-y-1">
          <div><span className="font-medium">Type:</span> {file.type}</div>
          <div><span className="font-medium">Language:</span> {file.language}</div>
          <div><span className="font-medium">Dependencies:</span> {file.dependencies.length}</div>
        </div>
        <div className="mt-1">
          <span className="font-medium">Purpose:</span> {file.purpose}
        </div>
      </div>

      {/* Code content */}
      <div className="flex-1 overflow-auto">
        <SyntaxHighlighter
          language={file.language}
          style={materialLight}
          customStyle={{
            margin: 0,
            borderRadius: 0,
            minHeight: '100%',
            fontSize: '0.9rem',
          }}
          showLineNumbers={true}
        >
          {file.code}
        </SyntaxHighlighter>
      </div>
    </div>
  );
}
EOL

# IDE Container Component
cat > src/components/ide/IDEContainer.tsx << 'EOL'
import React, { useState, useEffect } from 'react';
import { SplitPane, Pane } from 'split-pane-react';
import 'split-pane-react/esm/themes/default.css';
import { FileExplorer } from './FileExplorer';
import { CodeEditor } from './CodeEditor';
import { FileImplementation } from '../../lib/types/architect';
import { Download, Archive, ExternalLink, X } from 'lucide-react';
import JSZip from 'jszip';
import { saveAs } from 'file-saver';

interface IDEContainerProps {
  files: FileImplementation[];
  onClose: () => void;
  activeFile: FileImplementation | null;
  setActiveFile: (file: FileImplementation | null) => void;
}

export function IDEContainer({ files, onClose, activeFile, setActiveFile }: IDEContainerProps) {
  const [sizes, setSizes] = useState(['20%', '80%']);
  
  const handleCopyCode = () => {
    if (activeFile) {
      navigator.clipboard.writeText(activeFile.code);
      alert('Code copied to clipboard!');
    }
  };
  
  const handleDownloadFile = () => {
    if (activeFile) {
      const blob = new Blob([activeFile.code], { type: 'text/plain' });
      saveAs(blob, activeFile.name);
    }
  };
  
  const handleDownloadProject = async () => {
    try {
      const zip = new JSZip();
      
      // Helper function to ensure directories exist
      const ensureDirectory = (path: string) => {
        if (!path) return zip;
        const segments = path.split('/').filter(Boolean);
        let currentPath = '';
        
        for (const segment of segments) {
          currentPath = currentPath ? `${currentPath}/${segment}` : segment;
          if (!zip.folder(currentPath)) {
            zip.folder(currentPath);
          }
        }
        
        return zip.folder(path);
      };
      
      // Add all files to the zip
      for (const file of files) {
        const normalizedPath = file.path.replace(/^\/|\/$/g, '');
        ensureDirectory(normalizedPath);
        zip.file(`${normalizedPath}/${file.name}`, file.code);
      }
      
      // Generate and download the zip
      const content = await zip.generateAsync({ type: 'blob' });
      saveAs(content, 'project.zip');
      
    } catch (error) {
      console.error('Error creating zip file:', error);
      alert('Failed to download project. See console for details.');
    }
  };
  
  return (
    <div className="fixed inset-0 bg-white z-50 flex flex-col">
      {/* IDE Header */}
      <div className="border-b px-4 py-3 flex justify-between items-center bg-gray-50">
        <div className="flex items-center">
          <h2 className="font-semibold text-gray-800">Syntax IDE</h2>
          <div className="ml-4 text-sm text-gray-500">{files.length} files generated</div>
        </div>
        
        <div className="flex items-center space-x-3">
          <button 
            className="px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 text-sm rounded flex items-center"
            onClick={handleDownloadProject}
          >
            <Archive className="w-4 h-4 mr-1.5" />
            Download Project
          </button>
          
          <button 
            className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-full"
            onClick={onClose}
            title="Close IDE"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
      </div>
      
      {/* IDE Main Content */}
      <div className="flex-1 overflow-hidden">
        <SplitPane
          split="vertical"
          sizes={sizes}
          onChange={setSizes}
        >
          <Pane minSize="15%" maxSize="30%">
            <FileExplorer 
              files={files} 
              onSelectFile={setActiveFile} 
              activeFile={activeFile} 
            />
          </Pane>
          <div className="h-full">
            <CodeEditor 
              file={activeFile}
              onCopy={handleCopyCode}
              onDownload={handleDownloadFile}
            />
          </div>
        </SplitPane>
      </div>
    </div>
  );
}
EOL

# ============================
# Update Architect Output Component
# ============================
echo "=== Updating Architect Output Component ==="
cat > src/components/conversation/ArchitectOutput.tsx << 'EOL'
import React, { useState } from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon, BrainIcon, SearchIcon, LayersIcon, TerminalIcon, Users2Icon } from 'lucide-react';
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, FileImplementation, SpecialistVision } from '../../lib/types/architect';
import { IDEContainer } from '../ide/IDEContainer';

interface ArchitectOutputProps {
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
  generatedFiles: FileImplementation[];
  activeFile: FileImplementation | null;
  setActiveFile: (file: FileImplementation | null) => void;
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
  generatedFiles,
  activeFile,
  setActiveFile,
  onProceedToNextLevel
}: ArchitectOutputProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedFile, setExpandedFile] = useState<string | null>(null);
  const [selectedSpecialist, setSelectedSpecialist] = useState<number | null>(null);
  const [showIDE, setShowIDE] = useState(false);
  
  const getButtonText = () => {
    switch (currentLevel) {
      case 1:
        return 'Integrate Specialist Visions';
      case 2:
        return 'Generate Code';
      case 3:
        return 'Open IDE';
      default:
        return 'Proceed';
    }
  };

  const handleProceed = () => {
    if (currentLevel === 3) {
      setShowIDE(true);
    } else {
      onProceedToNextLevel();
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
        return !!level3Output?.implementations && level3Output.implementations.length > 0;
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
    
    // Count files in subfolders
    if (rootFolder.subfolders && Array.isArray(rootFolder.subfolders)) {
      for (const subfolder of rootFolder.subfolders) {
        count += getTotalFileCount(subfolder);
      }
    }
    
    return count;
  };
  
  const filteredImplementations = level3Output?.implementations?.filter(file => 
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

  if (showIDE) {
    return (
      <IDEContainer 
        files={generatedFiles} 
        onClose={() => setShowIDE(false)}
        activeFile={activeFile}
        setActiveFile={setActiveFile}
      />
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
                <span>Generating code implementations...</span>
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
              {currentLevel === 3 && "Generated Code"}
            </h3>
            <p className="text-sm text-gray-500">
              {currentLevel === 1 && `${level1Output?.specialists?.length || 0} specialists have provided their expert insights`}
              {currentLevel === 2 && `CTO's unified architecture with dependency tree (${level2Output?.dependencyTree?.files?.length || 0} files)`}
              {currentLevel === 3 && `Complete code implementation for ${level3Output?.implementations?.length || 0} files`}
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
                // Detailed view of the selected specialist
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
                // Summary view of all specialists
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

          {/* Level 3: Code Implementations */}
          {currentLevel === 3 && level3Output && level3Output.implementations && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <CodeIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Generated Code
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {level3Output.implementations.length} files
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
                {filteredImplementations && filteredImplementations.length > 0 ? (
                  <div className="space-y-4">
                    {filteredImplementations.map((file, index) => (
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
                              Type: {file.type} | Language: {file.language}
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
                              <p className="text-gray-600 mt-1">{file.purpose}</p>
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
                            
                            <div className="flex justify-end mt-2">
                              <button
                                onClick={() => {
                                  setActiveFile(file);
                                  setShowIDE(true);
                                }}
                                className="text-xs bg-blue-50 hover:bg-blue-100 text-blue-700 px-3 py-1 rounded transition-colors flex items-center"
                              >
                                <CodeIcon className="w-3 h-3 mr-1" />
                                View Code
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-4 text-gray-500">
                    {searchTerm ? "No files match your search" : "No code implementations found"}
                  </div>
                )}
              </div>
            </div>
          )}

          <button
            onClick={handleProceed}
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
EOL

# ============================
# Update ConversationUI Component
# ============================
echo "=== Updating ConversationUI component ==="
cat > src/components/conversation/ConversationUI.tsx << 'EOL'
import { useRef, useEffect, useState } from 'react';
import { useConversationStore } from '../../lib/stores/conversation';
import { ProjectStructure } from './ProjectStructure';
import { ArchitectOutput } from './ArchitectOutput';
import { FolderIcon, LayoutIcon, SendIcon, RefreshCwIcon, Code } from 'lucide-react';
import { IDEContainer } from '../ide/IDEContainer';

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
    generatedFiles,
    activeFile,
    setActiveFile,
    generateArchitectLevel1,
    generateArchitectLevel2,
    generateArchitectLevel3,
    generateProjectStructure
  } = useConversationStore();

  const [inputText, setInputText] = useState('');
  const [showIDE, setShowIDE] = useState(false);
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
  
  // If IDE is visible, render it in full screen
  if (showIDE && generatedFiles.length > 0) {
    return (
      <IDEContainer 
        files={generatedFiles} 
        onClose={() => setShowIDE(false)}
        activeFile={activeFile}
        setActiveFile={setActiveFile}
      />
    );
  }

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
          <div className="flex items-center space-x-3">
            {generatedFiles.length > 0 && (
              <button
                onClick={() => setShowIDE(true)}
                className="px-4 py-2 text-sm text-blue-600 bg-blue-50 hover:bg-blue-100 border border-blue-200 rounded-lg transition-colors flex items-center"
              >
                <Code className="w-4 h-4 mr-2" />
                Open IDE
              </button>
            )}
            <button
              onClick={reset}
              className="px-4 py-2 text-sm text-gray-600 hover:text-gray-900 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors flex items-center"
            >
              <RefreshCwIcon className="w-4 h-4 mr-2" />
              New Conversation
            </button>
          </div>
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
                  generatedFiles={generatedFiles}
                  activeFile={activeFile}
                  setActiveFile={setActiveFile}
                  onProceedToNextLevel={() => {
                    switch (architect.currentLevel) {
                      case 1:
                        generateArchitectLevel2();
                        break;
                      case 2:
                        generateArchitectLevel3();
                        break;
                      case 3:
                        setShowIDE(true);
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
EOL

# ============================
# Complete the installation script
# ============================
echo "=== Finalizing installation script ==="
cat >> src/lib/services/architect.service.ts << 'EOL'

# Update package.json to add new dependencies
echo "=== Updating package.json ==="
npm pkg set dependencies.react-syntax-highlighter="^15.5.0"
npm pkg set dependencies.react-monaco-editor="^0.54.0"
npm pkg set dependencies.@monaco-editor/react="^4.6.0"
npm pkg set dependencies.react-resizable="^3.0.5"
npm pkg set dependencies.split-pane-react="^0.1.3"
npm pkg set dependencies.file-saver="^2.0.5"
npm pkg set dependencies.jszip="^3.10.1"

# Install dependencies
echo "=== Installing dependencies ==="
npm install

# Finish
echo "=== Update Complete ==="
echo ""
echo "The Syntax AI Software Architect has been updated to directly generate code instead of code contexts."
echo "Features added:"
echo "- Enhanced CTO layer with better project structure generation"
echo "- Direct code generation replacing code contexts"
echo "- IDE-like environment for viewing and managing code"
echo "- Support for any programming language"
echo ""
echo "To start the application, run: npm run dev"
chmod +x ./syntax-update.sh

exit 0
EOL

# Make the script executable
echo "Implementation completed! Run the script with ./syntax-update.sh to apply the changes."