{
  lib,
  pkgs,
  fetchGitTree,
  sources,
  ...
}:
let
  workshopDir = "share/snd-workshop";
  cli =
    pkgs.writers.writePython3Bin "snd-import-workshop"
      {
        flakeIgnore = [ "E501" ];
      }
      ''
        import json
        import os
        import sys
        import urllib.error
        import urllib.request

        ROOT = "@WORKSHOP_DIR@"
        BASE = os.environ.get("SND_URL", "http://127.0.0.1:7123")


        def post(route, path):
            req = urllib.request.Request(
                BASE + "/api/" + route,
                data=json.dumps([[path]]).encode(),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            try:
                with urllib.request.urlopen(req) as res:
                    return res.status == 200
            except urllib.error.HTTPError:
                return False
            except urllib.error.URLError as err:
                sys.exit(f"snd-import-workshop: cannot reach {BASE}: {err.reason}")


        # a package folder is one of template/source/generator; snd tells them
        # apart by which importer accepts the folder, so try each in turn
        count = 0
        for repo in sorted(os.listdir(ROOT)):
            for name in sorted(os.listdir(os.path.join(ROOT, repo))):
                path = os.path.join(ROOT, repo, name)
                if not os.path.isdir(path):
                    continue
                for kind in ("Template", "Source", "Generator"):
                    if post(f"imports{kind}Folder", path):
                        print(f"{kind.lower():9} {name}")
                        count += 1
                        break
                else:
                    print(f"skipped   {name}", file=sys.stderr)
        print(f"{count} packages imported")
      '';
in
pkgs.runCommand "snd-workshop"
  {
    meta = {
      description = "Sales & Dungeons workshop content: templates, data sources and generators";
      homepage = "https://github.com/BigJk/snd-package-repo";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  }
  ''
    mkdir -p $out/${workshopDir}
    ${lib.concatStrings (
      lib.mapAttrsToList (
        name: source: "cp -r ${fetchGitTree source}/. $out/${workshopDir}/${name}/\n"
      ) sources.ttrpg.workshop
    )}

    install -Dm755 ${cli}/bin/snd-import-workshop $out/bin/snd-import-workshop
    substituteInPlace $out/bin/snd-import-workshop \
      --replace-fail "@WORKSHOP_DIR@" "$out/${workshopDir}"
  ''
