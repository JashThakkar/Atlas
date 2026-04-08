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

---

## Developer Setup Notes

### Firebase — `circles` Collection & Indexes

The **Circles** feature uses a Firestore collection named `circles`. You need to:

1. **Create the collection** — it is created automatically the first time a user creates a Circle inside the app. No manual step is required in the Firebase Console for the collection itself.

2. **Deploy the Firestore index** — the app queries circles by membership and sorts them by creation time, which requires a composite index. Deploy it with the Firebase CLI:

   ```bash
   firebase deploy --only firestore:indexes
   ```

   This reads `firestore.indexes.json` (already in the repo) and creates the required index:

   | Collection | Fields |
   |---|---|
   | `circles` | `memberIds` (array-contains) + `createdAt` (descending) |

   > **Without this index the Circles screen will show an error and a link to create the index in the Firebase Console.** You can also click that link to create it directly without the CLI.

3. **Firestore Security Rules** — ensure your `firestore.rules` allows authenticated users to read/write their own circles. The rules already in the repo cover this.

---

### Spotify Integration — `.env` and GitHub Secret

The in-app music player uses the Spotify Web API. To enable it:

#### Local development

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and sign in.
2. Click **Create app**, fill in a name, and set the Redirect URI to:
   ```
   atlasfit://spotify-callback
   ```
3. Copy the **Client ID** shown on the app's overview page.
4. Open (or create) the `.env` file in the project root and add:
   ```env
   SPOTIFY_CLIENT_ID=your_spotify_client_id_here
   ```

#### GitHub Actions (CI builds)

The build workflow reads `SPOTIFY_CLIENT_ID` from a GitHub secret so the APK produced by CI also includes Spotify support.

1. In your GitHub repository go to **Settings → Secrets and variables → Actions**.
2. Click **New repository secret**.
3. Set **Name** to `SPOTIFY_CLIENT_ID` and **Secret** to your Client ID from the Spotify Dashboard.
4. Click **Add secret**.

> **Note:** Playback control (play/pause/skip) requires a Spotify Premium account. All account types can view the currently-playing track.
