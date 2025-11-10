### Inventory Management App with Firestore

This project implements a fully functional Inventory Management Application using Flutter and Firebase Firestore, allowing users to perform standard Create, Read, Update, and Delete (CRUD) operations on inventory items, with real-time data synchronization.

### Implemented Enhanced Features

To meet the requirement for demonstrating a deeper understanding the following two enhanced features were implemented:

1.  Data Insights Dashboard
    * A separate screen accessible from the Home Page's AppBar (analytics icon).
    * Provides key, real-time aggregated statistics, including:
        * Total number of unique items
        * Total value of all inventory(calculated as the sum of quantity * price).
        * A list of out-of-stock items (quantity = 0).

2.  Advanced Filtering: Category Filter Dropdown
    * A dynamic Dropdown Filter is displayed on the main `Inventory Home Page`.
    * Allows users to filter the displayed item list in real-time based on the selected item category.

---

### Project Setup & How to Run

Follow these steps to configure and run the application locally:

### Prerequisites

* Flutter SDK installed and configured.
* The Firebase Console project with Firestore Database enabled in test mode.

### Configuration Steps

1.  Clone the Repository and navigate into the project directory
2.  Activate FlutterFire CLI (if not already done): `dart pub global activate flutterfire_cli`
3.  Install Dependencies: Run `flutter pub get` (This ensures `firebase_core` and `cloud_firestore` are included
4.  Configure Firebase Project: Run the FlutterFire CLI command from the project root: `flutterfire configure`
5.  Select your Firebase project. This generates the required `firebase_options.dart` file

### Running the App

1.  Start an emulator or connect a device.
2.  Run the application using the command: `flutter run`.

### APK Generation

* To create the release APK: `flutter build apk --release`
* The resulting file will be located at: `build/app/outputs/flutter-apk/app-release.apk`