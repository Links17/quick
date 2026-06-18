# Permissions

Quick has one local user role: the person running the macOS app.

## Permission Matrix

| Resource | Operation | Default `cmd+c+c` | Custom shortcut | Notes |
| --- | --- | --- | --- | --- |
| Pasteboard | Read text | Required | Required | Used as translation source. |
| Keychain | Read/write API key | Required | Required | Stores provider key. |
| Network | Send source text | Required | Required | Sends to configured Base URL. |
| Input Monitoring | Detect arbitrary global key shortcut | Not required | Required | Default path uses pasteboard changes instead. |
| Accessibility | Simulate `cmd+c` | Not required | Required | Only needed for custom shortcut copy simulation. |

## Important Boundaries

- Quick should not translate on arbitrary pasteboard changes. Pasteboard changes only count toward `cmd+c+c` while `cmd` is held.
- Quick should not send text unless there are two qualifying copy events or the user manually submits source text from the popup.
- Quick should not store API keys outside Keychain.

