---
name: design-doctrine
description: The rules every design step follows — where the visual truth lives, derived versus new screens, what to do about gaps, what a mockup is for, and who measures contrast. Read by /po-design-system; preloaded by the later design and review steps.
---
# Design doctrine

A screen is composed from the project's recorded system, `docs/design-system.md`, not drawn from taste. These rules say how.

## Where the truth lives
The repository is the source of truth. A design tool, a mockup or a conversation never overrides what is committed: when they disagree with the code or with `docs/design-system.md`, the committed version wins until a person changes it through the pipeline.

## Derived and new screens
- A derived screen is assembled from patterns the system already holds: a list like the other lists, a form like the other forms. It gets a design note that lists the deltas only — what differs from the pattern it reuses — and no mockup.
- A new screen has a layout the system does not have yet. It gets the same note plus exactly one artefact showing that layout; one, because two drafts invite a choice nobody recorded.

## No invention
Never invent a component or a token. Use what the inventory in `docs/design-system.md` lists, with the variants and states it lists.

## Gaps
When the system lacks what a screen needs — a token, a state, a component, a dark value — record the gap in the `## Gaps` section of `docs/design-system.md`, or in the screen's note, and leave the decision to a person. A gap filled on the spot becomes an identity nobody chose.

## Mockups
A mockup is a reference, never code: it shows intent, and it is not copied into source files. The code is built from the system's components and tokens.

## Measuring
Contrast is measured once, by `/po-design-system`, for every text/surface pair in light and in dark. Later steps look at the result and trust those numbers; they do not measure again. A token that changes goes back through `/po-design-system`, which measures the pairs it touches.

## Dark mode
Every colour token has a dark value. A light-only system is a gap: browsers and operating systems that force a dark theme recolour it in ways nobody checked.
