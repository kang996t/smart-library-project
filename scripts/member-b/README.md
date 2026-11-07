# Member B - MongoDB Infrastructure Scripts

This directory contains the reproducible deliverables for Task 5 (three-node
replica set) and Member B's infrastructure portion of Task 6 (sharded cluster).
The scripts target CentOS Stream 10, MongoDB 8.3.11, mongosh 2.12.0, service
user `mongolab`, and lab root `/opt/smart-library-b`.

## Safety and credentials

- Run process-management scripts as `root`; MongoDB processes are launched as
  `mongolab`.
- Keep administrator passwords and keyfiles outside Git. Export credentials in
  the current shell only when an authenticated command is required.
- Destructive drills require an explicit confirmation environment variable.
- Test writes use `library_b_test`, not the formal `smart_library` database.

Example local environment setup (do not commit real values):

```bash
export MONGO_ADMIN_USER='your_admin'
export MONGO_ADMIN_PASSWORD='your_local_password'
```

## Configuration installation

The repository templates live under `config/member-b/`; runtime configuration
files live under `/opt/smart-library-b/config/`.

```bash
# Preview only
sudo bash scripts/member-b/install_templates.sh --dry-run

# Apply, preserving replaced files in a timestamped backup directory
sudo bash scripts/member-b/install_templates.sh --apply
```

## Task 5 - replica set

Ports and roles:

| Node | Port | Priority | Runtime config |
|---|---:|---:|---|
| Node 1 | 27117 | 2 | `/opt/smart-library-b/config/node1.conf` |
| Node 2 | 27118 | 1 | `/opt/smart-library-b/config/node2.conf` |
| Node 3 | 27119 | 1 | `/opt/smart-library-b/config/node3.conf` |

Recommended order:

```bash
sudo bash scripts/member-b/init_environment.sh
sudo bash scripts/member-b/start_replica.sh

# First initialization; credentials are optional only before the first admin exists.
sudo -E bash scripts/member-b/bootstrap_replica.sh

bash scripts/member-b/check_replica.sh
```

Controlled failover and member-change drills:

```bash
export ALLOW_FAILOVER_DRILL=YES
sudo -E bash scripts/member-b/failover_drill.sh | tee task5-failover.log

export ALLOW_RS_RECONFIG=YES
bash scripts/member-b/member_change_drill.sh | tee task5-member-change.log
```

Application-level continuity probe (run in a second terminal before the
failover drill):

```bash
python3 -m pip install -r scripts/member-b/requirements.txt
export SMART_LIBRARY_REPLICA_URI='mongodb://USER:PASSWORD@127.0.0.1:27117,127.0.0.1:27118,127.0.0.1:27119/?replicaSet=libraryRS&authSource=admin&readPreference=secondaryPreferred&retryWrites=true&w=majority'
PROBE_DURATION_SECONDS=120 \
  python3 scripts/member-b/replica_failover_probe.py | tee task5-application-probe.jsonl
```

The probe records every successful or failed driver operation, the selected
primary, latency, and the final success/failure totals. Use its JSONL output
together with `failover_drill.sh` timestamps as the missing application-impact
evidence.

Shutdown:

```bash
sudo bash scripts/member-b/stop_replica.sh
```

## Task 6 - sharded-cluster infrastructure

| Component | Replica set | Port | Runtime config |
|---|---|---:|---|
| Config Server | `configRS` | 27219 | `configsvr.conf` |
| Shard 1 | `shard1RS` | 27211 | `shard1.conf` |
| Shard 2 | `shard2RS` | 27212 | `shard2.conf` |
| mongos | router | 27200 | `mongos.conf` |

Recommended order:

```bash
sudo bash scripts/member-b/start_cluster.sh
sudo -E bash scripts/member-b/bootstrap_sharded_cluster.sh
bash scripts/member-b/check_cluster.sh
bash scripts/member-b/verify_cluster_acceptance.sh | tee task6-infrastructure-acceptance.log
```

The bootstrap script initializes the three single-member replica sets and
registers `shard1RS` and `shard2RS` idempotently. The acceptance script checks
process identity, ports, ping, authenticated mongos identity, Config Server
identity, and both registered shards.

Shutdown and recovery:

```bash
sudo bash scripts/member-b/stop_cluster.sh
sudo bash scripts/member-b/start_cluster.sh
bash scripts/member-b/verify_cluster_acceptance.sh
```

Member C owns the business-data portion after this handoff: shard-key analysis,
enabling sharding for `borrow_logs`, importing or migrating 3000 records,
verifying distribution, and comparing targeted with scatter-gather queries.

## Script inventory

| File | Purpose |
|---|---|
| `member_b_common.sh` | Shared process, port, ping, auth, and safety helpers |
| `init_environment.sh` | Strict environment, directory, keyfile, and port preflight |
| `install_templates.sh` | Dry-run/apply installation of repository configuration templates |
| `start_replica.sh` / `stop_replica.sh` | Identity-checked replica process lifecycle |
| `bootstrap_replica.sh` | Idempotent `libraryRS` initialization and optional admin creation |
| `check_replica.sh` | Strict three-node topology and sample-data acceptance |
| `failover_drill.sh` | Timed PRIMARY stop, election, majority write/read, and node recovery |
| `member_change_drill.sh` | Guarded Node 3 remove/re-add and SECONDARY recovery check |
| `replica_failover_probe.py` | PyMongo read/write continuity evidence during failover |
| `start_cluster.sh` / `stop_cluster.sh` | Identity-checked sharded-cluster lifecycle |
| `bootstrap_sharded_cluster.sh` | Config/shard initialization, admin setup, and shard registration |
| `check_cluster.sh` | Routine component health and optional topology check |
| `verify_cluster_acceptance.sh` | Strict authenticated Task 6 infrastructure acceptance |

## Expected evidence outputs

Retain terminal output or screenshots that clearly include these markers:

- `REPLICA_ACCEPTANCE_PASS`
- `ELECTION_SECONDS=<number>` and `FAILOVER_DRILL_PASS`
- `MEMBER_CHANGE_DRILL_PASS`
- probe records with both `probe_start` and `probe_end`
- `SHARDED_CLUSTER_BOOTSTRAP_COMPLETE`
- `SHARDED_CLUSTER_ACCEPTANCE_PASS`

Do not treat source-code presence or a syntax check as runtime evidence.
