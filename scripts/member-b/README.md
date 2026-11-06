MongoDB cluster startup and health-check scripts
# Member B - MongoDB Infrastructure Scripts

## 1. Overview

This directory contains the infrastructure management scripts developed by Member B for the Smart Library Digital Resource Platform.

The scripts support environment verification, MongoDB sharded cluster startup, shutdown, and health checking.

**Environment:**
- Operating System: CentOS Stream 10
- MongoDB Server: 8.3.11
- MongoDB Shell: 2.12.0
- Service User: mongolab
- Project Directory: `/opt/smart-library-b`

## 2. Script Files

| Script | Description |
|---|---|
| `init_environment.sh` | Checks the operating system, MongoDB versions, service user, directories, keyfiles, and port availability. |
| `start_cluster.sh` | Starts Config Server, Shard 1, Shard 2, and mongos in sequence, with ping verification. |
| `stop_cluster.sh` | Stops mongos, Shard 2, Shard 1, and Config Server in reverse order. |
| `check_cluster.sh` | Checks service ports, MongoDB ping responses, system information, and memory usage. |

## 3. MongoDB Cluster Configuration

| Component | Port | Configuration |
|---|---:|---|
| Config Server | 27219 | `config/configsvr.conf` |
| Shard 1 | 27211 | `config/shard1.conf` |
| Shard 2 | 27212 | `config/shard2.conf` |
| mongos Router | 27200 | `config/mongos.conf` |

The cluster contains two registered shards:

- `shard1RS`: `localhost:27211`
- `shard2RS`: `localhost:27212`

The replica set configuration is maintained separately under `config/member-b/replica/`.

## 4. Usage

Run the following commands as the root user on the CentOS server.

### 4.1 Environment Check

```bash
bash /opt/smart-library-b/handoff/github/scripts/member-b/init_environment.sh
```

### 4.2 Start the Cluster

```bash
bash /opt/smart-library-b/handoff/github/scripts/member-b/start_cluster.sh
```

The startup sequence is:

1. Config Server
2. Shard 1
3. Shard 2
4. mongos Router

Each component is checked using a MongoDB ping command.

### 4.3 Check Cluster Health

```bash
bash /opt/smart-library-b/handoff/github/scripts/member-b/check_cluster.sh
```

The script checks whether all four components are running and responding to ping requests.

### 4.4 Stop the Cluster

```bash
bash /opt/smart-library-b/handoff/github/scripts/member-b/stop_cluster.sh
```

The shutdown sequence is:

1. mongos Router
2. Shard 2
3. Shard 1
4. Config Server

The shutdown script stops the corresponding MongoDB processes without deleting database files.

## 5. Verification Results

The following tests were completed:

- Environment inspection completed.
- All four MongoDB components started successfully.
- All four components returned successful ping responses.
- The shutdown script completed successfully.
- All four service ports were confirmed stopped after shutdown.
- Existing WiredTiger data files remained present.
- The startup script successfully restarted the cluster.
- Both registered shards remained available after restart.
- The cluster startup script returned exit code 0.

The registered shard information after restart was verified through:

```javascript
db.adminCommand({ listShards: 1 })
```

Expected registered shards:

- `shard1RS`
- `shard2RS`

## 6. Important Notes

1. Run the scripts on the configured CentOS server.
2. The MongoDB service processes run under the `mongolab` account.
3. The management scripts should be executed by root.
4. The environment check script performs inspection only; it does not initialize or recreate the database environment.
5. Do not delete or regenerate existing database data directories or authentication keyfiles during routine recovery.
6. Do not upload authentication keyfiles, passwords, or database files to GitHub.
7. Coordinate cluster shutdown with other team members before executing the shutdown script.

## 7. Member B Responsibilities

Member B is responsible for:

- MongoDB replica set infrastructure.
- MongoDB sharded cluster deployment.
- Config Server and shard configuration.
- Cluster startup and shutdown scripts.
- Infrastructure health checks.
- Deployment evidence and GitHub documentation.

**Status:** Core infrastructure deployment, shutdown, restart, and shard registration recovery verification completed.
