const friendlyNames: Record<string, string> = {};
export function setFriendlyNames(names: Record<string, string>) { Object.assign(friendlyNames, names); }
export function getFriendlyNames(): Record<string, string> { return friendlyNames; }
export function getFriendlyName(key: string): string { return friendlyNames[key] || key; }
