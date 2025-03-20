import React, { useState } from 'react';
import { Book, ChevronDown, ChevronUp, ChevronRight, FileText, BookOpen, Download } from 'lucide-react';
import { ImplementationBook } from '../../lib/types/architect';

interface ImplementationBookViewerProps {
  book: ImplementationBook;
  onClose: () => void;
}

export function ImplementationBookViewer({ book, onClose }: ImplementationBookViewerProps) {
  const [expandedChapters, setExpandedChapters] = useState<Set<number>>(new Set([0]));
  const [searchTerm, setSearchTerm] = useState('');

  const toggleChapter = (index: number) => {
    setExpandedChapters(prev => {
      const newSet = new Set(prev);
      if (newSet.has(index)) {
        newSet.delete(index);
      } else {
        newSet.add(index);
      }
      return newSet;
    });
  };

  const handleDownloadBook = () => {
    // Create book markdown content
    let content = `# ${book.title}\n\n`;
    content += book.introduction + '\n\n';
    content += '## Table of Contents\n';
    
    book.chapters.forEach((chapter, index) => {
      content += `${index + 1}. ${chapter.title}\n`;
    });
    
    content += '\n\n';
    
    book.chapters.forEach((chapter, index) => {
      content += `# ${index + 1}. ${chapter.title}\n\n`;
      content += chapter.content + '\n\n';
    });
    
    // Create and download the file
    const blob = new Blob([content], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = book.title.replace(/\s+/g, '-').toLowerCase() + '.md';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  // Filter chapters if search term is provided
  const filteredChapters = searchTerm ? 
    book.chapters.filter(chapter => 
      chapter.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      chapter.content.toLowerCase().includes(searchTerm.toLowerCase())
    ) : 
    book.chapters;

  return (
    <div className="fixed inset-0 bg-white z-50 flex flex-col">
      {/* Header */}
      <div className="border-b px-4 py-3 flex justify-between items-center bg-gray-50">
        <div className="flex items-center">
          <BookOpen className="w-5 h-5 mr-2 text-blue-600" />
          <h2 className="font-semibold text-gray-800">{book.title}</h2>
        </div>
        
        <div className="flex items-center space-x-3">
          <button 
            className="px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 text-sm rounded flex items-center"
            onClick={handleDownloadBook}
          >
            <Download className="w-4 h-4 mr-1.5" />
            Download Book
          </button>
          
          <button 
            className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-full"
            onClick={onClose}
            title="Close"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
      
      {/* Content */}
      <div className="flex flex-1 overflow-hidden">
        {/* Table of Contents */}
        <div className="w-1/4 border-r overflow-y-auto p-4">
          <div className="mb-4">
            <div className="relative">
              <input
                type="text"
                placeholder="Search chapters..."
                className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          
          <h3 className="text-lg font-semibold mb-2">Table of Contents</h3>
          
          <div className="space-y-1">
            {filteredChapters.map((chapter, index) => (
              <div key={index} className="cursor-pointer">
                <div 
                  className="flex items-center py-2 px-2 hover:bg-gray-100 rounded"
                  onClick={() => toggleChapter(index)}
                >
                  {expandedChapters.has(index) ? 
                    <ChevronDown className="w-4 h-4 mr-1" /> : 
                    <ChevronRight className="w-4 h-4 mr-1" />
                  }
                  <span>{index + 1}. {chapter.title}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
        
        {/* Chapter Content */}
        <div className="flex-1 overflow-y-auto p-6">
          <div className="max-w-3xl mx-auto">
            <h1 className="text-3xl font-bold mb-6">{book.title}</h1>
            
            <div className="prose prose-blue max-w-none">
              <div className="mb-8">
                <h2 className="text-xl font-semibold mb-4">Introduction</h2>
                <div className="whitespace-pre-wrap">
                  {book.introduction.split('\n\n').map((paragraph, i) => (
                    <p key={i} className="mb-4">{paragraph}</p>
                  ))}
                </div>
              </div>
              
              {filteredChapters.map((chapter, index) => (
                <div 
                  key={index} 
                  id={`chapter-${index}`}
                  className={`mb-10 p-4 border rounded-lg ${expandedChapters.has(index) ? '' : 'border-dashed'}`}
                >
                  <div 
                    className="flex items-center cursor-pointer"
                    onClick={() => toggleChapter(index)}
                  >
                    {expandedChapters.has(index) ? 
                      <ChevronDown className="w-5 h-5 mr-2" /> : 
                      <ChevronRight className="w-5 h-5 mr-2" />
                    }
                    <h2 className="text-2xl font-bold">{index + 1}. {chapter.title}</h2>
                  </div>
                  
                  {expandedChapters.has(index) && (
                    <div className="mt-4 whitespace-pre-wrap">
                      {chapter.content.split('\n\n').map((paragraph, i) => {
                        // Check if paragraph is a heading
                        if (paragraph.startsWith('# ')) {
                          return <h2 key={i} className="text-xl font-semibold mt-6 mb-4">{paragraph.substring(2)}</h2>;
                        } else if (paragraph.startsWith('## ')) {
                          return <h3 key={i} className="text-lg font-semibold mt-5 mb-3">{paragraph.substring(3)}</h3>;
                        } else if (paragraph.startsWith('### ')) {
                          return <h4 key={i} className="text-md font-semibold mt-4 mb-2">{paragraph.substring(4)}</h4>;
                        }
                        
                        // Check if paragraph is a code block
                        if (paragraph.startsWith('```')) {
                          const lines = paragraph.split('\n');
                          const language = lines[0].substring(3).trim();
                          const code = lines.slice(1, -1).join('\n');
                          
                          return (
                            <div key={i} className="bg-gray-100 p-4 rounded-md my-4 overflow-x-auto">
                              <pre><code className={`language-${language}`}>{code}</code></pre>
                            </div>
                          );
                        }
                        
                        // Regular paragraph
                        return <p key={i} className="mb-4">{paragraph}</p>;
                      })}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
