# Firebase Setup Guide

Follow these steps to prepare your project for Firebase integration.

## 1. Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com/).
2. Click **Add project**.
3. Name it (e.g., "ChatView App") and continue.
4. Disable Google Analytics for now (simplifies setup) and click **Create project**.

## 2. Register iOS App
1. In the project overview, click the **iOS+** icon.
2. Enter your **Bundle ID**. 
   - *To find this*: Open Xcode -> Click the root Project icon -> Select Target -> 'General' tab -> 'Bundle Identifier'.
3. (Optional) Enter App Nickname.
4. Click **Register app**.

## 3. Configuration File
1. Download **GoogleService-Info.plist**.
2. Drag and drop this file into your Xcode project navigator (root folder).
3. **Important**: Make sure "Add to targets" is checked for your main app target.

## 4. Enable Services

### Realtime Database
1. In Firebase Console sidebar, go to **Build** -> **Realtime Database**.
2. Click **Create Database**.
3. Choose a location (e.g., United States).
4. **Security Rules**: Choose **Start in Test Mode**.
   - *Note*: This allows anyone to read/write for 30 days. We will secure this later.
5. Click **Enable**.

### Storage
1. In sidebar, go to **Build** -> **Storage**.
2. Click **Get started**.
3. **Security Rules**: Choose **Start in Test Mode**.
4. Click **Done**.

### Authentication (Anonymous)
1. In sidebar, go to **Build** -> **Authentication**.
2. Click **Get started**.
3. Select **Anonymous** from the Sign-in method list.
4. Toggle **Enable** and save.
   - *Why?* Even for a demo, it's best to have a user ID so we can identify "me" vs "others".

## 5. Add SDK to Xcode (I will do this part, but here is how)
1. Settings -> Package Dependencies.
2. Add `https://github.com/firebase/firebase-ios-sdk`.
3. Choose modules: `FirebaseDatabase`, `FirebaseStorage`, `FirebaseAuth`.

Once you have downloaded `GoogleService-Info.plist` and added it to your project, let me know, and I will proceed with the code!
