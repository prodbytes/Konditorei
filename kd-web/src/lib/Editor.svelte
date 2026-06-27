<script lang="ts">
	import { onMount } from 'svelte';
	import { EditorView, basicSetup } from 'codemirror';
	import { javascript } from '@codemirror/lang-javascript';
	import { oneDark } from '@codemirror/theme-one-dark';

	let { value = '' }: { value?: string } = $props();

	let container: HTMLDivElement;
	let view: EditorView;

	onMount(() => {
		view = new EditorView({
			doc: value,
			extensions: [basicSetup, javascript(), oneDark, EditorView.lineWrapping],
			parent: container
		});

		return () => view.destroy();
	});

	/** Current editor contents (falls back to the seed value before mount). */
	export function getValue(): string {
		return view ? view.state.doc.toString() : value;
	}

	/** Replace the editor contents (used for live shared-code updates). */
	export function setValue(next: string) {
		if (!view) return;
		const current = view.state.doc.toString();
		if (current === next) return;
		view.dispatch({ changes: { from: 0, to: current.length, insert: next } });
	}
</script>

<div class="editor" bind:this={container}></div>

<style>
	.editor {
		height: 100%;
		overflow: hidden;
	}

	.editor :global(.cm-editor) {
		height: 100%;
	}

	.editor :global(.cm-scroller) {
		overflow-y: auto;
		overflow-x: hidden;
		/* discrete scrollbar (Firefox) */
		scrollbar-width: thin;
		scrollbar-color: rgba(255, 255, 255, 0.2) transparent;
	}

	/* discrete scrollbar (WebKit/Chrome) */
	.editor :global(.cm-scroller)::-webkit-scrollbar {
		width: 8px;
	}

	.editor :global(.cm-scroller)::-webkit-scrollbar-track {
		background: transparent;
	}

	.editor :global(.cm-scroller)::-webkit-scrollbar-thumb {
		background: rgba(255, 255, 255, 0.18);
		border-radius: 4px;
	}

	.editor :global(.cm-scroller)::-webkit-scrollbar-thumb:hover {
		background: rgba(255, 255, 255, 0.3);
	}
</style>
