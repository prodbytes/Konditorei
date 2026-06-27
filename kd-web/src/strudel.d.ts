// @strudel/web and @strudel/hydra ship no type declarations.
declare module '@strudel/web' {
	export function initStrudel(options?: {
		prebake?: () => void | Promise<void>;
		[key: string]: unknown;
	}): Promise<unknown>;
	export function evaluate(code: string, autostart?: boolean): Promise<unknown>;
	export function hush(): void;
	export function samples(url: string): Promise<unknown>;
	export function getAudioContext(): AudioContext;
}

declare module '@strudel/hydra' {
	export function initHydra(options?: Record<string, unknown>): Promise<unknown>;
}
