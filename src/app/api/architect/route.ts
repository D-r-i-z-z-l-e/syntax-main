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
      hasFolderStructure: !!folderStructure,
      folderStructureType: folderStructure ? typeof folderStructure : 'undefined'
    }));
    
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
        
        // Always ensure folder structure has rootFolder properly defined
        let normalizedFolderStructure;
        
        if (typeof folderStructure === 'object' && 'rootFolder' in folderStructure && folderStructure.rootFolder) {
          console.log('Using provided folder structure with rootFolder');
          normalizedFolderStructure = folderStructure;
        } else {
          console.log('Creating normalized folder structure with rootFolder');
          normalizedFolderStructure = { 
            rootFolder: typeof folderStructure === 'object' ? folderStructure : {
              name: "project-root",
              description: "Root directory for the project",
              purpose: "Main project folder",
              subfolders: []
            }
          };
        }
        
        console.log('Normalized folder structure has rootFolder:', 'rootFolder' in normalizedFolderStructure);
        
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
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate architect output' },
      { status: 500 }
    );
  }
}
