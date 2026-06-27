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
	}
</style>
