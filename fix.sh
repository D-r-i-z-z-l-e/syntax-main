#!/bin/bash

echo "Starting implementation of enhanced prompts for more detailed project structures..."

# Create a backup directory
mkdir -p ./backups

# Backup current architect service file
echo "Creating backup of architect service..."
cp src/lib/services/architect.service.ts ./backups/architect.service.ts.bak 2>/dev/null || true

# Update architect service with enhanced prompts
echo "Updating architect service with enhanced prompts..."
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
    console.log(`Generating detailed vision for specialist ${specialistIndex + 1}/${totalSpecialists}: ${role}`);
    
    // Specialist-specific prompts to focus their attention on their domain
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
    
    const systemPrompt = `You are a veteran Chief Technology Officer (CTO) with decades of experience leading architecture for enterprise systems at major tech companies. You have overseen dozens of successful large-scale commercial products from initial design through production deployment.

Your task is to create a COMPREHENSIVE, PRODUCTION-READY project structure by integrating and expanding upon the specialist visions provided. This is for a real commercial application, not a demo or prototype.

Your work will serve as the definitive implementation blueprint, so it must be EXHAUSTIVE and PRECISE. You must:

1. Create a UNIFIED, HOLISTIC architectural vision that synthesizes the best ideas from all specialists
2. Systematically identify and resolve ALL conflicts between specialist recommendations
3. Create a COMPLETE, PRODUCTION-READY project structure that includes EVERY file needed for implementation
4. Generate a detailed dependency tree that establishes the exact implementation order
5. Fill in any gaps left by the specialists to ensure the architecture is complete
6. Make technical decisions that prioritize maintainability, scalability, and best practices

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
    "Detailed explanation of how you resolved conflict/challenge #1 between specialists",
    "Detailed explanation of how you resolved conflict/challenge #2 between specialists",
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
    // File-type specific instructions
    let fileTypeInstructions = "";
    
    // Detect file type based on extension and path
    const fileExt = file.name.split('.').pop()?.toLowerCase() || '';
    const filePath = file.path.toLowerCase();
    
    if (fileExt === 'js' || fileExt === 'ts' || fileExt === 'jsx' || fileExt === 'tsx') {
      // JavaScript/TypeScript file
      if (filePath.includes('component') || filePath.includes('/ui/') || fileExt === 'jsx' || fileExt === 'tsx') {
        fileTypeInstructions = `
This appears to be a UI component file. Your implementation should include:
- Exact import statements
- Component props interface with types and descriptions
- State management details
- Effect hooks and lifecycle handling
- Render logic with JSX structure
- Style implementation details
- Event handlers
- Helper functions
- Props validation
- Performance optimization techniques`;
      } else if (filePath.includes('model') || filePath.includes('schema') || filePath.includes('entity')) {
        fileTypeInstructions = `
This appears to be a data model file. Your implementation should include:
- Class/interface definition with all properties and types
- Validation rules and constraints
- Relationship definitions with other models
- ORM/ODM decorators or configuration
- Database schema considerations
- Methods for CRUD operations
- Business logic related to this entity
- Serialization/deserialization logic`;
      } else if (filePath.includes('controller') || filePath.includes('handler') || filePath.includes('route')) {
        fileTypeInstructions = `
This appears to be a controller/route handler file. Your implementation should include:
- Exact route definitions with HTTP methods and paths
- Request parameter validation
- Authorization checks
- Business logic for each endpoint
- Error handling
- Response formatting
- Middleware integration
- Documentation for API endpoints
- Rate limiting and security considerations`;
      } else if (filePath.includes('service') || filePath.includes('provider')) {
        fileTypeInstructions = `
This appears to be a service file. Your implementation should include:
- Service class definition
- Dependency injection setup
- Public methods with parameters and return types
- Private helper methods
- External service integrations
- Error handling strategy
- Transaction management
- Logging and monitoring
- Performance considerations`;
      } else if (filePath.includes('test') || filePath.includes('spec')) {
        fileTypeInstructions = `
This appears to be a test file. Your implementation should include:
- Test suite organization
- Individual test cases for all functionality
- Mock/stub implementations
- Fixture setup
- Assertions for expected outcomes
- Edge case testing
- Integration test considerations
- Performance test scenarios if applicable`;
      } else if (filePath.includes('config') || filePath.includes('setup')) {
        fileTypeInstructions = `
This appears to be a configuration file. Your implementation should include:
- Configuration parameters with default values
- Environment variable handling
- Type definitions for config options
- Validation of configuration values
- Documentation of each configuration option
- Loading and initialization logic
- Security considerations for sensitive config`;
      }
    } else if (fileExt === 'css' || fileExt === 'scss' || fileExt === 'less') {
      fileTypeInstructions = `
