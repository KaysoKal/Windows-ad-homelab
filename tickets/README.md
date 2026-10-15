# Service Desk Tickets

I tracked work in this lab through **Jira Service Management**, in a project called *IT Help Desk*, the same way a help desk logs requests and incidents. Each ticket here follows the same structure:

- **Summary, type, priority**
- **Symptom:** what the user reported or what I saw
- **Internal notes:** technical steps for other techs, added as I worked
- **Root cause and fix**
- **Customer reply:** plain-language message to the requester
- **Resolution**

| Key | Ticket | Type | Priority |
|---|---|---|---|
| HELP-1 | [Onboard 10 new hires from HR list](01-onboard-new-hires.md) | Service request | Medium |
| HELP-2 | [Can't create WarehouseShare / warehouse team can't access shared drive](02-warehouse-share-access.md) | Incident | Medium |
| — | [Standard user can't sign in to workstation console](03-console-sign-in-refused.md) | Incident | Low |
| — | [BitLocker won't enable on WS01](04-bitlocker-enable-failed.md) | Incident | Medium |

HELP-1 and HELP-2 were logged in Jira (screenshots included). The other two are written up in the same format from my notes.

**Service request vs. incident:** a service request is something a user asks for (new accounts, access). An incident is something broken that needs fixing.
