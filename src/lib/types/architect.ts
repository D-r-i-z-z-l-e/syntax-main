export interface ArchitectLevel1 {
  visionText: string;
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
  rootFolder: FolderStructure;
  dependencyTree: {
    files: FileNode[];
  };
}

export interface ComponentInfo {
  name: string;
  type: string;
  purpose: string;
  dependencies: string[];
  details: string;
}

export interface ParameterInfo {
  name: string;
  type: string;
  description: string;
  validation?: string;
  defaultValue?: string;
}

export interface ImplementationInfo {
  name: string;
  type: string;
  description: string;
  parameters?: ParameterInfo[];
  returnType?: string;
  logic: string;
}

export interface FileContext {
  name: string;
  path: string;
  type: string;
  description: string;
  purpose: string;
  dependencies: string[];
  imports: string[];
  components: ComponentInfo[];
  implementations: ImplementationInfo[];
  styling?: string;
  configuration?: string;
  stateManagement?: string;
  dataFlow?: string;
  errorHandling?: string;
  testingStrategy?: string;
  integrationPoints?: string;
  edgeCases?: string;
  additionalContext: string;
}

export interface ArchitectLevel3 {
  implementationOrder: FileContext[];
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
}
