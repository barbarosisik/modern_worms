# Repository workflow

Current product scope (owner revision, 16 November 2026): enlarge and improve the existing three skirmish maps and two mission maps. Defer new campaign missions until the owner requests them. Mines, combat polish and animal abilities remain planned follow-up work.

- Start descriptive feature/fix branches from the current `development_branch`.
- Publish completed work on its task branch, then merge it into `development_branch` through a pull request after the relevant checks pass. Do not leave completed work only on a feature branch unless the owner explicitly requests that.
- Verify the integrated `development_branch` and update `PROJECT_LOG.md` with the work, checks and remaining tasks.
- Promotion to `main` is manual and handled by the owner. Do not push or merge into `main`.
- Keep commits under the owner's configured identity without assistant attribution.

Read the recent entries in `PROJECT_LOG.md`, `STEP_ONE.md` and `REFERENCE_DESIGN_RESEARCH.md` before continuing development. Follow `CARTOON_ASSET_SETUP.md` for local character assets; never commit the restricted files in `assets/local_plumberry/`.

## Maintained onboarding
Read [ONBOARDING.md](ONBOARDING.md) at the start of project work. At every handoff, update that file with
implemented work, validation, limitations and exact next tasks; update VISUAL_ADVANCEMENT_PLAN.md and
PROJECT_LOG.md too. Supply a copyable current onboarding prompt in chat. This is the owner's standing
request of 16 November 2026. Check the log before presenting historical plans as unfinished work.
