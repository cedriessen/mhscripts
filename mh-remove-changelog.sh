#!/bin/sh
for a in $(find etc docs -type f); do   
  awk '!/@changelog/' $a > ___fix_changelog___.tmp && mv ___fix_changelog___.tmp $a
done
git diff --stat -p