/**
 * Debug utility for logging structured data with truncation for large values
 */
export function debugLog(component: string, action: string, data: any, maxLength = 200) {
  console.log(`[${component}] ${action}:`, 
    JSON.stringify(data, (key, value) => {
      if (typeof value === 'string' && value.length > maxLength) {
        return value.substring(0, maxLength) + '...';
      }
      return value;
    }, 2)
  );
}

/**
 * Helper to truncate strings for debugging
 */
export function truncate(str: string, maxLength = 100) {
  if (!str) return str;
  return str.length > maxLength ? str.substring(0, maxLength) + '...' : str;
}
