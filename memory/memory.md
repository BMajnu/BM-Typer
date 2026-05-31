# BM-Typer Project Memory

## Entry #1
**Prompt:** Make the debugging on the app but first run the app on windows.
**Action:** Created Debug Screen and ran app on Windows
**Changes:**
- `lib/presentation/screens/debug_screen.dart`: নতুন ফাইল তৈরি (Debug Console with service health, logs, Firebase/Hive/Connectivity status)
- `lib/main.dart`: লাইন 28 (import) এবং লাইন 176-177 (route `/debug`) যোগ করা হয়েছে
- `lib/presentation/widgets/settings_panel.dart`: লাইন 14 (import) এবং লাইন 369-378 ("ডিবাগ কনসোল" মেনু আইটেম) যোগ করা হয়েছে
**Reason:** ব্যবহারকারী Windows-ে অ্যাপ রান করতে এবং ডিবাগিং ফিচার যোগ করতে চেয়েছিলেন
**Result:** অ্যাপ সফলভাবে Windows-ে বিল্ড ও রান হয়েছে। Debug Screen-ে Firebase, Hive, Connectivity স্ট্যাটাস এবং real-time log console যোগ করা হয়েছে। Settings Panel থেকে "ডিবাগ কনসোল" অপশনে ক্লিক করে যাওয়া যাবে।
**Timestamp:** 2026-05-27

---
