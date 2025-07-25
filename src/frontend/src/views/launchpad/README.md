# Launchpad Feature

## Overview

The Launchpad feature is a decentralized token sale platform built for the ICTO V2 dApp on the Internet Computer. It allows users to browse, filter, and participate in token launches.

## File Structure

```
src/
├── views/
│   └── Launchpad/
│       ├── LaunchpadIndex.vue    # Main landing page
│       └── LaunchpadDetail.vue    # Detailed view for each launchpad
├── components/
│   ├── Launchpad/
│   │   ├── LaunchpadCard.vue     # Card component for grid display
│   │   ├── ParticipateModal.vue  # Modal for token participation
│   │   ├── StatusBadge.vue       # Status indicator component
│   │   ├── TokenomicsChart.vue   # Pie chart for token distribution
│   │   └── VestingTimeline.vue   # Timeline for vesting schedules
│   └── common/
│       ├── TabGroup.vue          # Tab container component
│       ├── TabItem.vue           # Individual tab header
│       └── TabPanel.vue          # Tab content panel
├── composables/
│   └── launchpad/
│       └── useLaunchpad.js       # Business logic and data management
└── types/
    └── launchpad/
        └── index.ts              # TypeScript type definitions
```

## Features

### LaunchpadIndex View
- **Filter Tabs**: All, Participated, Upcoming, Launching, Finished
- **Search**: Search by project name or token symbol
- **Sort Options**: Most Recent, Ending Soon, Popular
- **Responsive Grid**: Displays launchpad cards in a responsive layout
- **Loading States**: Skeleton loaders while fetching data
- **Empty States**: User-friendly messages when no data is available

### LaunchpadDetail View
- **Overview Tab**: Basic information, progress, and participation CTA
- **Tokenomics Tab**: Token distribution chart and vesting timeline
- **Project Info Tab**: Description, links, team information
- **Participation Tab**: How to participate, limits, and conditions
- **Activity Tab**: Recent transaction history

### Components

#### LaunchpadCard
- Displays project summary in a card format
- Shows logo, name, symbol, status, dates, and progress
- Click to navigate to detail view

#### StatusBadge
- Visual indicator for launchpad status
- Color-coded with icons:
  - Upcoming: Gray with clock icon
  - Launching: Green with bolt icon
  - Finished: Red with stop icon

#### ParticipateModal
- Token selection (ICP/ICTO)
- Amount input with validation
- Min/max contribution limits
- Balance checking
- Gas fee preview
- Transaction processing with loading state

#### TokenomicsChart
- SVG-based pie chart
- Animated segments
- Color-coded legend
- Responsive design

#### VestingTimeline
- Visual timeline with milestones
- Shows TGE, cliff periods, and linear vesting
- Status indicators for completed/active/upcoming
- Detailed vesting information

## Usage

### Routes Setup

Add these routes to your Vue Router configuration:

```javascript
{
  path: '/launchpad',
  name: 'LaunchpadIndex',
  component: () => import('@/views/Launchpad/LaunchpadIndex.vue')
},
{
  path: '/launchpad/:id',
  name: 'LaunchpadDetail',
  component: () => import('@/views/Launchpad/LaunchpadDetail.vue')
}
```

### Dependencies

Make sure these packages are installed:
- `@headlessui/vue` - For modal components
- `@heroicons/vue` - For icons
- `vue-sonner` - For toast notifications

### Mock Data

The composable includes mock data for development. Replace the mock API calls with actual blockchain interactions when integrating with Internet Computer canisters.

## Customization

### Styling
- Uses TailwindCSS for styling
- Supports light/dark mode
- Responsive design with mobile-first approach
- Maximum card width: 380px

### Data Structure
See `src/types/launchpad/index.ts` for complete type definitions.

## Future Enhancements

1. **Wallet Integration**: Connect to Internet Computer wallets
2. **Real-time Updates**: WebSocket connections for live data
3. **Advanced Filtering**: Filter by raise type, token acceptance
4. **Favorites**: Save favorite launchpads
5. **Notifications**: Alert users about launchpad status changes
6. **Analytics**: Track participation history and ROI

## Notes

- All data is currently mocked for development
- Toast notifications are used for user feedback
- Error states are handled gracefully
- Loading states use skeleton screens
- Animations enhance user experience
