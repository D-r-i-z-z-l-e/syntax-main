import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, FileContext, FileNode, FolderStructure } from '../types/architect';

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

  async generateLevel1(requirements: string[]): Promise<ArchitectLevel1> {
    console.log('Generating comprehensive architectural vision');
    const systemPrompt = `You are an expert software architect.

Your task is to create a detailed architectural vision based on the requirements.

The vision should comprehensively cover:
1. Overall architectural pattern
2. Technology choices
3. Component breakdown
4. Data flow
5. Security considerations
6. Scalability approach

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "visionText": "Your detailed architectural vision here (in plain text, with paragraphs separated by newlines)"
}

NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

    return this.callClaude(systemPrompt, `Requirements:\n${requirements.join('\n')}`);
  }

  async generateLevel2(requirements: string[], visionText: string): Promise<ArchitectLevel2> {
    console.log('Generating project structure with dependency tree');
    const systemPrompt = `You are an expert software architect.

Your task is to create a complete project structure AND a dependency tree based on the architectural vision and requirements provided.

For the project structure, include all folders AND files needed for a complete project.

For the dependency tree, analyze which files depend on other files, and create a coherent implementation order.

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
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

The dependency tree must include ALL files from the project structure.
The implementationOrder values should start from 1 (no dependencies) and increase as dependencies increase.
Files with no dependencies should have an empty dependencies array.
The dependency analysis must be thorough and accurate.

NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

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
    console.log('Generating implementation contexts based on dependency tree');
    
    if (!folderStructure || !folderStructure.rootFolder || !folderStructure.dependencyTree) {
      console.error('Invalid folderStructure provided to generateLevel3:', folderStructure);
      throw new Error('Invalid folder structure: missing rootFolder or dependencyTree property');
    }
    
    const dependencyTree = folderStructure.dependencyTree;
    
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
      const fileContext = await this.generateFileContext(file, dependencyContexts, requirements, visionText);
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
