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
          nativeBuildInputs = [ pkgs.nodejs ];
        } ''
          set -euo pipefail
          mkdir -p $out

          # Prefer a package that already embeds examples/xpenguins-web.js
          if [ -f ${webPkg}/share/xpenguins-web/examples/xpenguins-web.js ]; then
            cp -a ${webPkg}/share/xpenguins-web/examples/. $out/
          else
            # Older package layout: examples + dist side by side under share/
            cp -a ${webPkg}/share/xpenguins-web/examples/. $out/
            if [ -f ${webPkg}/share/xpenguins-web/dist/xpenguins-web.js ]; then
              cp ${webPkg}/share/xpenguins-web/dist/xpenguins-web.js $out/xpenguins-web.js
            elif [ -f ${webPkg}/share/xpenguins-web/xpenguins-web.js ]; then
              cp ${webPkg}/share/xpenguins-web/xpenguins-web.js $out/xpenguins-web.js
            else
              echo "xpenguins-web package missing embedded bundle" >&2
              find ${webPkg}/share -type f >&2 || true
              exit 1
            fi
            # Rewrite legacy ../dist/ script src if present
            if [ -f $out/index.html ] && grep -q '../dist/xpenguins-web.js' $out/index.html; then
              substituteInPlace $out/index.html \
                --replace-fail 'src="../dist/xpenguins-web.js"' 'src="./xpenguins-web.js"'
            fi
          fi

          test -f $out/index.html
          test -f $out/xpenguins-web.js

          # GitHub Pages: no Jekyll processing of vendor files
          touch $out/.nojekyll

          # Helpful root readme for the published artifact
          cat > $out/README.txt <<EOF
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
    ) // {
      /*
        GitHub Actions / Pages often evaluate on x86_64-linux only.
        Re-export for convenience in docs.
      */
    };
}
