# ProjectR tool plugins

Drop `*.toml` files in this directory to extend ProjectR without editing
`lib/data/tools.sh`.

Supported keys:

```toml
cmd = "ripgrep"
pkg = "ripgrep"
name = "Ripgrep"
desc = "Fast recursive search"
type = "pkg"
extra = "-"
category = "Dev"
```

`type` can be `pkg`, `pip`, or `special`. For `special`, `extra` should be the
name of a shell function that has already been sourced by ProjectR.
