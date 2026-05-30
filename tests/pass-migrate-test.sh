#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATE_SCRIPT="$SCRIPT_DIR/../src/pass-migrate"
PASS_SCRIPT="$SCRIPT_DIR/../src/pass"
MOCK_PASS="$SCRIPT_DIR/mock-orig-pass.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""
PASS_EXIT=0
PASS_STDOUT=""
PASS_STDERR=""

# --- Test helpers ---

setup() {
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"

    # Mock original pass store
    MOCK_STORE="$TEST_HOME/.password-store"
    mkdir -p "$MOCK_STORE"

    # Age-pass store
    AGE_DIR="$TEST_HOME/.age"
    SECRETS_DIR="$AGE_DIR/secrets"
    KEY_FILE="$AGE_DIR/keys.txt"

    # Make mock executable
    chmod +x "$MOCK_PASS"
}

teardown() {
    rm -rf "$TEST_HOME"
}

# Create a mock entry: writes plaintext to .gpg file (mock encryption)
mock_entry() {
    local name="$1"
    local value="$2"
    local dir="$MOCK_STORE/$(dirname "$name")"
    mkdir -p "$dir"
    echo "$value" > "$MOCK_STORE/${name}.gpg"
}

# Run the migration script
run_migrate() {
    local stdout_file stderr_file
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    PASS_EXIT=0
    PASS_MOCK_STORE="$MOCK_STORE" HOME="$TEST_HOME" bash "$MIGRATE_SCRIPT" "$@" >"$stdout_file" 2>"$stderr_file" || PASS_EXIT=$?

    PASS_STDOUT="$(cat "$stdout_file")"
    PASS_STDERR="$(cat "$stderr_file")"
    rm -f "$stdout_file" "$stderr_file"
}

# Run age-pass directly (full path)
run_age_pass() {
    local stdout_file stderr_file
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    PASS_EXIT=0
    PASS_AGE_DIR="$AGE_DIR" HOME="$TEST_HOME" bash "$PASS_SCRIPT" "$@" >"$stdout_file" 2>"$stderr_file" || PASS_EXIT=$?

    PASS_STDOUT="$(cat "$stdout_file")"
    PASS_STDERR="$(cat "$stderr_file")"
    rm -f "$stdout_file" "$stderr_file"
}

