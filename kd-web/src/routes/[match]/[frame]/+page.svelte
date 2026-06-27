<script lang="ts">
	import { page } from '$app/stores';
	import MatchView from '$lib/MatchView.svelte';

	let { data }: { data: { solo: 'frameA' | 'frameB' } } = $props();
</script>

<!-- Remount when the match (or frame) changes so buffers/code reinitialize. -->
{#key `${$page.params.match}/${data.solo}`}
	<MatchView matchId={$page.params.match ?? ''} solo={data.solo} />
{/key}
