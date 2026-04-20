# Dashboard Module - File Locations

This document provides a complete reference of all files related to the Dashboard module.

---

## 📂 Component Files

### Dashboard Components (`src/frontend/src/components/dashboard/`)

| File | Description | Type |
|------|-------------|------|
| `StatsCard.vue` | Reusable statistics card with trend indicators | Component |
| `FactoryCard.vue` | Factory service showcase card with gradients | Component |
| `ActivityTimeline.vue` | Vertical timeline for recent activities | Component |
| `EcosystemChart.vue` | Donut chart for ecosystem distribution | Chart Component |
| `ActivityChart.vue` | Area chart for platform activity over time | Chart Component |

---

## 📄 View Files

### Dashboard Views (`src/frontend/src/views/Dashboard/`)

| File | Description | Route |
|------|-------------|-------|
| `DashboardView.vue` | Main comprehensive dashboard page | `/` |
| `User.vue` | User-specific dashboard (legacy) | `/user/:id` |

---

## 🛠️ Utility Files

### Dashboard Utilities (`src/frontend/src/utils/`)

| File | Description | Exports |
|------|-------------|---------|
| `dashboard.ts` | Dashboard helper functions | `formatICP()`, `formatNumber()`, `calculateChange()`, `generateMockTimeSeries()`, `getFactoryStatus()`, `getFactoryFeeInfo()`, `getFactoryFeatures()`, `getFactoryGradient()` |

---

## 🗺️ Configuration Files

### Router Configuration

| File | Description | Modified Section |
|------|-------------|-----------------|
| `src/frontend/src/router/index.ts` | Vue Router configuration | Added `/` route for DashboardView, `/token` routes |

---

## 📚 Documentation Files

### Dashboard Documentation (`documents/modules/dashboard/`)

| File | Description |
|------|-------------|
| `CHANGELOG.md` | Complete change history and future tasks |
| `FILES.md` | This file - complete file reference |
| `README.md` | Dashboard module overview (to be created) |
| `IMPLEMENTATION_GUIDE.md` | How to extend the dashboard (to be created) |

### Root Documentation

| File | Description |
|------|-------------|
| `DASHBOARD_IMPLEMENTATION.md` | Complete implementation documentation |

---

## 🎨 Asset Files

### Images (None currently - using Lucide icons)

Future assets may include:
- Logo variations
- Factory icons
- Illustration assets

---

## 📦 Type Definitions

### Types Used (from existing files)

| File | Types Imported |
|------|----------------|
| `src/frontend/src/types/token.ts` | TokenInfo, Token |
| `src/frontend/src/types/multisig.ts` | WalletInfo, WalletRegistry |
| `src/frontend/src/types/distribution.ts` | DistributionInfo |
| `src/frontend/src/types/dao.ts` | DAOInfo, DAOContract |
| `src/frontend/src/types/launchpad.ts` | LaunchpadInfo, LaunchpadContract |

### Types to Create (Future)

- `src/frontend/src/types/dashboard.ts`
  - DashboardStats
  - FactoryStats
  - ActivityData
  - TimeSeriesData

---

## 🔌 Service Integration

### Services Used

| Service File | Purpose |
|-------------|---------|
| `src/frontend/src/api/services/tokenFactory.ts` | Fetch token statistics |
| `src/frontend/src/api/services/multisigFactory.ts` | Fetch multisig statistics |
| `src/frontend/src/api/services/distributionFactory.ts` | Fetch distribution statistics |
| `src/frontend/src/api/services/daoFactory.ts` | Fetch DAO statistics |
| `src/frontend/src/api/services/launchpadFactory.ts` | Fetch launchpad statistics |
| `src/frontend/src/api/services/backend.ts` | Backend integration (future use) |

---

## 🧪 Test Files (To Be Created)

### Unit Tests

- `src/frontend/src/components/dashboard/__tests__/StatsCard.spec.ts`
- `src/frontend/src/components/dashboard/__tests__/FactoryCard.spec.ts`
- `src/frontend/src/components/dashboard/__tests__/ActivityTimeline.spec.ts`
- `src/frontend/src/components/dashboard/__tests__/EcosystemChart.spec.ts`
- `src/frontend/src/components/dashboard/__tests__/ActivityChart.spec.ts`

### Integration Tests

- `src/frontend/src/views/Dashboard/__tests__/DashboardView.spec.ts`

### Utility Tests

- `src/frontend/src/utils/__tests__/dashboard.spec.ts`

---

## 📊 Chart Components

### ApexCharts Integration

| Component | Chart Type | Data Source |
|-----------|-----------|-------------|
| `EcosystemChart.vue` | Donut | Factory statistics (tokens, multisigs, distributions, daos, launchpads) |
| `ActivityChart.vue` | Area | Time-series data (deployments, transactions) |

---

## 🎯 Icon Usage

### Lucide Icons Used

