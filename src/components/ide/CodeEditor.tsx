import React from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { materialLight } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { FileImplementation } from '../../lib/types/architect';
import { FileIcon, Download, Code, Copy } from 'lucide-react';

interface CodeEditorProps {
  file: FileImplementation | null;
  onCopy: () => void;
  onDownload: () => void;
}

export function CodeEditor({ file, onCopy, onDownload }: CodeEditorProps) {
  if (!file) {
    return (
      <div className="h-full flex items-center justify-center bg-gray-50 text-gray-400">
        <div className="text-center">
          <Code className="h-12 w-12 mx-auto mb-4 opacity-20" />
          <p>Select a file to view its code</p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* File header */}
      <div className="flex items-center justify-between px-4 py-2 border-b bg-gray-50">
        <div className="flex items-center">
          <FileIcon className="w-4 h-4 mr-2 text-gray-500" />
          <span className="font-medium text-sm">{file.path}/{file.name}</span>
        </div>
        <div className="flex space-x-2">
          <button 
            onClick={onCopy}
            className="p-1.5 text-xs flex items-center bg-gray-100 hover:bg-gray-200 rounded"
            title="Copy code"
          >
            <Copy className="w-3.5 h-3.5 mr-1" />
            Copy
          </button>
          <button 
            onClick={onDownload}
            className="p-1.5 text-xs flex items-center bg-gray-100 hover:bg-gray-200 rounded"
            title="Download file"
          >
            <Download className="w-3.5 h-3.5 mr-1" />
            Download
          </button>
        </div>
      </div>

      {/* File info */}
      <div className="px-4 py-2 border-b bg-gray-50 text-xs">
        <div className="flex flex-wrap gap-x-6 gap-y-1">
          <div><span className="font-medium">Type:</span> {file.type}</div>
          <div><span className="font-medium">Language:</span> {file.language}</div>
          <div><span className="font-medium">Dependencies:</span> {file.dependencies.length}</div>
        </div>
        <div className="mt-1">
          <span className="font-medium">Purpose:</span> {file.purpose}
        </div>
      </div>

      {/* Code content */}
      <div className="flex-1 overflow-auto">
        <SyntaxHighlighter
          language={file.language}
          style={materialLight}
          customStyle={{
            margin: 0,
            borderRadius: 0,
            minHeight: '100%',
            fontSize: '0.9rem',
          }}
          showLineNumbers={true}
        >
          {file.code}
        </SyntaxHighlighter>
      </div>
    </div>
  );
}
