# Prototype

Take one described piece of UI ("a toast", "the pricing card", "a hold-to-delete button"), build several different versions of it, and put them behind a picker so that the user can flip through them live and choose one.

The value of this job is divergence. Three tints of one idea teach the user nothing. Each variant is a direction that could ship on its own and answers the same brief differently. Every variant also meets `references/motion.md` and `references/foundations.md`: a sloppy variant loses on execution and says nothing about its direction.

## Rules

1. Production code stays untouched during exploration. Everything lives in an isolated prototype surface (step 4). Integration happens only in step 6, and only for the variant the user picked.
2. Variants differ on a named axis: layout, density, personality, motion or interaction model. Sharing the project's tokens is expected, since every variant should look like it could ship in this product tomorrow.
3. Every variant works: real interactions, real motion, realistic product copy and numbers. No lorem ipsum and no dead buttons.
4. The picker is harness chrome. Its markup, styles and behavior are specified in `references/picker.md`. Copy them as written and do not restyle the picker.
5. When a variant is promoted, delete the prototype surface unless the user asks to keep it.

## Steps

1. **Scope.** One piece per run. If the request spans several components ("the dashboard"), pick the one with the most leverage, say which and why, and offer the rest as later runs. Restate the brief in one sentence: what it is, where it lives, what it must do.
2. **Recon.** Note the framework, the styling system and the motion library, the tokens, the product's personality (it limits how far the boldest variant may go) and the context the piece renders in: background, neighbors, sizes. With no project (an empty directory, or a user who is only exploring), use the standalone branch in step 4 and a restrained default look: neutral grays, one accent, the system font stack.
3. **Choose directions.** Three variants by default, up to five when the user asks or the design space is wide. Before writing code, list a name and an axis for each. Names describe the direction ("Quiet", "Editorial", "Playful", "Dense"), never "Option A". Two directions that differ only in accent color or copy are one direction: replace one.
4. **Build the harness.** Choose the branch by what exists:
   - In a project with a dev server: an isolated route or page (`/prototypes/<slug>` or the framework's equivalent), with one file per variant and a small harness file. Nothing in the app imports from it.
   - With no project: one self-contained HTML file with inline CSS and JavaScript that opens directly in a browser.

   Load `references/picker.md` and build the picker from it. The harness renders one variant at a time, at full size, in realistic surrounding context: a toast needs a page behind it, a card needs siblings, a button needs a form. Side-by-side thumbnails distort spacing and scale. Switching variants is instant, with no transition.
5. **Check and hand off.** Run the harness, flip through every variant, and confirm that each renders, each interaction responds and the console is clean. If browser tooling is available, screenshot each variant. Then present this table and stop. The choice is the user's.

   | # | Variant | Axis | When it is the right choice | Its cost |
   |---|---|---|---|---|
   | 1 | Quiet | Minimal motion, borders over shadows | The product is a daily-use tool | Least memorable |
   | 2 | Editorial | Large type, generous whitespace | The moment deserves weight | Eats vertical space |

   Close with where the picker is running (URL or file path) and the keys that flip variants.
6. **Promote.** When the user picks, integrate that variant where it belongs, following the project's conventions for file layout, naming and tokens, then delete the prototype surface. When the user wants another round, keep the harness and return to step 3 with directions that diverge around the one they liked.

## Requests

| Request | Behavior |
|---|---|
| A description | All six steps with three variants, then wait for the choice |
| A description with a count ("x5") | The same with that many variants, at most five |
| "riff on Editorial" | A new round: keep the harness and build a fresh set that diverges around that variant |
| "keep Quiet" | Promote that variant and delete the prototype surface |
| "keep Quiet, leave the picker" | Promote it and keep the prototype surface |

## Presenting variants

Give each variant one line on when it wins and one on what it costs. Do not name a favorite in the table. If the user asks which you would choose, answer from the product's personality and how often the piece is used. If two variants converged while you built them, cut one and say so: two distinct directions teach more than three padded ones.
