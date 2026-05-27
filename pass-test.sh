#!/usr/bin/env bash
set -euo pipefail

PASS_SCRIPT="$(cd "$(dirname "$0")" && pwd)/pass"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""
PASS_EXIT=0
PASS_STDOUT=""
PASS_STDERR=""

# --- Test helpers ---

setup() {
    # Create isolated temp HOME
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"
    export AGE_DIR="$HOME/.age"
    export SECRETS_DIR="$AGE_DIR/secrets"
    export KEY_FILE="$AGE_DIR/keys.txt"
}

teardown() {
    rm -rf "$TEST_HOME"
}

run_pass() {
    # Run pass script, capture stdout, stderr, and exit code
    local stdout_file stderr_file
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"
    
    PASS_EXIT=0
    bash "$PASS_SCRIPT" "$@" >"$stdout_file" 2>"$stderr_file" || PASS_EXIT=$?
    
    PASS_STDOUT="$(cat "$stdout_file")"
    PASS_STDERR="$(cat "$stderr_file")"
    rm -f "$stdout_file" "$stderr_file"
}

# --- Assertions ---

assert_exit_code() {
    local expected=$1
    if [[ "$PASS_EXIT" -ne "$expected" ]]; then
        echo "  FAIL: expected exit code $expected, got $PASS_EXIT"
        echo "  stderr: $PASS_STDERR"
        return 1
    fi
}

assert_stdout_contains() {
    local pattern="$1"
    if [[ "$PASS_STDOUT" != *"$pattern"* ]]; then
        echo "  FAIL: stdout does not contain '$pattern'"
        echo "  stdout: $PASS_STDOUT"
        return 1
    fi
}

assert_stdout_equals() {
    local expected="$1"
    if [[ "$PASS_STDOUT" != "$expected" ]]; then
        echo "  FAIL: stdout does not match"
        echo "  expected: $expected"
        echo "  got:      $PASS_STDOUT"
        return 1
    fi
}

assert_stderr_contains() {
    local pattern="$1"
    if [[ "$PASS_STDERR" != *"$pattern"* ]]; then
        echo "  FAIL: stderr does not contain '$pattern'"
        echo "  stderr: $PASS_STDERR"
        return 1
    fi
}

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "  FAIL: file does not exist: $path"
        return 1
    fi
}

assert_file_not_exists() {
    local path="$1"
    if [[ -f "$path" ]]; then
        echo "  FAIL: file should not exist: $path"
        return 1
    fi
}

assert_dir_exists() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        echo "  FAIL: dir does not exist: $path"
        return 1
    fi
}

# --- Test runner ---

begin_test() {
    CURRENT_TEST="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    setup
}

pass_test() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS"
}

fail_test() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

end_test() {
    teardown
}

# --- Summary ---

summary() {
    echo ""
    echo "=============================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_RUN total"
    if [[ "$TESTS_FAILED" -gt 0 ]]; then
        echo "SOME TESTS FAILED"
        return 1
    else
        echo "ALL TESTS PASSED"
        return 0
    fi
}

# --- Run tests ---

echo "=== pass-test.sh ==="
echo ""

# --- RED→GREEN #1: first insert auto-generates keypair ---

begin_test "first insert auto-generates keypair and encrypts"
    # Run insert with piped password
    echo "my-secret-123" | run_pass insert test-key
    assert_exit_code 0
    # Key file should be created
    assert_file_exists "$KEY_FILE"
    # Encrypted file should exist
    assert_file_exists "$SECRETS_DIR/test-key.age"
    # Show should decrypt to original password
    run_pass show test-key
    assert_exit_code 0
    assert_stdout_equals "my-secret-123"
    pass_test
end_test

# --- RED→GREEN #2: insert + show basic flow (multiple entries) ---

begin_test "insert and show multiple entries"
    echo "password-aaa" | run_pass insert entry-a
    assert_exit_code 0
    echo "password-bbb" | run_pass insert entry-b
    assert_exit_code 0
    assert_file_exists "$SECRETS_DIR/entry-a.age"
    assert_file_exists "$SECRETS_DIR/entry-b.age"
    run_pass show entry-a
    assert_exit_code 0
    assert_stdout_equals "password-aaa"
    run_pass show entry-b
    assert_exit_code 0
    assert_stdout_equals "password-bbb"
    pass_test
end_test

# --- RED→GREEN #3: list displays entries ---

begin_test "list shows all entries"
    echo "pw1" | run_pass insert alpha
    echo "pw2" | run_pass insert beta
    echo "pw3" | run_pass insert gamma
    run_pass list
    assert_exit_code 0
    assert_stdout_contains "alpha"
    assert_stdout_contains "beta"
    assert_stdout_contains "gamma"
    pass_test
end_test

# --- RED→GREEN #4: rm deletes entry ---

begin_test "rm deletes entry"
    echo "secret" | run_pass insert to-delete
    assert_exit_code 0
    assert_file_exists "$SECRETS_DIR/to-delete.age"
    run_pass rm to-delete
    assert_exit_code 0
    assert_file_not_exists "$SECRETS_DIR/to-delete.age"
    run_pass show to-delete
    assert_exit_code 1
    pass_test
end_test

# --- RED→GREEN #5: missing args error handling ---

begin_test "show with no args prints usage and exits non-zero"
    run_pass show
    assert_exit_code 1
    assert_stderr_contains "Usage"
    pass_test
end_test

begin_test "insert with no args prints usage and exits non-zero"
    run_pass insert
    assert_exit_code 1
    assert_stderr_contains "Usage"
    pass_test
end_test

# --- RED→GREEN #6: insert existing entry prompts overwrite ---

begin_test "insert existing entry prompts overwrite"
    echo "first" | run_pass insert dup-key
    assert_exit_code 0
    # Second insert should prompt (we pipe 'y' to confirm)
    printf "y\nsecond\n" | run_pass insert dup-key
    assert_exit_code 0
    run_pass show dup-key
    assert_stdout_equals "second"
    pass_test
end_test

begin_test "insert existing entry with 'n' cancels"
    echo "keep-me" | run_pass insert cancel-key
    assert_exit_code 0
    printf "n\nnew-val\n" | run_pass insert cancel-key
    # Should still have old value
    run_pass show cancel-key
    assert_stdout_equals "keep-me"
    pass_test
end_test

summary
