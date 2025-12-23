# Application Audit (Follow-up)

## Scope
- Re-reviewed the Flutter client after the first round of fixes to confirm data integrity, performance, and UX resilience. This audit focuses on areas that still posed risk after enabling foreign keys, deduplication, and delete confirmations.

## Findings

### 1) Profile creation was not atomic
- `insertProfile` wrote the profile and the mandatory 100 yd zero in separate statements, so a crash between them could leave a profile without a zero row. This breaks assumptions in the UI and prediction logic.
- **Fix implemented:** wrap profile and zero inserts in a single database transaction to guarantee they commit together.

### 2) Profile loading performed N+1 queries and could miss zeros
- `fetchProfiles` queried DOPE points per profile (one query per profile) and created missing zero points ad hoc. Under load this is slow, and the extra inserts ran outside a transaction, risking inconsistent state if interrupted.
- **Fix implemented:** batch-load all DOPE points once, group them in memory, and ensure each profile has an indexed 100 yd zero before returning. New zero rows are written in-line so the in-memory list and database stay in sync.

### 3) Startup errors still hid failures
- Although loading now clears the spinner on failure, the UI still showed a blank state with no indication of the underlying issue or how to retry.
- **Fix implemented:** track load errors in `ProfileProvider` and surface them on the home screen with a clear message and a retry button so the user can recover.

## Remaining considerations
- Logging/telemetry remain minimal; capturing DB and import failures would aid support.
- Prediction quality still depends heavily on user-entered data; consider guiding users to add more confirmed points beyond the 100 yd zero.
