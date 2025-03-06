#!/bin/bash

# Script to apply enhanced logging for debugging the folder structure issue
# Run this from your syntax-main directory

set -e  # Exit on error

echo "Applying enhanced logging to diagnose the folder structure issue..."

# Backup the existing files
mkdir -p ./backups
cp ./src/app/api/architect/route.ts ./backups/route.ts.debug.$(date +%Y%m%d%H%M%S)
cp ./src/lib/stores/conversation.ts ./backups/conversation.ts.debug.$(date +%Y%m%d%H%M%S)
cp ./src/lib/services/architect.service.ts ./backups/architect.service.ts.debug.$(date +%Y%m%d%H%M%S)

# Create the updated route.ts file with enhanced logging
cat > ./src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';

export async function POST(req: NextRequest) {
  try {
    console.log('=== ARCHITECT API REQUEST RECEIVED ===');
    
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;
    
    console.log(`Architect API level ${level} request received`);
    console.log(`Request body:`, JSON.stringify({
      level,
      requirementsCount: requirements?.length,
      hasVisionText: !!visionText,
      hasFolderStructure: !!folderStructure
    }));
    
    // ENHANCED LOGGING - Inspect folder structure in detail
    if (folderStructure) {
      console.log('=== FOLDER STRUCTURE DETAILS ===');
      console.log('Type:', typeof folderStructure);
      console.log('Keys:', Object.keys(folderStructure));
      console.log('Has rootFolder property:', 'rootFolder' in folderStructure);
      if ('rootFolder' in folderStructure) {
        console.log('rootFolder type:', typeof folderStructure.rootFolder);
        console.log('rootFolder keys:', Object.keys(folderStructure.rootFolder));
      }
      console.log('First 500 chars of JSON representation:', 
                  JSON.stringify(folderStructure).substring(0, 500));
    } else {
      console.log('=== FOLDER STRUCTURE IS MISSING OR NULL ===');
    }
    
    if (!requirements || !Array.isArray(requirements)) {
      console.log('ERROR: Valid requirements array is required');
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }
    
    let result;
    switch (level) {
      case 1:
        result = await architectService.generateLevel1(requirements);
        break;
      case 2:
        if (!visionText) {
          console.log('ERROR: Vision text is required for level 2');
          return NextResponse.json({ error: 'Vision text is required for level 2' }, { status: 400 });
        }
        result = await architectService.generateLevel2(requirements, visionText);
        break;
      case 3:
        console.log('=== PROCESSING LEVEL 3 REQUEST ===');
        if (!visionText) {
          console.log('ERROR: Vision text is required for level 3');
          return NextResponse.json({ error: 'Vision text is required for level 3' }, { status: 400 });
        }
        
        if (!folderStructure) {
          console.log('ERROR: Missing folder structure for level 3');
          return NextResponse.json({ 
            error: 'Missing required inputs for level 3: ["folder structure"]' 
          }, { status: 400 });
        }
        
        // Deep logging of folder structure before normalization
        console.log('=== BEFORE NORMALIZATION ===');
        console.log(JSON.stringify(folderStructure, null, 2));
        
        // Make sure folderStructure has a rootFolder property
        const normalizedFolderStructure = typeof folderStructure === 'object' && 'rootFolder' in folderStructure
          ? folderStructure
          : { rootFolder: folderStructure };
        
        // Deep logging of folder structure after normalization
        console.log('=== AFTER NORMALIZATION ===');
        console.log(JSON.stringify(normalizedFolderStructure, null, 2));
        console.log('Has rootFolder property:', 'rootFolder' in normalizedFolderStructure);
        
        result = await architectService.generateLevel3(requirements, visionText, normalizedFolderStructure);
        break;
      default:
        console.log('ERROR: Invalid architect level:', level);
        return NextResponse.json({ error: 'Invalid architect level' }, { status: 400 });
    }
    
    console.log('API call completed successfully with result:', 
                result ? 'Result has data' : 'No result data');
    
    return NextResponse.json(result);
  } catch (error) {
    console.error('=== ERROR IN ARCHITECT API ===');
    console.error(error);
    console.error('Error stack:', error instanceof Error ? error.stack : 'No stack available');
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate architect output' },
      { status: 500 }
    );
  }
}
EOF

