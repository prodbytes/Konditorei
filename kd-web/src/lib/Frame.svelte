<script lang="ts">
	import Editor from '$lib/Editor.svelte';
	import QrCode from '$lib/QrCode.svelte';
	import type { FrameId } from '$lib/patches';

	let {
		frame,
		code,
		qrData,
		selected = false,
		playing = false,
		stars = 0,
		starred = false,
		muted = false,
		paused = false,
		time,
		showTimer = false,
		dim = false,
		onplay,
		onstar,
		onqr,
		onpublish,
		ongen,
		ontoggletimer
	}: {
		frame: FrameId;
		code: string;
		qrData: string;
		selected?: boolean;
		playing?: boolean;
		stars?: number;
		starred?: boolean;
		muted?: boolean;
		paused?: boolean;
		time: string;
		showTimer?: boolean;
		dim?: boolean;
		onplay: () => void;
		onstar: () => void;
		onqr: () => void;
		onpublish?: () => void;
		ongen?: () => void;
		ontoggletimer: () => void;
	} = $props();

	let editor: Editor;

	/** Current editor contents — read by the parent before playing. */
	export function getValue(): string {
		return editor ? editor.getValue() : code;
	}

	/** Replace the editor contents — used for live shared-code updates. */
	export function setValue(next: string) {
		editor?.setValue(next);
	}
</script>

<div class="frame {frame}" class:dim>
	<a
		class="qr-overlay"
		href={qrData}
		target="_blank"
		rel="noopener"
		title="Open this frame on another device (mutes here)"
		onclick={onqr}
	>
		<QrCode data={qrData} />
	</a>
	<div class="content">
		<Editor bind:this={editor} value={code} />
	</div>
	<div class="status-bar">
		<div class="status-left">
			{#if showTimer}
				<button
					class="timer"
					title={paused ? 'Resume timer' : 'Pause timer'}
					aria-pressed={paused}
					onclick={ontoggletimer}
				>
					{paused ? '▶' : '⏱'}
				</button>
				<span class="countdown">{time}</span>
			{/if}
			<span>{playing ? (muted ? 'Playing (muted)' : 'Playing') : 'Paused'}</span>
		</div>
		<div class="actions">
			{#if ongen}
				<button class="gen" title="Load a random sample patch and play it" onclick={ongen}>
					🎲 Gen
				</button>
			{/if}
			{#if onpublish}
				<button class="publish" title="Push this code to the match and all open editors" onclick={onpublish}>
					⬆ Update
				</button>
			{/if}
			<button
				class="select"
				class:active={playing}
				aria-pressed={playing}
				onclick={onplay}
			>
				{playing ? '⏸ Pause' : '▶ Play'}
			</button>
			<button
				class="star"
				class:active={starred}
				aria-pressed={starred}
				title={starred ? 'Remove your star' : 'Star this frame'}
				onclick={onstar}
			>
				★ <span class="star-count">{stars}</span>
			</button>
		</div>
	</div>
</div>

<style>
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
		right: 18px; /* clear the editor's scrollbar */
		z-index: 5;
		cursor: pointer;
		display: block;
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

	.publish {
		background: rgba(255, 255, 255, 0.15);
		border: 1px solid rgba(255, 255, 255, 0.4);
		border-radius: 0.25rem;
		cursor: pointer;
		padding: 0.2rem 0.6rem;
		color: white;
		font-family: inherit;
		font-size: 0.8rem;
		transition: background 0.15s;
	}

	.publish:hover {
		background: rgba(255, 255, 255, 0.25);
	}

	.gen {
		background: rgba(255, 255, 255, 0.15);
		border: 1px solid rgba(255, 255, 255, 0.4);
		border-radius: 0.25rem;
		cursor: pointer;
		padding: 0.2rem 0.6rem;
		color: white;
		font-family: inherit;
		font-size: 0.8rem;
		transition: background 0.15s;
	}

	.gen:hover {
		background: rgba(255, 255, 255, 0.25);
	}

	.select.active {
		background: white;
		color: black;
		border-color: white;
	}

	.star {
		display: inline-flex;
		align-items: center;
		gap: 0.25rem;
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

	.star-count {
		font-size: 0.85rem;
		font-variant-numeric: tabular-nums;
		color: white;
	}
</style>
