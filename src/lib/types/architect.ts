export interface SpecialistVision {
  role: string;
  expertise: string;
  visionText: string;
  projectStructure: {
    rootFolder: FolderStructure;
  };
}

export interface ArchitectLevel1 {
  specialists: SpecialistVision[];
  roles: string[];
}

export interface FileNode {
  name: string;
  path: string;
  description: string;
  purpose: string;
  dependencies: string[];
  dependents: string[];
  implementationOrder: number;
  type: string;
}

export interface FolderStructure {
  name: string;
  description: string;
  purpose: string;
  files?: {
    name: string;
    description: string;
    purpose: string;
  }[];
  subfolders?: FolderStructure[];
}

export interface ArchitectLevel2 {
  integratedVision: string;
  rootFolder: FolderStructure;
  dependencyTree: {
    files: FileNode[];
  };
  resolutionNotes: string[];
}

export interface FileImplementation {
  name: string;
  path: string;
  type: string;
  description: string;
  purpose: string;
  dependencies: string[];
  language: string;
  code: string;
  testCode?: string;
}

export interface ArchitectLevel3 {
  implementations: FileImplementation[];
}

export interface ArchitectState {
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
}

export interface ProjectFile {
  id: string;
  name: string;
  path: string;
  content: string;
  language: string;
}

export interface ProjectFolder {
  id: string;
  name: string;
  path: string;
  description?: string;
  children: (ProjectFile | ProjectFolder)[];
}

export interface ProjectStructure {
  rootFolder: ProjectFolder;
}
