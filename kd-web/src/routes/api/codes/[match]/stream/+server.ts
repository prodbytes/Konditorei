import type { RequestHandler } from '@sveltejs/kit';
import { getCodes, subscribe, type Codes } from '$lib/server/codes';

// Server-Sent Events: pushes the current frame code on connect and on change.
export const GET: RequestHandler = ({ params }) => {
	const match = params.match!;
	const encoder = new TextEncoder();
	let unsubscribe: (() => void) | undefined;

	const stream = new ReadableStream({
		start(controller) {
			const send = (c: Codes) => controller.enqueue(encoder.encode(`data: ${JSON.stringify(c)}\n\n`));
			send(getCodes(match)); // initial snapshot
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
