# Troubleshooting Log

Each issue is written the way I'd write a help desk ticket: symptom, what I checked, root cause, fix, and lesson.

---

## 1. Warehouse team can't reach their shared drive (three root causes)

**Symptom:** The warehouse share couldn't be created with PowerShell. After it was created through the GUI, a warehouse user still couldn't open it, and the `H:` drive never appeared.

### Cause 1: Typo in the security group name
- `New-SmbShare ... -FullAccess "LAB\SEC-Warehouse-Staff"` failed with *"No mapping between account names and security IDs was done"* (System Error 1332).
- Created the share through the GUI instead (Advanced Sharing). It worked.
- `Get-SmbShareAccess -Name WarehouseShare` showed the account as **`LAB\SEC-Warhouse-Staff`**, missing an "e".
- PowerShell needs an exact name. The GUI's **Check Names** found the close match, which is why it worked there.
- **Side effect:** the bulk user script added warehouse users to the correctly spelled group, which didn't exist, so none of them were in any group.
- **Fix:** renamed the group (both the logon name and the display name) and re-added the warehouse users. Share permissions are stored by SID, so the share followed the rename automatically.

### Cause 2: Missing NTFS permissions
- After the group fix, the user got *"You do not have permission to access"* the share.
- Share permissions allowed the group, but the folder's NTFS permissions didn't include it. **Both layers must allow access.**
- **Fix:** `icacls C:\Shares\WarehouseShare /grant "LAB\SEC-Warehouse-Staff:(OI)(CI)M"`

### Cause 3: Typo in the drive map path
- The user could open the share by typing the path, but `H:` never mapped.
- `gpresult` showed the drive map GPO was applied, so the GPO itself was being received.
- The event log showed **0x80070043** (network name not found).
- The drive map's Location was `\\DC01\WarehousesShare`, with an extra "s".
- **Fix:** corrected the path. `H:` mapped at next sign-in.

**Lesson:** one symptom can have several causes. Fixing the first one didn't solve the ticket, so I kept working layer by layer: does the group exist → are both permission layers right → is the GPO setting correct. Now I browse to paths and pick groups from lists instead of typing them.

---

## 2. Domain join failed on a typo

**Symptom:** `Add-Computer` failed with *"The user name or password is incorrect."*

**Root cause:** the credential was typed as `LAB\Adminstrator`, missing an "i".

**Fix:** retyped it as `LAB\Administrator` and the join succeeded.

**Lesson:** when an error says the password is wrong, check the user name first.

---

## 3. Standard user blocked from the VM console

**Symptom:** Signing in to WS01 as a warehouse user showed *"To sign in remotely, you need the right to sign in through Remote Desktop Services."*

**Root cause:** Hyper-V's **Enhanced Session** mode uses RDP behind the scenes. Standard users aren't in Remote Desktop Users, so they're refused, which is the policy working as intended.

**Fix:** View → uncheck **Enhanced Session** to use a basic console session for testing as a standard user.

---

## 4. Enable-BitLocker failed twice

**Error 1:** *"Group Policy settings require the creation of a recovery key"* (0x8031005F).
- The escrow GPO was set to **Require** a 256-bit recovery key *file* in addition to the 48-digit recovery password.
- **Fix:** changed it to **Allow**, then `gpupdate /force`.

**Error 2:** *"Only one key protector of this type is allowed"* (0x80310031).
- The first failed attempt had already added the TPM protector, so the retry tried to add a second one.
- **Fix:** started encryption with `manage-bde -on C: -em xts_aes256 -used -s`, which uses the protectors already on the drive instead of adding new ones.

**Also learned:** while rotating the recovery key, a backup command failed because `$id` was empty. The drive only had a TPM protector at that point, so there was no recovery password to find. Checking the protector list first showed the real problem.

**Lesson:** apply and confirm the escrow GPO before encrypting, add the recovery password first, and check what protectors exist before acting on them.

---

## 5. Sysprep blocked on the reference image

**Symptom:** Sysprep wouldn't run on the Windows 11 reference machine.

**Root cause:** Windows 11 had turned on device encryption (BitLocker) automatically.

**Fix:** let decryption finish (`FullyDecrypted`, protection Off), then ran Sysprep.

**Also:** the 32-bit PowerShell (x86) window can't find `sysprep.exe`. Run it from `C:\Windows\System32\Sysprep\` using Win+R or 64-bit PowerShell.
