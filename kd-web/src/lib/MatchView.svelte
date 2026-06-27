<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import Frame from '$lib/Frame.svelte';
	import { codeA, codeB, codeFor, type FrameId } from '$lib/patches';
	import { randomSample } from '$lib/samples';

	let { matchId, solo = null }: { matchId: string; solo?: FrameId | null } = $props();

	// Absolute solo URLs so the QR codes open each side on another device.
	// Uses the host you're actually viewing from (use the machine's LAN IP,
	// not localhost, for the QR to be reachable from a phone).
	const soloUrl = (frame: FrameId) =>
		`${$page.url.origin}/${matchId}/${frame === 'frameA' ? 'A' : 'B'}`;

	const ROTATE_SECONDS = 30;

	let starred = $state<FrameId | null>(null);
	let stars = $state<Record<FrameId, number>>({ frameA: 0, frameB: 0 });
	let selected = $state<FrameId | null>(null);

	const voteKey = $derived(`kd-vote-${matchId}`);

	// One star vote per user (persisted per match in this browser so it carries
	// between the solo and dual views). Counts live in shared server memory and
	// stream back via SSE, so a star here reflects everywhere watching this match.
	async function vote(frame: FrameId) {
		const from = starred;
		const to = starred === frame ? null : frame;
		starred = to;
		try {
			if (to) localStorage.setItem(voteKey, to);
			else localStorage.removeItem(voteKey);
		} catch {
			// ignore storage failures (private mode, etc.)
		}
		await fetch(`/api/votes/${matchId}`, {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ from, to })
		});
	}
	let muted = $state(false);
	let playing = $state(false);
	let remaining = $state(ROTATE_SECONDS);
	let paused = $state(false);

	const fmtTime = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

	let frameRefA = $state<Frame>();
	let frameRefB = $state<Frame>();
	const refFor = (frame: FrameId) => (frame === 'frameA' ? frameRefA : frameRefB);

	// Lazy, client-only import — @strudel/web touches `window` at load.
	let engine: typeof import('$lib/strudel') | null = null;
	async function getEngine() {
		if (!engine) engine = await import('$lib/strudel');
		return engine;
	}

	async function select(frame: FrameId) {
		selected = frame;
		playing = true;
		remaining = ROTATE_SECONDS; // restart the countdown on every (re)selection
		const code = refFor(frame)?.getValue() ?? codeFor(frame);
		const { playCode } = await getEngine();
		await playCode(code);
	}

	// Play/pause the selected frame. Clicking an unselected frame plays it.
	async function togglePlay(frame: FrameId) {
		if (selected === frame && playing) {
			playing = false;
			const { stopAudio } = await getEngine();
			stopAudio();
		} else {
			await select(frame);
		}
	}

	async function toggleMute() {
		muted = !muted;
		const { setMuted } = await getEngine();
		setMuted(muted);
	}

	// Opening a frame in another tab: mute this one so they don't overlap.
	// (The QR link handles the actual navigation to the new tab.)
	async function muteForQr() {
		if (muted) return;
		muted = true;
		const { setMuted } = await getEngine();
		setMuted(true);
	}

	// Switch to the other frame (select() restarts the countdown). Dual view only.
	function flip() {
		select(selected === 'frameA' ? 'frameB' : 'frameA');
	}

	function toggleTimer() {
		paused = !paused;
	}

	// Live shared star counts via Server-Sent Events.
	let votes: EventSource | undefined;
	onDestroy(() => votes?.close());

	// Live shared frame code via Server-Sent Events.
	let codes: EventSource | undefined;
	onDestroy(() => codes?.close());

	function applyCode(frame: FrameId, code: string) {
		const ref = frame === 'frameA' ? frameRefA : frameRefB;
		ref?.setValue(code);
	}

	// Load a random sample into the editor, share it, and play it.
	async function gen(frame: FrameId) {
		const ref = refFor(frame);
		const sample = randomSample(ref?.getValue());
		ref?.setValue(sample);
		await publish(frame); // store it server-side so QR/URL opens load the same code
		await select(frame); // select() reads the editor's (new) contents and plays
	}

	// Publish the solo editor's current code to shared memory (and every editor).
	async function publish(frame: FrameId) {
		const code = refFor(frame)?.getValue();
		if (code == null) return;
		await fetch(`/api/codes/${matchId}`, {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ frame, code })
		});
	}

	let ticker: ReturnType<typeof setInterval> | undefined;
	function startTicker() {
		if (ticker || solo) return; // no rotation in solo view
		ticker = setInterval(() => {
			if (paused || !playing || selected === null) return;
			remaining -= 1;
			if (remaining <= 0) flip();
		}, 1000);
	}
	onDestroy(() => clearInterval(ticker));

	onMount(async () => {
		// Restore this browser's vote for the match and subscribe to live counts.
		try {
			const saved = localStorage.getItem(voteKey);
			if (saved === 'frameA' || saved === 'frameB') starred = saved;
		} catch {
			// ignore storage failures
		}
		votes = new EventSource(`/api/votes/${matchId}/stream`);
		votes.onmessage = (e) => (stars = JSON.parse(e.data));

		// Sync editor contents with shared memory (initial snapshot + live updates).
		codes = new EventSource(`/api/codes/${matchId}/stream`);
		codes.onmessage = (e) => {
			const c = JSON.parse(e.data) as { frameA: string; frameB: string };
			if (solo === null || solo === 'frameA') applyCode('frameA', c.frameA);
			if (solo === null || solo === 'frameB') applyCode('frameB', c.frameB);
		};

		const engine = await getEngine();
		await engine.initAudioEngine();
		engine.stopAudio(); // clear any leftover/stacked audio first

		// Load this match's current code (a fresh match is seeded server-side
		// with two different random sample patches).
		try {
			const c = (await (await fetch(`/api/codes/${matchId}`)).json()) as {
				frameA: string;
				frameB: string;
			};
			if (solo === null || solo === 'frameA') applyCode('frameA', c.frameA);
			if (solo === null || solo === 'frameB') applyCode('frameB', c.frameB);
		} catch {
			// fall back to whatever seed values the editors already hold
		}

		// Autoplay is unreliable in browsers, so both frames start paused (the
		// Play button is shown). Pressing Play starts that frame and the
		// rotation countdown; the ticker idles here until then.
		startTicker();
	});

	const timeFor = (frame: FrameId) =>
		fmtTime(selected === frame ? remaining : ROTATE_SECONDS);
