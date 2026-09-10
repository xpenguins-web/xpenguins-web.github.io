# xpenguins-pages

Static **GitHub Pages** site for the [xpenguins-web](https://github.com/Grumbel/xpenguins-web) demo.

The site is **built entirely with Nix** (`flake.nix`). GitHub Actions runs
`nix build`, then publishes the result to GitHub Pages. There is no
hand-maintained `docs/` HTML tree.

> **Note:** [xpenguins-ng](https://github.com/Grumbel/xpenguins-ng) is the native
> X11 client. It has no web example. This Pages repo uses **xpenguins-web**,
> the browser port of the same idea.

## Local build

```bash
nix build                # → result/ (index.html + xpenguins-web.js)
nix run                  # serve result on http://127.0.0.1:8080/
nix flake check
```

Override the web input to a local checkout while developing:

```bash
nix build .#site --override-input xpenguins-web path:../xpenguins-web
```

## GitHub Pages

1. Push this repository to GitHub.
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. The workflow [`.github/workflows/pages.yml`](.github/workflows/pages.yml)
   runs on every push to `main` / `master`:
   - Install Nix
   - `nix build .#site`
   - Upload `result/` as a Pages artifact and deploy

The published site is the built `examples/` demo from xpenguins-web
(self-contained `index.html` + `xpenguins-web.js`).

## License

Site wiring: GPL-2.0-or-later (same family as xpenguins-web).
Penguin art and runtime follow upstream xpenguins-web / theme licenses.

## Live site

https://xpenguins-web.github.io/

Bookmarklet on the demo loads:

https://xpenguins-web.github.io/xpenguins-web.js
