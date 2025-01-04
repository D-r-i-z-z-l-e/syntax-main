import { NextRequest, NextResponse } from 'next/server';
import { conversationService } from '../../../lib/services/conversation.service';

export async function POST(req: NextRequest) {
  try {
    const { name } = await req.json();

    // Create a new project
    const project = await conversationService.createProject(name);

    // Create initial conversation for the project
    const conversation = await conversationService.createConversation(project.id);

    return NextResponse.json({ project, conversation });
  } catch (error) {
    console.error('Error in project API:', error);
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

export async function GET(req: NextRequest) {
  try {
    const url = new URL(req.url);
    const projectId = url.searchParams.get('projectId');

    if (!projectId) {
      return NextResponse.json(
        { error: 'Project ID is required' },
        { status: 400 }
      );
    }

    const project = await conversationService.getProject(projectId);

    if (!project) {
      return NextResponse.json(
        { error: 'Project not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ project });
  } catch (error) {
    console.error('Error in project API:', error);
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
