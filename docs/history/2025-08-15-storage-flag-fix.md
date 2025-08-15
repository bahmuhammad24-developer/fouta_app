Fixed CI deploy by switching from --only storage:rules (interpreted as a missing target named rules) to --only storage.

Context: firebase.json already maps the rules file (storage.rules); no targets were defined.
