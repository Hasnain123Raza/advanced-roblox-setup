/**
 * Builds a greeting for a script or player.
 *
 * @param name - Who is being greeted.
 * @returns The greeting text.
 * @example
 * ```ts
 * makeGreeting("main.server.ts"); // "Hello from main.server.ts!"
 * ```
 */
export function makeGreeting(name: string): string {
	return `Hello from ${name}!`;
}
