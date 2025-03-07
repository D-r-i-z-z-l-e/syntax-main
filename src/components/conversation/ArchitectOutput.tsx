import React from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon } from 'lucide-react';
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
  const getButtonText = () => {
    switch (currentLevel) {
      case 1:
        return 'Design Folder Structure';
      case 2:
        return 'Create Implementation Plan';
      case 3:
        return 'Generate Project Structure';
      default:
        return 'Proceed';
    }
  };

  const canProceedToNextLevel = () => {
    // Disable the button when thinking
    if (isThinking) return false;
    
    // Check correct progression based on levels and available data
    switch (currentLevel) {
      case 1:
        // Can only proceed from level 1 if we have the vision text
        return !!level1Output?.visionText;
      case 2:
        // Can only proceed from level 2 if we have the folder structure
        return !!level2Output && !!level2Output.rootFolder;
      case 3:
        // Can only proceed from level 3 if we have the implementation plan
        return !!level3Output && Array.isArray(level3Output.implementationOrder);
      default:
        return false;
    }
  };

  if (error) {
    return (
      <div className="w-full bg-red-50 rounded-lg border border-red-200 p-4 mb-4">
        <h2 className="text-sm font-semibold text-red-900 mb-2">Error</h2>
        <p className="text-sm text-red-700">{error}</p>
      </div>
    );
  }

  if (!level1Output && !isThinking && currentLevel === 1) return null;

  return (
    <div className="w-full architect-card p-5 mb-5">
      <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center">
        <CodeIcon className="w-4 h-4 mr-2 text-blue-500" />
        AI Architect Progress
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
            {currentLevel === 1 && "Analyzing requirements..."}
            {currentLevel === 2 && "Designing folder structure..."}
            {currentLevel === 3 && "Planning implementation details..."}
          </span>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Only show the current level and completed levels */}
          
          {/* Level 1: Architectural Vision */}
          {(currentLevel >= 1) && (
            <div className={`transition-all duration-300 ${currentLevel === 1 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-3">
                <div className={`w-7 h-7 rounded-full ${currentLevel === 1 ? 'bg-blue-500' : 'bg-green-500'} text-white flex items-center justify-center mr-3`}>
                  {currentLevel > 1 ? <CheckIcon className="w-4 h-4" /> : '1'}
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Architectural Vision
                </h3>
              </div>
              
              {level1Output && (
                <div className="text-sm text-gray-700 bg-gray-50 rounded-lg p-4 ml-10 max-h-[200px] overflow-y-auto border border-gray-200">
                  {level1Output.visionText}
                </div>
              )}
            </div>
          )}

          {/* Level 2: Folder Structure - Only show if we're at level 2 or higher */}
          {(currentLevel >= 2) && (
            <div className={`transition-all duration-300 ${currentLevel === 2 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-3">
                <div className={`w-7 h-7 rounded-full ${currentLevel === 2 ? 'bg-blue-500' : currentLevel > 2 ? 'bg-green-500' : 'bg-gray-300'} text-white flex items-center justify-center mr-3`}>
                  {currentLevel > 2 ? <CheckIcon className="w-4 h-4" /> : '2'}
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Project Structure
                </h3>
              </div>
              
              {level2Output && level2Output.rootFolder && (
                <div className="bg-gray-50 rounded-lg p-4 ml-10 max-h-[250px] overflow-y-auto border border-gray-200">
                  {renderFolderStructure(level2Output.rootFolder)}
                </div>
              )}
            </div>
          )}

          {/* Level 3: Implementation Plan - Only show if we're at level 3 */}
          {(currentLevel >= 3) && (
            <div className={`transition-all duration-300 ${currentLevel === 3 ? 'opacity-100' : 'opacity-80'}`}>
              <div className="flex items-center mb-3">
                <div className={`w-7 h-7 rounded-full ${currentLevel === 3 ? 'bg-blue-500' : 'bg-gray-300'} text-white flex items-center justify-center mr-3`}>
                  3
                </div>
                <h3 className="text-base font-semibold text-gray-800">
                  Implementation Plan
                </h3>
              </div>
              
              {level3Output && level3Output.implementationOrder && (
                <div className="bg-gray-50 rounded-lg p-4 ml-10 max-h-[250px] overflow-y-auto border border-gray-200">
                  {level3Output.implementationOrder.map((file, index) => (
                    <div key={index} className="mb-4 last:mb-0 text-sm">
                      <p className="font-medium text-gray-800">{file.path}/{file.name}</p>
                      <p className="text-xs text-gray-600 mt-1">{file.description}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Button to proceed to next level - only visible for the current level */}
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

function renderFolderStructure(folder: ArchitectLevel2['rootFolder'], depth = 0) {
  if (!folder) {
    return <div className="text-red-500 text-xs">Error: Invalid folder structure</div>;
  }
  
  return (
    <div className={`${depth > 0 ? 'ml-5' : ''} text-sm`}>
      <div className="flex items-start gap-3 mb-2">
        <FolderIcon className="w-4 h-4 mt-1 text-blue-500 flex-shrink-0" />
        <div>
          <p className="font-medium text-gray-800">{folder.name}</p>
          <p className="text-xs text-gray-600 mt-1">{folder.description}</p>
        </div>
      </div>
      {folder.subfolders?.map((subfolder, index) => (
        <div key={index} className="ml-3 mt-3 border-l-2 border-gray-100 pl-3">
          {renderFolderStructure(subfolder, depth + 1)}
        </div>
      ))}
    </div>
  );
}
