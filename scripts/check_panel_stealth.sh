#!/bin/bash
# ck-parrot v2.1.1: the menu-bar panel must stay a share-protected window.
# Menus, alerts and context menus open separate windows (NSMenu / NSAlert)
# that screen sharing can see, so the panel source must not use them.
set -e
cd "$(dirname "$0")/.."
f=Parrot/Views/MenuBarView.swift
fail=0
for pat in 'Menu {' 'Menu(' '.contextMenu' 'NSAlert' 'pickerStyle(.menu)' '.popover(' '.confirmationDialog' '.alert('; do
  if grep -vE '^[[:space:]]*//' "$f" | grep -qF "$pat"; then echo "FAIL: $f uses $pat"; fail=1; fi
done
grep -q 'menuBarExtraStyle(.window)' Parrot/ParrotApp.swift || { echo "FAIL: MenuBarExtra is not a .window panel"; fail=1; }
grep -q 'sharingType = type' Parrot/ParrotApp.swift || { echo "FAIL: share protection missing"; fail=1; }
grep -q 'didUpdateNotification' Parrot/ParrotApp.swift || { echo "FAIL: popups/tooltips not re-protected"; fail=1; }
[ $fail = 0 ] && echo "panel stealth: OK"
exit $fail
