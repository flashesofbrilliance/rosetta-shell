# Releasing

Releases are cut by pushing a version tag. CI does the rest
([`.github/workflows/release.yml`](.github/workflows/release.yml)):
publishes to npm **with provenance**, then bumps the Homebrew formula.

## One-time setup (repo secrets)

Add these under **Settings → Secrets and variables → Actions** on
`flashesofbrilliance/rosetta-shell`:

| Secret | What | Why |
|---|---|---|
| `NPM_TOKEN` | npm **automation** granular token, publish rights to `@flashesofbrilliance/rosetta-shell` | CI can't do passkey/OTP; automation tokens bypass 2FA |
| `HOMEBREW_TAP_TOKEN` | GitHub **fine-grained PAT**, `Contents: write` on `flashesofbrilliance/homebrew-tap` | lets CI push the formula bump to the tap repo |

npm **provenance** additionally requires the workflow's `id-token: write`
permission (already set) — it links the published package to this repo + commit.

## Cutting a release

```sh
npm version patch      # or minor / major — bumps package.json AND makes the git tag
git push --follow-tags
```

That's it. The `release` workflow fires on the `v*` tag and:
1. verifies the tag matches `package.json`,
2. `npm publish --provenance --access public`,
3. recomputes the tag tarball's sha256 and pushes the updated formula to the tap.

## Manual fallback (no CI)

```sh
npm version patch && git push --follow-tags
npm publish --access public            # local publish (no provenance)
# then in the tap repo, update url + sha256:
curl -sL <tag-tarball-url> | shasum -a 256
```
