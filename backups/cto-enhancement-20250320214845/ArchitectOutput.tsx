import React, { useState } from 'react';
import { CodeIcon, FolderIcon, FileIcon, ArrowRightIcon, CheckIcon, BrainIcon, SearchIcon, LayersIcon, TerminalIcon, Users2Icon, ChevronDownIcon, ChevronUpIcon } from 'lucide-react';
import { ArchitectLevel1, ArchitectLevel2, ArchitectLevel3, FileImplementation, SpecialistVision } from '../../lib/types/architect';
import { IDEContainer } from '../ide/IDEContainer';

interface ArchitectOutputProps {
  level1Output: ArchitectLevel1 | null;
  level2Output: ArchitectLevel2 | null;
  level3Output: ArchitectLevel3 | null;
  currentLevel: 1 | 2 | 3;
  isThinking: boolean;
  error: string | null;
  completedFiles: number;
  totalFiles: number;
  currentSpecialist: number;
  totalSpecialists: number;
  generatedFiles: FileImplementation[];
  activeFile: FileImplementation | null;
  setActiveFile: (file: FileImplementation | null) => void;
  onProceedToNextLevel: () => void;
}

const REPORT_SECTIONS = [
  { id: 'executive-summary', title: 'Executive Summary' },
  { id: 'system-architecture', title: 'System Architecture Overview' },
  { id: 'technology-stack', title: 'Technology Stack' },
  { id: 'component-architecture', title: 'Component Architecture' },
  { id: 'data-architecture', title: 'Data Architecture' },
  { id: 'security-architecture', title: 'Security Architecture' },
  { id: 'integration-architecture', title: 'Integration Architecture' },
  { id: 'deployment-architecture', title: 'Deployment Architecture' },
  { id: 'performance-considerations', title: 'Performance Considerations' },
  { id: 'development-guidelines', title: 'Development Guidelines' },
  { id: 'testing-strategy', title: 'Testing Strategy' },
  { id: 'operational-considerations', title: 'Operational Considerations' }
];

