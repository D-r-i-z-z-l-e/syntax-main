"use client";

import { ReactNode, useEffect } from 'react';
import { useConversationStore } from '../../lib/stores/conversation';

interface ConversationProviderProps {
  children: ReactNode;
}

export function ConversationProvider({ children }: ConversationProviderProps) {
  const { initializeProject, reset } = useConversationStore();

  // Initialize project and reset conversation state when component mounts
  useEffect(() => {
    reset();
    initializeProject().catch(console.error);
  }, [reset, initializeProject]);

  return <>{children}</>;
}
