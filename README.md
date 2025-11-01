# iliyayz-JewelRob (QBCore)

## 🇮🇷 فارسی

این منبع مربوط به **اسکریپت سرقت جواهرات (Jewelry Robbery)** برای سرورهای **QBCore** است.  
فایل **`server.lua`** منطق اصلی سرقت را در سمت سرور مدیریت می‌کند.

---

### 📁 توضیح فایل
**`server.lua`** مسئول موارد زیر است:
- بررسی تعداد پلیس‌های آنلاین و در حال انجام وظیفه  
- شروع سرقت و اعمال کول‌داون‌ها  
- اطلاع‌رسانی به پلیس از طریق dispatch یا اعلان (notify)  
- کنترل جوایز (Loot) و پایان رویداد  
- ثبت رویدادها در دیسکورد (در صورت تنظیم Webhook)

---

### ⚙️ وابستگی‌ها (Dependencies)

برای اجرای صحیح این اسکریپت باید منابع زیر فعال باشند:

| منبع | توضیح | لینک |
|------|--------|------|
| **qb-core** | فریم‌ورک اصلی برای مدیریت پلیر، شغل‌ها و رویدادها | [github.com/qbcore-framework/qb-core](https://github.com/qbcore-framework/qb-core) |
| **qb-inventory** یا **ox_inventory** | مدیریت آیتم‌ها و جوایز سرقت | [github.com/qbcore-framework/qb-inventory](https://github.com/qbcore-framework/qb-inventory) |
| **ps-dispatch** *(اختیاری)* | ارسال هشدار سرقت به پلیس | [github.com/Project-Sloth/ps-dispatch](https://github.com/Project-Sloth/ps-dispatch) |
| **qb-target** *(اختیاری)* | تعامل با ویترین‌ها یا نقاط خاص | [github.com/qbcore-framework/qb-target](https://github.com/qbcore-framework/qb-target) |
| **bl-ui** *(اختیاری)* | (hack)minigame رابط کاربری زیبا برای  | [github.com/Byte-Labs-Studio/bl_ui](https://github.com/Byte-Labs-Studio/bl_ui) |
| **Discord Webhook** *(اختیاری)* | ثبت گزارش در دیسکورد | [Discord Developer Portal](https://discord.com/developers/docs/resources/webhook) |

---

### 🧩 نحوه عملکرد

1. بازیکن سرقت را آغاز می‌کند.  
   - سرور بررسی می‌کند آیا تعداد پلیس‌های در حال Duty کافی هستند.  
   - آیتم لازم برای شروع سرقت بررسی می‌شود.

2. در صورت تأیید شرایط:  
   - آیتم از بازیکن گرفته می‌شود و کول‌داون فعال می‌شود.  
   - هشدار برای نیروهای پلیس ارسال می‌گردد.  

3. بازیکنان ویترین‌ها را می‌شکنند و جوایز به‌صورت تصادفی ذخیره می‌شوند.  

4. پس از پایان سرقت:  
   - جوایز به بازیکنان داده می‌شود.  
   - بلیپ‌ها حذف می‌شوند و رویداد در دیسکورد ثبت می‌شود.

---

### 📜 پیکربندی
تنظیمات در فایل `config.lua` انجام می‌شود، شامل:
- `Config.RequiredCops` → حداقل تعداد پلیس مورد نیاز  
- `Config.RequiredItem` → آیتم شروع سرقت  
- `Config.GlobalCooldown` → کول‌داون کلی بین سرقت‌ها  
- `Config.CaseCooldown` → کول‌داون هر ویترین  
- `Config.Loot` → جوایز و درصد شانس آن‌ها  
- `Config.Discord.Webhook` → لینک وب‌هوک دیسکورد (اختیاری)

---

### 🚀 نصب سریع
1. فولدر منبع را در مسیر `resources/[robbery]/GR-jewelrob` قرار دهید.  
2. در `server.cfg` بنویسید:
3. مطمئن شوید تمام وابستگی‌ها فعال هستند.  
4. سرور را ری‌استارت کنید.

### 🧾 لایسنس
کد بر اساس چارچوب **QBCore** توسعه داده شده و قابل ویرایش برای استفاده در سرورهای RP می‌باشد.



## en English

This resource is a **Jewelry Robbery Script** for **QBCore** servers.  
The **`server.lua`** file handles the main server-side logic of the robbery system.

---

### 📁 File Description
**`server.lua`** is responsible for:
- Checking the number of on-duty police officers  
- Starting the robbery and applying cooldowns  
- Notifying police via dispatch or in-game notifications  
- Handling loot distribution and robbery completion  
- Sending logs to Discord (if a webhook is configured)

---

### ⚙️ Dependencies

These resources must be installed and running for this script to work properly:

| Resource | Description | Link |
|-----------|--------------|------|
| **qb-core** | Core framework for managing players, jobs, and events | [github.com/qbcore-framework/qb-core](https://github.com/qbcore-framework/qb-core) |
| **qb-inventory** or **ox_inventory** | Handles player inventory and robbery rewards | [github.com/qbcore-framework/qb-inventory](https://github.com/qbcore-framework/qb-inventory) |
| **ps-dispatch** *(optional)* | Sends robbery alerts to police | [github.com/Project-Sloth/ps-dispatch](https://github.com/Project-Sloth/ps-dispatch) |
| **qb-target** *(optional)* | Enables player interaction with jewelry cases | [github.com/qbcore-framework/qb-target](https://github.com/qbcore-framework/qb-target) |
| **bl-ui** *(optional)* | Beautiful UI framework for minigames(hacks) you can replace other minigames in config| [github.com/Byte-Labs-Studio/bl_ui](https://github.com/Byte-Labs-Studio/bl_ui) |

| **Discord Webhook** *(optional)* | Logs robbery events to Discord | [Discord Developer Portal](https://discord.com/developers/docs/resources/webhook) |

---

### 🧩 How It Works

1. A player initiates the robbery.  
- The server checks if enough on-duty police officers are present.  
- It also verifies that the required item is in the player's inventory.

2. If all conditions are met:  
- The item is consumed and a cooldown starts.  
- A dispatch or in-game alert is sent to the police.

3. Players break display cases and loot is recorded temporarily.  

4. When all cases are broken:  
- Loot is given to the participants.  
- Police blips are cleared and the robbery ends.  
- Events are logged to Discord.

---

### 📜 Configuration
Edit `config.lua` to change:
- `Config.RequiredCops` → Minimum required police  
- `Config.RequiredItem` → Item required to start robbery  
- `Config.GlobalCooldown` → Global cooldown between robberies  
- `Config.CaseCooldown` → Per-case cooldown  
- `Config.Loot` → Reward items and chances  
- `Config.Discord.Webhook` → Discord webhook link (optional)

---

### 🚀 Quick Installation
1. Place the folder inside `resources/[robbery]/GR-jewelrob`.  
2. Add this line to your `server.cfg`:
3. Make sure all dependencies are installed.  
4. Restart your server.

---

### 🧾 License
Developed under **QBCore Framework**.  
You are free to modify and use it on your RP server.
