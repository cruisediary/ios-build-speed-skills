#!/usr/bin/env bash
# Before: default or suboptimal Xcode preferences
# Run this to see your current settings

defaults read com.apple.dt.Xcode ShowBuildOperationDuration 2>/dev/null || echo "ShowBuildOperationDuration: not set (build time hidden)"
defaults read com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 2>/dev/null || echo "IDEBuildOperationMaxNumberOfConcurrentCompileTasks: not set"
defaults read com.apple.dt.Xcode IDEIndexingEnabled 2>/dev/null || echo "IDEIndexingEnabled: not set"
defaults read com.apple.dt.Xcode DerivedDataLocationStyle 2>/dev/null || echo "DerivedDataLocationStyle: not set"
defaults read com.apple.dt.Xcode BuildSystemSchedulerWorkerCountOverride 2>/dev/null || echo "BuildSystemSchedulerWorkerCountOverride: not set"
