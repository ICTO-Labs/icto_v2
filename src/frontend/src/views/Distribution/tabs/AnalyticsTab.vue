<template>
  <div class="grid grid-cols-1 lg:grid-cols-5 gap-8">
    <!-- Main Chart -->
    <div class="lg:col-span-3 card">
      <h3 class="card-header">Distribution Progress</h3>
      <div id="chart">
        <apexchart type="area" height="350" :options="chartOptions" :series="series"></apexchart>
      </div>
    </div>

    <!-- Stats -->
    <div class="lg:col-span-2 space-y-8">
      <div class="card">
         <h3 class="card-header">Key Metrics</h3>
         <dl class="space-y-4">
            <div class="flex justify-between items-baseline">
              <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Participants</dt>
              <dd class="text-lg font-semibold text-gray-900 dark:text-white">{{ formatNumber(props.campaign.participants) }}</dd>
            </div>
            <div class="flex justify-between items-baseline">
              <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Total Claims</dt>
              <dd class="text-lg font-semibold text-gray-900 dark:text-white">{{ formatNumber(props.campaign.claims) }}</dd>
            </div>
            <div class="flex justify-between items-baseline">
              <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Avg. Claim Size</dt>
              <dd class="text-lg font-semibold text-gray-900 dark:text-white">{{ formatNumber(props.campaign.avgClaim) }} {{ props.campaign.token.symbol }}</dd>
            </div>
         </dl>
      </div>
       <div class="card">
         <h3 class="card-header">Progress</h3>
          <div>
            <div class="flex justify-between mb-1">
              <span class="text-base font-medium text-blue-700 dark:text-white">{{ formatNumber(props.campaign.distributedAmount) }} / {{ formatNumber(props.campaign.totalAmount) }}</span>
              <span class="text-sm font-medium text-blue-700 dark:text-white">{{ progressPercentage.toFixed(1) }}%</span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700">
              <div class="bg-blue-600 h-2.5 rounded-full" :style="{ width: `${progressPercentage}%` }"></div>
            </div>
          </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, PropType } from 'vue';
import type { DistributionCampaign } from '@/types/distribution';
import VueApexCharts from 'vue3-apexcharts';

const apexchart = VueApexCharts;

interface Props {
  campaign: {
    participants: number;
    claims: number;
    avgClaim: number;
    distributedAmount: number;
    totalAmount: number;
    token: {
      symbol: string;
    };
  };
}

const props = defineProps<Props>();

const formatNumber = (n: number) => new Intl.NumberFormat('en-US').format(n);

const progressPercentage = computed(() => {
  if (props.campaign.totalAmount === 0) return 0;
  return (props.campaign.distributedAmount / props.campaign.totalAmount) * 100;
});

const series = [
  {
    name: 'Tokens Distributed',
    data: [31, 40, 28, 51, 42, 109, 100, 120, 130, 150, 180, 250]
  }
];

const chartOptions = computed(() => ({
  chart: {
    height: 350,
    type: 'area',
    toolbar: { show: false },
    zoom: { enabled: false }
  },
  dataLabels: { enabled: false },
  stroke: { curve: 'smooth', width: 2 },
  xaxis: {
    type: 'datetime',
    categories: [
      "2023-09-19T00:00:00.000Z", "2023-09-20T00:00:00.000Z", "2023-09-21T00:00:00.000Z",
      "2023-09-22T00:00:00.000Z", "2023-09-23T00:00:00.000Z", "2023-09-24T00:00:00.000Z",
      "2023-09-25T00:00:00.000Z", "2023-09-26T00:00:00.000Z", "2023-09-27T00:00:00.000Z",
      "2023-09-28T00:00:00.000Z", "2023-09-29T00:00:00.000Z", "2023-09-30T00:00:00.000Z"
    ],
    labels: {
        style: { colors: '#6b7280' } // text-gray-500
    }
  },
  yaxis: {
    labels: {
        style: { colors: '#6b7280' } // text-gray-500
    }
  },
  tooltip: {
    x: { format: 'dd MMM yyyy' },
    theme: 'dark'
  },
  grid: {
      borderColor: '#e5e7eb' // gray-200
  },
  fill: {
    type: 'gradient',
    gradient: {
      shadeIntensity: 1,
      opacityFrom: 0.7,
      opacityTo: 0.3,
      stops: [0, 90, 100]
    }
  }
}));
</script>

<style scoped>
.card { @apply bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6; }
.card-header { @apply text-lg font-medium text-gray-900 dark:text-white mb-6; }
</style>