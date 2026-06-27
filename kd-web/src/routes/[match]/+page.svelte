<script lang="ts">
	import { page } from '$app/stores';
	import MatchView from '$lib/MatchView.svelte';
</script>

<MatchView matchId={$page.params.match ?? ''} />
