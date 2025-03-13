import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { requirements, architectVision, folderStructure, implementationPlan } = await req.json();

    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }

    const systemPrompt = `You are an experienced software architect tasked with creating a project structure. Based on the provided requirements, architectural vision, folder structure, and implementation plan, generate a comprehensive project structure that follows best practices.

Requirements:
${requirements.join('\n')}

Architectural Vision:
${architectVision || 'No architectural vision provided.'}

Folder Structure:
${JSON.stringify(folderStructure.rootFolder || {}, null, 2)}

Dependency Tree:
${JSON.stringify(folderStructure.dependencyTree || {}, null, 2)}

Implementation Plan:
${JSON.stringify(implementationPlan || {}, null, 2)}

Respond with ONLY a JSON object in this format:
{
  "structure": {
    "description": "Brief overview of the architecture",
    "directories": [
      {
        "name": "directory-name",
        "description": "Purpose of this directory",
        "contents": [
          {
            "name": "file-or-subdirectory",
            "type": "file|directory",
            "description": "Purpose of this item",
            "tech": "Technology/framework used (if applicable)"
          }
        ]
      }
    ]
  }
}`;

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
        'x-api-key': process.env.CLAUDE_API_KEY!,
        'Authorization': `Bearer ${process.env.CLAUDE_API_KEY}`
      },
      body: JSON.stringify({
        model: 'claude-3-5-sonnet-latest',
        max_tokens: 4096,
        temperature: 0.7,
        system: systemPrompt,
        messages: [{ role: 'user', content: 'Generate project structure' }]
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Claude API error:', errorText);
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }
    
    const cleanText = data.content[0].text
      .replace(/^```json\s*|\s*```$/g, '')
      .replace(/^`|`$/g, '')
      .replace(/[\n\r\t]/g, ' ')
      .replace(/\s+/g, ' ');
    
    const structureResponse = JSON.parse(cleanText);

    return NextResponse.json(structureResponse);
  } catch (error) {
    console.error('Error generating project structure:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate project structure' },
      { status: 500 }
    );
  }
}
