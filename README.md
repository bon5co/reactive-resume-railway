# Reactive Resume

Wrapper over the upstream `ghcr.io/reactive-resume/reactive-resume` image (v6.1.1) for Railway. The marketplace listing is described in `README-marketplace.md` and `template.md`.

- `Dockerfile` - pins the upstream image by digest, bakes `ADMIN_EMAIL`, `FLAG_DISABLE_SIGNUPS` and `FLAG_ENABLE_GUEST_LOGIN`, adds `seed.js` and the boot script as the image entrypoint.
- `boot.sh` - requires `DATABASE_URL`, `AUTH_SECRET`, `ADMIN_PASSWORD`, `API_KEY` and `RAILWAY_PUBLIC_DOMAIN`; derives `APP_URL` from the domain; hands the root-owned volume at `/app/data` to the `node` user; seeds in the background; starts the stock entrypoint.
- `seed.js` - waits for `/api/health` (the app applies its migrations before it listens), then writes the administrator account and an API key into the database. The account is created once; `API_KEY` is the template variable, so a changed value replaces the stored key.
- `make-spec.py` - writes `scripts/specs/reactive-resume.json` for `scripts/gen_draft.py`; takes the wrapper digest as its argument.
- `snippet.sh` - the Agent-contract script, run verbatim against a deploy.

The image is built by GitHub Actions in [bon5co/reactive-resume-railway](https://github.com/bon5co/reactive-resume-railway) and published to `ghcr.io/bon5co/reactive-resume-railway`.
