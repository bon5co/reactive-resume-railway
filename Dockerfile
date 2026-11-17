# Reactive Resume wrapper for Railway.
# The wrapper does the jobs a template cannot publish as variables: it hands the root-owned volume to the app user,
# derives APP_URL from the deploy's own domain, closes public sign-up and seeds the administrator account and an API
# key taken from the template variables once the app has applied its own migrations.
# upstream: AmruthPillai/Reactive-Resume
FROM ghcr.io/reactive-resume/reactive-resume:v6.1.1@sha256:6390bd3dfa2e1acd41dceef3e4be6724f4564346bfc9d0cd54316552cca9545d

ENV ADMIN_EMAIL=admin@example.com \
    FLAG_DISABLE_SIGNUPS=true \
    FLAG_ENABLE_GUEST_LOGIN=false

COPY seed.js /app/railway-seed.cjs
COPY boot.sh /usr/local/bin/railway-boot.sh
RUN chmod +x /usr/local/bin/railway-boot.sh

ENTRYPOINT ["/usr/local/bin/railway-boot.sh"]
CMD ["node", "apps/server/dist/index.mjs"]