export function ArchitectOutput({
  level1Output,
  level2Output,
  level3Output,
  currentLevel,
  isThinking,
  error,
  completedFiles,
  totalFiles,
  currentSpecialist,
  totalSpecialists,
  generatedFiles,
  activeFile,
  setActiveFile,
  onProceedToNextLevel
}: ArchitectOutputProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedFile, setExpandedFile] = useState<string | null>(null);
  const [selectedSpecialist, setSelectedSpecialist] = useState<number | null>(null);
  const [showIDE, setShowIDE] = useState(false);
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['executive-summary']));
  const [visibleVisionSection, setVisibleVisionSection] = useState('all');
  
  const toggleSection = (sectionId: string) => {
    setExpandedSections(prev => {
      const newSet = new Set(prev);
      if (newSet.has(sectionId)) {
        newSet.delete(sectionId);
      } else {
        newSet.add(sectionId);
      }
      return newSet;
    });
  };
  
  const getButtonText = () => {
    switch (currentLevel) {
      case 1:
        return 'Integrate Specialist Visions';
      case 2:
        return 'Generate Code';
      case 3:
        return 'Open IDE';
      default:
        return 'Proceed';
    }
  };

  const handleProceed = () => {
    if (currentLevel === 3) {
      setShowIDE(true);
    } else {
      onProceedToNextLevel();
    }
  };
  
  const canProceedToNextLevel = () => {
    if (isThinking) return false;
    
    switch (currentLevel) {
      case 1:
        return !!level1Output?.specialists && level1Output.specialists.length > 0;
      case 2:
        return !!level2Output?.rootFolder && !!level2Output?.integratedVision;
      case 3:
        return !!level3Output?.implementations && level3Output.implementations.length > 0;
      default:
        return false;
    }
  };
  
  const getTotalFileCount = (rootFolder: any): number => {
    let count = 0;
    
    // Count files in this folder
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
  
  const filteredImplementations = level3Output?.implementations?.filter(file => 
    file.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    file.path.toLowerCase().includes(searchTerm.toLowerCase()) ||
    file.description.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  const renderVisionSections = (visionText: string) => {
    if (visibleVisionSection !== 'all') {
      // Find the relevant section based on pattern matching
      const sections = extractSections(visionText);
      if (sections[visibleVisionSection]) {
        return (
          <div className="text-sm text-gray-700 bg-white rounded-lg p-5 max-h-[600px] overflow-y-auto border border-gray-200 prose prose-sm">
            {sections[visibleVisionSection].split('\n\n').map((paragraph, idx) => (
              <p key={idx} className="mb-4">{paragraph}</p>
            ))}
          </div>
        );
      }
    }
    
    // Default - show all content
    return (
      <div className="text-sm text-gray-700 bg-white rounded-lg p-5 max-h-[600px] overflow-y-auto border border-gray-200 prose prose-sm">
        {visionText.split('\n\n').map((paragraph, idx) => (
          <p key={idx} className="mb-4">{paragraph}</p>
        ))}
      </div>
    );
  };
  
  const extractSections = (visionText: string) => {
    const sections: Record<string, string> = {};
    let currentSection = 'executive-summary';
    let currentContent: string[] = [];
    
    // Split by lines to process section by section
    const lines = visionText.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // Check if this line is a section header
      const sectionMatch = /^(#+)\s+(.+)$/i.test(line) || 
                          /^([A-Z][A-Za-z\s]+):$/i.test(line) ||
                          /^([0-9]+\.\s+[A-Z][A-Za-z\s]+)$/i.test(line);
                          
      if (sectionMatch) {
        // Save the previous section
        if (currentContent.length > 0) {
          sections[currentSection] = currentContent.join('\n');
        }
        
        // Start a new section
        // Simplify the section name for mapping
        const sectionName = line.toLowerCase()
          .replace(/^#+\s+/, '')
          .replace(/[^a-z0-9\s-]/g, '')
          .replace(/\s+/g, '-')
          .trim();
          
        // Find the best matching predefined section
        currentSection = findBestMatchingSection(sectionName) || sectionName;
        currentContent = [line];
      } else {
        currentContent.push(line);
      }
    }
    
    // Save the last section
    if (currentContent.length > 0) {
      sections[currentSection] = currentContent.join('\n');
    }
    
    return sections;
  };
  
  const findBestMatchingSection = (sectionName: string): string | null => {
    // Map the input section to our predefined sections
    for (const section of REPORT_SECTIONS) {
      const normalizedSectionId = section.title.toLowerCase().replace(/\s+/g, '-');
      if (sectionName.includes(normalizedSectionId) || 
          normalizedSectionId.includes(sectionName)) {
        return section.id;
      }
    }
    return null;
  };

  if (error) {
    return (
      <div className="w-full bg-red-50 rounded-lg border border-red-200 p-4 mb-4">
        <h2 className="text-sm font-semibold text-red-900 mb-2">Error</h2>
        <p className="text-sm text-red-700">{error}</p>
      </div>
    );
  }

  if (showIDE) {
    return (
      <IDEContainer 
        files={generatedFiles} 
        onClose={() => setShowIDE(false)}
        activeFile={activeFile}
        setActiveFile={setActiveFile}
      />
    );
  }

  if ((!level1Output && !isThinking) || (!level1Output?.specialists && !isThinking && currentLevel === 1)) return null;

  return (
    <div className="w-full architect-card p-5 mb-5">
      <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center">
        {currentLevel === 1 && <Users2Icon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 2 && <BrainIcon className="w-5 h-5 mr-2 text-blue-500" />}
        {currentLevel === 3 && <CodeIcon className="w-5 h-5 mr-2 text-blue-500" />}
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
            {currentLevel === 1 && (
              <div className="flex flex-col items-center">
                <span>Consulting with specialists...</span>
                {totalSpecialists > 0 && (
                  <div className="mt-2 w-full max-w-xs">
                    <div className="flex justify-between text-xs mb-1">
                      <span>{currentSpecialist} of {totalSpecialists} specialists</span>
                      <span>{Math.round((currentSpecialist / totalSpecialists) * 100)}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="h-2 rounded-full bg-blue-500"
                        style={{ width: `${(currentSpecialist / totalSpecialists) * 100}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
            )}
            {currentLevel === 2 && "CTO is developing comprehensive architecture specification..."}
            {currentLevel === 3 && (
              <div className="flex flex-col items-center">
                <span>Generating code implementations...</span>
                {totalFiles > 0 && (
                  <div className="mt-2 w-full max-w-xs">
                    <div className="flex justify-between text-xs mb-1">
                      <span>{completedFiles} of {totalFiles} files</span>
                      <span>{Math.round((completedFiles / totalFiles) * 100)}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="h-2 rounded-full bg-blue-500"
                        style={{ width: `${(completedFiles / totalFiles) * 100}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
            )}
          </span>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Phase Title */}
          <div className="text-center mb-4">
            <h3 className="text-lg font-semibold text-blue-700">
              {currentLevel === 1 && "Specialist Visions"}
              {currentLevel === 2 && "CTO's Comprehensive Architecture"}
              {currentLevel === 3 && "Generated Code"}
            </h3>
            <p className="text-sm text-gray-500">
              {currentLevel === 1 && `${level1Output?.specialists?.length || 0} specialists have provided their expert insights`}
              {currentLevel === 2 && `Complete architectural specification with ${level2Output?.dependencyTree?.files?.length || 0} files`}
              {currentLevel === 3 && `Complete code implementation for ${level3Output?.implementations?.length || 0} files`}
            </p>
          </div>
          
          {/* Level 1: Specialist Visions */}
          {currentLevel === 1 && level1Output?.specialists && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <Users2Icon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Specialist Team
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {level1Output.specialists.length} specialists
                </div>
              </div>
              
              {/* Specialist selector tabs */}
              <div className="flex flex-wrap gap-2 mb-4">
                {level1Output.specialists.map((specialist, idx) => (
                  <button
                    key={idx}
                    className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                      selectedSpecialist === idx 
                        ? 'bg-blue-600 text-white' 
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                    onClick={() => setSelectedSpecialist(idx)}
                  >
                    {specialist.role}
                  </button>
                ))}
                <button
                  className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                    selectedSpecialist === null 
                      ? 'bg-blue-600 text-white' 
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                  onClick={() => setSelectedSpecialist(null)}
                >
                  All Specialists
                </button>
              </div>
              
              {/* Selected specialist detail or all specialists */}
              {selectedSpecialist !== null ? (
                // Detailed view of the selected specialist
                <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
                  <div className="mb-3">
                    <h4 className="text-base font-medium text-gray-900">{level1Output.specialists[selectedSpecialist].role}</h4>
                    <p className="text-sm text-gray-600">{level1Output.specialists[selectedSpecialist].expertise}</p>
                  </div>
                  
                  <div className="mb-4">
                    <h5 className="text-sm font-medium text-gray-800 mb-2">Vision</h5>
                    <div className="text-sm text-gray-700 bg-white rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200 prose prose-sm">
                      {level1Output.specialists[selectedSpecialist].visionText.split('\n\n').map((paragraph, idx) => (
                        <p key={idx} className="mb-4">{paragraph}</p>
                      ))}
                    </div>
                  </div>
                  
                  <div>
                    <h5 className="text-sm font-medium text-gray-800 mb-2">Proposed Structure</h5>
                    <div className="bg-white rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200">
                      {renderFolderStructure(level1Output.specialists[selectedSpecialist].projectStructure.rootFolder)}
                    </div>
                  </div>
                </div>
              ) : (
                // Summary view of all specialists
                <div className="space-y-4">
                  {level1Output.specialists.map((specialist, idx) => (
                    <div key={idx} className="bg-gray-50 rounded-lg p-4 border border-gray-200">
                      <div className="flex justify-between items-start">
                        <div>
                          <h4 className="text-base font-medium text-gray-900">{specialist.role}</h4>
                          <p className="text-sm text-gray-600">{specialist.expertise}</p>
                        </div>
                        <button
                          className="text-xs bg-blue-50 hover:bg-blue-100 text-blue-700 px-3 py-1 rounded-full transition-colors"
                          onClick={() => setSelectedSpecialist(idx)}
                        >
                          Full Details
                        </button>
                      </div>
                      
                      <div className="mt-3">
                        <h5 className="text-xs font-medium text-gray-800 mb-1">Key Points</h5>
                        <div className="text-xs text-gray-700 bg-white rounded p-3 border border-gray-100 line-clamp-3">
                          {specialist.visionText.substring(0, 180)}...
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Level 2: Enhanced CTO Architecture Report */}
          {currentLevel === 2 && level2Output && (
            <div className="space-y-6">
              {/* Section Tabs */}
              <div className="flex flex-wrap gap-2 mb-4">
                <button
                  className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                    visibleVisionSection === 'all' 
                      ? 'bg-blue-600 text-white' 
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                  onClick={() => setVisibleVisionSection('all')}
                >
                  Full Report
                </button>
                
                {REPORT_SECTIONS.map((section) => (
                  <button
                    key={section.id}
                    className={`px-3 py-1.5 text-xs rounded-full transition-colors ${
                      visibleVisionSection === section.id 
                        ? 'bg-blue-600 text-white' 
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                    onClick={() => setVisibleVisionSection(section.id)}
                  >
                    {section.title}
                  </button>
                ))}
              </div>
            
              {/* Integrated Vision - Enhanced Report Display */}
              <div>
                <div className="mb-3 flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <BrainIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      Comprehensive Architecture Specification
                    </h3>
                  </div>
                </div>
                
                {renderVisionSections(level2Output.integratedVision)}
              </div>
              
              {/* Resolution Notes */}
              {level2Output.resolutionNotes && level2Output.resolutionNotes.length > 0 && (
                <div>
                  <div className="flex items-center justify-between cursor-pointer mb-2" onClick={() => toggleSection('resolution-notes')}>
                    <div className="flex items-center">
                      <div className="w-7 h-7 rounded-full bg-yellow-500 text-white flex items-center justify-center mr-3">
                        <LayersIcon className="w-4 h-4" />
                      </div>
                      <h3 className="text-base font-semibold text-gray-800">
                        Architectural Decisions & Trade-offs
                      </h3>
                    </div>
                    {expandedSections.has('resolution-notes') ? 
                      <ChevronUpIcon className="w-5 h-5 text-gray-500" /> : 
                      <ChevronDownIcon className="w-5 h-5 text-gray-500" />
                    }
                  </div>
                  
                  {expandedSections.has('resolution-notes') && (
                    <div className="bg-yellow-50 rounded-lg p-4 border border-yellow-100 mt-2">
                      <ul className="list-disc pl-5 space-y-4">
                        {level2Output.resolutionNotes.map((note, idx) => (
                          <li key={idx} className="text-sm text-gray-700">{note}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              )}
              
              {/* Project Structure */}
              <div>
                <div className="flex items-center justify-between cursor-pointer mb-2" onClick={() => toggleSection('project-structure')}>
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <LayersIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      Project Structure
                    </h3>
                  </div>
                  {expandedSections.has('project-structure') ? 
                    <ChevronUpIcon className="w-5 h-5 text-gray-500" /> : 
                    <ChevronDownIcon className="w-5 h-5 text-gray-500" />
                  }
                </div>
                
                {expandedSections.has('project-structure') && (
                  <div className="bg-gray-50 rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200 mt-2">
                    <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full inline-block mb-3">
                      {level2Output.dependencyTree?.files?.length || 0} files
                    </div>
                    {renderFolderStructure(level2Output.rootFolder)}
                  </div>
                )}
              </div>
              
              {/* Dependency Tree */}
              <div>
                <div className="flex items-center justify-between cursor-pointer mb-2" onClick={() => toggleSection('dependency-tree')}>
                  <div className="flex items-center">
                    <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                      <CodeIcon className="w-4 h-4" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-800">
                      Implementation Order
                    </h3>
                  </div>
                  {expandedSections.has('dependency-tree') ? 
                    <ChevronUpIcon className="w-5 h-5 text-gray-500" /> : 
                    <ChevronDownIcon className="w-5 h-5 text-gray-500" />
                  }
                </div>
                
                {expandedSections.has('dependency-tree') && (
                  <div className="bg-gray-50 rounded-lg p-4 max-h-[300px] overflow-y-auto border border-gray-200 mt-2">
                    <div className="space-y-2">
                      {level2Output.dependencyTree?.files?.sort((a, b) => a.implementationOrder - b.implementationOrder)
                        .map((file, index) => (
                          <div key={index} className="flex items-start">
                            <div className="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center mr-2 flex-shrink-0 text-xs font-medium">
                              {file.implementationOrder}
                            </div>
                            <div>
                              <div className="flex items-center">
                                <FileIcon className="h-4 w-4 mr-2 text-gray-500" />
                                <span className="font-medium text-gray-900">{file.path}/{file.name}</span>
                              </div>
                              <p className="text-xs text-gray-600 mt-1">{file.description}</p>
                              {file.dependencies.length > 0 && (
                                <div className="mt-1">
                                  <span className="text-xs text-gray-500">Depends on: </span>
                                  <div className="flex flex-wrap gap-1 mt-1">
                                    {file.dependencies.map((dep, idx) => (
                                      <span key={idx} className="text-xs bg-gray-100 px-2 py-0.5 rounded text-gray-600">
                                        {dep}
                                      </span>
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>
                          </div>
                        ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Level 3: Code Implementations */}
          {currentLevel === 3 && level3Output && level3Output.implementations && (
            <div>
              <div className="mb-3 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-7 h-7 rounded-full bg-blue-500 text-white flex items-center justify-center mr-3">
                    <CodeIcon className="w-4 h-4" />
                  </div>
                  <h3 className="text-base font-semibold text-gray-800">
                    Generated Code
                  </h3>
                </div>
                <div className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                  {level3Output.implementations.length} files
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
                {filteredImplementations && filteredImplementations.length > 0 ? (
                  <div className="space-y-4">
                    {filteredImplementations.map((file, index) => (
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
                              Type: {file.type} | Language: {file.language}
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
                              <p className="text-gray-600 mt-1">{file.purpose}</p>
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
                            
                            <div className="flex justify-end mt-2">
                              <button
                                onClick={() => {
                                  setActiveFile(file);
                                  setShowIDE(true);
                                }}
                                className="text-xs bg-blue-50 hover:bg-blue-100 text-blue-700 px-3 py-1 rounded transition-colors flex items-center"
                              >
                                <CodeIcon className="w-3 h-3 mr-1" />
                                View Code
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-4 text-gray-500">
                    {searchTerm ? "No files match your search" : "No code implementations found"}
                  </div>
                )}
              </div>
            </div>
          )}

          <button
            onClick={handleProceed}
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