# Run mock original pass directly
run_orig_pass() {
    local stdout_file stderr_file
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    PASS_EXIT=0
    PASS_MOCK_STORE="$MOCK_STORE" bash "$MOCK_PASS" "$@" >"$stdout_file" 2>"$stderr_file" || PASS_EXIT=$?

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

assert_stdout_equals() {
    local expected="$1"
    if [[ "$PASS_STDOUT" != "$expected" ]]; then
        echo "  FAIL: stdout does not match"
        echo "  expected: $expected"
        echo "  got:      $PASS_STDOUT"
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

echo "=== pass-migrate-test.sh ==="
echo ""

# --- RED→GREEN #1: migrate flat entries ---

begin_test "migrate flat entries"
    mock_entry "github/token" "gh-secret-123"
    mock_entry "email/password" "email-pw-456"

    run_migrate --orig-pass "$MOCK_PASS" --age-pass "$PASS_SCRIPT"
    assert_exit_code 0

    # Verify age-pass has the entries
    run_age_pass show "github/token"
    assert_exit_code 0
    assert_stdout_equals "gh-secret-123"

    run_age_pass show "email/password"
    assert_exit_code 0
    assert_stdout_equals "email-pw-456"
    pass_test
end_test

# --- RED→GREEN #2: migrate nested entries ---

begin_test "migrate nested entries preserve tree structure"
    mock_entry "api/deepseek/key" "sk-deep-001"
    mock_entry "api/xiaomi/mimo/key" "sk-mimo-002"
    mock_entry "email/lobstermail/pass" "lobster-pw"

    run_migrate --orig-pass "$MOCK_PASS" --age-pass "$PASS_SCRIPT"
    assert_exit_code 0

    # Verify all entries exist with correct values
    run_age_pass show "api/deepseek/key"
    assert_stdout_equals "sk-deep-001"

    run_age_pass show "api/xiaomi/mimo/key"
    assert_stdout_equals "sk-mimo-002"

    run_age_pass show "email/lobstermail/pass"
    assert_stdout_equals "lobster-pw"

    # Verify tree structure matches
    run_orig_pass list
    _orig_list="$PASS_STDOUT"

    run_age_pass list
    _age_list="$PASS_STDOUT"

    # Strip root dir line for comparison
    _orig_tree="$(echo "$_orig_list" | tail -n +2)"
    _age_tree="$(echo "$_age_list" | tail -n +2)"

    if [[ "$_orig_tree" != "$_age_tree" ]]; then
        echo "  FAIL: tree structure mismatch"
        echo "  original:"
        echo "$_orig_tree"
        echo "  age-pass:"
        echo "$_age_tree"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        pass_test
    fi
end_test

# --- RED→GREEN #3: dry-run writes nothing ---

begin_test "dry-run does not write anything"
    mock_entry "test/key" "test-value"

    run_migrate --orig-pass "$MOCK_PASS" --age-pass "$PASS_SCRIPT" --dry-run
    assert_exit_code 0

    # Verify nothing was written
    if [[ -d "$SECRETS_DIR" ]] && [[ -n "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]]; then
        echo "  FAIL: dry-run should not create files"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        pass_test
    fi
end_test

# --- RED→GREEN #4: force overwrite ---

begin_test "force overwrites existing entries"
    mock_entry "dup/key" "original-val"

    # First migration
    run_migrate --orig-pass "$MOCK_PASS" --age-pass "$PASS_SCRIPT" --force
    assert_exit_code 0

    run_age_pass show "dup/key"
    assert_stdout_equals "original-val"

    # Update mock and re-migrate with --force
    mock_entry "dup/key" "updated-val"
    run_migrate --orig-pass "$MOCK_PASS" --age-pass "$PASS_SCRIPT" --force
    assert_exit_code 0

    run_age_pass show "dup/key"
    assert_stdout_equals "updated-val"
    pass_test
end_test

# --- RED→GREEN #5: empty source store ---

begin_test "empty source store exits cleanly"
    run_migrate --orig-pass "$MOCK_PASS" --age-pass "$PASS_SCRIPT"
    assert_exit_code 0
    assert_stdout_contains "Nothing to migrate"
    pass_test
end_test

# --- RED→GREEN #6: missing original pass ---

begin_test "missing original pass exits with error"
    run_migrate --orig-pass "/nonexistent/pass" --age-pass "$PASS_SCRIPT"
    assert_exit_code 1
    assert_stderr_contains "not found"
    pass_test
end_test

# --- RED→GREEN #7: missing age-pass ---

begin_test "missing age-pass exits with error"
    run_migrate --orig-pass "$MOCK_PASS" --age-pass "/nonexistent/pass"
    assert_exit_code 1
    assert_stderr_contains "not"
    pass_test
end_test

# --- RED→GREEN #8: value diff after migration ---

begin_test "all values match between original and age-pass"
    mock_entry "a" "val-a"
    mock_entry "b" "val-b"
    mock_entry "c/deep" "val-c-deep"

    run_migrate --orig-pass "$MOCK_PASS" --age-pass "$PASS_SCRIPT"
    assert_exit_code 0

    # Compare each entry
    _all_ok=true
    for key in a b c/deep; do
        run_orig_pass show "$key"
        _orig_val="$PASS_STDOUT"

        run_age_pass show "$key"
        _age_val="$PASS_STDOUT"

        if [[ "$_orig_val" != "$_age_val" ]]; then
            echo "  FAIL: value mismatch for '$key'"
            echo "  original: $_orig_val"
            echo "  age-pass: $_age_val"
            _all_ok=false
        fi
    done

    if $_all_ok; then
        pass_test
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
end_test

# --- RED→GREEN #9: help output ---

begin_test "help shows usage"
    run_migrate --help
    assert_exit_code 0
    assert_stdout_contains "Usage"
    pass_test
end_test

summary
