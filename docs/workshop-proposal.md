# Battle of the Strudels — A Live-Coding Music Workshop

> **Format:** Hands-on workshop · **Duration:** 90 minutes (also available as a 3-hour deep dive)
> **Track:** Creative coding / Live coding / Music technology / Web
> **Level:** Beginner-friendly — no music theory or live-coding experience required
> **Capacity:** 15–60 participants · **Hardware:** One laptop per person or per pair; a phone is a bonus

---

## Tagline

Two editors. One stage. Thirty seconds on the clock. Learn [Strudel](https://strudel.cc) — the
browser-native live-coding language for music — by going head-to-head in a friendly beat battle
where the whole room codes, listens, and votes.

## Abstract

Most introductions to live coding stall at the same place: a blank editor, a silent room, and the
quiet fear of typing the wrong thing in front of strangers. **Konditorei** turns that anxiety into a
game. It's a head-to-head "music battle" built on Strudel (sound) and Hydra (visuals), where two
sides — **Frame A** and **Frame B** — trade four-bar ideas while a 30-second timer flips the
spotlight between them and the audience stars their favorite.

In this workshop, participants don't watch a lecture about live coding — they *do* live coding from
minute three. We scaffold Strudel one concept at a time (a sound, a rhythm, a melody, an effect, a
visual), and after each concept the room immediately puts it into the ring. By the end, every
participant has written, performed, and "shipped" a pattern that played on the main screen — and
they leave with a URL they can keep hacking on after they walk out.

The battle framing does real pedagogical work: the timer enforces small, fast iterations (the single
most important live-coding skill); the A/B split makes it safe to experiment because *someone else's
code is always also on stage*; and the audience vote turns listening into active, critical practice.

## Why this works (and why it's different)

- **Sound on the first try.** Strudel runs entirely in the browser — no installs, no toolchains,
  no audio-driver yak-shaving. Open a URL and you have a synth.
- **Failure is cheap and funny.** In a battle, a broken bar is a missed punch, not a catastrophe.
  Laughter lowers the stakes; lowered stakes accelerate learning.
- **Everyone participates, not just the brave.** Spectators scan a QR code to open one side on their
  own phone or laptop, fork the pattern, and submit their version back to the shared stage. The
  "audience" and the "performers" are the same people.
- **Constraints teach.** A 30-second rotation is a teacher in disguise: it rewards the habit of
  changing one thing, hearing it, and keeping it — the loop at the heart of all live coding.

## Learning objectives

By the end of the session, participants will be able to:

1. Trigger and sequence sounds in Strudel using mini-notation (`"bd ~ sd ~"`, `*`, `<>`, `[]`).
2. Build a layered pattern with `stack`, samples (`s`, `bank`), and notes (`note`, `n`, `scale`).
3. Shape sound with common effects (`lpf`, `room`, `gain`, `delay`) and control tempo (`cpm`).
4. Add a reactive Hydra visual (`osc`, `voronoi`, `.out()`) driven alongside the music.
5. Iterate *live* — evaluate, listen, and revise in tight loops under gentle time pressure.
6. Share and remix a pattern with others in real time.

## Who should attend

Curious beginners, web developers, musicians-who-don't-code, coders-who-don't-make-music,
educators looking for an engaging CS-through-art activity, and anyone who has watched an algorave and
thought "I could never do that." Pairs are welcome and encouraged — one drives, one heckles, swap
often.

**Prerequisites:** A laptop with a modern browser (Chrome/Firefox/Edge) and headphones or a
willingness to share the room's speakers. No prior Strudel, JavaScript, or music theory needed.

## Session outline (90 minutes)

| Time | Segment | What happens |
|------|---------|--------------|
| 0:00–0:05 | **Drop in** | Everyone opens the match URL; the room is making noise within minutes. No slides yet. |
| 0:05–0:15 | **A sound** | Mini-notation basics: one drum, then a beat. First "ring" — half the room on Frame A, half on B. |
| 0:15–0:30 | **A groove** | `stack`, samples, `bank`, tempo. Build a two-layer loop. Battle round 1, audience votes. |
| 0:30–0:45 | **A melody** | `note`/`n`, `scale`, and why `<>` and `*` are your best friends. Battle round 2. |
| 0:45–1:00 | **A vibe** | Effects: `lpf`, `room`, `delay`, `gain`. Turning a loop into a *feeling*. Battle round 3. |
| 1:00–1:10 | **A picture** | A 4-line Hydra visual layered behind the sound. The stage gets cinematic. |
| 1:10–1:25 | **The Grand Battle** | Open format. Teams iterate; the 30s timer flips the spotlight; the room stars the winner. |
| 1:25–1:30 | **Take it home** | Where to learn more, how to keep your URL, the Strudel/TidalCycles community, next steps. |

*(3-hour version adds: drum-machine deep dive, polyrhythms and Euclidean rhythms, signals & LFOs,
song structure with `arrange`, custom samples, and a longer collaborative performance.)*

## What participants take home

- A working Strudel pattern they wrote and performed, saved at a shareable URL.
- A mental model of the live-coding loop they can apply in any environment.
- A one-page cheat sheet of the functions covered.
- Links into the Strudel and TidalCycles communities to keep going.

## The tool: how Konditorei works

Konditorei is a small open-source web app (SvelteKit + Strudel + Hydra) we built specifically to run
this workshop. It is the workshop's "stage":

- **Two live editors side by side** — Frame A and Frame B — each a full code editor with syntax
  highlighting, running real Strudel + Hydra.
- **A 30-second rotation timer** that flips which side is "live," with a one-click pause so the
  facilitator can stop and teach at any moment.
- **Join from anywhere:** each side shows a QR code that opens *that* frame on a phone or second
  laptop. Tapping it mutes your current tab so the room never turns into feedback soup.
- **A shared stage:** code and audience star-votes live in shared memory keyed by a human-friendly
  **match ID** (e.g. `funky-zippy-banjo`). Edit on your phone, hit **Update**, and your code appears
  on the main screen and every other open editor instantly.
- **Audience voting:** spectators star the side they like; tallies update live across every device
  watching the match.

Because each session has its own match ID, you can run several simultaneous battles (great for
breakout groups) and keep them cleanly separated. The app is browser-only and requires no accounts.

## Facilitator requirements

- A projector/screen with audio for the "main stage" (the facilitator's laptop running the match).
- Reliable local network or internet (Strudel loads samples and Hydra from CDNs).
- Optional: a small Bluetooth speaker per breakout group for the 3-hour version.

## What we provide

- The hosted match URL (or a local server for offline venues).
- Printable cheat sheets and the slide-free "concept cards."
- The open-source repository, so attendees and other educators can run their own battles afterward.

## About the facilitator(s)

*[Your name], [role/affiliation].* [One or two sentences on your background in live coding, music,
education, or web development, and any prior Strudel/TidalCycles/algorave experience. Mention that
Konditorei is your own open-source project built for teaching.]

## A note on accessibility & inclusion

The battle is explicitly **non-elimination and team-friendly**: nobody is put on the spot alone, code
is shared so no one starts from a blank page, and "winning" is a show of hands, not a judgment of
skill. We actively encourage pairing, swapping drivers, and celebrating the weirdest result as much
as the cleanest one. Content is suitable for all ages; sample packs are curated to avoid explicit
material.

---

*Konditorei — German for "confectionery." Here, it's where you bake patterns. Bring your ears.*
