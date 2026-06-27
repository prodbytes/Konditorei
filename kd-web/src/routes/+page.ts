import { redirect } from '@sveltejs/kit';
import { generateMatchId } from '$lib/matchId';

// Visiting the root starts a new match: redirect to a generated match id so
// each frameA-vs-frameB session has its own trackable URL.
export const load = () => {
	redirect(307, `/${generateMatchId()}`);
};
