import React from 'react';
import { FolderIcon, FileIcon } from 'lucide-react';

interface StructureItem {
  name: string;
  type: 'file' | 'directory';
  description: string;
  tech?: string;
}

interface Directory {
  name: string;
  description: string;
  contents: StructureItem[];
}

interface ProjectStructure {
  description: string;
  directories: Directory[];
}

interface ProjectStructureProps {
  structure: ProjectStructure;
}

export function ProjectStructure({ structure }: ProjectStructureProps) {
  return (
    <div className="bg-white p-4 h-[calc(100vh-1rem)] overflow-y-auto">
      <h2 className="text-sm font-semibold text-gray-900 mb-2 flex items-center sticky top-0 bg-white py-2">
        <FolderIcon className="w-4 h-4 mr-1" />
        Project Structure
      </h2>
      <p className="text-xs text-gray-600 mb-4">{structure.description}</p>
      <div>
        {structure.directories.map((dir) => (
          <div key={dir.name} className="mb-4">
            <div className="flex items-start">
              <FolderIcon className="w-4 h-4 mr-2 mt-1 text-blue-500" />
              <div>
                <h3 className="text-sm font-medium text-gray-900">{dir.name}</h3>
                <p className="text-xs text-gray-600 mb-2">{dir.description}</p>
              </div>
            </div>
            <div className="ml-6">
              {dir.contents.map((item, index) => (
                <div key={`${dir.name}-${item.name}-${index}`} className="flex items-start my-2">
                  {item.type === 'directory' ? (
                    <FolderIcon className="w-4 h-4 mr-2 text-blue-500" />
                  ) : (
                    <FileIcon className="w-4 h-4 mr-2 text-gray-500" />
                  )}
                  <div className="flex-1">
                    <p className="text-xs font-medium text-gray-900">{item.name}</p>
                    <p className="text-xs text-gray-600">{item.description}</p>
                    {item.tech && (
                      <span className="inline-block mt-1 px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-xs">
                        {item.tech}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
