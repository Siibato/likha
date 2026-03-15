# Likha Load Testing Suite

Load testing for Likha server using k6, running on a single MacBook M1/M2/M3 client connecting to Raspberry Pi via Ubiquiti EAP225 access point.

## Quick Start

### 1. Install k6

```bash
brew install k6
```

### 2. Create Test Accounts (You Do This)

Likha uses **usernames** (not emails). Create these accounts in your Likha server as an admin. All use password `TestPassword123!`:

**Accounts to create:**
- `admin01`, `admin02`, `admin03` (role: admin)
- `teacher01` through `teacher05` (role: teacher)
- `student01` through `student10` (role: student)

**Example: Create and activate an account via API:**
```bash
# Step 1: Create account (requires admin auth)
curl -X POST http://<pi-ip>:8000/api/v1/auth/accounts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin-token>" \
  -d '{"username":"teacher01","full_name":"Teacher One","role":"teacher"}'

# Step 2: Activate account (set password)
curl -X POST http://<pi-ip>:8000/api/v1/auth/activate \
  -H "Content-Type: application/json" \
  -d '{"username":"teacher01","password":"TestPassword123!","confirm_password":"TestPassword123!"}'
```

**Username constraints:**
- 3-50 characters
- Only: letters, numbers, underscores, hyphens (e.g., `student_01`, `john-doe`)

See `lib/accounts.js` to change passwords if needed.

### 3. Set Up Environment

```bash
cp .env.example .env
nano .env  # Set BASE_URL to your Pi's IP
```

### 4. Increase MacBook Socket Limit

```bash
ulimit -n 65535  # Must do before each k6 run
```

### 5. Run Tests in Order

```bash
# Each test:
# 1. Setup phase: logs in all accounts ONCE
# 2. Test phase: each VU uses pre-fetched token for API calls

# Test 1: Baseline (confirm everything works)
k6 run --env-file .env scripts/01_baseline.js

# Test 2: Stress test (ramp 50→500 users, find breaking point)
k6 run --env-file .env scripts/02_stress.js

# Test 3: Sync flow (realistic multi-step flows)
k6 run --env-file .env scripts/03_sync_flow.js
```

### 6. Export Results to CSV

```bash
k6 run --env-file .env --out csv=results.csv scripts/02_stress.js
```

## How Tests Work

Each test script has two phases:

### Setup Phase
```
1. Login all accounts ONCE before test starts
2. Print success/failure for each login
3. Return tokens to be used during test
```

**Output example:**
```
Setup phase: Logging in student accounts...
✓ VU 1 (student01) logged in
✓ VU 2 (student02) logged in
...
Setup complete: 50 users ready
```

### Test Phase
```
1. Each VU gets its pre-fetched token from setup
2. VU makes API calls with that token
3. Requests are measured and checked
4. Load ramps up according to test config
```

**This means:**
- ✅ Login happens ONCE per account (setup)
- ✅ Actual API testing is what we measure
- ✅ Realistic: simulates real users who login then make requests
- ✅ Faster: no login overhead during test iterations

---

## Test Scripts

### 01_baseline.js
**Purpose:** Verify server is healthy and responsive before stress testing

- **Load:** 50 concurrent users, steady for 2 minutes
- **Endpoints Tested:** classes, assessments, assignments
- **Checks:** Status 200, response time < 200ms
- **Expected:** All checks pass, no errors
- **When to Run:** Before any stress testing

### 02_stress.js
**Purpose:** Find system breaking point - EAP225 limits and Pi capacity

- **Load:** Ramp up 50→200→500 users over 5 minutes
- **Endpoints Tested:** Sync (40%), Classes (30%), Assessments (30%)
- **Checks:** Status 200, p95 latency < 500ms, fail rate < 1%
- **Expected:** Failures start around 400-500 concurrent users
- **When to Run:** Main load testing, run multiple times

### 03_sync_flow.js
**Purpose:** Test realistic multi-step user flows under concurrent load

- **Load:** Ramp 10→100 users over 3 minutes
- **Simulates:** Login → Get Classes → Sync Fetch → Sync Push
- **Checks:** Each step completes, no cascade failures
- **Expected:** Sync operations complete successfully at 100 concurrent
- **When to Run:** After baseline, focus on sync reliability

## Monitoring During Tests

### Terminal 1: Run k6
```bash
ulimit -n 65535
k6 run --env-file .env scripts/02_stress.js
```

### Terminal 2: Monitor Raspberry Pi
```bash
ssh pi@<your-pi-ip>
watch -n 1 'top -b -n 1 | head -20'
```

Watch for:
- CPU% (should hit 80%+ during stress)
- Memory usage (stable or growing?)
- Likha process count/threads

### Terminal 3: Monitor EAP225 (optional)
```bash
ssh admin@<eap225-ip>:8080
# Check System → System Log for dropped packets
```

## Understanding Results

### k6 Output Format

```
checks.................: 95.2% ✓ 5712  ✗ 284
data_received..........: 1.2 MB
data_sent..............: 234 kB
http_req_duration......: avg=156ms p(95)=312ms p(99)=523ms
http_req_failed........: 4.8%
http_reqs..............: 6000
iterations.............: 3000
vus.....................: 500
```

**Key Metrics:**
- `http_req_duration` — Response time (higher = slower)
- `http_req_failed` — Percentage of failed requests (should be <1%)
- `checks` — Pass rate (>95% target)
- `vus` — Virtual users currently active

### Expected Results by Load Level

| VU Count | Latency (p95) | Failures | Sync Reliable? |
|----------|---|---|---|
| 50 | <100ms | 0% | Yes |
| 200 | 150-250ms | <1% | Yes |
| 400 | 300-500ms | 2-5% | Partial |
| 500+ | 500ms+ | >5% | No |

## Troubleshooting

**"Too many open files" error**
```bash
ulimit -n 65535
```

**Connection refused to Pi**
- Check Pi is running: `ping 192.168.x.x`
- Check server: `curl http://192.168.x.x:8000/health`
- Check Wi-Fi hotspot connection

**All requests timeout**
- Verify AUTH_TOKEN is valid (not expired)
- Check BASE_URL is correct
- Confirm EAP225 and Pi are on same network

**Inconsistent results between runs**
- Wi-Fi environmental interference - run multiple times and average
- Keep MacBook at consistent distance from EAP225
- Avoid running during other network-heavy activity

## Advanced Options

### Run with custom duration
```bash
k6 run -d 10m --env-file .env scripts/02_stress.js
```

### Run with custom VU target
```bash
k6 run -u 1000 -d 5m --env-file .env scripts/02_stress.js
```

### Run all scripts sequentially
```bash
k6 run --env-file .env scripts/01_baseline.js && \
k6 run --env-file .env scripts/02_stress.js && \
k6 run --env-file .env scripts/03_sync_flow.js
```

## References

- [k6 Documentation](https://k6.io/docs/)
- [k6 Options](https://k6.io/docs/using-k6/k6-options/)
- [k6 Checks & Thresholds](https://k6.io/docs/using-k6/checks/)
