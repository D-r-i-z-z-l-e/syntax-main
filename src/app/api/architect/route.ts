import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { requirements } = await req.json();

    if (!requirements || !Array.isArray(requirements)) {
      return NextResponse.json({ error: 'Valid requirements array is required' }, { status: 400 });
    }

    const systemPrompt = `You are an exceptionally experienced software architect with decades of experience in designing and implementing complex systems. You will analyze the provided requirements and create a detailed architectural vision.

Respond with only a JSON object in exactly this format - no markdown, no backticks:
{
  "architectOutput": "Your complete architectural analysis here without any formatting characters"
}

The architectOutput should cover:
1. System Architecture Overview
   - High-level system design
   - Component interactions 
   - Data flow patterns

2. Implementation Strategy
   - Technology stack recommendations
   - Development approach
   - Project phases and milestones

3. Technical Considerations
   - Performance optimization
   - Scalability approach
   - Security measures
   - Error handling

4. Best Practices and Patterns
   - Design patterns
   - Code organization
   - Testing strategy
   - Documentation needs

5. Potential Challenges and Solutions
   - Technical risks
   - Mitigation strategies
   - Alternative approaches

6. Integration Points
   - External system interactions
   - API design principles
   - Service communication

7. Deployment and DevOps
   - Infrastructure requirements
   - CI/CD recommendations
   - Monitoring and logging

Be extremely specific and detailed, but ensure your response is in plain text format without any markdown or special formatting.

Requirements to analyze:
${requirements.join('\n')}`;

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
        messages: [{ role: 'user', content: 'Provide architectural vision in JSON format' }]
      })
    });

    if (!response.ok) {
      throw new Error(`Claude API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    if (!data.content || !data.content[0] || !data.content[0].text) {
      throw new Error('Invalid response format from Claude API');
    }

    // Clean and parse the response
    let parsedResponse;
    try {
      // Remove any leading/trailing markdown or code block indicators
      let cleanText = data.content[0].text.replace(/^```json\s*|\s*```$/g, '');
      cleanText = cleanText.replace(/^`|`$/g, '');
      
      // Parse the cleaned text
      parsedResponse = JSON.parse(cleanText);

      // Validate the response structure
      if (!parsedResponse.architectOutput) {
        throw new Error('Response missing architectOutput field');
      }
    } catch (e: unknown) {
      const error = e instanceof Error ? e : new Error(String(e));
      console.error('Failed to parse Claude response:', error);
      console.error('Raw response:', data.content[0].text);
      throw new Error(`Failed to parse architect response: ${error.message}`);
    }

    return NextResponse.json({ architectOutput: parsedResponse.architectOutput });
  } catch (error) {
    console.error('Error in architect API:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate architect output' },
      { status: 500 }
    );
  }
}