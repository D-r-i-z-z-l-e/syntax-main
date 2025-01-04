import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../db/prisma';

class ConversationService {
  private static instance: ConversationService;

  private constructor() {}

  public static getInstance(): ConversationService {
    if (!ConversationService.instance) {
      ConversationService.instance = new ConversationService();
    }
    return ConversationService.instance;
  }

  async createProject(name: string = 'New Project') {
    try {
      const project = await prisma.project.create({
        data: {
          name,
        },
      });
      return project;
    } catch (error) {
      console.error('Error in createProject:', error);
      throw error;
    }
  }

  async createConversation(projectId: string) {
    try {
      const conversation = await prisma.conversation.create({
        data: {
          id: uuidv4(),
          projectId,
        },
      });
      return conversation;
    } catch (error) {
      console.error('Error in createConversation:', error);
      throw error;
    }
  }

  async addMessage(
    conversationId: string = uuidv4(),
    role: 'user' | 'assistant',
    content: string
  ) {
    try {
      // First, ensure a project exists
      let project = await prisma.project.findFirst();
      if (!project) {
        project = await this.createProject();
      }

      // Then, ensure the conversation exists
      let conversation = await prisma.conversation.findUnique({
        where: { id: conversationId }
      });

      if (!conversation) {
        conversation = await prisma.conversation.create({
          data: {
            id: conversationId,
            projectId: project.id
          }
        });
      }

      // Finally, add the message
      const message = await prisma.message.create({
        data: {
          conversationId: conversation.id,
          role,
          content,
        },
      });

      return message;
    } catch (error) {
      console.error('Error in addMessage:', error);
      throw error;
    }
  }

  async getMessages(conversationId: string) {
    try {
      const messages = await prisma.message.findMany({
        where: { conversationId },
        orderBy: { createdAt: 'asc' },
      });
      return messages;
    } catch (error) {
      console.error('Error in getMessages:', error);
      throw error;
    }
  }

  async getProject(projectId: string) {
    try {
      const project = await prisma.project.findUnique({
        where: { id: projectId },
        include: {
          conversations: {
            include: {
              messages: true,
            },
          },
        },
      });
      return project;
    } catch (error) {
      console.error('Error in getProject:', error);
      throw error;
    }
  }

  async updateProject(projectId: string, data: any) {
    try {
      const project = await prisma.project.update({
        where: { id: projectId },
        data,
      });
      return project;
    } catch (error) {
      console.error('Error in updateProject:', error);
      throw error;
    }
  }
}

export const conversationService = ConversationService.getInstance();
