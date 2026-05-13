const friendlyNames: Record<string, string> = {};
let _devMode = false;

export function setFriendlyNames(names: Record<string, string>) { Object.assign(friendlyNames, names); }
export function getFriendlyNames(): Record<string, string> { return friendlyNames; }
export function getFriendlyName(key: string): string { return friendlyNames[key] || key; }
export function isDevMode(): boolean { return _devMode; }
export function setDevMode(v: boolean) { _devMode = v; }
