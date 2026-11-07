#!/usr/bin/env python3
"""Continuously exercise a replica-set URI during a controlled failover.

Required environment variable:
  SMART_LIBRARY_REPLICA_URI

The probe writes only to library_b_test.infrastructure_probe and prints one
JSON record per attempt so the output can be retained as task evidence.
"""

from __future__ import annotations

import json
import os
import sys
import time
import uuid
from datetime import datetime, timezone

uri = os.environ.get("SMART_LIBRARY_REPLICA_URI")
if not uri:
    sys.exit("SMART_LIBRARY_REPLICA_URI is required")

try:
    from pymongo import MongoClient, WriteConcern
except ModuleNotFoundError:
    sys.exit(
        "pymongo is required; run: "
        "python3 -m pip install -r scripts/member-b/requirements.txt"
    )


def emit(**payload: object) -> None:
    payload["time_utc"] = datetime.now(timezone.utc).isoformat()
    print(json.dumps(payload, ensure_ascii=False), flush=True)

duration = int(os.environ.get("PROBE_DURATION_SECONDS", "120"))
interval = float(os.environ.get("PROBE_INTERVAL_SECONDS", "1"))
token = os.environ.get("PROBE_TOKEN", str(uuid.uuid4()))

client = MongoClient(
    uri,
    serverSelectionTimeoutMS=2500,
    connectTimeoutMS=2500,
    retryWrites=True,
)
collection = client["library_b_test"].get_collection(
    "infrastructure_probe", write_concern=WriteConcern("majority", wtimeout=5000)
)

deadline = time.monotonic() + duration
attempt = 0
successes = 0
failures = 0

emit(event="probe_start", token=token, duration_seconds=duration)
while time.monotonic() < deadline:
    attempt += 1
    started = time.monotonic()
    try:
        hello = client.admin.command("hello")
        collection.update_one(
            {"token": token},
            {"$set": {"attempt": attempt, "updated_at": datetime.now(timezone.utc)}},
            upsert=True,
        )
        visible = collection.count_documents({"token": token})
        successes += 1
        emit(
            event="attempt",
            attempt=attempt,
            status="ok",
            primary=hello.get("primary"),
            visible=visible,
            elapsed_ms=round((time.monotonic() - started) * 1000, 1),
        )
    except Exception as exc:  # evidence must include transient driver errors
        failures += 1
        emit(
            event="attempt",
            attempt=attempt,
            status="error",
            error_type=type(exc).__name__,
            error=str(exc),
            elapsed_ms=round((time.monotonic() - started) * 1000, 1),
        )
    time.sleep(interval)

emit(event="probe_end", token=token, successes=successes, failures=failures)
sys.exit(0 if successes else 1)
