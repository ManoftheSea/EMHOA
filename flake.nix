{
  description = "Project environment for latex";
  nixConfig.bash-prompt-suffix = "(latex) ";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  } @ inputs: let
    systems = [
      "x86_64-linux"
    ];
  in
    flake-utils.lib.eachSystem systems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      tex = pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
          latex-bin
          latexmk
          scheme-basic
          titlesec
          ;
      };
    in {
      devShells.default = pkgs.mkShellNoCC {
        name = "LaTeX environment";
        packages = [
          (pkgs.aspellWithDicts (
            dicts:
              builtins.attrValues {
                inherit
                  (dicts)
                  en
                  en-computers
                  en-science
                  ;
              }
          ))
          tex
        ];
        shellHook = ''
          echo "Welcome to $name"
        '';
      };

      formatter = pkgs.alejandra;
      packages = {
        default = self.packages.${system}.documents;
        documents = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "EMHOA-Docs";
          version = "0.1";
          src = ./src;
          buildInputs = [pkgs.coreutils tex];
          phases = ["unpackPhase" "buildPhase" "installPhase"];
          # suppressoptionalinfo removes random PDF id from lualatex
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath buildInputs}";
            mkdir -p .cache/texmf-var
            env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
              SOURCE_DATE_EPOCH=${toString self.lastModified} \
              latexmk -interaction=nonstopmode -pdf -lualatex \
              -pretex="\pdfvariable suppressoptionalinfo 512\relax" \
              -usepretex \
              Bylaws.tex Covenants.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp *.pdf $out/
          '';
        };
      };
    });
}