| Icon | Usage Location | Purpose |
|------|---------------|---------|
| `RocketIcon` | Hero, Launchpad card, Activities | Token launches, deployment |
| `PlusIcon` | CTAs | Create actions |
| `WalletIcon` | Multisig card | Wallet operations |
| `TrendingUpIcon` | Stats cards | Positive trends |
| `TrendingDownIcon` | Stats cards | Negative trends |
| `LayoutGridIcon` | Total contracts | Grid representation |
| `UsersIcon` | Active users | User count |
| `DollarSignIcon` | TVL | Financial metrics |
| `ActivityIcon` | Transactions | Activity indicator |
| `FactoryIcon` | Factory section | Factory services |
| `CoinsIcon` | Token factory, Quick actions | Token operations |
| `LockKeyholeIcon` | Multisig factory | Security |
| `SendIcon` | Distribution factory | Distribution |
| `BuildingIcon` | DAO factory | Governance |
| `SparklesIcon` | Coming soon | Future features |
| `PieChartIcon` | Ecosystem chart | Data visualization |
| `RefreshCwIcon` | Refresh buttons | Reload data |
| `BarChart3Icon` | Activity chart | Chart indicator |
| `ClockIcon` | Activity timeline | Time tracking |
| `ZapIcon` | Quick actions, Features | Speed/performance |
| `BookOpenIcon` | Resources | Documentation |
| `ArrowRightIcon` | Links | Navigation |
| `ExternalLinkIcon` | External links | External navigation |
| `EyeIcon` | View buttons | View action |
| `GaugeIcon` | Performance | Metrics |
| `ShieldCheckIcon` | Security | Trust/safety |

---

## 🔗 Component Dependencies

### Dependency Tree

```
DashboardView.vue
├── AdminLayout.vue (layout)
├── PageBreadcrumb.vue (navigation)
├── StatsCard.vue × 4 (metrics)
├── FactoryCard.vue × 6 (factories)
├── EcosystemChart.vue (visualization)
├── ActivityChart.vue (visualization)
└── ActivityTimeline.vue (activity feed)
```

### External Dependencies

```json
{
  "apexcharts": "^4.4.0",
  "vue3-apexcharts": "^1.8.0",
  "@lucide-vue-next": "latest",
  "vue": "^3.x",
  "vue-router": "^4.x"
}
```

---

## 📝 Configuration Files

### TailwindCSS Configuration

Colors defined in `tailwind.config.js`:
- Custom golden gradient colors
- Factory-specific color schemes

### Environment Variables

Used from `.env`:
- `VITE_BACKEND_CANISTER_ID`
- `VITE_TOKEN_FACTORY_CANISTER_ID`
- `VITE_MULTISIG_FACTORY_CANISTER_ID`
- `VITE_DISTRIBUTION_FACTORY_CANISTER_ID`
- `VITE_DAO_FACTORY_CANISTER_ID`
- `VITE_LAUNCHPAD_FACTORY_CANISTER_ID`

---

## 🚀 Build Files

### Compilation Output

After `npm run build`:
- `dist/assets/DashboardView-[hash].js`
- `dist/assets/StatsCard-[hash].js`
- `dist/assets/FactoryCard-[hash].js`
- `dist/assets/ActivityTimeline-[hash].js`
- `dist/assets/EcosystemChart-[hash].js`
- `dist/assets/ActivityChart-[hash].js`

---

## 📖 Quick File Access Guide

### To modify dashboard layout:
→ `src/frontend/src/views/Dashboard/DashboardView.vue`

### To change stats card styling:
→ `src/frontend/src/components/dashboard/StatsCard.vue`

### To update factory information:
→ `src/frontend/src/utils/dashboard.ts` (getFactoryFeatures, getFactoryFeeInfo)

### To add new chart:
→ Create new component in `src/frontend/src/components/dashboard/`
→ Follow pattern from `EcosystemChart.vue` or `ActivityChart.vue`

### To modify routes:
→ `src/frontend/src/router/index.ts`

### To update factory data sources:
→ Check service files in `src/frontend/src/api/services/`

---

## 🗂️ Directory Structure

```
icto_v2/
├── src/frontend/src/
│   ├── components/
│   │   └── dashboard/          # Dashboard components
│   │       ├── StatsCard.vue
│   │       ├── FactoryCard.vue
│   │       ├── ActivityTimeline.vue
│   │       ├── EcosystemChart.vue
│   │       └── ActivityChart.vue
│   │
│   ├── views/
│   │   └── Dashboard/          # Dashboard views
│   │       ├── DashboardView.vue
│   │       └── User.vue
│   │
│   ├── utils/
│   │   └── dashboard.ts        # Dashboard utilities
│   │
│   ├── router/
│   │   └── index.ts           # Router config (modified)
│   │
│   └── api/services/          # Service integration
│       ├── tokenFactory.ts
│       ├── multisigFactory.ts
│       ├── distributionFactory.ts
│       ├── daoFactory.ts
│       └── launchpadFactory.ts
│
├── documents/modules/
│   └── dashboard/              # Dashboard documentation
│       ├── CHANGELOG.md
│       ├── FILES.md (this file)
│       ├── README.md (to be created)
│       └── IMPLEMENTATION_GUIDE.md (to be created)
│
└── DASHBOARD_IMPLEMENTATION.md  # Root documentation
```

---

## 📅 File Modification History

| File | Created | Last Modified | Author |
|------|---------|--------------|--------|
| `DashboardView.vue` | 2025-10-09 | 2025-10-09 | Claude |
| `StatsCard.vue` | 2025-10-09 | 2025-10-09 | Claude |
| `FactoryCard.vue` | 2025-10-09 | 2025-10-09 | Claude |
| `ActivityTimeline.vue` | 2025-10-09 | 2025-10-09 | Claude |
| `EcosystemChart.vue` | 2025-10-09 | 2025-10-09 | Claude |
| `ActivityChart.vue` | 2025-10-09 | 2025-10-09 | Claude |
| `dashboard.ts` | 2025-10-09 | 2025-10-09 | Claude |
| `router/index.ts` | Previous | 2025-10-09 | Claude |

---

**Last Updated**: 2025-10-09
**Maintained By**: ICTO Development Team
**Version**: 1.0.0
