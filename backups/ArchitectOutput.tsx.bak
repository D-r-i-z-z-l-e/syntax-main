import React from 'react';
import { CodeIcon, Send } from 'lucide-react';

interface ArchitectOutputProps {
  architectOutput: string | null;
  onPassToConstructor: () => void;
  isLoading: boolean;
}

export function ArchitectOutput({ architectOutput, onPassToConstructor, isLoading }: ArchitectOutputProps) {
  if (!architectOutput && !isLoading) return null;

  return (
    <div className="fixed bottom-4 right-4 w-96 bg-white rounded-lg shadow-lg border border-gray-200 p-4 transition-all duration-300 ease-in-out">
      <h2 className="text-sm font-semibold text-gray-900 mb-2 flex items-center">
        <CodeIcon className="w-4 h-4 mr-1" />
        Architect's Vision
      </h2>
      
      {isLoading ? (
        <div className="flex items-center justify-center space-x-2 py-4">
          <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600">Architect is thinking...</span>
        </div>
      ) : (
        <>
          <div className="max-h-[60vh] overflow-y-auto">
            <div className="text-sm text-gray-600 whitespace-pre-wrap">
              {architectOutput}
            </div>
          </div>
          
          <button
            onClick={onPassToConstructor}
            className="mt-4 w-full bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg px-4 py-2 flex items-center justify-center transition-colors"
          >
            <Send className="w-4 h-4 mr-2" />
            Pass to Constructor
          </button>
        </>
      )}
    </div>
  );
}