</script>

<div class="app">
	<header class="topbar">
		<span class="brand">
			<a href="/" title="Start a new match">Konditorei</a>
			<span class="match-id">
				<a href={`/${matchId}`} title="Open the full match">{matchId}</a>{#if solo}
					/ <a
						href={`/${matchId}/${solo === 'frameA' ? 'A' : 'B'}`}
						title="Open this frame's editor">{solo === 'frameA' ? 'A' : 'B'}</a
					>{/if}
			</span>
		</span>
		<div class="global-actions">
			<a
				class="doclink"
				href="https://strudel.cc/learn/"
				target="_blank"
				rel="noopener"
				title="Strudel documentation"
			>
				Docs
			</a>
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
		{#if solo === null || solo === 'frameA'}
			<Frame
				bind:this={frameRefA}
				frame="frameA"
				code={codeA}
				qrData={soloUrl('frameA')}
				selected={selected === 'frameA'}
				playing={selected === 'frameA' && playing}
				starred={starred === 'frameA'}
				stars={stars.frameA}
				{muted}
				{paused}
				time={timeFor('frameA')}
				showTimer={solo === null}
				dim={selected !== null && selected !== 'frameA'}
				onplay={() => togglePlay('frameA')}
				onstar={() => vote('frameA')}
				onqr={muteForQr}
				onpublish={solo === 'frameA' ? () => publish('frameA') : undefined}
				ongen={solo === 'frameA' ? () => gen('frameA') : undefined}
				ontoggletimer={toggleTimer}
			/>
		{/if}
		{#if solo === null || solo === 'frameB'}
			<Frame
				bind:this={frameRefB}
				frame="frameB"
				code={codeB}
				qrData={soloUrl('frameB')}
				selected={selected === 'frameB'}
				playing={selected === 'frameB' && playing}
				starred={starred === 'frameB'}
				stars={stars.frameB}
				{muted}
				{paused}
				time={timeFor('frameB')}
				showTimer={solo === null}
				dim={selected !== null && selected !== 'frameB'}
				onplay={() => togglePlay('frameB')}
				onstar={() => vote('frameB')}
				onqr={muteForQr}
				onpublish={solo === 'frameB' ? () => publish('frameB') : undefined}
				ongen={solo === 'frameB' ? () => gen('frameB') : undefined}
				ontoggletimer={toggleTimer}
			/>
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

	.brand a {
		color: inherit;
		text-decoration: none;
	}

	.brand a:hover {
		text-decoration: underline;
	}

	.match-id {
		font-weight: 400;
		font-size: 0.7rem;
		opacity: 0.6;
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

	.doclink {
		display: flex;
		align-items: center;
		background: #3a3a3a;
		border: 1px solid #4a4a4a;
		border-radius: 0.25rem;
		color: #ddd;
		text-decoration: none;
		padding: 0.1rem 0.5rem;
		font-size: 0.75rem;
		line-height: 1.6;
		transition: background 0.15s;
	}

	.doclink:hover {
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
</style>
