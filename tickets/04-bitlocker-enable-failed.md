# Ticket 4: BitLocker won't enable on WS01

| Field | Value |
|---|---|
| Type | Incident |
| Priority | Medium (device not yet encrypted, security requirement) |
| Affected | WS01 |
| Status | Resolved |

## Symptom
`Enable-BitLocker` failed on WS01 with two different errors on two attempts.

## Internal notes
**Note 1: First error**
```
Enable-BitLocker -MountPoint C: -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector -SkipHardwareTest
Error 0x8031005F: "Group Policy settings require the creation of a recovery key."
GPO-BitLocker-Escrow had "Allow 256-bit recovery key" set to Require. That demands a
recovery key file in addition to the 48-digit recovery password.
Fix: changed to Allow, gpupdate /force on WS01.
```

**Note 2: Second error**
```
Retry error 0x80310031: "Only one key protector of this type is allowed."
The first failed attempt had already added the TPM protector.
Used manage-bde -on C: -em xts_aes256 -used -s, which starts encryption with the
protectors already on the drive.
```

**Note 3: Recovery password missing**
```
Backup-BitLockerKeyProtector failed: KeyProtectorId argument null.
Get-BitLockerVolume showed KeyProtector {Tpm} only, so no recovery password existed to back up.
Added one: Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
Backed it up to AD with Backup-BitLockerKeyProtector.
```

**Note 4: Verified**
```
Get-BitLockerVolume C: → KeyProtector {Tpm, RecoveryPassword}, encrypting.
ADUC → WS01 → BitLocker Recovery tab shows the recovery password.
```

## Screenshots
![The two errors](../screenshots/29-bitlocker-errors.png)
![Key in AD](../screenshots/32-bitlocker-ad.png)

## Resolution
Escrow GPO corrected from Require to Allow, encryption started with existing protectors, recovery password added and confirmed in AD.

**Lesson:** confirm the escrow GPO applied before encrypting, add the recovery password first, and check which protectors exist before acting on them.
