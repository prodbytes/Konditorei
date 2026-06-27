<script lang="ts">
	import QRCode from 'qrcode';

	let { data, size = 72 }: { data: string; size?: number } = $props();

	let svg = $state('');

	$effect(() => {
		// Transparent background, soft-white modules so it overlays the visuals.
		QRCode.toString(data, {
			type: 'svg',
			margin: 0,
			errorCorrectionLevel: 'M',
			color: { dark: '#ffffffcc', light: '#00000000' }
		})
			.then((s) => (svg = s))
			.catch(() => (svg = ''));
	});
</script>

<div class="qr" style="width:{size}px;height:{size}px">{@html svg}</div>

<style>
	.qr {
		pointer-events: none;
	}

	.qr :global(svg) {
		display: block;
		width: 100%;
		height: 100%;
	}
</style>
