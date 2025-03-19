#!/bin/bash

# Script to enhance the CTO layer of the Syntax AI Software Architect
# This script improves the CTO's analytical capabilities and report generation

set -e

echo "=== Enhancing CTO layer of the Syntax AI Software Architect ==="
echo "This script will update the CTO layer to provide much deeper analysis and synthesis."

# Check if we're in the right directory
if [ ! -f "src/lib/services/architect.service.ts" ]; then
  echo "Error: Please run this script from the root of the syntax project."
  exit 1
fi

# ============================
# Update Architect Service
# ============================
echo "=== Updating architect service with enhanced CTO capabilities ==="
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
    console.log('Generating comprehensive CTO architecture with deep analysis...');
    
    if (!level1Output.specialists || level1Output.specialists.length === 0) {
      throw new Error('No specialist visions available to integrate');
    }
    
    const specialistVisions = level1Output.specialists;
    
    const systemPrompt = `You are a world-class Chief Technology Officer (CTO) with 30+ years of experience leading technology teams at major global enterprises. You have led the architecture and successful delivery of hundreds of complex, mission-critical software systems that have scaled to millions of users worldwide. Your expertise spans all aspects of software architecture, engineering leadership, and technical innovation.

Your task is to create an EXTRAORDINARILY DETAILED and COMPREHENSIVE architectural specification and project structure based on specialist inputs. This is for a real enterprise-grade production application, not a prototype or MVP.

# YOUR RESPONSIBILITIES:

1. DEEP ANALYTICAL SYNTHESIS: You MUST perform an extraordinarily detailed analysis of each specialist's input. You are not merely combining their ideas but critically evaluating each element, identifying strengths, weaknesses, and how they might conflict or complement each other.

2. ORIGINAL ARCHITECTURAL THINKING: You MUST contribute your own significant original architectural thinking beyond what the specialists provided. Apply your decades of experience to create an architecture that is greater than the sum of its parts.

3. COMPREHENSIVE TECHNICAL SPEC: Your output must be an extremely detailed, production-ready technical specification that thoroughly documents every aspect of the system architecture. The level of detail must be sufficient for an engineering team to implement without further architectural guidance.

4. TECHNOLOGY CHOICES WITH JUSTIFICATION: Make clear, decisive technology choices for every aspect of the system. Provide thorough justification for each choice based on technical considerations, scalability needs, maintainability, security, and business requirements.

5. CROSS-CUTTING CONCERNS: Address ALL cross-cutting concerns that individual specialists might have missed, including:
   - Global error handling strategy
   - Comprehensive logging and monitoring approach
   - System-wide security architecture
   - Scalability and performance optimizations
   - Deployment and operational considerations
   - Maintenance and upgrade paths
   - Disaster recovery strategy
   - Compliance and regulatory requirements

6. COMPREHENSIVE PROJECT STRUCTURE: Generate a COMPLETE project structure with EVERY file needed for implementation. This includes code files, configuration, documentation, tests, deployment scripts, etc.

7. DETAILED DEPENDENCY MANAGEMENT: Create a meticulously designed dependency structure that minimizes coupling and maximizes cohesion.

# ANALYSIS APPROACH:

1. For each specialist input:
   - Identify the core architectural approach proposed
   - Extract key technical decisions and justifications
   - Note any potential conflicts or gaps with other specialists
   - Evaluate tradeoffs in their approach

2. Synthesize across specialists:
   - Resolve conflicts between different specialist recommendations
   - Identify synergies where different specialists' ideas can be combined
   - Fill gaps that no specialist adequately addressed
   - Ensure consistency across the entire architecture

3. Apply your expertise:
   - Introduce architectural patterns that improve the overall design
   - Make technology selections based on requirements and best practices
   - Optimize for maintainability, scalability, and performance
   - Ensure comprehensive test coverage
   - Address deployment, monitoring, and operations

# REPORT STRUCTURE:

Your integrated vision MUST contain the following sections in detail:

1. Executive Summary: High-level overview of the architecture and key decisions
2. System Architecture Overview: Detailed description of the overall architecture pattern and main components
3. Technology Stack: Complete technology selections with justification
4. Component Architecture: Each major component or service described in detail
5. Data Architecture: Complete data model, storage strategies, and data flow
6. Security Architecture: Comprehensive security design and implementation strategies
7. Integration Architecture: How the system integrates with external systems and APIs
8. Deployment Architecture: Complete deployment strategy, environments, and pipeline
9. Performance Considerations: Specific optimizations and scaling strategies
10. Development Guidelines: Coding standards, patterns, and practices
11. Testing Strategy: Complete testing approach from unit to production
12. Operational Considerations: Monitoring, alerting, and maintenance

You MUST present a deep, detailed architectural vision that demonstrates expert-level understanding. This is not a high-level overview - it is a comprehensive specification with implementation details.

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "integratedVision": "Your extremely comprehensive architectural specification with every detail required for implementation (use paragraphs separated by newlines, include detailed sections covering all architectural aspects)",
  "resolutionNotes": [
    "Detailed explanation of how you resolved conflict/challenge between specialists, including your analysis and reasoning",
    "Detailed explanation of how you resolved another conflict/challenge between specialists",
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

The project structure should contain AT MINIMUM 150-200 files for any non-trivial application. Include ALL files necessary for a complete production implementation.

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
# Update Architect Output Component (to better display comprehensive CTO report)
# ============================
echo "=== Updating Architect Output Component for better CTO report display ==="
cat > src/components/conversation/ArchitectOutput.tsx << 'EOL'
import React, { useState } from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon, BrainIcon, SearchIcon, LayersIcon, TerminalIcon, Users2Icon, ChevronDownIcon, ChevronUpIcon } from 'lucide-react';
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

const REPORT_SECTIONS = [
  { id: 'executive-summary', title: 'Executive Summary' },
  { id: 'system-architecture', title: 'System Architecture Overview' },
  { id: 'technology-stack', title: 'Technology Stack' },
  { id: 'component-architecture', title: 'Component Architecture' },
  { id: 'data-architecture', title: 'Data Architecture' },
  { id: 'security-architecture', title: 'Security Architecture' },
  { id: 'integration-architecture', title: 'Integration Architecture' },
  { id: 'deployment-architecture', title: 'Deployment Architecture' },
  { id: 'performance-considerations', title: 'Performance Considerations' },
  { id: 'development-guidelines', title: 'Development Guidelines' },
  { id: 'testing-strategy', title: 'Testing Strategy' },
  { id: 'operational-considerations', title: 'Operational Considerations' }
];

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
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['executive-summary']));
  const [visibleVisionSection, setVisibleVisionSection] = useState('all');
  
  const toggleSection = (sectionId: string) => {
    setExpandedSections(prev => {
      const newSet = new Set(prev);
      if (newSet.has(sectionId)) {
        newSet.delete(sectionId);
      } else {
        newSet.add(sectionId);
      }
      return newSet;
    });
  };
  
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
  
  const renderVisionSections = (visionText: string) => {
    if (visibleVisionSection !== 'all') {
      // Find the relevant section based on pattern matching
      const sections = extractSections(visionText);
      if (sections[visibleVisionSection]) {
        return (
          <div className="text-sm text-gray-700 bg-white rounded-lg p-5 max-h-[600px] overflow-y-auto border border-gray-200 prose prose-sm">
            {sections[visibleVisionSection].split('\n\n').map((paragraph, idx) => (
              <p key={idx} className="mb-4">{paragraph}</p>
            ))}
          </div>
        );
      }
    }
    
    // Default - show all content
    return (
      <div className="text-sm text-gray-700 bg-white rounded-lg p-5 max-h-[600px] overflow-y-auto border border-gray-200 prose prose-sm">
        {visionText.split('\n\n').map((paragraph, idx) => (
          <p key={idx} className="mb-4">{paragraph}</p>
        ))}
      </div>
    );
  };
  
  const extractSections = (visionText: string) => {
    const sections: Record<string, string> = {};
    let currentSection = 'executive-summary';
    let currentContent: string[] = [];
    
    // Split by lines to process section by section
    const lines = visionText.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // Check if this line is a section header
      const sectionMatch = /^(#+)\s+(.+)$/i.test(line) || 
                          /^([A-Z][A-Za-z\s]+):$/i.test(line) ||
                          /^([0-9]+\.\s+[A-Z][A-Za-z\s]+)$/i.test(line);
                          
      if (sectionMatch) {
        // Save the previous section
        if (currentContent.length > 0) {
          sections[currentSection] = currentContent.join('\n');
        }
        
        // Start a new section
        // Simplify the section name for mapping
        const sectionName = line.toLowerCase()
          .replace(/^#+\s+/, '')
          .replace(/[^a-z0-9\s-]/g, '')
          .replace(/\s+/g, '-')
          .trim();
          
        // Find the best matching predefined section
        currentSection = findBestMatchingSection(sectionName) || sectionName;
        currentContent = [line];
      } else {
        currentContent.push(line);
      }
    }
    
    // Save the last section
    if (currentContent.length > 0) {
      sections[currentSection] = currentContent.join('\n');
    }
    
    return sections;
  };
  
  const findBestMatchingSection = (sectionName: string): string | null => {
    // Map the input section to our predefined sections
    for (const section of REPORT_SECTIONS) {
      const normalizedSectionId = section.title.toLowerCase().replace(/\s+/g, '-');
      if (sectionName.includes(normalizedSectionId) || 
          normalizedSectionId.includes(sectionName)) {
        return section.id;
      }
    }
    return null;
  };

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
            {currentLevel === 2 && "CTO is developing comprehensive architecture specification..."}
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
              {currentLevel === 2 && "CTO's Comprehensive Architecture"}
              {currentLevel === 3 && "Generated Code"}
            </h3>
            <p className="text-sm text-gray-500">
              {currentLevel === 1 && `${level1Output?.specialists?.length || 0} specialists have provided their expert insights`}
              {currentLevel === 2 && `Complete architectural specification with ${level2Output?.dependencyTree?.files?.length || 0} files`}
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

          {/* Level 2: Enhanced CTO Architecture Report */}
          {currentLevel === 2 && level2Output && (
            <div className="space-y-6">
              {/* Section Tabs */}
              <div className="flex flex-wrap gap-2 mb-4">
                <button
                  className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                    visibleVisionSection === 'all' 
                      ? 'bg-blue-600 text-white' 
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                  onClick={() => setVisibleVisionSection('all')}
                >
                  Full Report
                </button>
                
                {REPORT_SECTIONS.map((section) => (
                  <button
                    key={section.id}
                    className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                      visibleVisionSection === section.id 
                        ? 'bg-blue-600 text-white' 
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                    onClick={() => setVisibleVisionSection(section.id)}
                  >
                    {section.title}
                  </button>
                ))}
              </div>
            
              {/* Integrated Vision - Enhanced Report Display */}
              <div>
                <div className="mb-3 flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <BrainIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      Comprehensive Architecture Specification
                    </h3>
                  </div>
                </div>
                
                {renderVisionSections(level2Output.integratedVision)}
              </div>
              
              {/* Resolution Notes */}
              {level2Output.resolutionNotes && level2Output.resolutionNotes.length > 0 && (
                <div>
                  <div className="flex items-center justify-between cursor-pointer mb-2" onClick={() => toggleSection('resolution-notes')}>
                    <div className="flex items-center">
                      <div className="w-7 h-7 rounded-full bg-yellow-500 text-white flex items-center justify-center mr-3">
                        <LayersIcon className="w-4 h-4" />
                      </div>
                      <h3 className="text-base font-semibold text-gray-800">
                        Architectural Decisions & Trade-offs
                      </h3>
                    </div>
                    {expandedSections.has('resolution-notes') ? 
                      <ChevronUpIcon className="w-5 h-5 text-gray-500" /> : 
                      <ChevronDownIcon className="w-5 h-5 text-gray-500" />
                    }
                  </div>
                  
                  {expandedSections.has('resolution-notes') && (
                    <div className="bg-yellow-50 rounded-lg p-4 border border-yellow-100 mt-2">
                      <ul className="list-disc pl-5 space-y-4">
                        {level2Output.resolutionNotes.map((note, idx) => (
                          <li key={idx} className="text-sm text-gray-700">{note}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              )}
              
              {/* Project Structure */}
              <div>
                <div className="flex items-center justify-between cursor-pointer mb-2" onClick={() => toggleSection('project-structure')}>
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <LayersIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      Project Structure
                    </h3>
                  </div>
                  {expandedSections.has('project-structure') ? 
                    <ChevronUpIcon className="w-5 h-5 text-gray-500" /> : 
                    <ChevronDownIcon className="w-5 h-5 text-gray-500" />
                  }
                </div>
                
                {expandedSections.has('project-structure') && (
                  <div className="bg-gray-50 rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200 mt-2">
                    <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full inline-block mb-3">
                      {level2Output.dependencyTree?.files?.length || 0} files
                    </div>
                    {renderFolderStructure(level2Output.rootFolder)}
                  </div>
                )}
              </div>
              
              {/* Dependency Tree */}
              <div>
                <div className="flex items-center justify-between cursor-pointer mb-2" onClick={() => toggleSection('dependency-tree')}>
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <CodeIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      Implementation Order
                    </h3>
                  </div>
                  {expandedSections.has('dependency-tree') ? 
                    <ChevronUpIcon className="w-5 h-5 text-gray-500" /> : 
                    <ChevronDownIcon className="w-5 h-5 text-gray-500" />
                  }
                </div>
                
                {expandedSections.has('dependency-tree') && (
                  <div className="bg-gray-50 rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200 mt-2">
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
                )}
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

# Make the script executable

echo "=== Enhancement Complete ==="
echo ""
echo "The Syntax AI Software Architect's CTO layer has been enhanced to provide much more comprehensive"
echo "architectural specifications that will truly integrate and build upon specialist perspectives."
echo ""
echo "Key improvements:"
echo "1. Enhanced CTO prompt with detailed analytical requirements"
echo "2. Required comprehensive analysis of each specialist's input"
echo "3. Expanded report structure with detailed sections for all architectural aspects"
echo "4. Improved UI to better display and navigate the CTO's architectural report"
echo "5. Emphasis on original architectural thinking beyond specialist recommendations"
echo ""
echo "To apply these changes, run: ./enhance-cto-layer.sh"