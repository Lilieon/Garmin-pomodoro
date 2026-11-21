# Local container hooks (gitignored)

Every `*.sh` in this directory runs at the end of `postCreateCommand`
(after `.devcontainer/scripts/post-create.sh`), inside the container, as `node`.

Put personal setup here — never in committed files:

- git identity
- personal CLI tools
- anything machine- or user-specific

Example `post-create.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
# sudo npm install -g your-personal-cli  (sudo: global prefix is root-owned)
```

For container-level personalization (mounts, environment, DNS), use
`../docker-compose.override.yml` instead (see its `.example`).
