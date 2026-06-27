<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import Editor from '$lib/Editor.svelte';
	import QrCode from '$lib/QrCode.svelte';

	const ROTATE_SECONDS = 30;

	let starred = $state<'frameA' | 'frameB' | null>(null);
	let selected = $state<'frameA' | 'frameB' | null>(null);
	let muted = $state(false);
	let remaining = $state(ROTATE_SECONDS);
	let paused = $state(false);
	let needsStart = $state(false);

	const fmtTime = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

	let editorA: Editor;
	let editorB: Editor;

	// Lazy, client-only import — @strudel/web touches `window` at load.
	let engine: typeof import('$lib/strudel') | null = null;
	async function getEngine() {
		if (!engine) engine = await import('$lib/strudel');
		return engine;
	}

	async function select(frame: 'frameA' | 'frameB') {
		selected = frame;
		remaining = ROTATE_SECONDS; // restart the countdown on every (re)selection
		const code = frame === 'frameA' ? editorA.getValue() : editorB.getValue();
		const { playCode } = await getEngine();
		await playCode(code);
	}

	async function toggleMute() {
		muted = !muted;
		const { setMuted } = await getEngine();
		setMuted(muted);
	}

	// Switch to the other frame (select() restarts the countdown).
	function flip() {
		select(selected === 'frameA' ? 'frameB' : 'frameA');
	}

	function toggleTimer() {
		paused = !paused;
	}

	let ticker: ReturnType<typeof setInterval> | undefined;
	function startTicker() {
		if (ticker) return;
		ticker = setInterval(() => {
			if (paused || selected === null) return;
			remaining -= 1;
			if (remaining <= 0) flip();
		}, 1000);
	}
	onDestroy(() => clearInterval(ticker));

	// Click-to-start fallback when the browser blocks autoplay.
	async function start() {
		needsStart = false;
		const engine = await getEngine();
		await engine.resumeAudio();
		if (selected) await select(selected);
		startTicker();
	}

	// Auto-play a random side on load. Browsers may keep the audio context
	// suspended until the first user gesture, so visuals start immediately and
	// sound kicks in on the first interaction (e.g. clicking a Select button).
	onMount(async () => {
		const engine = await getEngine();
		await engine.initAudioEngine();
		engine.stopAudio(); // clear any leftover/stacked audio first
		await select(Math.random() < 0.5 ? 'frameA' : 'frameB');

		// Try to autostart. Browsers allow this for sites with prior engagement
		// (localhost during dev usually qualifies); otherwise show a start gate.
		const running = await engine.resumeAudio();
		if (running) startTicker();
		else needsStart = true;
	});

	const codeA = `// Strudel + Hydra — frame A
await initHydra()

// slow drifting haze
osc(4, 0.03, 0.3)
  .color(0.4, 0.8, 0.5)
  .rotate(0.04, 0.01)
  .modulate(noise(0.4))
  .out()

// mellow lo-fi dub
stack(
  note("<c2 g1 eb2 f1>").sound("sawtooth").lpf(380).gain(0.45).room(0.7).slow(2),
  note("<c4 eb4 g4 bb4>").sound("triangle").lpf(700).gain(0.3).room(0.8).slow(4),
  s("bd ~ ~ ~, ~ ~ rim ~").bank("RolandTR707").gain(0.35)
).cpm(58)`;

	const codeB = `// Strudel + Hydra — frame B
await initHydra()

// gentle voronoi drift
voronoi(3, 0.12, 0.1)
  .color(0.3, 0.5, 0.9)
  .scrollX(0.02)
  .modulateScale(osc(0.5), 0.1)
  .out()

// dusty lo-fi hip-hop
stack(
  n("0 ~ 2 ~ 3 ~ 2 ~").scale("D:minor:pentatonic").sound("piano").gain(0.4).lpf(1100).room(0.4),
  s("bd ~ ~ bd, ~ sd ~ ~").bank("RolandTR808").gain(0.4),
  s("hh*4").gain(0.18).lpf(2800)
).cpm(72)`;
</script>

