<div align="center">

# `CYBERSHIELD`
### Windows System Utility • Troubleshooting • Security Awareness

<img alt="Project status" src="https://img.shields.io/badge/status-learning%20project-00e5ff?style=for-the-badge">
<img alt="Platform" src="https://img.shields.io/badge/platform-Windows-7aa2f7?style=for-the-badge&logo=windows">
<img alt="Shell" src="https://img.shields.io/badge/shell-Batch%20%2B%20PowerShell-39ff14?style=for-the-badge">

**A terminal-style Windows utility project for learning system administration and security fundamentals.**

`[ SYSTEM INITIALIZED ]  [ LOCAL USE ONLY ]  [ READ BEFORE RUNNING ]`

</div>

---

## ▌Overview

CyberShield is a Windows batch-script learning project with a menu-driven interface for selected system maintenance and troubleshooting tasks.

> **Important:** The supplied script can disable Windows Update services and scheduled tasks, suppress update notifications, and create a scheduled task that reapplies those settings. This may prevent important security patches from installing. Review the code carefully and do not run it on a primary or managed computer.

## ▌Features in the supplied script

- Menu-driven command-line interface
- Windows Update service and policy controls
- Status checks for selected update services
- DISM and SFC system-repair commands
- Disk-check scheduling
- DNS cache flush
- Temporary-file cleanup
- Restore-point creation attempt
- Restore option for several modified settings

Feature availability and behavior can vary by Windows version and system policy. A restore point may fail if System Protection is not enabled.

## ▌Requirements

- Windows 10/11
- Administrator permissions for system-level actions
- Review of the script before execution
- Backup or restore point where appropriate

## ▌Project structure

```text
CyberShield/
├── Win10_Update_Disable_AllInOne.bat
├── README.md
└── LICENSE
```

Place the original `.bat` file in this folder after reviewing it.

## ▌Run safely

1. Read the entire `.bat` file before running it.
2. Test only in a disposable virtual machine or a non-critical test PC.
3. Keep Windows security updates enabled on everyday systems.
4. Do not run scripts from unknown sources with administrator privileges.
5. Verify every registry, service, scheduled-task, and notification change before applying it.

## ▌Learning goals

This project can be used to study:

- Windows batch scripting
- Windows services and scheduled tasks
- Registry configuration
- Administrator privileges and least privilege
- System recovery and troubleshooting
- Safe documentation and change management

## ▌Roadmap

- [ ] Add a dry-run / preview mode
- [ ] Add explicit confirmation before system changes
- [ ] Improve error handling and logging
- [ ] Verify restore behavior on supported Windows versions
- [ ] Separate troubleshooting tools from update-policy controls
- [ ] Add screenshots from a test virtual machine

## ▌Disclaimer

This repository is for educational use and authorized administration only. System-level changes can reduce security, cause unexpected behavior, or be reversed by Windows policy. The author makes no guarantee that the script is suitable for every system. Review and test before use.

---

<div align="center">

`ACCESS GRANTED // LEARN • TEST • DOCUMENT • RESTORE`

</div>
