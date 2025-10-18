<template>
  <div class="w-full">
    <VueApexCharts
      type="area"
      :height="height"
      :options="chartOptions"
      :series="series"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import VueApexCharts from 'vue3-apexcharts'

interface Props {
  data: {
    deployments: number[]
    transactions: number[]
    labels: string[]
  }
  height?: number
}

const props = withDefaults(defineProps<Props>(), {
  height: 320
})

const series = computed(() => [
  {
    name: 'Deployments',
    data: props.data.deployments
  },
  {
    name: 'Transactions',
    data: props.data.transactions
  }
])

const chartOptions = ref({
  chart: {
    fontFamily: 'Outfit, sans-serif',
    type: 'area',
    toolbar: {
      show: false
    },
    zoom: {
      enabled: false
    }
  },
  colors: ['#b27c10', '#e1b74c'],
  dataLabels: {
    enabled: false
  },
  stroke: {
    curve: 'smooth' as const,
    width: [3, 3]
  },
  fill: {
    type: 'gradient',
    gradient: {
      enabled: true,
      opacityFrom: 0.55,
      opacityTo: 0.1
    }
  },
  grid: {
    borderColor: '#e5e7eb',
    strokeDashArray: 5,
    xaxis: {
      lines: {
        show: false
      }
    },
    yaxis: {
      lines: {
        show: true
      }
    }
  },
  xaxis: {
    categories: props.data.labels,
    axisBorder: {
      show: false
    },
    axisTicks: {
      show: false
    }
  },
  yaxis: {
    title: {
      text: 'Count',
      style: {
        fontSize: '14px',
        fontWeight: 500
      }
    }
  },
  legend: {
    show: true,
    position: 'top' as const,
    horizontalAlign: 'right' as const,
    fontFamily: 'Outfit',
    fontSize: '14px',
    markers: {
      radius: 12
    }
  },
  tooltip: {
    x: {
      format: 'dd MMM yyyy'
    }
  }
})
</script>
