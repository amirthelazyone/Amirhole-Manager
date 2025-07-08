<p align="center">
  <img src="https://raw.githubusercontent.com/amirthelazyone/Amirhole-Manager/main/.assets/amirhole.svg" width="280" alt="Amirhole logo"/>
</p>

<h1 align="center">Amirhole-Manager</h1>
<p align="center">
  <sub>Bash watchdog &amp; menu script for <a href="https://github.com/rapiz1/rathole">Rathole</a> tunnels</sub><br/>
  <sub>Unofficial fork – inspired by Musixal’s script</sub>
</p>

---

> **📌 Quick one-liner install**  
> ```bash
> bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/amirthelazyone/Amirhole-Manager/main/boat.sh)
> ```

---

## What is Rathole? *(EN)*
A lightweight, high-performance reverse-proxy written in Rust, perfect for punching through NAT and building secure tunnels.

## ✨ Features (EN)
- Interactive menu (TUI) for installing/updating/removing watchdog, live log, status, etc.
- Auto-watchdog service (systemd) – restarts Rathole if any tunnel port is down.
- Colour output (green info • orange warning • red error).
- Custom **Amirhole** ASCII banner with Geo-IP (country & ISP).
- Live `tail -f` log inside menu (press <kbd>Enter</kbd> to return).

---

# رت هول چیست؟ *(FA)*
رت‌هول یک پروکسی معکوس سبک، امن و پرسرعت است که با زبان Rust نوشته شده و برای عبور از NAT و تونل کردن سرویس‌ها به‌کار می‌رود.

## نحوهٔ نصب *(سریع)*
در سرور (اوبونتو یا دبیان) دستور زیر را بزنید:

```bash
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/amirthelazyone/Amirhole-Manager/main/boat.sh)
