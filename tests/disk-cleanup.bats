#!/usr/bin/env bats
# Tests for disk-cleanup: which JetBrains dirs count as stale, the dry-run /
# apply split, the log age cutoff, and the Docker API guard that keeps
# `docker volume prune` away from named volumes on old engines.
#
# Hermetic: HOME is a temp dir and every tool the script probes is stubbed on
# PATH. docker in particular must be stubbed, not just absent: the Ubuntu CI
# runner ships a real /usr/bin/docker.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SCRIPT="$REPO_ROOT/dot_local/bin/executable_disk-cleanup"

    WORKDIR="$(mktemp -d)"
    export HOME="$WORKDIR/home"
    export CALLS="$WORKDIR/calls"
    unset XDG_CACHE_HOME PRE_COMMIT_HOME
    mkdir -p "$HOME" "$WORKDIR/bin"
    : >"$CALLS"

    # Record every invocation; report no cache dir, so the target probes as 0 KB.
    for tool in uv npm pre-commit brew; do
        cat >"$WORKDIR/bin/$tool" <<EOF
#!/bin/sh
echo "$tool \$*" >>"\$CALLS"
exit 1
EOF
        chmod +x "$WORKDIR/bin/$tool"
    done
    # Engine not running unless a test opts in with DOCKER_UP=1.
    cat >"$WORKDIR/bin/docker" <<'EOF'
#!/bin/sh
echo "docker $*" >>"$CALLS"
case "$1" in
    info) [ "${DOCKER_UP:-0}" = 1 ] ;;
    version) echo "${DOCKER_API:-1.47}" ;;
    system)
        if [ "$3" = "-v" ]; then
            printf 'VOLUME NAME%*sLINKS SIZE\n' 60 ''
            printf '%s 0 171MB\n' 0000000000000000000000000000000000000000000000000000000000000001
            printf '%s 1 94MB\n' 0000000000000000000000000000000000000000000000000000000000000002
            printf 'clarion_app_backend_mysql_db_data 0 2.4GB\n'
            printf '\nBuild cache usage: 0B\n'
        else
            echo 'Build Cache|1GB (50%)'
        fi
        ;;
esac
EOF
    chmod +x "$WORKDIR/bin/docker"
    export PATH="$WORKDIR/bin:/usr/bin:/bin"
}

teardown() {
    rm -rf "$WORKDIR"
}

# mkdir_with_data <dir> — a dir du reports as non-empty.
mkdir_with_data() {
    mkdir -p "$1"
    head -c 16384 /dev/zero >"$1/blob"
}

@test "dry run lists superseded JetBrains versions and deletes nothing" {
    caches="$HOME/Library/Caches/JetBrains"
    mkdir_with_data "$caches/PyCharm2026.2"
    mkdir_with_data "$caches/PyCharm2026.3"

    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"JetBrains old versions"* ]]
    [[ "$output" == *"disk-cleanup --apply"* ]]
    [ -d "$caches/PyCharm2026.2" ]
    [ -d "$caches/PyCharm2026.3" ]
}

@test "apply keeps the newest version per product in both JetBrains roots" {
    caches="$HOME/Library/Caches/JetBrains"
    support="$HOME/Library/Application Support/JetBrains"
    for d in PyCharm2026.1 PyCharm2026.3 WebStorm2026.2 RustRover2026.1 Toolbox acp-agents; do
        mkdir_with_data "$caches/$d"
    done
    mkdir_with_data "$support/PyCharm2026.2"
    mkdir_with_data "$support/PyCharm2026.3"

    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    [ ! -e "$caches/PyCharm2026.1" ]
    [ ! -e "$support/PyCharm2026.2" ]
    [ -d "$caches/PyCharm2026.3" ]
    [ -d "$support/PyCharm2026.3" ]
    # Sole version of its product, even if the IDE is uninstalled: kept.
    [ -d "$caches/WebStorm2026.2" ]
    [ -d "$caches/RustRover2026.1" ]
    [ -d "$caches/Toolbox" ]
    [ -d "$caches/acp-agents" ]
}

@test "version sort ranks 2026.10 above 2026.9" {
    caches="$HOME/Library/Caches/JetBrains"
    mkdir_with_data "$caches/PyCharm2026.9"
    mkdir_with_data "$caches/PyCharm2026.10"

    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    [ ! -e "$caches/PyCharm2026.9" ]
    [ -d "$caches/PyCharm2026.10" ]
}

@test "apply removes only logs older than the age cutoff" {
    logs="$HOME/Library/Logs/SomeApp"
    mkdir -p "$logs"
    head -c 16384 /dev/zero >"$logs/old.log"
    head -c 16384 /dev/zero >"$logs/new.log"
    touch -t 202001010000 "$logs/old.log"

    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    [ ! -e "$logs/old.log" ]
    [ -f "$logs/new.log" ]
}

@test "a tool whose cache is empty is not cleaned" {
    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    ! grep -q "uv cache clean" "$CALLS"
    ! grep -q "npm cache clean" "$CALLS"
}

@test "a cache with content is cleaned through its own tool" {
    mkdir_with_data "$WORKDIR/uv-cache"
    cat >"$WORKDIR/bin/uv" <<EOF
#!/bin/sh
echo "uv \$*" >>"\$CALLS"
[ "\$1 \$2" = "cache dir" ] && echo "$WORKDIR/uv-cache"
exit 0
EOF

    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    grep -q "^uv cache clean" "$CALLS"
}

@test "docker is skipped when the engine is not running" {
    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    [[ "$output" == *"Docker build cache + anon vols"*"skipped"* ]]
    ! grep -q "prune" "$CALLS"
}

@test "docker counts only unused anonymous volumes and prunes them on API >= 1.42" {
    export DOCKER_UP=1 DOCKER_API=1.47

    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    # 1GB build cache + 171MB unused anonymous volume; the in-use anonymous
    # volume and the named DB volume are excluded.
    [[ "$output" == *"Docker build cache + anon vols"*"1.1G"* ]]
    grep -q "docker builder prune -f" "$CALLS"
    grep -q "docker volume prune -f" "$CALLS"
}

@test "docker volume prune is refused on engines older than API 1.42" {
    export DOCKER_UP=1 DOCKER_API=1.41

    run "$SCRIPT" --apply
    [ "$status" -eq 0 ]
    grep -q "docker builder prune -f" "$CALLS"
    ! grep -q "docker volume prune" "$CALLS"
    [[ "$output" == *"skipped volume prune"* ]]
}

@test "unknown argument exits 2" {
    run "$SCRIPT" --bogus
    [ "$status" -eq 2 ]
}
