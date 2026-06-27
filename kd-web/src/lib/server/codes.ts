// In-memory, per-match frame code shared across every connected editor.
// (Server module — never shipped to the client. Resets when the server restarts.)
import { codeA, codeB, type FrameId } from '$lib/patches';

export type Codes = { frameA: string; frameB: string };

const store = new Map<string, Codes>();
const listeners = new Map<string, Set<(c: Codes) => void>>();

function ensure(match: string): Codes {
	let c = store.get(match);
	if (!c) {
		c = { frameA: codeA, frameB: codeB }; // seed defaults until someone publishes
		store.set(match, c);
	}
	return c;
}

export function getCodes(match: string): Codes {
	return { ...ensure(match) };
}

export function setCode(match: string, frame: FrameId, code: string): Codes {
	const c = ensure(match);
	c[frame] = code;
	const snapshot = { ...c };
	listeners.get(match)?.forEach((fn) => fn(snapshot));
	return snapshot;
}

export function subscribe(match: string, fn: (c: Codes) => void): () => void {
	let set = listeners.get(match);
	if (!set) {
		set = new Set();
		listeners.set(match, set);
	}
	set.add(fn);
	return () => set!.delete(fn);
}
