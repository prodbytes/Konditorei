// Strudel + Hydra sample patches, each living in its own file under
// ./sample-patches/*.strudel and loaded here as raw text (sorted by filename).
const modules = import.meta.glob('./sample-patches/*.strudel', {
	query: '?raw',
	import: 'default',
	eager: true
}) as Record<string, string>;

export const sampleLibrary: string[] = Object.keys(modules)
	.sort()
	.map((path) => modules[path].trim());

/** Pick a random sample, optionally avoiding an exact repeat of `not`. */
export function randomSample(not?: string): string {
	if (sampleLibrary.length <= 1) return sampleLibrary[0] ?? '';
	let pick = sampleLibrary[Math.floor(Math.random() * sampleLibrary.length)];
	while (pick === not) {
		pick = sampleLibrary[Math.floor(Math.random() * sampleLibrary.length)];
	}
	return pick;
}
