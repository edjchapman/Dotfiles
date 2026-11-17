#!/usr/bin/env bats
#
# Tests for the shared fixtures in helpers.bash themselves. feed_tty is the
# input source for every interactive test in mac.bats and brew-sync.bats, so a
# race inside it shows up as a suite hang in whichever test loses it.

load helpers

setup() {
    TMPDIR_T="$(mktemp -d)"
}

teardown() {
    [[ -z ${FEED_TTY_PID:-} ]] || kill "$FEED_TTY_PID" 2>/dev/null || true
    rm -rf "$TMPDIR_T"
}

@test "feed_tty: the holder survives a reader that closes while answers are still being written" {
    # bash writes one line per write(), and the scripts under test close the
    # fifo after every prompt. A write landing while no reader has it open is
    # SIGPIPE: the holder died, the remaining answers were lost, and the next
    # prompt's open blocked forever. Enough answers that the first reader is
    # certain to close mid-stream.
    local answers=() line i
    for ((i = 0; i < 500; i++)); do answers+=("a$i"); done
    feed_tty "$TMPDIR_T/tty" "${answers[@]}"

    read -r line <"$TMPDIR_T/tty"
    [ "$line" = a0 ]

    # Let a signalled holder finish dying, so that a regression fails on the
    # next line instead of hanging in the open below.
    sleep 0.2
    kill -0 "$FEED_TTY_PID"

    read -r line <"$TMPDIR_T/tty"
    [ "$line" = a1 ]

    exec 8<"$TMPDIR_T/tty"
    for ((i = 2; i < 500; i++)); do read -r line <&8; done
    exec 8<&-
    [ "$line" = a499 ]
}
