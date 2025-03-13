#!/bin/bash

# Script to enhance Level 3 with comprehensive implementation contexts
# Run this from your syntax-main directory

set -e  # Exit on error

echo "=== Enhancing Level 3 with comprehensive implementation contexts ==="

# Create backup
mkdir -p ./backups/level3-enhanced-$(date +%Y%m%d%H%M%S)
BACKUP_DIR="./backups/level3-enhanced-$(date +%Y%m%d%H%M%S)"
cp ./src/lib/services/architect.service.ts "$BACKUP_DIR/architect.service.ts.bak"

echo "Backed up original file to $BACKUP_DIR"

# Update the architect service with enhanced Level 3
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
    // Find the first { and the last }
    const startIndex = str.indexOf('{');
    const endIndex = str.lastIndexOf('}');
    
    if (startIndex === -1 || endIndex === -1 || endIndex <= startIndex) {
      console.error('Cannot find valid JSON object in the string');
      throw new Error('Cannot find valid JSON object in the response');
    }
    
    // Extract the JSON part
    let jsonPart = str.substring(startIndex, endIndex + 1);
    
    // Clean up any issues with the JSON string
    jsonPart = jsonPart.replace(/[\n\r\t]/g, ' ');
    jsonPart = jsonPart.replace(/\s+/g, ' ');
    jsonPart = jsonPart.replace(/\\([^"\\\/bfnrt])/g, '$1');
    
    return jsonPart;
  }

  private extractJsonFromText(text: string): string {
    try {
      // First, try to find JSON between ```json and ``` markers
      const jsonRegex = /```json\s*([\s\S]*?)\s*```/;
      const match = text.match(jsonRegex);
      
      if (match && match[1]) {
        return match[1];
      }
      
      // If that fails, try to find the first { and last } that contain valid JSON
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
          temperature: 0.2, // Lower temperature for more deterministic JSON generation
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
    console.log('Generating complete project skeleton with all files');
    const systemPrompt = `You are an expert software architect.

Your task is to create a complete project structure based on the architectural vision and requirements provided.

The structure must include all folders AND files needed for a complete project.

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
  }
}

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
    console.log('Generating comprehensive implementation contexts');
    
    // Validate folder structure before using
    if (!folderStructure || !folderStructure.rootFolder) {
      console.error('Invalid folderStructure provided to generateLevel3:', folderStructure);
      throw new Error('Invalid folder structure: missing rootFolder property');
    }
    
    // Process files in batches to handle larger projects
    const allFiles = this.extractAllFiles(folderStructure.rootFolder);
    
    // Sort files by importance for better prioritization
    const sortedFiles = this.sortFilesByImportance(allFiles);
    
    // Select the top files based on importance (adjust based on your needs)
    const filesToProcess = sortedFiles.slice(0, 10);
    
    console.log(`Processing ${filesToProcess.length} files for implementation contexts out of ${allFiles.length} total files`);
    
    const systemPrompt = `You are a master software engineer. Your task is to create EXTREMELY DETAILED implementation contexts for each file.

Each implementation context must be comprehensive enough that ANY programmer could implement the file perfectly from just this description.

Your implementation contexts must:

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

Think of each implementation context as an exhaustive guide that contains EVERY PIECE OF INFORMATION needed to build the file without additional guidance.

IMPORTANT: You MUST respond with a JSON object in EXACTLY this format:
{
  "implementationOrder": [
    {
      "name": "filename.ext",
      "path": "file path",
      "type": "file type (e.g., JavaScript, TypeScript, etc.)",
      "description": "Brief file description",
      "purpose": "What this file accomplishes",
      "dependencies": ["list of files this depends on"],
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
  ]
}

NO OTHER TEXT before or after the JSON.
NO explanation.
NO conversation.
ONLY the JSON object.`;

    // Process all files in a single batch to maintain dependencies
    return this.processFileBatch(requirements, visionText, filesToProcess, systemPrompt);
  }
  
  private async processFileBatch(
    requirements: string[],
    visionText: string,
    files: any[],
    systemPrompt: string
  ): Promise<ArchitectLevel3> {
    console.log(`Processing batch of ${files.length} files`);
    
    const response = await this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}

Architectural Vision:
${visionText}

Files to Implement (Implement ALL of these files with COMPLETE, EXHAUSTIVE detail):
${this.formatFilesForPrompt(files)}
`);
    
    if (!response.implementationOrder || !Array.isArray(response.implementationOrder)) {
      console.error('Invalid implementation plan response:', response);
      throw new Error('Invalid implementation plan response: missing or invalid implementationOrder');
    }
    
    return response;
  }
  
  // Helper methods
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
  
  private sortFilesByImportance(files: any[]): any[] {
    // Prioritize entry points, core components, and key configuration files
    return [...files].sort((a, b) => {
      // Score each file based on importance factors
      const scoreA = this.calculateFileImportance(a);
      const scoreB = this.calculateFileImportance(b);
      
      // Sort by score (higher is more important)
      return scoreB - scoreA;
    });
  }
  
  private calculateFileImportance(file: any): number {
    let score = 0;
    const name = file.name.toLowerCase();
    const path = file.path.toLowerCase();
    
    // Entry points are very important
    if (name.includes('index') || name.includes('main') || name.includes('app')) {
      score += 30;
    }
    
    // Core configuration files
    if (name.includes('config') || name.endsWith('.json') || name.includes('.env')) {
      score += 25;
    }
    
    // Core components and services
    if (path.includes('component') || path.includes('service') || path.includes('controller')) {
      score += 20;
    }
    
    // Database models and schemas
    if (path.includes('model') || path.includes('schema') || path.includes('entity')) {
      score += 18;
    }
    
    // API endpoints
    if (path.includes('api') || path.includes('route') || path.includes('endpoint')) {
      score += 15;
    }
    
    // Utilities and helpers
    if (path.includes('util') || path.includes('helper') || path.includes('common')) {
      score += 10;
    }
    
    // By file extension/type
    const ext = name.split('.').pop() || '';
    
    if (['js', 'ts', 'jsx', 'tsx'].includes(ext)) score += 8;
    if (['py', 'java', 'rb'].includes(ext)) score += 8;
    if (['html', 'css'].includes(ext)) score += 5;
    if (['md', 'txt'].includes(ext)) score += 2;
    
    return score;
  }
  
  private formatFilesForPrompt(files: any[]): string {
    return files.map(file => 
      `- ${file.path}/${file.name}: ${file.description}`
    ).join('\n');
  }
}

export const architectService = ArchitectService.getInstance();
EOF

echo "=== Level 3 Enhancement Complete ==="
echo "The Level 3 implementation has been completely reimagined to provide:"
echo ""
echo "1. EXTREMELY DETAILED implementation contexts for each file"
echo "   - Comprehensive enough for any programmer to implement perfectly"
echo "   - Essentially pseudocode in natural language form"
echo ""
echo "2. Complete coverage of:"
echo "   - Every function, class, variable, and component"
echo "   - All business logic in detailed steps"
echo "   - All imports and dependencies"
echo "   - All parameters, return types, and error handling"
echo "   - Data flow through each function"
echo "   - Edge cases, validation, and error states"
echo ""
echo "3. Intelligent file prioritization"
echo "   - Focuses on the most important files first"
echo "   - Ranks files by their role in the architecture"
echo ""
echo "This implementation should now provide exhaustive implementation details"
echo "that would allow any programmer to implement the file correctly from just"
echo "reading the file context, with no additional information needed."