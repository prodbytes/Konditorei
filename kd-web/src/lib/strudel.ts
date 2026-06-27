// Client-only Strudel engine wrapper.
// NOTE: @strudel/web assigns to `window` at import time, so this module must
// only ever be imported dynamically from the browser (never during SSR).
import { initStrudel, evaluate, hush, samples, getAudioContext } from '@strudel/web';
import { initHydra } from '@strudel/hydra';

let ready: Promise<unknown> | null = null;
let muted = false;

/** Boot Strudel once: register sounds, load default samples, expose initHydra. */
export function initAudioEngine() {
	if (ready) return ready;

	// The evaluated code calls `initHydra()` — make it resolvable in that scope.
	(globalThis as Record<string, unknown>).initHydra = initHydra;

	ready = initStrudel({
		prebake: async () => {
			const ds = 'https://raw.githubusercontent.com/felixroos/dough-samples/main';
			await Promise.all([
				samples(`${ds}/tidal-drum-machines.json`),
				samples(`${ds}/piano.json`),
				samples(`${ds}/Dirt-Samples.json`),
				samples(`${ds}/EmuSP12.json`),
				samples(`${ds}/vcsl.json`)
			]);
		}
	});

	return ready;
}

/** Evaluate and play a block of Strudel code (audio + hydra visuals). */
export async function playCode(code: string) {
	await initAudioEngine();
	const ctx = getAudioContext();
	if (!muted && ctx.state === 'suspended') await ctx.resume();
	await evaluate(code);
}

/** Stop all audio and clear the current pattern (safe before init). */
export function stopAudio() {
	try {
		hush();
	} catch {
		// no repl yet — nothing to stop
	}
}

/** Resume the audio context. Returns true if audio is actually running after. */
export async function resumeAudio(): Promise<boolean> {
	const ctx = getAudioContext();
	if (!muted && ctx.state === 'suspended') {
		try {
			await ctx.resume();
		} catch {
			// blocked by autoplay policy — needs a user gesture
		}
	}
	return ctx.state === 'running';
}

/** Mute/unmute by suspending the audio context (hydra keeps animating). */
export function setMuted(value: boolean) {
	muted = value;
	const ctx = getAudioContext();
	if (value) ctx.suspend();
	else ctx.resume();
}
