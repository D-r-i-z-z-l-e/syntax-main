// src/app/api/project-structure/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { requirements } = await req.json();

    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }

    const systemPrompt = `You are an experienced software architect tasked with creating a project structure. Based on the provided requirements, generate a comprehensive project structure that follows best practices.

Requirements:
${requirements.join('\n')}

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
        messages: [
          {
            role: 'user',
            content: systemPrompt
          }
        ]
      })
    });

    if (!response.ok) {
      console.error('Claude API error:', {
        status: response.status,
        statusText: response.statusText,
        body: await response.text()
      });
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }

    let structureResponse;
    try {
      structureResponse = JSON.parse(data.content[0].text);
    } catch (e) {
      console.error('Failed to parse Claude response:', data.content[0].text);
      throw new Error('Failed to parse project structure from Claude response');
    }

    return NextResponse.json(structureResponse);
  } catch (error) {
    console.error('Error generating project structure:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate project structure' },
      { status: 500 }
    );
  }
}