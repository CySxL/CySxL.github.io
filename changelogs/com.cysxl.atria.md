## 1.9.3
* ask whether to include App Library categories when exporting settings, since they list your installed apps.
* keep Edit Categories changes when Settings is closed from the app switcher.
* leave Custom Categories inactive on iOS versions that lack what it needs, rather than risk crashing SpringBoard.
* say in the Hide Actions footer that the App Library category actions stay.

## 1.9.2
* add Hide Suggestions and Hide Recently Added.
* add Show in Dock to Category Order, to pick the category the dock's App Library icon shows.
* show the remaining apps as four small icons on the dock's App Library icon.

## 1.9.0
* add an App Library Categories page to the settings.
* add Edit Categories to drag apps between categories and reorder them.
* add Category Order to reorder and rename categories.
* add new categories, and delete them to give their apps back.
* fix three causes of SpringBoard crashing at launch on iOS 26.
* turn Dynamic Widget Sizing off on iOS 26, where it crashed SpringBoard.

## 1.8.6
* move apps to another App Library category and rename categories from the long press menu, with Custom Categories on.
* add Reset Categories to put every app and name back.

## 1.8.5
* fix SpringBoard crashing into safe mode when the editor opens on iOS 17.
* credit s-gdn for the iOS 17 fix, with a link to the source.

## 1.8.4
* keep the App Library pod in place when a Handoff app appears, with App Library Before Recents on.

## 1.8.3
* show the package icon after install.
* add a Tip on Ko-fi row to the credits.

## 1.8.2
* move to the com.cysxl package id, replacing ren7995's Atria.

Changes from ren7995's Atria 1.4.1:
* support roothide and rootless.
* add Label Y Offset to the dock and homescreen editors.
* add Show in Dock, which labels dock icons, recents and the App Library pod.
* add App Library Before Recents, Lock Label Text and Hide Open Folder Background.
* position the page dots per page, and let dot and label offsets reach the top of the screen.
* fetch the weather only when it is shown, and turn Show Weather Icon off by default.
* pick colors with the system color picker.
* hide rows whose switch is off.
* fix the floating dock showing only two recents.
* fix Hide Page Dots on iOS 16.
* check a saved icon layout before SpringBoard gets it, so a bad one can no longer stop the homescreen coming up.
* cut the work done per icon, per label and per layout, which removes the stutter on page swipes and in low power mode.
