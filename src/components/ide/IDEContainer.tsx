import React, { useState, useEffect } from 'react';
import { SplitPane, Pane } from 'split-pane-react';
import 'split-pane-react/esm/themes/default.css';
import { FileExplorer } from './FileExplorer';
import { CodeEditor } from './CodeEditor';
import { FileImplementation } from '../../lib/types/architect';
import { Download, Archive, ExternalLink, X } from 'lucide-react';
import JSZip from 'jszip';
import { saveAs } from 'file-saver';

interface IDEContainerProps {
  files: FileImplementation[];
  onClose: () => void;
  activeFile: FileImplementation | null;
  setActiveFile: (file: FileImplementation | null) => void;
}

export function IDEContainer({ files, onClose, activeFile, setActiveFile }: IDEContainerProps) {
  const [sizes, setSizes] = useState(['20%', '80%']);
  
  const handleCopyCode = () => {
    if (activeFile) {
      navigator.clipboard.writeText(activeFile.code);
      alert('Code copied to clipboard!');
    }
  };
  
  const handleDownloadFile = () => {
    if (activeFile) {
      const blob = new Blob([activeFile.code], { type: 'text/plain' });
      saveAs(blob, activeFile.name);
    }
  };
  
  const handleDownloadProject = async () => {
    try {
      const zip = new JSZip();
      
      // Helper function to ensure directories exist
      const ensureDirectory = (path: string) => {
        if (!path) return zip;
        const segments = path.split('/').filter(Boolean);
        let currentPath = '';
        
        for (const segment of segments) {
          currentPath = currentPath ? `${currentPath}/${segment}` : segment;
          if (!zip.folder(currentPath)) {
            zip.folder(currentPath);
          }
        }
        
        return zip.folder(path);
      };
      
      // Add all files to the zip
      for (const file of files) {
        const normalizedPath = file.path.replace(/^\/|\/$/g, '');
        ensureDirectory(normalizedPath);
        zip.file(`${normalizedPath}/${file.name}`, file.code);
      }
      
      // Generate and download the zip
      const content = await zip.generateAsync({ type: 'blob' });
      saveAs(content, 'project.zip');
      
    } catch (error) {
      console.error('Error creating zip file:', error);
      alert('Failed to download project. See console for details.');
    }
  };
  
  return (
    <div className="fixed inset-0 bg-white z-50 flex flex-col">
      {/* IDE Header */}
      <div className="border-b px-4 py-3 flex justify-between items-center bg-gray-50">
        <div className="flex items-center">
          <h2 className="font-semibold text-gray-800">Syntax IDE</h2>
          <div className="ml-4 text-sm text-gray-500">{files.length} files generated</div>
        </div>
        
        <div className="flex items-center space-x-3">
          <button 
            className="px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 text-sm rounded flex items-center"
            onClick={handleDownloadProject}
          >
            <Archive className="w-4 h-4 mr-1.5" />
            Download Project
          </button>
          
          <button 
            className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-full"
            onClick={onClose}
            title="Close IDE"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
      </div>
      
      {/* IDE Main Content */}
      <div className="flex-1 overflow-hidden">
        <SplitPane
          split="vertical"
          sizes={sizes}
          onChange={setSizes}
        >
          <Pane minSize="15%" maxSize="30%">
            <FileExplorer 
              files={files} 
              onSelectFile={setActiveFile} 
              activeFile={activeFile} 
            />
          </Pane>
          <div className="h-full">
            <CodeEditor 
              file={activeFile}
              onCopy={handleCopyCode}
              onDownload={handleDownloadFile}
            />
          </div>
        </SplitPane>
      </div>
    </div>
  );
}
