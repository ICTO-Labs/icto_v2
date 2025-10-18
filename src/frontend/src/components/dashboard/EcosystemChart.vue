<template>
  <div class="w-full">
    <VueApexCharts
      type="donut"
      :height="height"
      :options="chartOptions"
      :series="series"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import VueApexCharts from 'vue3-apexcharts'

interface Props {
  data: {
    tokens: number
    multisigs: number
    distributions: number
    daos: number
    launchpads: number
  }
  height?: number
}

const props = withDefaults(defineProps<Props>(), {
  height: 350
})

const series = computed(() => [
  props.data.tokens,
  props.data.multisigs,
  props.data.distributions,
  props.data.daos,
  props.data.launchpads
])

const chartOptions = ref({
  chart: {
    fontFamily: 'Outfit, sans-serif',
    type: 'donut',
  },
  colors: ['#b27c10', '#d8a735', '#eacf6f', '#f5e590', '#e1b74c'],
  labels: ['Tokens', 'Multisig Wallets', 'Distributions', 'DAOs', 'Launchpads'],
  legend: {
    show: true,
    position: 'bottom' as const,
    fontFamily: 'Outfit',
    fontSize: '14px',
  },
  plotOptions: {
    pie: {
      donut: {
        size: '70%',
        labels: {
          show: true,
          total: {
            show: true,
            label: 'Total Contracts',
            fontSize: '16px',
            fontWeight: 600,
            formatter: function (w: any) {
              return w.globals.seriesTotals.reduce((a: number, b: number) => a + b, 0)
            }
          }
        }
      }
    }
  },
  dataLabels: {
    enabled: false
  },
  responsive: [
    {
      breakpoint: 640,
      options: {
        chart: {
          width: 300
        },
        legend: {
          position: 'bottom' as const
        }
      }
    }
  ],
  tooltip: {
    y: {
      formatter: function (val: number) {
        return val.toString() + ' contracts'
      }
    }
  }
})
</script>
