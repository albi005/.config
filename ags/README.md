
# Starter Config

> [!warning]
> Run `ags --init` before editing to update `./types`

if suggestions don't work, first make sure
you have TypeScript LSP working in your editor

if you do not want typechecking only suggestions

```json
// tsconfig.json
"checkJs": false
```

types are symlinked to:
/nix/store/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-ags-x.x.x/share/com.github.Aylur.ags/types
