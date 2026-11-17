# Development and releases

Run `python tools/test_all.py` locally before proposing a change. Tests use Lua 5.1 through Lupa and synthetic game fixtures. They do not access an installed game or personal account data.

Use a focused pull request with a clear problem, resulting behavior and verification evidence. No GitHub Actions workflows are used for checks, packaging or deployment.

The runtime is in `ApexUI/`. Bundled module sources are in `ApexUI/Source/`; generated module wrappers are in `ApexUI/Modules/`. Preserve upstream licenses and attribution. Never commit saved account data, authentication material or paid third-party guides.

`release/package-manifest.json` is an explicit list of reviewed distribution files and hashes. Update affected hashes only after inspecting and testing changes. `python tools/build_release.py` validates that list, compiles Lua, checks TOC references and creates a deterministic ZIP in `.dist/`. Tests and repository documentation outside that allowlist are not shipped to the game.

For a new release, update addon version metadata and `release/release.json`, run local verification, inspect the diff, merge the pull request and publish with the GitHub CLI. Attach the `-forever.zip` archive, `release.json` and `SHA256SUMS.txt`. Mark beta releases as prereleases. Keep the client flavor `forever` and supported interface metadata accurate.

Screenshots for WowUp live in `.previews/`. Preserve the existing ApexInterfectum branding. Never claim support for untested game branches or claim live scenarios were tested solely from mocked API results.
