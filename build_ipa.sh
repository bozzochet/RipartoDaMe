#!/bin/bash

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
/opt/homebrew/bin/flutter build ipa --release
ls -Flarth build/ios/ipa
open build/ios/ipa
