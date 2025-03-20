const fs = require('fs');
const path = require('path');

// Path to the file
const filePath = path.join('src', 'components', 'conversation', 'ArchitectOutput.tsx');

// Read the file
let content = fs.readFileSync(filePath, 'utf8');

// Add import for the book viewer
content = content.replace(
  "import { FileImplementation } from '../../lib/types/architect';",
  "import { FileImplementation, ImplementationBook } from '../../lib/types/architect';\nimport { ImplementationBookViewer } from '../book/ImplementationBook';"
);

// Update the ArchitectOutputProps interface
content = content.replace(
  /interface ArchitectOutputProps {[^}]*}/s,
  `interface ArchitectOutputProps {
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
  onGenerateBook?: () => void;
  bookGenerationProgress?: {
    totalChapters: number;
    completedChapters: number;
    currentChapter: string;
    progress: number;
  };
}`
);

// Add state for showing the book
content = content.replace(
  "const [showIDE, setShowIDE] = useState(false);",
  "const [showIDE, setShowIDE] = useState(false);\n  const [showBook, setShowBook] = useState(false);"
);

// Add the case for book generation button
content = content.replace(
  "const getButtonText = () => {",
  `const getButtonText = () => {
    if (currentLevel === 2 && level2Output?.implementationBook) {
      return 'View Implementation Book';
    }`
);

// Update the handleProceed function
content = content.replace(
  "const handleProceed = () => {",
  `const handleProceed = () => {
    if (currentLevel === 2 && level2Output?.implementationBook) {
      setShowBook(true);
      return;
    }`
);

// Add book generation button
content = content.replace(
  "const canProceedToNextLevel = () => {",
  `const handleGenerateBook = () => {
    if (onGenerateBook) {
      onGenerateBook();
    }
  };

  const canProceedToNextLevel = () => {`
);

// Return the book viewer when showBook is true
content = content.replace(
  "if (showIDE) {",
  `if (showBook && level2Output?.implementationBook) {
    return (
      <ImplementationBookViewer 
        book={level2Output.implementationBook} 
        onClose={() => setShowBook(false)}
      />
    );
  }
  
  if (showIDE) {`
);

// Add book generation progress indicator
content = content.replace(
  "{currentLevel === 2 && level2Output &&
  <div className="space-y-6">",
  `{currentLevel === 2 && level2Output &&
            <div className="space-y-6">
              
              {/* Book Generation Progress */}
              {bookGenerationProgress && (
                <div className="mb-4 bg-blue-50 rounded-lg p-4 border border-blue-100">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="text-base font-semibold text-blue-800">
                      <BookOpen className="w-4 h-4 inline mr-2" />
                      Generating Implementation Book
                    </h3>
                    <div className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-full">
                      {Math.round(bookGenerationProgress.progress)}%
                    </div>
                  </div>
                  
                  <div className="w-full bg-blue-200 rounded-full h-2.5 mb-2">
                    <div 
                      className="h-2.5 rounded-full bg-blue-600 transition-all duration-300"
                      style={{ width: \`\${bookGenerationProgress.progress}%\` }}
                    />
                  </div>
                  
                  <div className="flex justify-between text-xs text-blue-700">
                    <span>
                      {bookGenerationProgress.completedChapters} of {bookGenerationProgress.totalChapters} chapters
                    </span>
                    <span>Current: {bookGenerationProgress.currentChapter}</span>
                  </div>
                </div>
              )}
              
              {/* Generate Book Button - Show if we have CTO architecture but no book yet */}
              {currentLevel === 2 && !level2Output.implementationBook && !bookGenerationProgress && (
                <div className="mb-4">
                  <button
                    onClick={handleGenerateBook}
                    className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-medium rounded-lg px-5 py-3 flex items-center justify-center transition-colors"
                  >
                    <BookOpen className="w-4 h-4 mr-2" />
                    Generate Comprehensive Implementation Book
                  </button>
                  <p className="text-xs text-gray-500 mt-2 text-center">
                    This will create a detailed step-by-step guide for implementing the entire system
                  </p>
                </div>
              )}`
);

// Save the file
fs.writeFileSync(filePath, content, 'utf8');
console.log('Updated ArchitectOutput.tsx successfully');
