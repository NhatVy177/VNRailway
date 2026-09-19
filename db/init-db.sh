#!/bin/bash
# Script to initialize VNRailway database on SQL Server

DB_SERVER="localhost"
DB_USER="sa"
DB_PASS="VNRailwayStrongPass123!"

echo "Waiting for SQL Server to start..."
sleep 15s

echo "Running Database initialization scripts..."

run_sql() {
    echo "Executing $1..."
    /opt/mssql-tools/bin/sqlcmd -S $DB_SERVER -U $DB_USER -P $DB_PASS -i "$1"
}

# 1. Schema
run_sql "/db/schema/VNRAILWAY.sql"

# 2. Types
for f in /db/type/*.sql; do run_sql "$f"; done

# 3. Sequences
for f in /db/sequences/*.sql; do run_sql "$f"; done

# 4. Functions
for f in /db/function/*.sql; do run_sql "$f"; done

# 5. Stored Procedures
for f in /db/storedprocedure/*.sql; do run_sql "$f"; done

# 6. Triggers
for f in /db/trigger/*.sql; do run_sql "$f"; done

# 7. Data
for f in /db/data/*.sql; do
    if [ -f "$f" ]; then
        run_sql "$f"
    fi
done

# 8. Setup scripts
for f in /db/SETUP_*.sql; do
    if [ -f "$f" ]; then
        run_sql "$f"
    fi
done

echo "Database initialization completed!"
