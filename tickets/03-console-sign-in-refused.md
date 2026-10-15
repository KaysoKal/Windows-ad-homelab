# Ticket 3: Standard user can't sign in to workstation console

| Field | Value |
|---|---|
| Type | Incident |
| Priority | Low (test environment, workaround available) |
| Affected | maria.santos on WS01 |
| Status | Resolved — working as designed |

## Symptom
Signing in to WS01 as maria.santos through Hyper-V showed:
"To sign in remotely, you need the right to sign in through Remote Desktop Services."

## Internal notes
```
Connection was through Hyper-V Enhanced Session, which uses RDP behind the scenes.
maria.santos is not in Remote Desktop Users (only SEC-IT-Helpdesk is, via GPO), so the
sign-in is refused. This is the RDP restriction working as intended.
Workaround: View → uncheck Enhanced Session for a basic console session.
Maria signed in successfully with the basic session.
```

## Root cause
Not a fault. Enhanced Session counts as a remote sign-in, and standard users don't have remote sign-in rights.

## Screenshot
![Sign-in refused](../screenshots/27-rdp-refused.png)

## Resolution
Use a basic console session when testing as a standard user. Enhanced Session works for admins and help desk accounts.
