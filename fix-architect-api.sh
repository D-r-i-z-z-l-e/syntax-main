#!/bin/bash

# Script to fix the "Missing required inputs for level 3: ["folder structure"]" error
# Run this from your syntax-main directory

set -e  # Exit on error

echo "Applying fix for architect API route.ts..."

# Backup the existing file
mkdir -p ./backups
cp ./src/app/api/architect/route.ts ./backups/route.ts.bak.$(date +%Y%m%d%H%M%S)

# Create the updated route.ts file
cat > ./src/app/api/architect/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;
    
    console.log(`Architect API level ${level} request received`);
    console.log(`Request body:`, JSON.stringify({
      level,
      requirementsCount: requirements?.length,
      hasVisionText: !!visionText,
      hasFolderStructure: !!folderStructure,
      folderStructureType: folderStructure ? typeof folderStructure : 'undefined'
    }));
    
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
        if (!visionText) {
          return NextResponse.json({ error: 'Vision text is required for level 3' }, { status: 400 });
        }
        
        if (!folderStructure) {
          return NextResponse.json({ error: 'Missing required inputs for level 3: ["folder structure"]' }, { status: 400 });
        }
        
        // Make sure folderStructure has a rootFolder property
        const normalizedFolderStructure = typeof folderStructure === 'object' && 'rootFolder' in folderStructure
          ? folderStructure
          : { rootFolder: folderStructure };
        
        console.log('Using normalized folder structure:', JSON.stringify(normalizedFolderStructure).substring(0, 200) + '...');
        
        result = await architectService.generateLevel3(requirements, visionText, normalizedFolderStructure);
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

echo "Adding additional fix to generateArchitectLevel3 in conversation store..."

# Backup the existing file
cp ./src/lib/stores/conversation.ts ./backups/conversation.ts.bak.$(date +%Y%m%d%H%M%S)

# Use sed to update the function in the conversation store
# This is a more targeted approach than replacing the whole file
sed -i.bak '
/generateArchitectLevel3: async () => {/,/})/ {
  /const folderStructure/,/};/ {
    s/const folderStructure.*/const folderStructure = typeof level2Output === "object" \&\& "rootFolder" in level2Output\n        ? level2Output\n        : { rootFolder: level2Output };/
  }
}
' ./src/lib/stores/conversation.ts

# Remove the temporary .bak file created by sed
rm -f ./src/lib/stores/conversation.ts.bak

echo "Fix applied successfully!"
echo "The following changes were made:"
echo "1. Updated src/app/api/architect/route.ts to properly normalize folder structure"
echo "2. Updated src/lib/stores/conversation.ts to fix the generateArchitectLevel3 function"
echo "Backups of the original files are stored in the ./backups directory"