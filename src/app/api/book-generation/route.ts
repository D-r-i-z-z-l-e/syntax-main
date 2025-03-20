import { NextRequest, NextResponse } from 'next/server';
import { architectService } from '../../../lib/services/architect.service';
import { v4 as uuidv4 } from 'uuid';

// In-memory storage for book generation status
// In a production app, you'd use a database
const bookGenerations = new Map();

export async function POST(req: NextRequest) {
  try {
    const { requirements, level2Output } = await req.json();

    if (!requirements || !Array.isArray(requirements) || !level2Output) {
      return NextResponse.json(
        { error: 'Valid requirements and level2Output are required' },
        { status: 400 }
      );
    }

    const generationId = uuidv4();
    
    // Initialize generation status
    bookGenerations.set(generationId, {
      status: 'initializing',
      progress: 0,
      totalChapters: 0,
      completedChapters: 0,
      currentChapter: 'Initializing',
      startedAt: new Date(),
      lastUpdated: new Date(),
      error: null,
      book: null
    });

    // Start book generation in the background
    architectService.startBookGeneration(
      requirements,
      level2Output,
      (progress) => {
        // Update status with the progress information
        const currentStatus = bookGenerations.get(generationId);
        if (currentStatus) {
          bookGenerations.set(generationId, {
            ...currentStatus,
            ...progress,
            status: progress.error ? 'error' : (progress.progress >= 100 ? 'complete' : 'in-progress'),
            lastUpdated: new Date()
          });
        }
      }
    ).catch(error => {
      console.error('Error in book generation:', error);
      const currentStatus = bookGenerations.get(generationId);
      if (currentStatus) {
        bookGenerations.set(generationId, {
          ...currentStatus,
          status: 'error',
          error: error.message || 'Unknown error occurred',
          lastUpdated: new Date()
        });
      }
    });

    // Return the generation ID for status polling
    return NextResponse.json({
      generationId,
      status: 'initializing',
      message: 'Book generation started',
      totalChapters: 0,
      completedChapters: 0,
      currentChapter: 'Initializing'
    });
    
  } catch (error) {
    console.error('Error starting book generation:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'An unexpected error occurred' },
      { status: 500 }
    );
  }
}
