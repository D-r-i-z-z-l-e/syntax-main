#!/bin/bash

# Create backup
echo "Creating backup..."
cp src/lib/stores/conversation.ts ./backups/conversation.ts.bak 2>/dev/null || true

# Update the store with proper TypeScript typing
echo "Updating conversation store..."

# Find the generateArchitectLevel3 function and update it
sed -i.bak '
/generateArchitectLevel3: async () => {/,/}\,/c\
  generateArchitectLevel3: async () => {\
    const state = get();\
    const { level1Output, level2Output } = state.architect;\
    const requirements = state.context.extractedInfo.requirements;\
\
    const missing: string[] = [];\
    if (!level1Output?.visionText) missing.push('\''architectural vision'\'');\
    if (!level2Output?.rootFolder) missing.push('\''folder structure'\'');\
    if (!requirements?.length) missing.push('\''requirements'\'');\
\
    if (missing.length > 0) {\
      set(state => ({\
        architect: {\
          ...state.architect,\
          error: `Missing required input for level 3: ${missing.join('\'', '\'')}`,\
        }\
      }));\
      return;\
    }\
\
    try {\
      set(state => ({\
        architect: {\
          ...state.architect,\
          isThinking: true,\
          error: null,\
          level3Output: null\
        }\
      }));\
\
      const response = await fetch('\''/api/architect'\'', {\
        method: '\''POST'\'',\
        headers: { '\''Content-Type'\'': '\''application/json'\'' },\
        body: JSON.stringify({\
          level: 3,\
          requirements,\
          visionText: level1Output.visionText,\
          folderStructure: level2Output\
        }),\
      });\
\
      if (!response.ok) {\
        throw new Error(`Failed to generate implementation plan: ${response.statusText}`);\
      }\
\
      const data = await response.json();\
      set(state => ({\
        architect: {\
          ...state.architect,\
          level3Output: data,\
          currentLevel: 3,\
          isThinking: false\
        }\
      }));\
    } catch (error) {\
      console.error('\''Error generating architect level 3:'\'', error);\
      set(state => ({\
        architect: {\
          ...state.architect,\
          error: error instanceof Error ? error.message : '\''Failed to generate implementation plan'\'',\
          isThinking: false\
        }\
      }));\
    }\
  },
' src/lib/stores/conversation.ts

# Make the script executable
