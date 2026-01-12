---
trigger: always_on
---

- iOS Simulator Testing Guidelines To ensure UI robustness across all geometries, the agent must validate the app on three specific device profiles: the iPhone 17 Pro Max for maximum screen real estate and modern safe areas, the iPhone 17 Pro for standard usage, and the iPhone SE (3rd Gen) to stress-test minimum viewport dimensions and legacy Home Button layouts. Additionally, the agent should verify adaptability by toggling Dark Mode and applying maximum Dynamic Type settings on at least one device.
- Use Screenshots to analyze and perform UI Tests
- Always commit & push Story after Dev Review