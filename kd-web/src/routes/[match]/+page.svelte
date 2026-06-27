<script lang="ts">
	import { page } from '$app/stores';
	import MatchView from '$lib/MatchView.svelte';
</script>

<!-- Remount per match id so a new match initializes fresh frame buffers/code. -->
{#key $page.params.match}
	<MatchView matchId={$page.params.match ?? ''} />
{/key}
