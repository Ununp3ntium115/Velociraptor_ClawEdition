## Gap Information

**Gap ID**: gap-0x01
**Priority**: P0 - CRITICAL
**Estimated Effort**: 18-22 hours
**Phase**: 1 (Foundation)
**Status**: 🔴 Open

---

## Current State

**BRUTAL HONESTY**: ❌ **ZERO API INTEGRATION**

- ❌ **Missing**: No HTTP client to communicate with Velociraptor server
- ❌ **Missing**: No REST API endpoints implemented
- ❌ **Missing**: No WebSocket support
- ❌ **Missing**: Cannot connect to Velociraptor server at all

**Parity**: 0% (Electron has 100%, macOS has 0%)

**Impact**: **Cannot function as DFIR platform without this**. This is the foundation for ALL other features.

---

## Electron Equivalent

**File**: `backend/velociraptor-api-client.js` (570 lines)
**Features**:
- Full REST API client with 25+ endpoints
- Certificate-based authentication (mTLS)
- API key authentication
- Request/response handling
- Error handling with retry logic
- Connection pooling
- WebSocket support

---

## Required Implementation

### Files to Create

- [ ] `Services/VelociraptorAPIClient.swift` (~2,000 lines)
  - HTTP/HTTPS support
  - Certificate-based auth (mTLS)
  - API key authentication
  - Request/response handling
  - Error handling with retry logic
  - Connection pooling
  - All 25+ API endpoints implemented
- [ ] `Services/APIAuthService.swift` (~500 lines)
  - Certificate management
  - API key management
  - Authentication state tracking
- [ ] Swift 6 concurrency compliance (`async`/`await`, `@MainActor`)

### API Endpoints Required (25+)

1. `GET /api/v1/health` - Server health check
2. `GET /api/v1/version` - Velociraptor version
3. `GET /api/v1/server/status` - Server status
4. `GET /api/v1/clients` - List all clients
5. `POST /api/v1/clients/:id/interrogate` - Interrogate client
6. `POST /api/v1/clients/:id/collect` - Collect artifacts
7. `POST /api/v1/clients/:id/shell` - Open VQL shell
8. `DELETE /api/v1/clients/:id` - Remove client
9. `GET /api/v1/hunts` - List hunts
10. `POST /api/v1/hunts` - Create hunt
11. `POST /api/v1/hunts/:id/start` - Start hunt
12. `POST /api/v1/hunts/:id/stop` - Stop hunt
13. `GET /api/v1/hunts/:id/results` - Hunt results
14. `GET /api/v1/artifacts` - List artifacts
15. `POST /api/v1/query` - Execute VQL query
16. `GET /api/v1/vfs/:clientId/*` - VFS file browsing
17. `GET /api/v1/vfs/:clientId/*/download` - VFS file download
18. `POST /api/v1/server/start` - Start Velociraptor server
19. `POST /api/v1/server/stop` - Stop Velociraptor server
20. `POST /api/v1/config/generate` - Generate server config
21. `POST /api/v1/config/api-client` - Generate API client config
22. `POST /api/v1/deploy` - Deploy Velociraptor
23. `GET /api/v1/tools` - List DFIR tools
24. `POST /api/v1/tools/:id/install` - Install tool
25. `GET /api/v1/info` - Server info

---

## Closure Criteria

A gap is **CLOSED** when ALL of the following are met:

- [ ] `VelociraptorAPIClient.swift` created (~2,000 lines)
- [ ] `APIAuthService.swift` created (~500 lines)
- [ ] All 25 API endpoints implemented
- [ ] mTLS authentication working
- [ ] API key authentication working
- [ ] Connection state tracking implemented
- [ ] Error recovery and retry logic working
- [ ] Async/await Swift 6 compliant
- [ ] Unit tests passing (>80% coverage)
- [ ] Can connect to Velociraptor server via HTTPS
- [ ] Can authenticate with mTLS certificates
- [ ] Can authenticate with API keys

---

## Verification Code

```swift
// Test: Can connect to server
let client = VelociraptorAPIClient(baseURL: "https://127.0.0.1:8889")
let health = try await client.getHealth()
assert(health.status == "ok")

// Test: Can authenticate with mTLS
try await client.authenticate(certificate: certPath)
let clients = try await client.getClients()
assert(clients.count >= 0)

// Test: Can authenticate with API key
try await client.authenticate(apiKey: apiKey)
let version = try await client.getVersion()
assert(version.version != nil)

// Test: Error handling works
do {
    let _ = try await client.getClients()
} catch VelociraptorAPIError.unauthorized {
    // Expected for unauthenticated requests
    assert(true)
}

// Test: Retry logic works
let clientWithRetry = VelociraptorAPIClient(baseURL: "https://127.0.0.1:8889", maxRetries: 3)
// Simulate network failure and verify retry
```

**Expected Results**:
- Test 1: Health check returns "ok" status
- Test 2: Can list clients after mTLS auth
- Test 3: Can get version after API key auth
- Test 4: Unauthorized errors are caught correctly
- Test 5: Retry logic attempts 3 times before failing

---

## Dependencies

**Depends on**: None (foundation for all other gaps)

**Blocks**:
- gap-0x02 (Dashboard) - Needs API to fetch stats
- gap-0x03 (Client Management) - Needs API to manage clients
- gap-0x04 (Hunt Management) - Needs API to manage hunts
- gap-0x05 (VQL Terminal) - Needs API to execute queries
- gap-0x06 (VFS Browser) - Needs API to browse VFS
- gap-0x07 (Tools Integration) - Needs API to manage tools
- gap-0x08 (WebSocket) - Needs API foundation
- All other gaps depend on this

---

## Implementation Notes

- This is the **MOST CRITICAL** gap - must be completed first
- Foundation for all other features
- Must follow Swift 6 concurrency rules strictly
- Use `URLSession` for HTTP requests
- Use `NWConnection` or `URLSessionWebSocketTask` for WebSocket (gap-0x08)
- Certificate handling must use Keychain (see `KeychainManager.swift`)
- Error handling must be comprehensive (network errors, auth errors, server errors)

---

## Related Documentation

- Master Iteration Document: `steering/macos-app/macOS-Implementation-Guide.md`
- Gap Analysis: `docs/GAP-ANALYSIS-EXECUTIVE-SUMMARY.md`
- Detailed Analysis: `docs/MASSIVE-GAP-ANALYSIS-MACOS-VS-ELECTRON-2026-01-31.md`
- Electron Reference: `VelociraptorPlatform-Electron/backend/velociraptor-api-client.js`

---

## Acceptance Criteria

- [ ] Feature works as specified
- [ ] No regressions introduced
- [ ] Code follows Swift 6 concurrency rules
- [ ] All 25 endpoints functional
- [ ] Authentication works (mTLS and API key)
- [ ] Error handling comprehensive
- [ ] Unit tests >80% coverage
- [ ] Documentation updated
