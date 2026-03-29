#!/usr/bin/env bash
# After: optimized Xcode preferences
# These are the commands xcode-settings applies (with your confirmation)

# Show build duration in the Xcode activity viewer
defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES

# Remove artificial compile task limit (let Xcode use all CPU cores)
defaults delete com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 2>/dev/null || true

# For large projects (>200 source files): disable Index While Building
# defaults write com.apple.dt.Xcode IDEIndexingEnabled -bool NO

# Remove artificial scheduler worker override
defaults delete com.apple.dt.Xcode BuildSystemSchedulerWorkerCountOverride 2>/dev/null || true

echo "✅ Xcode preferences updated. Quit and relaunch Xcode for changes to take effect."
