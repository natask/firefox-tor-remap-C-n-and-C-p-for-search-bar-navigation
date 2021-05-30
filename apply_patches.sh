#!/bin/bash
# configuration variables
backup=true
firefoxType="firefox-developer-edition"
backupOmniLocation="~/org-data/23/bf5056-ded7-4a8e-8c00-c6a924208c17/omni.ja"

# setup stuff and get started
backupOmniLocation="${backupOmniLocation/#\~/$HOME}" #replaces ~ with ${HOME}
omniPath="/usr/lib/${firefoxType}/browser/omni.ja" 
tempdir=$(mktemp -d)
mkdir "$tempdir/extract"
cd "$tempdir/extract"

#set +e
#unzip /usr/lib/firefox/browser/omni.ja
unzip ${omniPath}; #unzip /usr/lib/firefox/browser/omni.ja
#if [ "$?" -ne 0 ]; then
#  echo >&2 "Unexpected exit code from unzip"
#  exit 1
#fi
#set -e


# apply patches
set +e
patch chrome/browser/content/browser/browser.xhtml << EOF
diff --git a/chrome/browser/content/browser/broswer.xhtml.orig b/chrome/browser/content/browser/browser.xhtml
index ffd3d59..ed48e55 100644
--- a/chrome/browser/content/browser/broswer.xhtml.orig
+++ b/chrome/browser/content/browser/browser.xhtml
@@ -270,7 +270,7 @@ if (AppConstants.platform == "macosx") {
     <key id="key_newNavigator"
          data-l10n-id="window-new-shortcut"
          command="cmd_newNavigator"
-         modifiers="accel" reserved="true"/>
+         modifiers="alt" reserved="true"/>
     <key id="key_newNavigatorTab" data-l10n-id="tab-new-shortcut" modifiers="accel"
          command="cmd_newNavigatorTabNoEvent" reserved="true"/>
     <key id="focusURLBar" data-l10n-id="location-open-shortcut" command="Browser:OpenLocation"
@@ -290,7 +290,7 @@ if (AppConstants.platform == "macosx") {
     <key id="key_openAddons" data-l10n-id="addons-shortcut" command="Tools:Addons" modifiers="accel,shift"/>
     <key id="openFileKb" data-l10n-id="file-open-shortcut" command="Browser:OpenFile"  modifiers="accel"/>
     <key id="key_savePage" data-l10n-id="save-page-shortcut" command="Browser:SavePage" modifiers="accel"/>
-    <key id="printKb" data-l10n-id="print-shortcut" command="cmd_print"  modifiers="accel"/>
+    <key id="printKb" data-l10n-id="print-shortcut" command="cmd_print"  modifiers="alt"/>
     <key id="key_close" data-l10n-id="close-shortcut" command="cmd_close" modifiers="accel" reserved="true"/>
     <key id="key_closeWindow" data-l10n-id="close-shortcut" command="cmd_closeWindow" modifiers="accel,shift" reserved="true"/>
     <key id="key_toggleMute" data-l10n-id="mute-toggle-shortcut" command="cmd_toggleMute" modifiers="control"/>
     <key id="key_toggleMute" data-l10n-id="mute-toggle-shortcut" command="cmd_toggleMute" modifiers="control"/>
EOF
if [ "$?" -ne 0 ]; then
  echo >&2 "Unexpected exit code from first patch"
  exit 1
fi
patch  modules/UrlbarController.jsm << EOF
--- extract_orig/modules/UrlbarController.jsm   2010-01-01 00:00:00.000000000 -0800
+++ extract/modules/UrlbarController.jsm        2020-07-22 16:36:20.000000000 -0700
@@ -337,6 +337,35 @@
           event.preventDefault();
         }
         break;
+      case KeyEvent.DOM_VK_N:
+      case KeyEvent.DOM_VK_P:
+        if(event.ctrlKey && !event.altKey && !event.shiftKey) {
+            if (this.view.isOpen) {
+                if (executeAction) {
+                    //this.userSelectionBehavior = "emacs";
+                    this.view.selectBy(
+                            1,
+                        {
+                            reverse:
+                            event.keyCode == KeyEvent.DOM_VK_P,
+                        }
+                    );
+                }
+            } else {
+                if (this.keyEventMovesCaret(event)) {
+                    break;
+                }
+                if (executeAction) {
+                    //this.userSelectionBehavior = "emacs";
+                    this.input.startQuery({
+                        searchString: this.input.value,
+                        event,
+                    });
+                }
+            }
+            event.preventDefault();
+        }
+        break;
       case KeyEvent.DOM_VK_DOWN:
       case KeyEvent.DOM_VK_UP:
       case KeyEvent.DOM_VK_PAGE_DOWN:
EOF
if [ "$?" -ne 0 ]; then
  echo >&2 "Unexpected exit code from second patch"
  exit 1
fi
set -e

# zip back omni.ja
zip -qr9XD ../omni.ja *

#do backup if told
if [ "${backup}" = "true" ];then
cat "${omniPath}" > "${backupOmniLocation}"
fi

#set new omni.ja as current omni.ja
sudo bash -c "cat $tempdir/omni.ja > ${omniPath}"

#flush cache 
find ~/.cache/mozilla/firefox -type d -name startupCache | xargs rm -rf
cd /

rm -r "$tempdir"
