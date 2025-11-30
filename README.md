# ⚡ FastCharge Next

[![GitHub release](https://img.shields.io/github/v/release/Dev97633/chargeboost-magisk?style=for-the-badge&color=brightgreen)](../../releases)
[![GitHub stars](https://img.shields.io/github/stars/Dev97633/chargeboost-magisk?style=for-the-badge&color=yellow)](../../stargazers)
[![License](https://img.shields.io/github/license/Dev97633/chargeboost-magisk?style=for-the-badge&color=blue)](LICENSE)
[![Magisk](https://img.shields.io/badge/Magisk-Module-orange?style=for-the-badge&logo=android)](https://github.com/topjohnwu/Magisk)

Boost your charging speed on rooted Android devices with this simple Magisk module.  
**FastCharge Next** tweaks kernel and system parameters to optimize charging current, reducing charge time while staying safe. 🚀  

---

## ✨ Features
- ⚡ Increases charging current for faster charging
- 🔋 Works on most rooted Android devices (Magisk / KernelSU / APatch)
- 🛡️ Safe limits applied to prevent overheating or battery damage
- 🔧 Easy install & uninstall via Magisk Manager
- 📂 Open source & customizable script

---


## 📥 Installation
1. Download the latest release from **[Releases](../../releases)**
2. Flash the `.zip` in Magisk Manager (or KernelSU/APatch)
3. Reboot your device
4. Enjoy faster charging ⚡

---

## 🧑‍💻 Usage
- Module is automatic — just install & reboot
- Config file located at: /data/adb/modules/fastcharge-next/config.sh
-  You can edit limits to suit your device (default = safe values)

---

## 🛠️ Compatibility
- ✅ Magisk 24+
- ✅ KernelSU (Compatible with **[latest Releases](../../releases/v2.0.1)**)
- ✅ Android 8 – 14  
- ❌ Non-rooted devices are **not supported**

---

## 📜 How It Works
- Writes safe charging values to:
- `/sys/class/power_supply/battery/`
- `/sys/class/power_supply/usb/`
- Optimizes kernel fast-charge settings if available
- Ensures no permanent modification — **removing module restores defaults**

---

## 🚀 Example Config (optional)
```bash
# Max charging current in mA
CHARGE_CURRENT=3000

# Max voltage in mV
CHARGE_VOLTAGE=4400
```

---

## 🤝 Contributing
- We welcome contributions from the community! 🚀
- Here’s how you can help:

1. 🍴 Fork the repository
2. 🌱 Create a new branch (git checkout -b feature-xyz)
3. 🛠️ Make your changes
4. ✅ Commit (git commit -m "Add feature xyz")
5. 📤 Push (git push origin feature-xyz)
6. 🔄 Open a Pull Request