This appears to be a styling file. Your implementation should include:
- Complete CSS/SCSS/LESS structure
- All necessary selectors and rules
- Variable definitions
- Mixins and functions
- Responsive design considerations
- Theme integration
- Animation definitions
- Accessibility considerations
- Browser compatibility notes`;
    } else if (fileExt === 'html') {
      fileTypeInstructions = `
This appears to be an HTML file. Your implementation should include:
- Complete HTML structure
- Semantic markup
- Meta tags and SEO considerations
- Accessibility attributes
- Script and style inclusions
- Template structure if applicable
- Responsive considerations
- Browser compatibility notes`;
    } else if (fileExt === 'sql') {
      fileTypeInstructions = `
This appears to be a SQL file. Your implementation should include:
- Complete SQL statements
- Table creation with all columns and constraints
- Index definitions
- Foreign key relationships
- Stored procedures or functions
- Transaction handling
- Optimization considerations
- Migration strategy`;
    } else if (fileExt === 'md' || fileExt === 'mdx') {
      fileTypeInstructions = `
This appears to be a Markdown documentation file. Your implementation should include:
- Complete documentation structure
- All sections and subsections
- Code examples where relevant
- Usage instructions
- API documentation if applicable
- Links to related resources
- Visual aids descriptions where needed`;
    } else if (fileExt === 'json' || fileExt === 'yaml' || fileExt === 'yml') {
      fileTypeInstructions = `
This appears to be a data configuration file. Your implementation should include:
- Complete structure with all required fields
- Field descriptions and valid values
- Schema conformance details
- Environment-specific configurations
- Security considerations
- Integration points`;
    }
    
    const systemPrompt = `You are a world-class senior staff software engineer with 20+ years of experience. Your task is to create an EXTREMELY DETAILED implementation context for a specific file in a production software project.

This file implementation context must be EXHAUSTIVE and COMPREHENSIVE, leaving no detail unspecified. A junior developer should be able to implement the file perfectly with only your instructions, without needing to ask any questions.

${fileTypeInstructions}

Your implementation context must cover ALL of the following:

1. EXACT imports with specific package versions and import paths
2. Every function, class, variable, and component in COMPLETE detail
3. FULL business logic as detailed, step-by-step pseudocode
4. ALL parameters, return types, error handling approaches
5. COMPLETE data flow through each function
6. Design patterns and principles with implementation details
7. ALL edge cases, error states, and validation requirements
8. Initialization, lifecycle methods, and cleanup procedures
9. File configuration, environment variables, and connection details
10. THOROUGH descriptions of HTML/CSS layouts where applicable
11. SPECIFIC test strategies for this file
12. ALL integration points with other system components

Do not leave ANY implementation detail unspecified. Consider this a complete blueprint for production-quality code.

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "name": "${file.name}",
  "path": "${file.path}",
  "type": "${file.type}",
  "description": "${file.description}",
  "purpose": "${file.purpose}",
  "dependencies": ${JSON.stringify(file.dependencies || [])},
  "imports": ["All required imports with SPECIFIC versions"],
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
          "validation": "SPECIFIC validation requirements",
          "defaultValue": "default value if applicable"
        }
      ],
      "returnType": "return type if applicable",
      "logic": "COMPREHENSIVE step-by-step implementation details in plain English, written as an extremely detailed paragraph that covers EVERY aspect of the implementation. This should be extremely extensive, describing every variable, every condition, every edge case, and the exact logic flow as if writing pseudocode in natural language. Include ALL validation, ALL error handling, ALL business logic, and EVERY step in the process."
    }
  ],
  "styling": "If applicable, DETAILED description of styling/CSS with all properties and values",
  "configuration": "ALL configuration details and settings with exact parameters",
  "stateManagement": "COMPREHENSIVE description of how state is managed in this file",
  "dataFlow": "DETAILED description of data flow through this file, including all inputs and outputs",
  "errorHandling": "COMPLETE error handling strategy for this file with all possible error scenarios",
  "testingStrategy": "DETAILED approach to testing this file with test cases and methodologies",
  "integrationPoints": "ALL integration points with other system components including exact method calls",
  "edgeCases": "ALL edge cases that need to be handled with specific solutions",
  "additionalContext": "ANY other implementation details the developer needs to know to implement this file correctly and completely"
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

Please generate a COMPREHENSIVE implementation context for this specific file, leaving no detail unspecified. The implementation should be of PRODUCTION QUALITY.
`;

    return this.callClaude(systemPrompt, userMessage);
  }
}

export const architectService = ArchitectService.getInstance();
EOF

echo "Script execution completed successfully!"
echo "The architect service has been updated with significantly enhanced prompts that will:"
echo "1. Generate much more detailed project structures from each specialist"
echo "2. Produce comprehensive production-ready project structures from the CTO"
echo "3. Create exhaustive implementation contexts for each file"
echo ""
echo "The changes are now ready to use. Run your application to see the improved results."
echo ""
echo "Note: The token usage will likely increase as the responses will be much more detailed."