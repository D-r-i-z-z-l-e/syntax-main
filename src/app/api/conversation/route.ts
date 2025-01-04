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
    if (error instanceof Error) {
      return NextResponse.json(
        { error: error.message },
        { status: 500 }
      );
    }
    return NextResponse.json(
      { error: 'An unexpected error occurred' },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    console.log('Received conversation request');
    const { messages, context } = await req.json();
    console.log('Messages:', JSON.stringify(messages, null, 2));
    console.log('Context:', JSON.stringify(context, null, 2));

    // Add user message to database
    const lastMessage = messages[messages.length - 1];
    console.log('Adding user message to database:', JSON.stringify(lastMessage, null, 2));
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

    // Get Claude's response
    console.log('Getting response from Claude');
    let claudeResponse;
    try {
      claudeResponse = await claudeService.continueConversation(
        messages,
        context
      );
      console.log('Claude response:', JSON.stringify(claudeResponse, null, 2));
    } catch (claudeError) {
      console.error('Error from Claude API:', claudeError);
      throw new Error('Failed to get response from Claude');
    }

    // Add assistant message to database
    console.log('Adding assistant message to database');
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

    // Calculate new metrics
    const newMetrics = {
      coreConcept: Math.min(100, (context.understanding.coreConcept || 0) + (claudeResponse.extractedContext?.understandingUpdate?.coreConcept || 0)),
      requirements: Math.min(100, (context.understanding.requirements || 0) + (claudeResponse.extractedContext?.understandingUpdate?.requirements || 0)),
      technical: Math.min(100, (context.understanding.technical || 0) + (claudeResponse.extractedContext?.understandingUpdate?.technical || 0)),
      constraints: Math.min(100, (context.understanding.constraints || 0) + (claudeResponse.extractedContext?.understandingUpdate?.constraints || 0)),
      userContext: Math.min(100, (context.understanding.userContext || 0) + (claudeResponse.extractedContext?.understandingUpdate?.userContext || 0)),
    };

    console.log('Current metrics:', context.understanding);
    console.log('Updates:', claudeResponse.extractedContext?.understandingUpdate);
    console.log('New metrics:', newMetrics);

    // Calculate overall understanding
    const weights = {
      coreConcept: 0.3,
      requirements: 0.25,
      technical: 0.2,
      constraints: 0.15,
      userContext: 0.1
    };

    const overallUnderstanding = Math.round(
      weights.coreConcept * newMetrics.coreConcept +
      weights.requirements * newMetrics.requirements +
      weights.technical * newMetrics.technical +
      weights.constraints * newMetrics.constraints +
      weights.userContext * newMetrics.userContext
    );

    // Return the processed response
    const responseData = {
      response: claudeResponse.response,
      extractedContext: {
        ...claudeResponse.extractedContext,
        requirements: claudeResponse.extractedContext?.requirements || [],
        technicalDetails: claudeResponse.extractedContext?.technicalDetails || [],
        nextPhase: claudeResponse.extractedContext?.nextPhase || context.currentPhase,
        understandingUpdate: newMetrics,
        overallUnderstanding
      }
    };

    console.log('Sending response:', JSON.stringify(responseData, null, 2));
    return NextResponse.json(responseData);

  } catch (error) {
    console.error('Error in conversation API:', error);
    if (error instanceof Error) {
      console.error('Error details:', {
        name: error.name,
        message: error.message,
        stack: error.stack,
      });
      return NextResponse.json(
        { error: error.message },
        { status: 500 }
      );
    }
    return NextResponse.json(
      { error: 'An unexpected error occurred' },
      { status: 500 }
    );
  }
}
