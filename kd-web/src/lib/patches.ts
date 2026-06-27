// Seed Strudel + Hydra patches for each frame, shared across the dual and solo views.
export const codeA = `// Strudel + Hydra — frame A
await initHydra()

// slow drifting haze
osc(4, 0.03, 0.3)
  .color(0.4, 0.8, 0.5)
  .rotate(0.04, 0.01)
  .modulate(noise(0.4))
  .out()

// mellow lo-fi dub
stack(
  note("<c2 g1 eb2 f1>").sound("sawtooth").lpf(380).gain(0.45).room(0.7).slow(2),
  note("<c4 eb4 g4 bb4>").sound("triangle").lpf(700).gain(0.3).room(0.8).slow(4),
  s("bd ~ ~ ~, ~ ~ rim ~").bank("RolandTR707").gain(0.35)
).cpm(58)`;

export const codeB = `// Strudel + Hydra — frame B
await initHydra()

// gentle voronoi drift
voronoi(3, 0.12, 0.1)
  .color(0.3, 0.5, 0.9)
  .scrollX(0.02)
  .modulateScale(osc(0.5), 0.1)
  .out()

// dusty lo-fi hip-hop
stack(
  n("0 ~ 2 ~ 3 ~ 2 ~").scale("D:minor:pentatonic").sound("piano").gain(0.4).lpf(1100).room(0.4),
  s("bd ~ ~ bd, ~ sd ~ ~").bank("RolandTR808").gain(0.4),
  s("hh*4").gain(0.18).lpf(2800)
).cpm(72)`;

export type FrameId = 'frameA' | 'frameB';

export const codeFor = (frame: FrameId) => (frame === 'frameA' ? codeA : codeB);
