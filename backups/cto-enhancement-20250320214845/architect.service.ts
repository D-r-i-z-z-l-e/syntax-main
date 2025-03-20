import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, BookOutline, ChapterContent, FileImplementation, FileNode, FolderStructure, ImplementationBook, SpecialistVision } from '../types/architect';

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
    // First, attempt to find JSON between ```json and ``` markers
    const jsonRegex = /```json\s*([\s\S]*?)\s*```/;
    const match = str.match(jsonRegex);
    
    if (match && match[1]) {
      return match[1].trim();
    }
    
    // If no JSON code block found, extract between the first { and last }
    const startIndex = str.indexOf('{');
    const endIndex = str.lastIndexOf('}');
    
    if (startIndex === -1 || endIndex === -1 || endIndex <= startIndex) {
      console.error('Cannot find valid JSON object in the string');
      throw new Error('Cannot find valid JSON object in the response');
    }
    
    // Extract the JSON part
    let jsonPart = str.substring(startIndex, endIndex + 1);
    
    // Clean up the JSON
    jsonPart = jsonPart.replace(/[\n\r\t]/g, ' ');
    jsonPart = jsonPart.replace(/\s+/g, ' ');
    jsonPart = jsonPart.replace(/\\([^"\\\/bfnrt])/g, '$1');
    
    return jsonPart;
  }

  private extractJsonFromText(text: string): string {
    try {
      // Try to find JSON between code block markers
      const jsonRegex = /```json\s*([\s\S]*?)\s*```/;
      const match = text.match(jsonRegex);
      
      if (match && match[1]) {
        return match[1];
      }
      
      // If not found, try cleaning the string
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

  private async callClaudeWithRetry(systemPrompt: string, userMessage: string, maxRetries = 3) {
    let retries = 0;
    while (retries < maxRetries) {
      try {
        return await this.callClaude(systemPrompt, userMessage);
      } catch (error) {
        retries++;
        console.error(`API call failed (attempt ${retries}/${maxRetries}):`, error);
        
        if (retries >= maxRetries) {
          throw error;
        }
        
        // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, 2000 * Math.pow(2, retries)));
      }
    }
    throw new Error('Max retries exceeded');
  }

  private determineSpecialistsNeeded(requirements: string[]): string[] {
    const requirementsText = requirements.join('\n').toLowerCase();
    
    // Always include these core specialists
    const specialists = ['Backend Developer', 'Frontend Developer'];
    
    // Add specialists based on requirements content
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
    
    // Always add CTO at the end
    specialists.push('Chief Technology Officer');
    
    return specialists;
  }

  async generateSpecialistVision(requirements: string[], role: string, specialistIndex: number, totalSpecialists: number): Promise<SpecialistVision> {
    console.log(`Generating detailed vision for specialist ${specialistIndex + 1}/${totalSpecialists}: ${role}`);
    
    // Customize instructions based on specialist role
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
    
    // Generate vision for each specialist
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

    // Format specialist visions for the prompt
    const specialistVisionsFormatted = specialistVisions.map((sv, i) => 
      `Specialist ${i+1}: ${sv.role}
Expertise: ${sv.expertise}
Vision:
${sv.visionText}
Project Structure:
${JSON.stringify(sv.projectStructure, null, 2)}
`).join('\n\n--------------\n\n');

    // Get the core architecture
    const architectureOutput = await this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Specialist Visions:
${specialistVisionsFormatted}`);

    // Generate the implementation book
    console.log('Generating comprehensive implementation book...');
    
    const bookOutline = await this.generateBookOutline(architectureOutput, requirements);
    console.log(`Book outline generated with ${bookOutline.chapters.length} chapters`);
    
    // Initialize empty implementation book
    const implementationBook: ImplementationBook = {
      title: bookOutline.title,
      introduction: bookOutline.introduction,
      chapters: bookOutline.chapters.map(chapter => ({
        title: chapter.title,
        content: '',
        isComplete: false
      })),
      isComplete: false,
      lastUpdated: new Date().toISOString()
    };
    
    // Return just the architecture output for now - book generation will continue asynchronously
    return {
      ...architectureOutput,
      implementationBook
    };
  }

  // New function to generate book outline
  async generateBookOutline(architectureOutput: ArchitectLevel2, requirements: string[]): Promise<BookOutline> {
    const systemPrompt = `
As a world-class CTO, create a detailed outline for a comprehensive implementation instruction book for this project.

The book should be structured to provide complete guidance for implementing the entire project.

Your outline must include:
1. A title for the implementation book that reflects the project's nature
2. A detailed introduction explaining the project scope, purpose, and how to use the book
3. A list of chapters, each with:
   - A clear title describing the implementation area
   - 5-10 detailed sections covering all aspects of implementation
   - Ordered to follow the dependency structure of the project

Return ONLY a JSON in this format:
{
  "title": "Book title",
  "introduction": "Detailed introduction text",
  "chapters": [
    {
      "title": "Chapter title",
      "sections": [
        "Section 1 title",
        "Section 2 title",
        ...
      ]
    },
    ...
  ]
}

The book should thoroughly cover:
- Architecture implementation details
- Setup and configuration
- All major components and modules
- Integration points
- Testing approach
- Deployment procedures
- Performance optimization
- Security measures

Ensure the chapters build on each other logically, starting with foundational components and progressing to more complex systems.`;

    const bookStructureResponse = await this.callClaudeWithRetry(
      systemPrompt, 
      `Project Requirements:\n${requirements.join('\n')}\n\nArchitectural Vision:\n${architectureOutput.integratedVision.substring(0, 5000)}...\n\nGenerate a comprehensive implementation book outline for this project.`
    );

    return bookStructureResponse as BookOutline;
  }

  // Generate content for a single chapter
  async generateChapterContent(
    chapterTitle: string, 
    sections: string[], 
    architectureOutput: ArchitectLevel2,
    requirements: string[]
  ): Promise<ChapterContent> {
    const systemPrompt = `
You are writing a chapter for the implementation instruction book for this software project.

Chapter Title: "${chapterTitle}"

Write extremely detailed implementation instructions for this chapter, covering these sections:
${sections.join('\n')}

Your instructions must:
- Be incredibly specific and actionable
- Include code patterns and specific implementation approaches
- Cover all edge cases and potential issues
- Explain the reasoning behind each implementation decision
- Reference relevant parts of the project architecture

If you cannot complete the entire chapter within token limits, end with [INCOMPLETE] and briefly 
describe what content remains to be covered.

If you complete the chapter, end with [COMPLETE].

Your goal is to create a comprehensive and detailed chapter that provides step-by-step guidance
for implementing this part of the system. This should be written like a detailed
technical guidebook with code examples and implementation patterns.

Start each section with a clear heading, and organize content with subheadings as needed.
Include diagrams described in text if they would be helpful to explain concepts.`;

    const response = await this.callClaudeWithRetry(
      systemPrompt, 
      `Project Requirements:\n${requirements.join('\n')}\n\nChapter to write: ${chapterTitle}\n\nArchitectural Context:\n${architectureOutput.integratedVision.substring(0, 3000)}...\n\nFiles related to this chapter:\n${JSON.stringify(architectureOutput.dependencyTree.files.slice(0, 10), null, 2)}`
    );
    
    const content = response.content || '';
    const isComplete = !content.includes('[INCOMPLETE]');
    
    return {
      content: content.replace('[COMPLETE]', '').replace('[INCOMPLETE]', ''),
      continuationContext: isComplete ? null : {
        chapterTitle,
        sections,
        completedContent: content,
        remainingSections: this.determineRemainingSections(content, sections)
      }
    };
  }

  // Continue generating content where it left off
  async continueChapterGeneration(
    chapterTitle: string,
    continuationContext: any,
    architectureOutput: ArchitectLevel2
  ): Promise<ChapterContent> {
    const systemPrompt = `
Continue writing the implementation instruction chapter that was previously cut off.

Chapter Title: "${chapterTitle}"

Previously completed content (last few paragraphs for context):
${this.getLastParagraphs(continuationContext.completedContent, 3)}

Continue from where you left off, covering these remaining sections:
${continuationContext.remainingSections.join('\n')}

Your instructions must maintain the same level of detail and specificity.

If you cannot complete the entire chapter within token limits, end with [INCOMPLETE] and briefly 
describe what content remains to be covered.

If you complete the chapter, end with [COMPLETE].

Continue with the same comprehensive, detailed approach as before. Make sure your continuation
flows naturally from the previous content.`;

    const response = await this.callClaudeWithRetry(
      systemPrompt, 
      `Continue the implementation instructions for chapter "${chapterTitle}". Pick up exactly where the previous text left off.`
    );
    
    const content = response.content || '';
    const isComplete = !content.includes('[INCOMPLETE]');
    
    return {
      content: content.replace('[COMPLETE]', '').replace('[INCOMPLETE]', ''),
      continuationContext: isComplete ? null : {
        chapterTitle,
        sections: continuationContext.remainingSections,
        completedContent: continuationContext.completedContent + content,
        remainingSections: this.determineRemainingSections(content, continuationContext.remainingSections)
      }
    };
  }

  // Helper to generate an entire implementation book
  async generateImplementationBook(architectureOutput: ArchitectLevel2, requirements: string[], progressCallback: Function): Promise<ImplementationBook> {
    // 1. Generate the book outline if not already generated
    let bookOutline: BookOutline;
    if (architectureOutput.implementationBook) {
      bookOutline = {
        title: architectureOutput.implementationBook.title,
        introduction: architectureOutput.implementationBook.introduction,
        chapters: architectureOutput.implementationBook.chapters.map(chapter => ({
          title: chapter.title,
          sections: [] // Will need to regenerate sections if not saved
        }))
      };
    } else {
      bookOutline = await this.generateBookOutline(architectureOutput, requirements);
    }
    
    // Initialize the implementation book
    const implementationBook: ImplementationBook = {
      title: bookOutline.title,
      introduction: bookOutline.introduction,
      chapters: bookOutline.chapters.map(chapter => ({
        title: chapter.title,
        content: '',
        isComplete: false
      })),
      isComplete: false,
      lastUpdated: new Date().toISOString()
    };
    
    // 2. Generate each chapter recursively
    const totalChapters = bookOutline.chapters.length;
    let completedChapters = 0;
    
    for (let i = 0; i < bookOutline.chapters.length; i++) {
      const chapter = bookOutline.chapters[i];
      
      // Update progress
      progressCallback({
        totalChapters,
        completedChapters,
        currentChapter: chapter.title,
        progress: (completedChapters / totalChapters) * 100
      });
      
      let chapterContent = '';
      
      // Get or regenerate sections if needed
      const sections = chapter.sections.length ? chapter.sections : 
        this.generateDefaultSections(chapter.title, architectureOutput);
      
      // Initial chapter generation
      const initialContent = await this.generateChapterContent(
        chapter.title, 
        sections, 
        architectureOutput,
        requirements
      );
      
      chapterContent += initialContent.content;
      
      // If the chapter generation was incomplete, continue recursively
      let continuationContext = initialContent.continuationContext;
      while (continuationContext) {
        const continuation = await this.continueChapterGeneration(
          chapter.title,
          continuationContext,
          architectureOutput
        );
        
        chapterContent += continuation.content;
        continuationContext = continuation.continuationContext;
        
        // Update lastUpdated timestamp to track progress
        implementationBook.lastUpdated = new Date().toISOString();
      }
      
      // Update the chapter in the book
      implementationBook.chapters[i].content = chapterContent;
      implementationBook.chapters[i].isComplete = true;
      
      // Increment completed chapters count and update progress
      completedChapters++;
      progressCallback({
        totalChapters,
        completedChapters,
        currentChapter: i < bookOutline.chapters.length - 1 ? bookOutline.chapters[i + 1].title : 'Complete',
        progress: (completedChapters / totalChapters) * 100
      });
    }
    
    // Mark the book as complete
    implementationBook.isComplete = true;
    implementationBook.lastUpdated = new Date().toISOString();
    
    return implementationBook;
  }

  // Helper to determine which sections remain to be covered
  private determineRemainingSections(content: string, allSections: string[]): string[] {
    const remainingSections = [...allSections];
    
    for (const section of allSections) {
      if (content.includes(section)) {
        const index = remainingSections.indexOf(section);
        if (index > -1) {
          remainingSections.splice(index, 1);
        }
      }
    }
    
    return remainingSections;
  }

  // Helper to generate default sections if none are provided
  private generateDefaultSections(chapterTitle: string, architectureOutput: ArchitectLevel2): string[] {
    // Generate sections based on chapter title and project context
    const defaultSections = [
      "Overview and Purpose",
      "Architecture and Design",
      "Dependencies and Requirements",
      "Implementation Steps",
      "Configuration Details",
      "Integration Points",
      "Testing Approach",
      "Error Handling",
      "Performance Considerations",
      "Security Measures"
    ];
    
    // Customize sections based on chapter title
    if (chapterTitle.toLowerCase().includes('database')) {
      return [
        "Database Schema Design",
        "Entity Relationships",
        "Indexing Strategy",
        "Query Optimization",
        "Migration Approach",
        "Data Access Patterns",
        "Transaction Management",
        "Connection Pooling",
        "Backup and Recovery",
        "Data Security"
      ];
    }
    
    if (chapterTitle.toLowerCase().includes('frontend')) {
      return [
        "Component Architecture",
        "State Management",
        "Routing and Navigation",
        "UI Component Design",
        "API Integration",
        "Form Handling",
        "Error and Loading States",
        "Responsive Design",
        "Testing and Validation",
        "Performance Optimization"
      ];
    }
    
    if (chapterTitle.toLowerCase().includes('api')) {
      return [
        "API Design Principles",
        "Endpoint Definitions",
        "Request/Response Formats",
        "Authentication and Authorization",
        "Error Handling",
        "Rate Limiting",
        "Versioning Strategy",
        "Documentation",
        "Testing Strategy",
        "Performance Considerations"
      ];
    }
    
    if (chapterTitle.toLowerCase().includes('security')) {
      return [
        "Security Architecture",
        "Authentication Implementation",
        "Authorization and Access Control",
        "Data Encryption",
        "Input Validation",
        "Attack Prevention Strategies",
        "Secure Communication",
        "Secret Management",
        "Security Logging and Monitoring",
        "Security Testing"
      ];
    }
    
    return defaultSections;
  }

  // Helper to get the last N paragraphs of text
  private getLastParagraphs(text: string, count: number): string {
    const paragraphs = text.split('\n\n');
    return paragraphs.slice(Math.max(0, paragraphs.length - count)).join('\n\n');
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
    
    // Sort files by implementation order
    const sortedFiles = [...dependencyTree.files].sort((a, b) => a.implementationOrder - b.implementationOrder);
    
    // Generate implementations for each file
    const implementations: FileImplementation[] = [];
    
    for (const file of sortedFiles) {
      console.log(`Generating implementation for ${file.path}/${file.name} (order: ${file.implementationOrder})`);
      
      // Get the file's dependencies
      const dependencies = file.dependencies || [];
      
      // Get implementations of dependencies
      const dependencyImplementations = implementations
        .filter(impl => dependencies.includes(`${impl.path}/${impl.name}`));
      
      // Generate implementation for this file
      const fileImplementation = await this.generateFileImplementation(
        file, 
        dependencyImplementations, 
        requirements, 
        level2Output.integratedVision,
        level2Output.implementationBook
      );
      
      implementations.push(fileImplementation);
    }
    
    return { implementations };
  }
  
  private async generateFileImplementation(
    file: FileNode,
    dependencyImplementations: FileImplementation[],
    requirements: string[],
    visionText: string,
    implementationBook?: ImplementationBook
  ): Promise<FileImplementation> {
    // Determine language based on file extension
    const fileExt = file.name.split('.').pop()?.toLowerCase() || '';
    const language = this.getLanguageFromExtension(fileExt);
    
    // Get specialized instructions based on file type
    let fileTypeInstructions = this.getFileTypeInstructions(file, fileExt);
    
    // Extract relevant chapter content from implementation book if available
    let bookInstructions = '';
    if (implementationBook && implementationBook.chapters) {
      // Look for relevant chapters based on file path and name
      const filePathLower = file.path.toLowerCase();
      const fileNameLower = file.name.toLowerCase();
      
      for (const chapter of implementationBook.chapters) {
        if (chapter.isComplete && chapter.content) {
          const chapterLower = chapter.title.toLowerCase();
          
          // Check if chapter is relevant to this file
          if (
            filePathLower.includes(chapterLower) || 
            fileNameLower.includes(chapterLower) ||
            chapterLower.includes(filePathLower.split('/').pop() || '') ||
            chapterLower.includes(fileNameLower.split('.')[0] || '')
          ) {
            bookInstructions += `\n\nRelevant Implementation Book Chapter: ${chapter.title}\n${chapter.content.substring(0, 3000)}...\n`;
            break; // Just include the most relevant chapter
          }
        }
      }
    }
    
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

    // Format dependency implementations for context
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
${visionText.substring(0, 2000)}...
${bookInstructions}

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
    // Customize instructions based on file path and extension
    const filePath = file.path.toLowerCase();
    
    // JavaScript/TypeScript files
    if (fileExt === 'js' || fileExt === 'ts' || fileExt === 'jsx' || fileExt === 'tsx') {
      // UI components
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
    
    // Default instructions for any other file type
    return `
This file requires a complete, production-ready implementation. Your code should:
- Follow best practices for this file type and language
- Include all necessary imports/references
- Implement all required functionality
- Handle errors appropriately
- Be well-documented
- Be performant and secure`;
  }
  
  // New method to start asynchronous book generation
  async startBookGeneration(
    requirements: string[],
    level2Output: ArchitectLevel2,
    progressCallback: Function
  ): Promise<void> {
    // Start the book generation in the background
    this.generateImplementationBook(level2Output, requirements, progressCallback)
      .then((book) => {
        console.log(`Implementation book generation completed with ${book.chapters.length} chapters`);
        
        // Here you could save the book to a database or notify the client that it's ready
        // For now, we'll just log completion
        progressCallback({
          totalChapters: book.chapters.length,
          completedChapters: book.chapters.length,
          currentChapter: 'Complete',
          progress: 100,
          book: book // Include the completed book in the callback
        });
      })
      .catch((error) => {
        console.error('Error generating implementation book:', error);
        progressCallback({
          error: error.message || 'Failed to generate implementation book'
        });
      });
  }
}

export const architectService = ArchitectService.getInstance();
