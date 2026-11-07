# Smart Library Digital Resource Platform - Member B Infrastructure

This checkout contains Member B's deliverables for:

- Task 5: three-node MongoDB replica set, authentication, synchronization,
  read preferences, controlled failover, recovery, and member changes.
- Task 6 infrastructure: Config Server, two shards, mongos, authentication,
  lifecycle automation, and handoff to Member C for shard-key experiments.

Start with [the infrastructure runbook](scripts/member-b/README.md), then use
[the completion report](docs/member-b/TASK5_TASK6_COMPLETION.md) and
[the delivery checklist](docs/member-b/DELIVERY_CHECKLIST.md) for submission.
The report-ready draft is in
[`REPORT_DRAFT_TASK5_TASK6.md`](docs/member-b/REPORT_DRAFT_TASK5_TASK6.md).
Beginner GitHub/Xshell/Xftp update instructions are in
[`GITHUB_UPDATE_GUIDE.md`](docs/member-b/GITHUB_UPDATE_GUIDE.md).

No real password, keyfile, database file, token, or private key belongs in this
repository. `config/member-b/member-b.env.example` contains placeholders only.
