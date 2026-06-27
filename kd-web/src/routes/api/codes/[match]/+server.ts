import { json, type RequestHandler } from '@sveltejs/kit';
import { getCodes, setCode } from '$lib/server/codes';
import type { FrameId } from '$lib/patches';

export const GET: RequestHandler = ({ params }) => json(getCodes(params.match!));

export const POST: RequestHandler = async ({ params, request }) => {
	const { frame, code } = (await request.json()) as { frame: FrameId; code: string };
	return json(setCode(params.match!, frame, code));
};
