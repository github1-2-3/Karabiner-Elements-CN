#!/bin/sh
make -C /Users/mojave/Karabiner-Elements/src/core/kextd/build_xcode -f /Users/mojave/Karabiner-Elements/src/core/kextd/build_xcode/CMakeScripts/ZERO_CHECK_cmakeRulesBuildPhase.make$CONFIGURATION OBJDIR=$(basename "$OBJECT_FILE_DIR_normal") all
