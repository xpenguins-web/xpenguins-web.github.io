{
  description = "GitHub Pages site for xpenguins-web (static demo built via Nix flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    /*
      Browser port with the DOM demo. (xpenguins-ng is the native X11 client
      and does not ship a static web example.)
    */
    xpenguins-web.url = "github:Grumbel/xpenguins-web";
  };

  outputs = { self, nixpkgs, flake-utils, xpenguins-web }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        webPkg = xpenguins-web.packages.${system}.default;

        /*
          Static site root suitable for GitHub Pages / any static host.
          Layout:
            /index.html
            /xpenguins-web.js
        */
        site = pkgs.runCommand "xpenguins-pages-site" {
          nativeBuildInputs = [ pkgs.python3 ];
        } ''
          set -euo pipefail
          mkdir -p "$out"

          # Store paths are mode 555/444 — never preserve those into $out or
          # later writes (cp, touch, substituteInPlace) fail with EACCES.
          copy_rw() {
            cp -r --no-preserve=mode,ownership "$@"
          }

          share="${webPkg}/share/xpenguins-web"

          if [ -d "$share/examples" ]; then
            copy_rw "$share/examples/." "$out/"
          else
            echo "xpenguins-web package missing share/.../examples" >&2
            find "${webPkg}" -type f 2>/dev/null | head -50 >&2 || true
            exit 1
          fi

          chmod -R u+w "$out"

          if [ ! -f "$out/xpenguins-web.js" ]; then
            if [ -f "$share/dist/xpenguins-web.js" ]; then
              copy_rw "$share/dist/xpenguins-web.js" "$out/xpenguins-web.js"
            elif [ -f "$share/xpenguins-web.js" ]; then
              copy_rw "$share/xpenguins-web.js" "$out/xpenguins-web.js"
            else
              echo "xpenguins-web package missing embedded bundle" >&2
              find "$share" -type f >&2 || true
              exit 1
            fi
          fi

          chmod -R u+w "$out"

          if [ -f "$out/index.html" ] && grep -q '\.\./dist/xpenguins-web\.js' "$out/index.html"; then
            substituteInPlace "$out/index.html" \
              --replace-fail 'src="../dist/xpenguins-web.js"' 'src="./xpenguins-web.js"'
          fi

          test -f "$out/index.html"
          test -f "$out/xpenguins-web.js"

          # Canonical bookmarklet → public Pages URL (Python avoids Nix quote hell).
          python3 -c "
import re
from pathlib import Path
p = Path('$out/index.html')
t = p.read_text()
prod = 'https://xpenguins-web.github.io/xpenguins-web.js'
t = re.sub(r\"var PRODUCTION = '[^']*';\", \"var PRODUCTION = '%s';\" % prod, t)
t = re.sub(
    r\"var scriptUrl = new URL\\('xpenguins-web\\.js', window\\.location\\.href\\)\\.href;\",
    \"var scriptUrl = '%s';\" % prod,
    t,
)
p.write_text(t)
"

          touch "$out/.nojekyll"

          cat > "$out/README.txt" <<EOF
xpenguins-web static demo
Built from the xpenguins-web Nix package.
Open index.html (or visit the GitHub Pages URL).
EOF
        '';
      in {
        packages.default = site;
        packages.site = site;

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "xpenguins-pages-serve";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              echo "Serving ${site} on http://127.0.0.1:8080/"
              cd ${site}
              exec python3 -m http.server 8080
            '';
          }}/bin/xpenguins-pages-serve";
          meta.description = "Serve the built static site on :8080";
        };

        checks.site = site;
      }
    );
}
