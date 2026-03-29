# Atlas Fitness

An AI-powered fitness tracking app for Android built with Flutter.

---

## 📲 Getting the App on Your Android Phone

### Step 1 — Download the APK from GitHub Actions

Every push to `main` automatically builds a release APK and uploads it as a GitHub Actions artifact.

1. Go to the **Actions** tab at the top of this repository page.
2. Click the latest **"Build Android APK"** workflow run that has a green ✅ checkmark.
3. Scroll to the bottom of the run page to the **Artifacts** section.
4. Click **`atlas-release-apk`** to download a `.zip` file.
5. Unzip the file — inside you will find **`app-release.apk`**.

> The artifact is kept for **30 days** per run. If it has expired, re-trigger a build by going to  
> Actions → Build Android APK → **Run workflow**.

---

### Step 2 — Install the APK on Your Android Phone

Android blocks installs from outside the Play Store by default. Follow these steps once to allow it.

#### Enable "Install unknown apps"

| Android version | Where to find the setting |
|---|---|
| Android 8+ | Settings → Apps → Special app access → Install unknown apps → select your **browser or Files app** → turn on *Allow from this source* |
| Android 7 and below | Settings → Security → turn on *Unknown sources* |

#### Transfer and install

1. **Transfer** `app-release.apk` to your phone — easiest ways:
   - Share via **Google Drive / Dropbox / OneDrive** and open it on the phone.
   - Connect via USB cable and copy the file to the phone's storage.
   - Email it to yourself and open the attachment on the phone.
2. On the phone, open a **file manager** (or the email/cloud app), find the APK, and tap it.
3. Tap **Install** → **Open**.

---

### Step 3 — Add Your Gemini API Key

The AI Diet Coach feature requires a free Gemini API key. The key is stored securely on your device using Android's encrypted storage — it is never sent anywhere except directly to Google's Gemini API.

#### Get a free key (takes ~1 minute)

1. Go to **[https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)**
2. Sign in with your Google account.
3. Click **"Create API key"** and copy the key (it starts with `AIza...`).

#### Enter the key in the app

1. Open **Atlas** on your phone.
2. Tap the **☰ menu** (top-left) or navigate to **Settings** (⚙️ icon).
3. Under **"AI Diet Coach"**, paste your key into the **Gemini API Key** field.
4. Tap **Save API Key**.

The AI Diet Coach chat will work immediately — no restart needed.

> **Privacy note:** The key is stored using Android's `EncryptedSharedPreferences` (backed by  
> the Android Keystore). Other apps cannot read it.

---

## Features

- 🤖 **AI Diet Coach** — conversational nutrition guidance powered by Gemini
- 🏋️ **Exercise Logger** — sets, reps, and weight tracking
- 📊 **Body Metric Charts** — interactive weight and measurement progress
- ⚡ **Workout Generator** — auto-generated plans by difficulty and muscle group
- 🔥 **Streak Tracking** — daily workout consistency streaks
- 🏆 **Weekly Challenges** — gamified competitive challenges
- 📣 **Community Feed** — post, like, and comment
- 🔔 **Smart Notifications** — daily tips and workout reminders

---

## Full Developer Docs

See [ATLAS_README.md](ATLAS_README.md) for the complete setup guide (Flutter, Firebase, environment variables, project structure, and more).
