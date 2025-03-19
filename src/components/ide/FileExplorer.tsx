import React, { useState } from 'react';
import { ChevronDown, ChevronRight, Folder, FileIcon, Code } from 'lucide-react';
import { FileImplementation } from '../../lib/types/architect';

interface FileExplorerProps {
  files: FileImplementation[];
  onSelectFile: (file: FileImplementation) => void;
  activeFile: FileImplementation | null;
}

interface FileTreeNode {
  id: string;
  name: string;
  path: string;
  type: 'file' | 'folder';
  children: FileTreeNode[];
  fileData?: FileImplementation;
}

export function FileExplorer({ files, onSelectFile, activeFile }: FileExplorerProps) {
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set());

  // Build file tree
  const buildFileTree = (): FileTreeNode => {
    const root: FileTreeNode = {
      id: 'root',
      name: 'project-root',
      path: '',
      type: 'folder',
      children: []
    };

    // Map to store folder nodes for quick lookup
    const folderMap = new Map<string, FileTreeNode>();
    folderMap.set('', root);

    // Process all files, creating folder structure as needed
    files.forEach((file) => {
      // Normalize path to not have leading or trailing slashes
      const normalizedPath = file.path.replace(/^\/|\/$/g, '');
      
      // Split path into segments
      const segments = normalizedPath.split('/');
      
      // Track current path as we build
      let currentPath = '';
      let parentNode = root;
      
      // Create or traverse folders
      for (let i = 0; i < segments.length; i++) {
        const segment = segments[i];
        if (!segment) continue;
        
        // Update current path
        currentPath = currentPath ? `${currentPath}/${segment}` : segment;
        
        // Check if folder already exists
        if (!folderMap.has(currentPath)) {
          // Create new folder node
          const newFolder: FileTreeNode = {
            id: `folder-${currentPath}`,
            name: segment,
            path: currentPath,
            type: 'folder',
            children: []
          };
          
          // Add to parent and update maps
          parentNode.children.push(newFolder);
          folderMap.set(currentPath, newFolder);
        }
        
        // Update parent for next iteration
        parentNode = folderMap.get(currentPath)!;
      }
      
      // Add file node to the appropriate folder
      const fileNode: FileTreeNode = {
        id: `file-${file.path}/${file.name}`,
        name: file.name,
        path: `${normalizedPath}/${file.name}`,
        type: 'file',
        children: [],
        fileData: file
      };
      
      parentNode.children.push(fileNode);
    });

    // Sort each folder's children: folders first, then files, both alphabetically
    const sortNode = (node: FileTreeNode) => {
      node.children.sort((a, b) => {
        // Folders before files
        if (a.type !== b.type) {
          return a.type === 'folder' ? -1 : 1;
        }
        // Alphabetical within same type
        return a.name.localeCompare(b.name);
      });
      
      // Recursively sort children
      node.children.forEach(child => {
        if (child.type === 'folder') {
          sortNode(child);
        }
      });
    };
    
    sortNode(root);
    return root;
  };

  const toggleFolder = (path: string) => {
    setExpandedFolders(prev => {
      const newSet = new Set(prev);
      if (newSet.has(path)) {
        newSet.delete(path);
      } else {
        newSet.add(path);
      }
      return newSet;
    });
  };

  const renderTree = (node: FileTreeNode, depth = 0): JSX.Element => {
    const isExpanded = expandedFolders.has(node.path);
    const isFolder = node.type === 'folder';
    const isActive = !isFolder && 
      activeFile && 
      node.fileData?.path === activeFile.path && 
      node.fileData?.name === activeFile.name;

    return (
      <div key={node.id}>
        <div 
          className={`flex items-center py-1 pl-${depth * 4} ${isActive ? 'bg-blue-100 text-blue-800' : 'hover:bg-gray-100'} cursor-pointer rounded`}
          onClick={() => {
            if (isFolder) {
              toggleFolder(node.path);
            } else if (node.fileData) {
              onSelectFile(node.fileData);
            }
          }}
        >
          <span className="mr-1">
            {isFolder ? (
              isExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />
            ) : null}
          </span>
          <span className="mr-2">
            {isFolder ? (
              <Folder className="w-4 h-4 text-yellow-500" />
            ) : (
              <FileIcon className="w-4 h-4 text-gray-500" />
            )}
          </span>
          <span className="text-sm truncate">{node.name}</span>
        </div>
        
        {isFolder && isExpanded && (
          <div className="ml-4">
            {node.children.map(child => renderTree(child, depth + 1))}
          </div>
        )}
      </div>
    );
  };

  const fileTree = buildFileTree();

  return (
    <div className="h-full overflow-auto p-2">
      <div className="flex items-center justify-between mb-4 sticky top-0 bg-white py-2 z-10">
        <div className="flex items-center">
          <Code className="w-5 h-5 mr-2 text-blue-600" />
          <h3 className="text-sm font-medium">Project Files</h3>
        </div>
        <div className="text-xs text-gray-500">{files.length} files</div>
      </div>
      {files.length > 0 ? (
        renderTree(fileTree)
      ) : (
        <div className="text-center text-gray-500 text-sm py-4">
          No files generated yet
        </div>
      )}
    </div>
  );
}
