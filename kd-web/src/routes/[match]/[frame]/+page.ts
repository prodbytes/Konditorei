import { error } from '@sveltejs/kit';
import type { FrameId } from '$lib/patches';

const map: Record<string, FrameId> = { a: 'frameA', b: 'frameB' };

export const load = ({ params }: { params: { frame: string } }) => {
	const solo = map[params.frame.toLowerCase()];
	if (!solo) error(404, `Unknown frame "${params.frame}" — use /A or /B`);
	return { solo };
};
