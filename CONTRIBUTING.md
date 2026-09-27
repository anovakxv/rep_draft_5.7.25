# Contributing to Rep (for invited collaborators)

Welcome! This guide explains how to make changes **safely**. You don't need a deep
software background — just follow the workflow below and you can't hurt the live app.

> **Why we're careful:** Rep runs on **one shared backend** that serves the **live**
> web app, iOS app, and Android app at the same time. So we work in a way where
> **nothing you do goes live until Adam reviews and merges it.** You get to move fast
> on your own copy; Adam is the one who presses the "deploy" button (by merging).

> _This file is for people Adam has personally invited. Rep's code is published but not
> open to general outside contributions — see [NOTICE.md](NOTICE.md)._

---

## The one golden rule

**Never work directly on the `Adam_July2025` branch.** That branch *is* what's live in
production — a change there deploys instantly to real users. (It's locked so you can't
push to it anyway.) Instead, always make your **own branch** and open a **Pull Request**.

---

## The workflow — every change follows these steps

1. **Get the latest code:**
   ```
   git checkout Adam_July2025
   git pull
   ```
2. **Make your own branch** (name it `yourname/what-youre-doing`):
   ```
   git checkout -b yourname/fix-signup-button
   ```
3. **Make your changes**, then save them ("commit"):
   ```
   git add .
   git commit -m "Short description of what you changed"
   ```
4. **Send your branch to GitHub ("push"):**
   ```
   git push -u origin yourname/fix-signup-button
   ```
5. **Open a Pull Request (PR)** on GitHub: it will offer to compare your branch against
   `Adam_July2025`. Write a sentence or two on what you changed and why.
6. **Adam reviews it.** If it's good, he **merges** it — and *that* is what makes it go
   live. If it needs tweaks, he'll comment; just push more commits to the **same branch**
   and they'll show up in the PR automatically.

That's the whole loop. **You never deploy — merging is Adam's job.**

---

## What you can work on freely vs. what needs extra care

✅ **Go for it (lower risk):**
- The **web app** (`web-app/`). Bonus: every PR automatically gets a **preview link**
  (from Vercel) so you can see your web changes on a live test URL *before* anything
  merges. Look for the Vercel check/comment on your PR.
- Text/copy, styling, UI tweaks, new frontend components.

⚠️ **Expect Adam's review to be required (higher risk — this is automatic, not a mistake):**
- Anything in the **backend** (`my-ios-app/Python_Backend/`) — the shared live server.
- **Database migrations** — schema changes are hard to undo.
- The iOS core files **`RepApp.swift`** and **`MainScreen.swift`** (app entry + navigation).
- Dependency/config files (`requirements.txt`, `package.json`, `Procfile`, `vercel.json`).

GitHub will automatically ask for Adam's approval on those — just expect it.

---

## Please don't

- ❌ Push directly to `Adam_July2025` or `master`.
- ❌ Force-push (`git push --force`) to any shared branch.
- ❌ Run database migrations (`flask db upgrade`) — **Adam only.**
- ❌ Commit secrets, API keys, passwords, or `.env` files.

---

## If something breaks or you get stuck

- **Relax — nothing on your branch can affect the live app.** That's the whole point of
  this workflow. Breaking things on your own branch is totally fine.
- If your branch gets messy, you can start clean: make a fresh branch from
  `Adam_July2025` and redo your change there.
- When in doubt, open the PR anyway and ask Adam in the PR comments.

---

## Quick reference

| Thing | Answer |
|---|---|
| Branch that's live (don't touch) | `Adam_July2025` |
| Where you work | a new branch → Pull Request |
| Who deploys | Adam, by merging your PR |
| Backend / DB / iOS-core changes | require Adam's review (automatic) |
| Web changes | get a preview link on your PR |
| Run database migrations? | Never — Adam only |
