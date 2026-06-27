// In-memory, per-match star tallies shared across every connected view.
// (Server module — never shipped to the client. Resets when the server restarts.)
import type { FrameId } from '$lib/patches';

export type Counts = { frameA: number; frameB: number };

const store = new Map<string, Counts>();
const listeners = new Map<string, Set<(c: Counts) => void>>();

function ensure(match: string): Counts {
	let c = store.get(match);
	if (!c) {
		c = { frameA: 0, frameB: 0 };
		store.set(match, c);
	}
	return c;
}

export function getCounts(match: string): Counts {
	return { ...ensure(match) };
}

/** Move a vote from one frame to another (either side may be null). */
export function applyVote(match: string, from: FrameId | null, to: FrameId | null): Counts {
	const c = ensure(match);
	if (from) c[from] = Math.max(0, c[from] - 1);
	if (to) c[to] += 1;
	const snapshot = { ...c };
	listeners.get(match)?.forEach((fn) => fn(snapshot));
	return snapshot;
}

export function subscribe(match: string, fn: (c: Counts) => void): () => void {
	let set = listeners.get(match);
	if (!set) {
		set = new Set();
		listeners.set(match, set);
	}
	set.add(fn);
	return () => set!.delete(fn);
}