# Update the conversation store with enhanced logging
cat > ./src/lib/stores/conversation.ts.debug-part << 'EOF'
  generateArchitectLevel3: async () => {
    const state = get();
    const { level1Output, level2Output } = state.architect;
    const requirements = state.context.extractedInfo.requirements;
    
    console.log('=== ARCHITECT LEVEL 3 GENERATION STARTED ===');
    console.log('- Has level1Output:', !!level1Output);
    console.log('- Has level2Output:', !!level2Output);
    
    if (level2Output) {
      console.log('- level2Output type:', typeof level2Output);
      console.log('- level2Output keys:', Object.keys(level2Output));
      console.log('- Has rootFolder property:', 'rootFolder' in level2Output);
      if ('rootFolder' in level2Output) {
        console.log('- rootFolder type:', typeof level2Output.rootFolder);
      }
      console.log('- Level2Output structure (first 300 chars):', 
                  JSON.stringify(level2Output).substring(0, 300) + '...');
    }
    
    if (!level1Output?.visionText || !level2Output || !requirements?.length) {
      const missing: string[] = [];
      if (!level1Output?.visionText) missing.push('architectural vision');
      if (!level2Output) missing.push('folder structure');
      if (!requirements?.length) missing.push('requirements');
      
      console.error('Missing required inputs for level 3:', missing);
      
      set(state => ({
        architect: {
          ...state.architect,
          error: `Missing required inputs for level 3: ${JSON.stringify(missing)}`
        }
      }));
      return;
    }
    
    try {
      set(state => ({
        architect: {
          ...state.architect,
          isThinking: true,
          error: null,
          level3Output: null
        }
      }));
      
      // Enhanced logging for folder structure
      console.log('=== PREPARING FOLDER STRUCTURE FOR LEVEL 3 ===');
      console.log('Original level2Output:', JSON.stringify(level2Output).substring(0, 300) + '...');
      
      // Create deep clone of the folder structure with careful handling and logging
      let folderStructureClone;
      try {
        folderStructureClone = JSON.parse(JSON.stringify(level2Output));
        console.log('Successfully cloned folder structure');
      } catch (cloneError) {
        console.error('Error cloning folder structure:', cloneError);
        folderStructureClone = level2Output; // Fallback to original if clone fails
      }
      
      // Ensure the folder structure has a rootFolder property
      const folderStructure = typeof folderStructureClone === 'object' && 'rootFolder' in folderStructureClone
        ? folderStructureClone
        : { rootFolder: folderStructureClone };
      
      console.log('Final folderStructure format:',
                 'has rootFolder:', 'rootFolder' in folderStructure,
                 'first 300 chars:', JSON.stringify(folderStructure).substring(0, 300) + '...');
      
      const requestBody = {
        level: 3,
        requirements,
        visionText: level1Output.visionText,
        folderStructure
      };
      
      console.log('Level 3 request body (partial):', JSON.stringify({
        level: requestBody.level,
        requirementsCount: requestBody.requirements.length,
        visionTextLength: requestBody.visionText.length,
        hasFolderStructure: !!requestBody.folderStructure,
        folderStructureHasRootFolder: !!requestBody.folderStructure?.rootFolder
      }));
      
      const response = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(requestBody),
      });
      
      const responseStatus = response.status;
      const responseStatusText = response.statusText;
      console.log(`API Response status: ${responseStatus} ${responseStatusText}`);
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Level 3 API error response:', {
          status: responseStatus,
          statusText: responseStatusText,
          body: errorText
        });
        throw new Error(`Failed to generate implementation plan: ${responseStatusText} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('Level 3 success response received:', 
                 'has data:', !!data,
                 'has implementationOrder:', !!data?.implementationOrder);
      
      set(state => ({
        architect: {
          ...state.architect,
          level3Output: data,
          currentLevel: 3,
          isThinking: false
        }
      }));
    } catch (error) {
      console.error('=== ERROR GENERATING ARCHITECT LEVEL 3 ===');
      console.error('Error:', error);
      console.error('Error stack:', error instanceof Error ? error.stack : 'No stack available');
      set(state => ({
        architect: {
          ...state.architect,
          error: error instanceof Error ? error.message : 'Failed to generate implementation plan',
          isThinking: false
        }
      }));
    }
  },
EOF

# Replace the generateArchitectLevel3 function with our heavily logged version
# This approach preserves the rest of the file
perl -i -p0e 's/generateArchitectLevel3: async \(\) => \{.*?\},/'"$(cat ./src/lib/stores/conversation.ts.debug-part | sed 's/\//\\\//g; s/\$/\\$/g')"'/s' ./src/lib/stores/conversation.ts

# Clean up the temporary file
rm ./src/lib/stores/conversation.ts.debug-part

# Add logging to the architect service
cat > ./src/lib/services/architect.service.ts.debug-part << 'EOF'
  async generateLevel3(
    requirements: string[],
    visionText: string,
    folderStructure: ArchitectLevel2
  ): Promise<ArchitectLevel3> {
    console.log('=== ARCHITECT SERVICE: GENERATE LEVEL 3 ===');
    console.log('Requirements count:', requirements.length);
    console.log('Vision text length:', visionText.length);
    console.log('Folder structure received:', {
      type: typeof folderStructure,
      hasRootFolder: 'rootFolder' in folderStructure,
      keys: Object.keys(folderStructure),
      rootFolderType: folderStructure.rootFolder ? typeof folderStructure.rootFolder : 'null/undefined'
    });
    console.log('Folder structure JSON (first 300 chars):', 
               JSON.stringify(folderStructure).substring(0, 300));
    
    const systemPrompt = `You are an expert software architect. Create a detailed implementation plan.
IMPORTANT: Respond with ONLY a valid JSON object in this exact format:
{
  "implementationOrder": [
    {
      "name": "filename",
      "path": "file path",
      "type": "file type",
      "description": "file description",
      "purpose": "file purpose",
      "dependencies": [],
      "components": [
        {
          "name": "component name",
          "type": "component type",
          "purpose": "component purpose",
          "dependencies": [],
          "details": "implementation details"
        }
      ],
      "implementations": [],
      "additionalContext": "implementation context"
    }
  ]
}`;

    // Validate folder structure before sending
    if (!folderStructure || !folderStructure.rootFolder) {
      console.error('CRITICAL ERROR: Invalid folder structure:', folderStructure);
      throw new Error('Invalid folder structure: missing rootFolder property');
    }

    try {
      console.log('Calling Claude API for level 3 implementation plan');
      const response = await this.callClaude(systemPrompt, `
Requirements:
${requirements.join('\n')}
Architectural Vision:
${visionText}
Folder Structure:
${JSON.stringify(folderStructure, null, 2)}`);
      
      console.log('Claude API response received:', {
        hasImplementationOrder: 'implementationOrder' in response,
        implementationOrderType: typeof response.implementationOrder,
        isArray: Array.isArray(response.implementationOrder),
        length: response.implementationOrder ? response.implementationOrder.length : 0
      });
      
      if (!response.implementationOrder || !Array.isArray(response.implementationOrder)) {
        console.error('Invalid implementation plan response:', response);
        throw new Error('Invalid implementation plan response: missing or invalid implementationOrder');
      }
      return response;
    } catch (error) {
      console.error('Error in generateLevel3:', error);
      throw error;
    }
  }
EOF

# Replace the generateLevel3 function with our heavily logged version
perl -i -p0e 's/async generateLevel3\(.*?\): Promise<ArchitectLevel3> \{.*?\}/'"$(cat ./src/lib/services/architect.service.ts.debug-part | sed 's/\//\\\//g; s/\$/\\$/g')"'/s' ./src/lib/services/architect.service.ts

# Clean up the temporary file
rm ./src/lib/services/architect.service.ts.debug-part

echo "Enhanced logging has been applied!"
echo "The following changes were made:"
echo "1. Added detailed logging to src/app/api/architect/route.ts"
echo "2. Added extensive logging to generateArchitectLevel3 in conversation store"
echo "3. Added validation and logging to architect service"
echo ""
echo "Backups of the original files are stored in the ./backups directory"
echo ""
echo "Now you can run your application and reproduce the error."
echo "The logs should help diagnose the specific issue with the folder structure."