import { NextRequest, NextResponse } from 'next/server';

// Accessing the same in-memory storage from the book-generation route
// In a production app, you'd use a database
declare global {
  var bookGenerations: Map<string, any>;
}

if (!global.bookGenerations) {
  global.bookGenerations = new Map();
}

const bookGenerations = global.bookGenerations;

export async function GET(req: NextRequest) {
  try {
    const url = new URL(req.url);
    const generationId = url.searchParams.get('id');

    if (!generationId) {
      return NextResponse.json(
        { error: 'Generation ID is required' },
        { status: 400 }
      );
    }

    const generationStatus = bookGenerations.get(generationId);
    if (!generationStatus) {
      return NextResponse.json(
        { error: 'Generation not found' },
        { status: 404 }
      );
    }

    // Return the current status
    return NextResponse.json({
      generationId,
      status: generationStatus.status,
      progress: generationStatus.progress,
      totalChapters: generationStatus.totalChapters,
      completedChapters: generationStatus.completedChapters,
      currentChapter: generationStatus.currentChapter,
      startedAt: generationStatus.startedAt,
      lastUpdated: generationStatus.lastUpdated,
      error: generationStatus.error,
      isComplete: generationStatus.status === 'complete',
      book: generationStatus.book
    });
    
  } catch (error) {
    console.error('Error checking book generation status:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'An unexpected error occurred' },
      { status: 500 }
    );
  }
}
