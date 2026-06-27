{
  fetchFromGitHub,
  lib,
  stdenv,
  tree-sitter,
  runCommand,
}:

let
  kcl-grammar = tree-sitter.buildGrammar {
    language = "kcl";
    version = "0.0.0+rev=b0b2eb3";
    src = fetchFromGitHub {
      owner = "kcl-lang";
      repo = "tree-sitter-kcl";
      rev = "b0b2eb38009e04035a6e266c7e11e541f3caab7c";
      hash = "sha256-Aeu1j77GdsNpo9PU+FcqN3ttT0eLaDKY4n8buftMiDc=";
    };
    generate = true;
  };

  highlights = builtins.readFile ./highlights.scm;
in

runCommand "kcl-helix-runtime"
{
  passthru = {
    inherit kcl-grammar;
    grammar = kcl-grammar;
  };
}
''
  mkdir -p $out/grammars
  cp ${kcl-grammar}/parser $out/grammars/kcl.so

  mkdir -p $out/queries/kcl
  cat > $out/queries/kcl/highlights.scm <<'HEREDOC'
${highlights}
HEREDOC
''
