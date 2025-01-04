import { create } from 'zustand';
import { v4 as uuidv4 } from 'uuid';
import type { ConversationContext, ConversationPhase, ExtractedContext } from '../claude';
import { conversationService } from '../services/conversation.service';

interface DbMessage {
  id: string;
  conversationId: string;
  role: string;
  content: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Message {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

interface ConversationStore {
  messages: Message[];
  context: ConversationContext;
  isLoading: boolean;
  error: string | null;
  projectId: string | null;
  conversationId: string | null;
  initializeProject: () => Promise<void>;
  loadConversation: (conversationId: string) => Promise<void>;
  sendMessage: (content: string) => Promise<void>;
  reset: () => void;
}

export const useConversationStore = create<ConversationStore>((set, get) => ({
  messages: [],
  context: {
    currentPhase: 'initial',
    extractedInfo: {
      requirements: [],
      technicalDetails: [],
      constraints: [],
    },
    understanding: {
      coreConcept: 0,
      requirements: 0,
      technical: 0,
      constraints: 0,
      userContext: 0,
    },
    overallUnderstanding: 0,
  },
  isLoading: false,
  error: null,
  projectId: null,
  conversationId: null,

  initializeProject: async () => {
    try {
      set({ isLoading: true, error: null });

      // Create new project through API
      const response = await fetch('/api/project', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'New Project' }),
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }

      const data = await response.json();
      console.log('Project initialized:', data);

      set({
        projectId: data.project.id,
        conversationId: data.conversation.id,
        messages: [],
        isLoading: false,
      });
    } catch (error) {
      console.error('Error initializing project:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to initialize project',
        isLoading: false,
      });
    }
  },

  loadConversation: async (conversationId: string) => {
    try {
      set({ isLoading: true, error: null });

      const response = await fetch(`/api/conversation?id=${conversationId}`, {
        method: 'GET',
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }

      const data = await response.json();

      set({
        messages: data.messages.map((msg: any) => ({
          id: msg.id,
          conversationId: msg.conversationId,
          role: msg.role,
          content: msg.content,
          timestamp: new Date(msg.createdAt).getTime(),
        })),
        conversationId,
        isLoading: false,
      });
    } catch (error) {
      console.error('Error loading conversation:', error);
      set({
        error: error instanceof Error ? error.message : 'Failed to load conversation',
        isLoading: false,
      });
    }
  },

  sendMessage: async (content: string) => {
    try {
      set({ isLoading: true, error: null });
      
      // Create new message
      const conversationId = get().conversationId || uuidv4();
      const newMessage: Message = {
        id: uuidv4(),
        conversationId,
        role: 'user',
        content,
        timestamp: Date.now(),
      };

      // Add message to state
      set(state => ({
        messages: [...state.messages, newMessage],
      }));

      // Send to API
      const response = await fetch('/api/conversation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: [...get().messages, newMessage],
          context: get().context,
        }),
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.statusText}`);
      }

      const data = await response.json();
      console.log('API Response:', data);

      if (data.error) {
        throw new Error(data.error);
      }

      // Create assistant message
      const assistantMessage: Message = {
        id: uuidv4(),
        conversationId,
        role: 'assistant',
        content: data.response,
        timestamp: Date.now(),
      };

      // Update state with new message and context
      set(state => ({
        messages: [...state.messages, assistantMessage],
        context: {
          ...state.context,
          currentPhase: data.extractedContext.nextPhase || state.context.currentPhase,
          extractedInfo: {
            requirements: [
              ...(state.context.extractedInfo.requirements || []),
              ...(data.extractedContext.requirements || []),
            ],
            technicalDetails: [
              ...(state.context.extractedInfo.technicalDetails || []),
              ...(data.extractedContext.technicalDetails || []),
            ],
            constraints: state.context.extractedInfo.constraints || [],
          },
          understanding: data.extractedContext.understandingUpdate || state.context.understanding,
          overallUnderstanding: data.extractedContext.overallUnderstanding || state.context.overallUnderstanding,
        },
        isLoading: false,
      }));

    } catch (error) {
      console.error('Error in sendMessage:', error);
      set({
        error: error instanceof Error ? error.message : 'An error occurred',
        isLoading: false,
      });
    }
  },

  reset: () => {
    set({
      messages: [],
      context: {
        currentPhase: 'initial',
        extractedInfo: {
          requirements: [],
          technicalDetails: [],
          constraints: [],
        },
        understanding: {
          coreConcept: 0,
          requirements: 0,
          technical: 0,
          constraints: 0,
          userContext: 0,
        },
        overallUnderstanding: 0,
      },
      isLoading: false,
      error: null,
      projectId: null,
      conversationId: null,
    });
  },
}));
