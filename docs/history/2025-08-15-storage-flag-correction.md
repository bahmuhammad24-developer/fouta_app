Fixed CI deploy by replacing --only storage:rules with --only storage.

Ensures Storage rules from storage.rules (linked in firebase.json) are deployed.

Prevents Firebase CLI error: "Could not find rules for the following storage targets: rules".
