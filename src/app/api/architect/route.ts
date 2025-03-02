import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { level, requirements, visionText, folderStructure } = body;
    
    console.log(`Architect API level ${level} request received`);
    
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
        
        // Special debug for level 3
        console.log('Level 3 folderStructure debugging:');
        console.log('folderStructure received:', JSON.stringify(folderStructure));
        console.log('Type:', typeof folderStructure);
        
        // Check for rootFolder - this is the key check
        if (!folderStructure || typeof folderStructure !== 'object') {
          return NextResponse.json({ error: 'Missing required input for level 3: folder structure (no object)' }, { status: 400 });
        }
        
        if (!('rootFolder' in folderStructure)) {
          return NextResponse.json({ error: 'Missing required input for level 3: folder structure (no rootFolder)' }, { status: 400 });
        }
        
        // Wrap folderStructure if needed
        let processedStructure = folderStructure;
        if (folderStructure.rootFolder) {
          processedStructure = { rootFolder: folderStructure.rootFolder };
        }
        
        console.log('Using folderStructure:', JSON.stringify(processedStructure));
        
        result = await architectService.generateLevel3(requirements, visionText, processedStructure);
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
