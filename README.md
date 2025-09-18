Project 2 — BeReal Clone (Instaparse, Part 1)
=================================================

Submitted by: 
Angelo Milonas  
Z23473813

Overview
--------
This project is a Part‑1 clone of BeReal built with UIKit. Users can sign up, log in, and stay logged in using a Parse backend (Back4App). They can pick a photo from the library, add a caption, and upload a post. The feed shows posts with username, image, caption, and timestamp. For my variant, the feed is **gated**: newly logged‑in users see a message until they upload a photo in the current session.

Tech Stack
----------
- UIKit, Auto Layout
- ParseSwift SDK (Back4App)
- PhotosUI (`PHPickerViewController`)
- AlamofireImage (async image loading)
- Swift 5, Xcode (iOS 17+/18 simulator)

Required Features (Part 1)
--------------------------
- [x] User can **sign up** for a new account using Parse backend  
- [x] User can **log in** to an existing account  
- [x] User can **log out** of their account  
- [x] Login credentials are **persisted** across app launches  
- [x] User can **pick an image** from the photo library using `PHPickerViewController`  
- [x] User can **create a post** with a caption and image (uploaded as `ParseFile`)  
- [x] User can **view posts** in a feed with username, image, caption, and timestamp  

Additional / Custom Features
----------------------------
- [x] **Session gate**: Hide feed images until the user uploads a photo **during this session**; show a centered label instead
- [x] Background label uses `tableView.backgroundView` for a clean empty state
- [x] Error handling alerts for sign‑up, login, and posting
- [x] Lightweight image compression before upload
- [x] Async image loading in table cells with request cancellation on reuse
- [x] Basic dark mode UI polish (system colors, gray placeholders, centered text fields)

Walkthrough (GIF)
-----------------
- `lab2-amilonas2018.gif` (add to repo root or link here)

Architecture Notes
------------------
- **Models**: `User` (`ParseUser`), `Post` (`ParseObject` with `user`, `caption`, `imageFile`)
- **Controllers**: `LoginViewController`, `FeedViewController`, `PostViewController`
- **Session flow**: Login → (Feed gated) → Post → Feed shows images
- **Notifications**: `Notification.Name("login")`, `Notification.Name("logout")`, and custom `.didCreatePost` notify feed to refresh after a post
- **Persistence**: ParseSwift handles current user. A `UserDefaults` flag (`hasPostedThisSession`) tracks the session gate.

Setup / How to Run
------------------
1. Clone or open the project in Xcode.
2. Add your Back4App keys (`applicationId`, `clientKey`, `serverURL`) in your app startup (e.g., `AppDelegate`).
3. Run on an iPhone simulator or device.
4. Create an account, log in, **upload a photo**, and then view the feed.

Known Limitations / Next Steps
------------------------------
- Stretch goals such as **pull to refresh**, **infinite scroll**, and **location/time metadata** are not yet implemented.
- Real‑time updates and friend graph are out of scope for Part 1.

Attribution
-----------
- Based on CodePath iOS102 Unit 2 (BeReal clone) guidelines and README template.
- ParseSwift and Back4App documentation for backend setup.

License
-------
Copyright 2025 Angelo Milonas

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
