# RDP Wrapper 1.6.2 for Windows build **10.0.26100.9818**

Unlocks **concurrent (multi-user) RDP sessions** on Windows 11 Pro by hooking
`termsrv.dll`, plus the policy patches that remove the single-session limit.
This is the same mechanism RDP Wrapper has always used — it does not add a new
service, it swaps `TermService`'s `ServiceDll` for `rdpwrap.dll`.

---

## 1. What this build is

Verified on this machine:

| Item | Value |
|---|---|
| OS | Windows 11 Pro, 64-bit |
| Build / UBR | **10.0.26100.9818** |
| `termsrv.dll` file version | 10.0.26100.8115 |
| Architecture | x64 (`SingleUserOffset.x64` etc.) |

The `26H2` / `26300` numbers visible in `winver`-style registry keys are the
enablement-package values; `termsrv.dll` and the RDP stack are **26100.9818**.
The ini section name must match **build.UBR** — `[10.0.26100.9818]` — which is
what ships here.

## 2. Where the offsets came from

Generated locally with `RDPWrapOffsetFinder 1.0` against the live
`C:\Windows\System32\termsrv.dll`, not copy-pasted:

```
[10.0.26100.9818]                      [10.0.26100.9818-SLInit]
SingleUserOffset.x64 = AC5DB           bServerSku.x64          = 135354
SingleUserCode.x64   = mov_eax_1_nop_2 bRemoteConnAllowed.x64  = 13536C
DefPolicyOffset.x64  = A977D           bFUSEnabled.x64         = 13537C
DefPolicyCode.x64    = CDefPolicy_Query_r9d_rdi_jmp
LocalOnlyOffset.x64  = 9FA61           bAppServerAllowed.x64   = 135360
LocalOnlyCode.x64    = jmpshort        bMultimonAllowed.x64    = 135370
SLInitOffset.x64     = C0798           lMaxUserSessions.x64    = 135358
SLInitFunc.x64       = New_CSLQuery_Initialize
                                       ulMaxDebugSessions.x64  = 135378
                                       bInitialized.x64        = 135350
```

These values were cross-checked against the community `rdpwrap.ini` entry for
the same build and matched byte-for-byte, so the signature search was clean.

## 3. Files in this folder

| File | Purpose |
|---|---|
| `rdpwrap.ini` | Full configuration (1498 sections) **+ the 26100.9818 entry** appended at the end |
| `install.bat` | Self-elevates, installs the wrapper, copies the ini, restarts `TermService` |
| `update.bat` | Re-applies the ini after a Windows update without reinstalling |
| `uninstall.bat` | Restores stock `termsrv.dll` behaviour |
| `regen-offsets.bat` | Runs the offset finder to produce a section for whatever build is installed *now* |
| `RDPWInst.exe` | RDP Wrapper 1.6.2 installer engine |
| `RDPConf.exe` | Status/config GUI |
| `RDPCheck.exe` | Local loopback RDP test client |

`RDPWInst.exe` reads `rdpwrap.ini` **from its own folder**, so keep all files
together — don't move the ini out.

## 4. Install

1. Right-click **`install.bat` → Run as administrator** (it self-elevates if you
   just double-click; accept the UAC prompt).
2. Let it finish, then look at **`RDPConf.exe`**:
   - `Listener state` → **Listening**
   - `Service state` → **Installed / Running**
   - `Wrapper state` → **Installed**
   - All four rows **green**. Any red row → section 7.
3. Test locally with **`RDPCheck.exe`** (connects to `127.0.0.2`).

RDP must be on: **Settings → System → Remote Desktop → On**
(`fDenyTSConnections = 0`, and the three `RemoteDesktop-*` firewall rules
enabled — both already true on this PC).

To verify multi-session: log in locally as user A, then RDP in as user B from
another machine. Before the patch, session B would kick A out; now both stay
connected (`qwinsta` shows two `rdp-tcp#` sessions).

## 5. After every Windows update

Windows updates replace `termsrv.dll` and bump the UBR, so the ini section no
longer matches and `RDPConf` turns red (`Not supported`).

1. Run **`regen-offsets.bat`** → it prints the section for the new build and
   writes `offsets-current.ini`.
2. Open `rdpwrap.ini`, append that section (keep both `[build.ubr]` and
   `[build.ubr-SLInit]` headers), save.
3. Run **`update.bat`**, then check `RDPConf.exe`.

If the new build already exists in the shipped ini, step 1–2 are unnecessary:
just run `update.bat`. Newer community inis (`sebaxakerhtc/rdpwrap.ini`) are a
drop-in replacement for `rdpwrap.ini`.

## 6. Uninstall / rollback

Run **`uninstall.bat`** as administrator. It restores `TermService`'s
`ServiceDll` to `C:\Windows\System32\termsrv.dll` and removes the patched
configuration; no reboot needed.

Manual check that it is clean:

```
reg query "HKLM\SYSTEM\CurrentControlSet\Services\TermService\Parameters" /v ServiceDll
```

Should read `C:\Windows\System32\termsrv.dll` again.

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| `RDPConf`: **Not supported** / red rows | Build/UBR doesn't match a section. Run `regen-offsets.bat`, append the result, `update.bat`. |
| `RDPConf`: **Wrapper not installed** | `install.bat` didn't run elevated, or AV removed `RDPWInst.exe`/`rdpwrap.dll`. |
| `RDPConf`: **Listener not listening** | `TermService` stopped, or firewall rules disabled. `net start TermService`; re-enable the `Remote Desktop` rule group. |
| Sessions still kick each other | Ini copied but service not restarted — `net stop TermService /y && net start TermService`. |
| `rdpwrap.txt` in `C:\` | Normal: the ini sets `LogFile=\rdpwrap.txt`. Useful for hook errors. |

## 8. Caveats (read these)

- **Windows Defender / SmartScreen** flags `RDPWInst.exe` and the unsigned
  `rdpwrap.dll` as `HackTool`/`PUA`. That is expected for a DLL that patches
  `termsrv.dll`; if AV quarantines it, add an exclusion or the install silently
  fails. Understand what you're excluding before you do.
- **Licensing**: concurrent RDP sessions on Windows client are an RDS feature
  that Microsoft licenses separately. This patch circumvents that limit — fine
  for a machine you own and administer yourself, not something to deploy across
  a business without the proper RDS/Windows Server licensing.
- **Fragile by nature**: every cumulative update can break it until a matching
  ini section exists. Keep `regen-offsets.bat` handy.
- Restarting `TermService` **drops active RDP sessions** — the scripts do it
  for you, so don't run them while someone is connected remotely.
- `RDPWrap-v1.6.2` in the parent folder is the untouched stock download; this
  package is the build-specific, ready-to-run copy.
