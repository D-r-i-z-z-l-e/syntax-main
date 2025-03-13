export interface ArchitectLevel1 {
  visionText: string;
}

export interface FolderStructure {
  name: string;
  description: string;
  purpose: string;
  subfolders?: FolderStructure[];
}

export interface ArchitectLevel2 {
  rootFolder: FolderStructure;
}

export interface FileContext {
  name: string;
  path: string;
  type: string;
  description: string;
  purpose: string;
  dependencies: string[];
  components: {
    name: string;
    type: string;
    purpose: string;
    dependencies: string[];
    details: string;
  }[];
  implementations: {
    name: string;
    type: string;
    description: string;
    parameters?: {
      name: string;
      type: string;
      description: string;
    }[];
    returnType?: string;
    logic: string;
  }[];
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
}
