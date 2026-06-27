import type { RequestHandler } from '@sveltejs/kit';
import { getCounts, subscribe, type Counts } from '$lib/server/votes';

// Server-Sent Events: pushes the current tally on connect and on every change.
export const GET: RequestHandler = ({ params }) => {
	const match = params.match!;
	const encoder = new TextEncoder();
	let unsubscribe: (() => void) | undefined;

	const stream = new ReadableStream({
		start(controller) {
			const send = (c: Counts) => controller.enqueue(encoder.encode(`data: ${JSON.stringify(c)}\n\n`));
			send(getCounts(match)); // initial snapshot
			unsubscribe = subscribe(match, send);
		},
		cancel() {
			unsubscribe?.();
		}
	});

	return new Response(stream, {
		headers: {
			'content-type': 'text/event-stream',
			'cache-control': 'no-cache',
			connection: 'keep-alive'
		}
	});
};
