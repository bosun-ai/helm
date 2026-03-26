## [0.9.0] - 2026-03-26

### 🚀 Features

- Support extra Quak volumes and configurable Postgres PGDATA (#18)
## [bosun-0.8.3] - 2026-02-02

### ⚙️ Miscellaneous Tasks

- Bump appVersion
- Release 0.8.3 (#17)
## [bosun-0.8.2] - 2026-01-30

### ⚙️ Miscellaneous Tasks

- Bump appVersion
- Bump appVersion
- Bump appVersion
- Release 0.8.2 (#16)
## [bosun-0.8.1] - 2026-01-28

### ⚙️ Miscellaneous Tasks

- Bump chart version
- Release 0.8.1 (#15)
## [bosun-0.8.0] - 2026-01-26

### 🚀 Features

- Opt-out auto generate AR encryption secrets once

### ⚙️ Miscellaneous Tasks

- Release 0.8.0 (#14)
## [bosun-0.7.2] - 2026-01-26

### ⚙️ Miscellaneous Tasks

- Bump appVersion
- Release 0.7.2 (#13)
## [bosun-0.7.1] - 2026-01-26

### ⚙️ Miscellaneous Tasks

- Bump appVersion
- Release 0.7.1 (#12)
## [bosun-0.7.0] - 2026-01-23

### 🚀 Features

- Optionally override executor image

### 🐛 Bug Fixes

- Disable tasks-only node selection by default

### 📚 Documentation

- Explain cidr support

### ⚙️ Miscellaneous Tasks

- Release 0.7.0 (#11)
## [bosun-0.6.0] - 2026-01-23

### 🚀 Features

- Ensure stern / quak are always in allowed hosts

### 🐛 Bug Fixes

- Executor uses the release namespace by default
- RBAC follows the executor namespace if overridden

### ⚙️ Miscellaneous Tasks

- Release 0.6.0 (#10)
## [bosun-0.5.1] - 2026-01-23

### ⚙️ Miscellaneous Tasks

- Bump appVersion
- Release 0.5.1 (#9)
## [bosun-0.5.0] - 2026-01-22

### 🚀 Features

- Configure stern allowed hosts

### ⚙️ Miscellaneous Tasks

- Bump appVersion to 0.76
- Release 0.5.0 (#8)
## [bosun-0.4.0] - 2026-01-22

### 🚀 Features

- Configurable STERN_BASE_URL with sane default
- Default to subpath for backend ingress

### ⚙️ Miscellaneous Tasks

- Bump appVersion
- Release 0.4.0 (#7)
## [bosun-0.3.0] - 2026-01-21

### 🚀 Features

- Opt-out storage and configurable resources for executor

### ⚙️ Miscellaneous Tasks

- Bump Bosun app version
- Release 0.3.0 (#6)
## [bosun-0.2.0] - 2026-01-21

### 🐛 Bug Fixes

- Strip bosun- prefix from cliff version
## [bosun-v0.2.0] - 2026-01-20

### 🚀 Features

- Global tolerations
- Global tolerations also apply to k88s executor
- Auto-generate internal api token

### 🐛 Bug Fixes

- *(ci)* Edit correct chart release with change notes
- Manually set chart version

### ⚙️ Miscellaneous Tasks

- Bump appVersion to 0.73.0
- Release bosun-v0.2.0 (#5)
## [bosun-v0.1.2] - 2026-01-19

### 🐛 Bug Fixes

- *(ci)* Trim extra versions from pipeline

### ⚙️ Miscellaneous Tasks

- Test empty release
- Test empty release
- Release v0.1.2 (#4)
## [0.1.1] - 2026-01-19

### 🐛 Bug Fixes

- *(ci)* Fix linter
- *(ci)* Set user name and email for chart release

### ⚙️ Miscellaneous Tasks

- Release vv0.1.1 (#3)
## [0.1.0] - 2026-01-19

### 🚀 Features

- Working on e2e
- Tag to latest and bosun workspace
- Support both github and gitlab
- *(ci)* Automate chart releases
- Use the appVersion with configurable overrides

### 🐛 Bug Fixes

- Autogen secrets
- Set current to 0.0.1 and exit early if update failed
- Skip verify on helm-unittest and fix test
- *(ci)* Woops arg order

### 📚 Documentation

- Improve readme
- Update readme with github helm repo

### ⚙️ Miscellaneous Tasks

- Initial commit
- Focus on zero config
- Release chart
- Fix chart version
- Release v0.1.0 (#2)
- Also publish github release
- *(ci)* Add lint and unit tests to ci
- Remove temporary k3d kubeconfig from git
- Move chart to subdirectory
