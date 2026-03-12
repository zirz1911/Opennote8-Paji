# Openclaw on Note 8

คู่มือติดตั้ง Openclaw บน Samsung Note 8 ผ่าน Termux

## ขั้นตอนก่อนรัน Script

1. ลง **Termux** จาก F-Droid
2. เปิด Termux → อนุญาต Storage permission:
   ```
   termux-setup-storage
   ```

---

## รัน Script เดียวจบ

หลัง Termux พร้อมแล้ว รันคำสั่งนี้:

```bash
pkg install -y git && git clone https://github.com/zirz1911/Opennote8-Paji && cd Opennote8-Paji && bash install.sh
```

---

## Script ทำอะไรบ้าง

| Step | รายละเอียด |
|------|-----------|
| **2** | `pkg update` + ติดตั้ง proot-distro, git, nodejs, openssh, tmux และ packages อื่นๆ |
| **3** | เปิด `sshd` + ตั้งรหัสผ่าน `openclaw` |
| **4** | ติดตั้ง Ubuntu (proot-distro) + ตั้ง timezone Asia/Bangkok + Node.js v22 |
| **5** | Config NPM timeout + ติดตั้ง `openclaw@latest` (retry อัตโนมัติถ้า network fail) |

---

## หลังติดตั้งเสร็จ

เข้า Ubuntu:
```bash
proot-distro login ubuntu
```

SSH เข้าจากคอม (port 8022):
```bash
ssh <username>@<ip> -p 8022
# รหัสผ่าน: openclaw
```

---

## อ้างอิง

- [คู่มือต้นฉบับ](https://ordershrimp.9aum.com/manual/4.install_openclaw_yourself.html)