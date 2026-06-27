<script lang="ts">
	import Editor from '$lib/Editor.svelte';

	let starred = $state<'green' | 'blue' | null>(null);
	let selected = $state<'green' | 'blue' | null>(null);
	let muted = $state(false);

	const greenCode = `// Strudel + Hydra — green side
await initHydra()

// kaleidoscopic oscillator
osc(18, 0.1, 0.9)
  .color(0.4, 0.9, 0.5)
  .kaleid(5)
  .rotate(0.1, 0.05)
  .modulate(noise(2))
  .out()

// dub techno groove
stack(
  note("c2 [eb2 g2] c2 g1").sound("sawtooth").lpf(700).room(0.3),
  s("bd*2, ~ hh, ~ cp").bank("RolandTR909")
).cpm(120)`;

	const blueCode = `// Strudel + Hydra — blue side
await initHydra()

// pulsing voronoi field
voronoi(6, 0.3, 0.2)
  .color(0.3, 0.5, 1.0)
  .scrollX(0.1)
  .repeat(2, 2)
  .modulateScale(osc(3), 0.2)
  .out()

// dreamy arpeggio
stack(
  n("0 2 4 6 7 6 4 2").scale("A:minor").sound("triangle").delay(0.4).room(0.5),
  s("bd ~ sd ~").bank("RolandTR808"),
  s("hh*8").gain(0.35)
).cpm(110)`;
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
				onclick={() => (muted = !muted)}
			>
				{muted ? '🔇' : '🔊'}
			</button>
		</div>
	</header>

	<div class="split">
		<div class="frame green">
		<div class="content">
			<Editor value={greenCode} />
		</div>
		<div class="status-bar">
			<span>Ready</span>
			<div class="actions">
				<button
					class="select"
					class:active={selected === 'green'}
					aria-pressed={selected === 'green'}
					onclick={() => (selected = 'green')}
				>
					Select
				</button>
				<button
					class="star"
					class:active={starred === 'green'}
					aria-pressed={starred === 'green'}
					onclick={() => (starred = 'green')}
				>
					★
				</button>
			</div>
		</div>
	</div>
	<div class="frame blue">
		<div class="content">
			<Editor value={blueCode} />
		</div>
		<div class="status-bar">
			<span>Ready</span>
			<div class="actions">
				<button
					class="select"
					class:active={selected === 'blue'}
					aria-pressed={selected === 'blue'}
					onclick={() => (selected = 'blue')}
				>
					Select
				</button>
				<button
					class="star"
					class:active={starred === 'blue'}
					aria-pressed={starred === 'blue'}
					onclick={() => (starred = 'blue')}
				>
					★
				</button>
			</div>
		</div>
	</div>
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
	}

	.content {
		flex: 1;
		min-height: 0;
		overflow: hidden;
	}

	.green {
		background: #b5e8b0;
	}

	.blue {
		background: #aecbeb;
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
