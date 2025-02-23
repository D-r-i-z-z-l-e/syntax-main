import { NextRequest, NextResponse } from 'next/server';
import { ClaudeService } from '../../../lib/claude';
import { conversationService } from '../../../lib/services/conversation.service';

const claudeService = ClaudeService.getInstance();

export async function GET(req: NextRequest) {
  try {
    const url = new URL(req.url);
    const conversationId = url.searchParams.get('id');

    if (!conversationId) {
      return NextResponse.json(
        { error: 'Conversation ID is required' },
        { status: 400 }
      );
    }

    const messages = await conversationService.getMessages(conversationId);
    return NextResponse.json({ messages });

  } catch (error) {
    console.error('Error in conversation GET API:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'An unexpected error occurred' },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    console.log('Received conversation request');
    const { messages, context } = await req.json();
    
    // Add user message to database
    const lastMessage = messages[messages.length - 1];
    try {
      await conversationService.addMessage(
        lastMessage.conversationId,
        lastMessage.role,
        lastMessage.content
      );
    } catch (dbError) {
      console.error('Database error adding user message:', dbError);
      throw new Error('Failed to save user message');
    }

    // Get response from Claude
    let claudeResponse;
    try {
      claudeResponse = await claudeService.continueConversation(
        messages,
        context
      );
    } catch (error) {
      console.error('Error from Claude API:', error);
      throw new Error(error instanceof Error ? error.message : 'Failed to get response from Claude');
    }

    if (!claudeResponse || !claudeResponse.response) {
      throw new Error('Invalid response from Claude');
    }

    // Add assistant message to database
    try {
      await conversationService.addMessage(
        lastMessage.conversationId,
        'assistant',
        claudeResponse.response
      );
    } catch (dbError) {
      console.error('Database error adding assistant message:', dbError);
      throw new Error('Failed to save assistant message');
    }

    return NextResponse.json(claudeResponse);

  } catch (error) {
    console.error('Error in conversation API:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'An unexpected error occurred' },
      { status: 500 }
    );
  }
}