<div class="app">
	<header class="topbar">
		<span class="brand">Konditorei</span>
		<div class="global-actions">
			<button
				class="mute"
				class:active={muted}
				aria-pressed={muted}
				title={muted ? 'Unmute' : 'Mute'}
				onclick={toggleMute}
			>
				{muted ? '🔇' : '🔊'}
			</button>
		</div>
	</header>

	<div class="split">
		<div class="frame frameA" class:dim={selected !== null && selected !== 'frameA'}>
		<div class="qr-overlay"><QrCode data={codeA} /></div>
		<div class="content">
			<Editor bind:this={editorA} value={codeA} />
		</div>
		<div class="status-bar">
			<div class="status-left">
				<button
					class="timer"
					title={paused ? 'Resume timer' : 'Pause timer'}
					aria-pressed={paused}
					onclick={toggleTimer}
				>
					{paused ? '▶' : '⏱'}
				</button>
				<span class="countdown">{fmtTime(remaining)}</span>
				<span>{selected === 'frameA' ? (muted ? 'Playing (muted)' : 'Playing') : 'Ready'}</span>
			</div>
			<div class="actions">
				<button
					class="select"
					class:active={selected === 'frameA'}
					aria-pressed={selected === 'frameA'}
					onclick={() => select('frameA')}
				>
					▶ Play
				</button>
				<button
					class="star"
					class:active={starred === 'frameA'}
					aria-pressed={starred === 'frameA'}
					onclick={() => (starred = 'frameA')}
				>
					★
				</button>
			</div>
		</div>
	</div>
	<div class="frame frameB" class:dim={selected !== null && selected !== 'frameB'}>
		<div class="qr-overlay"><QrCode data={codeB} /></div>
		<div class="content">
			<Editor bind:this={editorB} value={codeB} />
		</div>
		<div class="status-bar">
			<div class="status-left">
				<button
					class="timer"
					title={paused ? 'Resume timer' : 'Pause timer'}
					aria-pressed={paused}
					onclick={toggleTimer}
				>
					{paused ? '▶' : '⏱'}
				</button>
				<span class="countdown">{fmtTime(remaining)}</span>
				<span>{selected === 'frameB' ? (muted ? 'Playing (muted)' : 'Playing') : 'Ready'}</span>
			</div>
			<div class="actions">
				<button
					class="select"
					class:active={selected === 'frameB'}
					aria-pressed={selected === 'frameB'}
					onclick={() => select('frameB')}
				>
					▶ Play
				</button>
				<button
					class="star"
					class:active={starred === 'frameB'}
					aria-pressed={starred === 'frameB'}
					onclick={() => (starred = 'frameB')}
				>
					★
				</button>
			</div>
		</div>
	</div>

	{#if needsStart}
		<button class="start-overlay" onclick={start}>
			<span class="start-icon">▶</span>
			<span>Click to start</span>
		</button>
	{/if}
	</div>
</div>

<style>
	:global(html, body) {
		margin: 0;
		overflow: hidden;
	}

	.app {
		display: flex;
		flex-direction: column;
		height: 100vh;
		/* Own stacking layer above the fixed #hydra-canvas so the visuals
		   sit behind the UI instead of painting over the topbar/status bars. */
		position: relative;
		z-index: 1;
	}

	/* Keep hydra's fullscreen canvas behind the app layer. */
	:global(#hydra-canvas) {
		z-index: 0;
	}

	.topbar {
		display: flex;
		align-items: center;
		gap: 1rem;
		height: 30px;
		flex: 0 0 30px;
		padding: 0 0.6rem;
		background: #2b2b2b;
		border-bottom: 1px solid #1a1a1a;
		color: #ddd;
		font-family: sans-serif;
		font-size: 0.8rem;
	}

	.brand {
		font-weight: 600;
		letter-spacing: 0.02em;
	}

	.global-actions {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		margin-left: auto;
	}

	.topbar button {
		display: flex;
		align-items: center;
		justify-content: center;
		background: #3a3a3a;
		border: 1px solid #4a4a4a;
		border-radius: 0.25rem;
		color: #ddd;
		cursor: pointer;
		padding: 0.1rem 0.35rem;
		font-family: inherit;
		font-size: 0.75rem;
		line-height: 1;
		transition: background 0.15s;
	}

	.topbar button:hover {
		background: #484848;
	}

	.topbar .mute.active {
		background: #b5483f;
		border-color: #b5483f;
		color: white;
	}

	.split {
		display: flex;
		width: 100%;
		flex: 1;
		min-height: 0;
	}

	.frame {
		flex: 1;
		display: flex;
		flex-direction: column;
		transition: opacity 0.2s;
		position: relative;
	}

	.qr-overlay {
		position: absolute;
		top: 8px;
		right: 8px;
		z-index: 5;
		pointer-events: none;
	}

	/* Unselected frame reads as inactive; selected stays full strength. */
	.frame.dim {
		opacity: 0.4;
	}

	.content {
		flex: 1;
		min-height: 0;
		overflow: hidden;
	}

	/* Translucent tints so the fullscreen #hydra-canvas shows through. */
	.frameA {
		background: rgba(181, 232, 176, 0.25);
	}

	.frameB {
		background: rgba(174, 203, 235, 0.25);
	}

	/* Let the editor sit over the visuals with a readable dark scrim. */
	.content :global(.cm-editor),
	.content :global(.cm-gutters) {
		background: rgba(20, 22, 30, 0.55);
	}

	.status-bar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0.5rem 1rem;
		background: rgba(0, 0, 0, 0.4);
		color: white;
		font-family: sans-serif;
		font-size: 0.85rem;
	}

	.start-overlay {
		position: fixed;
		inset: 0;
		z-index: 100;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
		border: none;
		cursor: pointer;
		background: rgba(15, 16, 22, 0.7);
		backdrop-filter: blur(2px);
		color: white;
		font-family: sans-serif;
		font-size: 1.1rem;
		letter-spacing: 0.03em;
	}

	.start-icon {
		font-size: 3rem;
		line-height: 1;
	}

	.status-left {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.timer {
		background: none;
		border: none;
		cursor: pointer;
		padding: 0;
		line-height: 1;
		font-size: 1rem;
		color: rgba(255, 255, 255, 0.85);
	}

	.timer:hover {
		color: white;
	}

	.countdown {
		font-variant-numeric: tabular-nums;
		opacity: 0.85;
	}

	.actions {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.select {
		background: rgba(255, 255, 255, 0.15);
		border: 1px solid rgba(255, 255, 255, 0.4);
		border-radius: 0.25rem;
		cursor: pointer;
		padding: 0.2rem 0.6rem;
		color: white;
		font-family: inherit;
		font-size: 0.8rem;
		transition:
			background 0.15s,
			border-color 0.15s;
	}

	.select:hover {
		background: rgba(255, 255, 255, 0.25);
	}

	.select.active {
		background: white;
		color: black;
		border-color: white;
	}

	.star {
		background: none;
		border: none;
		cursor: pointer;
		padding: 0;
		line-height: 1;
		font-size: 1.1rem;
		color: rgba(255, 255, 255, 0.4);
		transition: color 0.15s;
	}

	.star:hover {
		color: rgba(255, 255, 255, 0.7);
	}

	.star.active {
		color: gold;
	}
</style>
