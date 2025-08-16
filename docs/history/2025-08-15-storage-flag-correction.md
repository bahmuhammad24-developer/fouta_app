Fixed CI deploy by replacing the invalid `--only storage` filter that specified a target named `rules` with the correct `--only storage`.

Ensures Storage rules from storage.rules (linked in firebase.json) are deployed.

Prevents Firebase CLI error: "Could not find rules for the following storage targets: rules".
