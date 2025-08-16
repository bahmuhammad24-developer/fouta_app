Fixed CI deploy by switching from a command that targeted `storage` bucket `rules` to using the generic `--only storage` option.

Context: firebase.json already maps the rules file (storage.rules); no targets were defined.
