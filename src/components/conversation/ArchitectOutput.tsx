import React, { useState } from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon, BrainIcon, SearchIcon, LayersIcon, TerminalIcon } from 'lucide-react';
import { ArchitectLevel2, FileContext } from '../../lib/types/architect';

interface ArchitectOutputProps {
  level1Output: { visionText: string } | null;
  level2Output: ArchitectLevel2 | null;
  level3Output: { implementationOrder: FileContext[] } | null;
  currentLevel: 1 | 2 | 3;
  isThinking: boolean;
  error: string | null;
  onProceedToNextLevel: () => void;
}

export function ArchitectOutput({
  level1Output,
  level2Output,
  level3Output,
  currentLevel,
  isThinking,
  error,
  onProceedToNextLevel
}: ArchitectOutputProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedFile, setExpandedFile] = useState<string | null>(null);
  
  const getButtonText = () => {
    switch (currentLevel) {
      case 1:
        return 'Create Project Structure';
      case 2:
        return 'Generate Implementation Plan';
      case 3:
        return 'Build Project';
      default:
        return 'Proceed';
    }
  };

  const canProceedToNextLevel = () => {
    if (isThinking) return false;
    
    switch (currentLevel) {
      case 1:
        return !!level1Output?.visionText;
      case 2:
        return !!level2Output?.rootFolder;
      case 3:
        return !!level3Output?.implementationOrder;
      default:
        return false;
    }
  };

  const getTotalFileCount = (rootFolder: any): number => {
    let count = 0;
    
    // Count files in current folder
    if (rootFolder.files && Array.isArray(rootFolder.files)) {
      count += rootFolder.files.length;
    }
    
    // Count files in subfolders
    if (rootFolder.subfolders && Array.isArray(rootFolder.subfolders)) {
      for (const subfolder of rootFolder.subfolders) {
        count += getTotalFileCount(subfolder);
      }
    }
    
    return count;
  };
  
  const filteredImplementationOrder = level3Output?.implementationOrder?.filter(file => 
    file.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    file.path.toLowerCase().includes(searchTerm.toLowerCase()) ||
    file.description.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (error) {
    return (
      <div className="w-full bg-red-50 rounded-lg border border-red-200 p-4 mb-4">
        <h2 className="text-sm font-semibold text-red-900 mb-2">Error</h2>
        <p className="text-sm text-red-700">{error}</p>
      </div>
    );
  }

  if (!level1Output && !isThinking) return null;

  return (
    <div className="w-full architect-card p-5 mb-5">
      <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center">
        {currentLevel === 1 && <BrainIcon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 2 && <FolderIcon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 3 && <TerminalIcon className="w-5 h-5 mr-2 text-blue-500" />}
        AI Architect - Phase {currentLevel}
      </h2>
      
      {/* Progress Indicator */}
      <div className="progress-indicator mb-6">
        <div className={`step ${currentLevel >= 1 ? (currentLevel > 1 ? 'completed' : 'active') : 'inactive'}`}>
          {currentLevel > 1 ? <CheckIcon className="w-4 h-4" /> : 1}
        </div>
        <div className={`line ${currentLevel > 1 ? 'active' : ''}`}></div>
        <div className={`step ${currentLevel >= 2 ? (currentLevel > 2 ? 'completed' : 'active') : 'inactive'}`}>
          {currentLevel > 2 ? <CheckIcon className="w-4 h-4" /> : 2}
        </div>
        <div className={`line ${currentLevel > 2 ? 'active' : ''}`}></div>
        <div className={`step ${currentLevel >= 3 ? 'active' : 'inactive'}`}>
          3
        </div>
      </div>
      
      {isThinking ? (
        <div className="flex items-center justify-center space-x-3 py-8">
          <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600 font-medium">
            {currentLevel === 1 && "Creating comprehensive architectural vision..."}
            {currentLevel === 2 && "Designing complete project structure..."}
            {currentLevel === 3 && "Developing detailed implementation plans..."}
          </span>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Phase Title */}
          <div className="text-center mb-4">
            <h3 className="text-lg font-semibold text-blue-700">
              {currentLevel === 1 && "Architectural Vision"}
              {currentLevel === 2 && "Complete Project Structure"}
              {currentLevel === 3 && "Implementation Blueprint"}
            </h3>
            <p className="text-sm text-gray-500">
              {currentLevel === 1 && "A comprehensive blueprint of the software architecture"}
              {currentLevel === 2 && `Complete project skeleton with ${level2Output?.rootFolder ? getTotalFileCount(level2Output.rootFolder) : 0} files`}
              {currentLevel === 3 && `Detailed implementation instructions for ${level3Output?.implementationOrder?.length || 0} files`}
            </p>
          </div>
          
          {/* Level 1: Architectural Vision */}
          {currentLevel === 1 && level1Output && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <BrainIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Comprehensive Architecture
                  </h3>
                </div>
              </div>
              
              <div className="text-sm text-gray-700 bg-gray-50 rounded-lg p-5 max-h-[600px] overflow-y-auto border border-gray-200 prose prose-sm">
                {level1Output.visionText.split('\n\n').map((paragraph, idx) => (
                  <p key={idx} className="mb-4">{paragraph}</p>
                ))}
              </div>
            </div>
          )}

          {/* Level 2: Project Structure */}
          {currentLevel === 2 && level2Output && level2Output.rootFolder && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <LayersIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Project Files & Directories
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {getTotalFileCount(level2Output.rootFolder)} files
                </div>
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4 max-h-[600px] overflow-y-auto border border-gray-200">
                {renderFolderStructure(level2Output.rootFolder)}
              </div>
            </div>
          )}

          {/* Level 3: Implementation Plan */}
          {currentLevel === 3 && level3Output && level3Output.implementationOrder && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <CodeIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Implementation Details
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {level3Output.implementationOrder.length} files
                </div>
              </div>
              
              {/* Search bar */}
              <div className="relative mb-4">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <SearchIcon className="h-4 w-4 text-gray-400" />
                </div>
                <input
                  type="text"
                  className="bg-white border border-gray-300 rounded-md py-2 pl-10 pr-4 w-full text-sm text-gray-900 focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Search files..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              
              <div className="bg-gray-50 rounded-lg p-4 max-h-[600px] overflow-y-auto border border-gray-200">
                {filteredImplementationOrder && filteredImplementationOrder.length > 0 ? (
                  <div className="space-y-4">
                    {filteredImplementationOrder.map((file, index) => (
                      <div 
                        key={index} 
                        className={`mb-4 last:mb-0 text-sm border-b border-gray-200 pb-4 last:border-b-0 ${
                          expandedFile === `${file.path}/${file.name}` ? 'bg-blue-50 p-2 rounded' : ''
                        }`}
                      >
                        <div 
                          className="flex items-start cursor-pointer"
                          onClick={() => setExpandedFile(expandedFile === `${file.path}/${file.name}` ? null : `${file.path}/${file.name}`)}
                        >
                          <FileIcon className="w-4 h-4 mt-1 text-blue-500 mr-2 flex-shrink-0" />
                          <div className="flex-1">
                            <p className="font-medium text-gray-800">
                              {file.path}/{file.name}
                            </p>
                            <p className="text-xs text-gray-500 mt-1">
                              Type: {file.type} | Purpose: {file.purpose}
                            </p>
                          </div>
                          <div className="text-xs bg-gray-100 rounded-md px-2 py-0.5 text-gray-500">
                            {expandedFile === `${file.path}/${file.name}` ? 'Hide' : 'Details'}
                          </div>
                        </div>
                        
                        {expandedFile === `${file.path}/${file.name}` && (
                          <div className="mt-3 ml-6 text-sm">
                            <div className="bg-white p-3 rounded border border-gray-200 mb-3">
                              <p className="text-gray-600">{file.description}</p>
                            </div>
                            
                            {file.dependencies && file.dependencies.length > 0 && (
                              <div className="mt-2 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Dependencies:</p>
                                <div className="flex flex-wrap gap-1">
                                  {file.dependencies.map((dep, idx) => (
                                    <span key={idx} className="text-xs bg-gray-100 px-2 py-0.5 rounded text-gray-600">
                                      {dep}
                                    </span>
                                  ))}
                                </div>
                              </div>
                            )}

                            {file.imports && file.imports.length > 0 && (
                              <div className="mt-2 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Imports:</p>
                                <div className="bg-gray-50 p-2 rounded text-xs font-mono text-gray-600">
                                  {file.imports.map((imp, idx) => (
                                    <div key={idx}>{imp}</div>
                                  ))}
                                </div>
                              </div>
                            )}
                            
                            {file.components && file.components.length > 0 && (
                              <div className="mt-3 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Components:</p>
                                <div className="space-y-2">
                                  {file.components.map((component, idx) => (
                                    <div key={idx} className="text-xs bg-gray-100 p-2 rounded border border-gray-200">
                                      <p className="font-medium text-gray-800">{component.name} ({component.type})</p>
                                      <p className="text-gray-600 mt-1">{component.details}</p>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                            
                            {file.implementations && file.implementations.length > 0 && (
                              <div className="mt-3 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Implementations:</p>
                                <div className="space-y-3">
                                  {file.implementations.map((impl, idx) => (
                                    <div key={idx} className="bg-white p-2 rounded border border-gray-200">
                                      <p className="font-medium text-gray-800 text-xs">{impl.name}: {impl.type}</p>
                                      <p className="text-gray-600 text-xs mt-1">{impl.description}</p>
                                      
                                      {impl.parameters && impl.parameters.length > 0 && (
                                        <div className="mt-2">
                                          <p className="text-xs font-medium text-gray-600">Parameters:</p>
                                          <ul className="text-xs pl-4 list-disc">
                                            {impl.parameters.map((param, pidx) => (
                                              <li key={pidx}>
                                                <span className="font-mono">{param.name}</span> ({param.type}): {param.description}
                                              </li>
                                            ))}
                                          </ul>
                                        </div>
                                      )}
                                      
                                      {impl.returnType && (
                                        <p className="text-xs text-gray-600 mt-1">
                                          Returns: <span className="font-mono">{impl.returnType}</span>
                                        </p>
                                      )}
                                      
                                      {impl.logic && (
                                        <div className="mt-2 border-t border-gray-100 pt-2">
                                          <p className="text-xs font-medium text-gray-600">Implementation:</p>
                                          <p className="text-xs text-gray-600">{impl.logic}</p>
                                        </div>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                            
                            {file.testingStrategy && (
                              <div className="mt-2 mb-3">
                                <p className="text-xs font-medium text-gray-700 mb-1">Testing Strategy:</p>
                                <p className="text-xs bg-gray-100 p-2 rounded text-gray-600">{file.testingStrategy}</p>
                              </div>
                            )}
                            
                            {file.additionalContext && (
                              <div className="mt-2 text-xs italic bg-yellow-50 p-2 rounded text-gray-600 border border-yellow-100">
                                <p className="font-medium text-yellow-700 mb-1">Additional Notes:</p>
                                {file.additionalContext}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-4 text-gray-500">
                    {searchTerm ? "No files match your search" : "No implementation details found"}
                  </div>
                )}
              </div>
            </div>
          )}

          <button
            onClick={onProceedToNextLevel}
            disabled={!canProceedToNextLevel()}
            className={`w-full mt-6 ${canProceedToNextLevel() 
              ? 'bg-blue-600 hover:bg-blue-700 text-white' 
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
            } font-medium rounded-lg px-5 py-3 flex items-center justify-center transition-colors`}
          >
            {getButtonText()}
            <ArrowRightIcon className="w-4 h-4 ml-2" />
          </button>
        </div>
      )}
    </div>
  );
}

function renderFolderStructure(folder: any, depth = 0) {
  if (!folder) {
    return <div className="text-red-500 text-xs">Error: Invalid folder structure</div>;
  }
  
  return (
    <div className={`${depth > 0 ? 'ml-4' : ''} text-sm`}>
      <div className="flex items-start mb-2">
        <FolderIcon className="w-4 h-4 mt-1 text-blue-500 flex-shrink-0" />
        <div className="ml-2">
          <p className="font-medium text-gray-800">{folder.name}</p>
          <p className="text-xs text-gray-600">{folder.description}</p>
          {folder.purpose && (
            <p className="text-xs text-gray-500 italic">Purpose: {folder.purpose}</p>
          )}
        </div>
      </div>
      
      {/* Files */}
      {folder.files && folder.files.length > 0 && (
        <div className="ml-4 space-y-2 mt-2">
          {folder.files.map((file: any, fileIndex: number) => (
            <div key={fileIndex} className="flex items-start">
              <FileIcon className="w-4 h-4 mt-1 text-gray-500 flex-shrink-0" />
              <div className="ml-2">
                <p className="font-medium text-gray-700 text-xs">{file.name}</p>
                <p className="text-xs text-gray-500">{file.description}</p>
              </div>
            </div>
          ))}
        </div>
      )}
      
      {/* Subfolders */}
      {folder.subfolders?.map((subfolder: any, index: number) => (
        <div key={index} className="ml-4 mt-3 border-l-2 border-gray-100 pl-3">
          {renderFolderStructure(subfolder, depth + 1)}
        </div>
      ))}
    </div>
  );
}
