# STAANA Project

STAANA is a Flutter shoe-shopping app with product browsing, community shoe
listings, favorites, cart and checkout, order history, reviews, and private
one-to-one chat.

## Features

- Browse men's and women's shoes, search and sort products, and view product
  details and reviews.
- Save or remove favorites and manage a user-specific shopping cart.
- Submit shoe listings with a photo, description, available sizes, and price.
- Review the current user's orders and listings.
- Create orders through the demo checkout flow.
- Chat privately with another registered user. Conversations are stored in
  Firestore under a room shared by the two participants.
- Switch between light and dark appearance from the Profile tab.
- Admin users can approve or reject submitted shoe listings.

Catalog products are fetched from DummyJSON. User accounts, community listings,
orders, favorites, carts, reviews, and chats use Firebase.

## Requirements

- Flutter SDK and Dart SDK compatible with the versions declared in
  `pubspec.yaml`.
- Android Studio / Android SDK for Android builds, or another Flutter-supported
  platform toolchain.
- A Firebase project with Firebase Authentication and Cloud Firestore enabled.

## Run locally

From the project directory:

```sh
flutter pub get
flutter run
```

To target a specific connected device:

```sh
flutter devices
flutter run -d <device-id>
```

## Firebase configuration

The app initializes Firebase with `lib/firebase_options.dart`. To configure a
different Firebase project, install the FlutterFire CLI and run:

```sh
flutterfire configure --project=<firebase-project-id>
```

Deploy the Firestore security rules before using the app:

```sh
firebase deploy --only firestore:rules --project <firebase-project-id>
```

The rules are in `firestore.rules`, and `firebase.json` points to that file.
The private chat rules require each `chat_rooms/{roomId}` document to contain
the two participant user IDs. Messages are stored in the room's `messages`
subcollection with `text`, `senderId`, `senderName`, and `createdAt` fields.
Only those participants can read the room and its messages.

The rules allow signed-in users to read user profile documents, as required by
the current profile and chat contact screens. Review the rules and adjust them
for your deployment's privacy requirements.

## Firestore data

- `users/{uid}`: profile fields, including display name, email, phone, address,
  and role.
- `users/{uid}/cart/{itemId}`: that user's cart items.
- `users/{uid}/favorites/{productId}`: that user's saved product IDs.
- `listings/{listingId}`: community-submitted shoes and moderation status.
- `orders/{orderId}`: checkout records associated with a user ID.
- `products/{productId}/reviews/{reviewId}`: product reviews.
- `chat_rooms/{roomId}` and `chat_rooms/{roomId}/messages/{messageId}`: private
  conversations and their messages.

## Checks

Run static analysis and tests with:

```sh
flutter analyze
flutter test
```

Build an Android debug APK with:

```sh
flutter build apk --debug
```
