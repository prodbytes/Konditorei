import { json, type RequestHandler } from '@sveltejs/kit';
import { getCounts, applyVote } from '$lib/server/votes';
import type { FrameId } from '$lib/patches';

export const GET: RequestHandler = ({ params }) => json(getCounts(params.match!));

export const POST: RequestHandler = async ({ params, request }) => {
	const { from, to } = (await request.json()) as {
		from: FrameId | null;
		to: FrameId | null;
	};
	return json(applyVote(params.match!, from ?? null, to ?? null));
};
