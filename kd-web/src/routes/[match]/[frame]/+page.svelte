<script lang="ts">
	import { page } from '$app/stores';
	import MatchView from '$lib/MatchView.svelte';

	let { data }: { data: { solo: 'frameA' | 'frameB' } } = $props();
</script>

<MatchView matchId={$page.params.match ?? ''} solo={data.solo} />
