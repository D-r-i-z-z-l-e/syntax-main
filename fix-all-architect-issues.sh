#!/bin/bash

echo "Starting comprehensive fix for architect feature..."

# Apply all changes
echo "Applying architecture type definitions..."
cp src/lib/types/architect.ts src/lib/types/architect.ts.bak
cat src/lib/types/architect.ts > src/lib/types/architect.ts

echo "Applying architect service implementation..."
cp src/lib/services/architect.service.ts src/lib/services/architect.service.ts.bak
cat src/lib/services/architect.service.ts > src/lib/services/architect.service.ts

echo "Applying API route changes..."
cp src/app/api/architect/route.ts src/app/api/architect/route.ts.bak
cat src/app/api/architect/route.ts > src/app/api/architect/route.ts

echo "Applying store changes..."
cp src/lib/stores/conversation.ts src/lib/stores/conversation.ts.bak
cat src/lib/stores/conversation.ts > src/lib/stores/conversation.ts

echo "Applying UI component changes..."
cp src/components/conversation/ArchitectOutput.tsx src/components/conversation/ArchitectOutput.tsx.bak
cat src/components/conversation/ArchitectOutput.tsx > src/components/conversation/ArchitectOutput.tsx

echo "Creating debug utility..."
mkdir -p src/lib/utils
cat src/lib/utils/debug.ts > src/lib/utils/debug.ts

echo "All files have been updated!"
echo "To apply the changes, please restart your development server."
echo "Done!"

# Make the script executable
chmod +x $0
