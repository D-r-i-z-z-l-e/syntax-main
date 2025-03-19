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
