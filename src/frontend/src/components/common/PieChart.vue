<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">{{ title }}</h4>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Pie Chart -->
      <div class="relative">
        <div v-if="hasData">
          <VueApexCharts 
            type="donut" 
            height="250" 
            :options="chartOptions" 
            :series="chartData.data" 
          />
        </div>
        <div v-else class="flex items-center justify-center h-64 text-gray-500 dark:text-gray-400">
          <div class="text-center">
            <div class="text-4xl mb-2">📊</div>
            <div class="text-sm">No data to display</div>
          </div>
        </div>
      </div>
      
      <!-- Legend -->
      <div class="space-y-2">
        <div 
          v-for="(item, index) in chartData.labels" 
          :key="`${item}-${index}`"
          class="flex items-center justify-between p-2 rounded hover:bg-white dark:hover:bg-gray-800 hover:shadow-sm transition-all duration-200 border border-transparent hover:border-gray-200 dark:hover:border-gray-600"
        >
          <div class="flex items-center">
            <span 
              class="w-3 h-3 rounded-full mr-3 flex-shrink-0"
              :style="{ backgroundColor: chartData.colors[index] }"
            ></span>
            <span 
              class="text-sm font-medium truncate"
              :style="`color: ${chartData.colors[index]} !important`"
            >
              {{ item }}
            </span>
          </div>
          <div class="text-right ml-2">
            <div 
              class="text-sm font-bold"
              :style="`color: ${chartData.colors[index]} !important`"
            >
              {{ chartData.percentages[index] }}%
            </div>
            <div v-if="showValues && chartData.values" class="text-xs opacity-60" :style="`color: ${chartData.colors[index]} !important`">
              {{ formatNumber(chartData.values[index]) }} {{ valueUnit }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import VueApexCharts from 'vue3-apexcharts'

interface ChartData {
  labels: string[]
  data: number[]
  colors: string[]
  percentages: number[]
  values?: number[]
}

interface Props {
  title: string
  chartData: ChartData
  showValues?: boolean
  valueUnit?: string
  centerLabel?: string
  totalValue?: number
}

const props = withDefaults(defineProps<Props>(), {
  showValues: false,
  valueUnit: '',
  centerLabel: '',
  totalValue: 0
})

const hasData = computed(() => props.chartData.data.some(value => value > 0))

const chartOptions = computed(() => ({
  chart: {
    fontFamily: 'Inter, sans-serif',
    type: 'donut',
    toolbar: {
      show: false,
    },
    animations: {
      enabled: true,
      easing: 'easeinout',
      speed: 800,
      animateGradually: {
        enabled: true,
        delay: 150
      },
      dynamicAnimation: {
        enabled: true,
        speed: 350
      }
    }
  },
  colors: props.chartData.colors,
  labels: props.chartData.labels,
  legend: {
    show: false
  },
  plotOptions: {
    pie: {
      donut: {
        size: '65%',
        labels: {
          show: true,
          total: {
            show: true,
            showAlways: true,
            label: props.centerLabel || 'Total',
            fontSize: '12px',
            fontWeight: 500,
            color: '#6B7280',
            formatter: () => {
              if (props.totalValue) {
                return formatNumber(props.totalValue)
              }
              return '100%'
            }
          },
          value: {
            show: false
          }
        }
      },
      expandOnClick: false
    }
  },
  dataLabels: {
    enabled: false
  },
  stroke: {
    show: true,
    width: 2,
    colors: ['transparent']
  },
  tooltip: {
    enabled: true,
    y: {
      formatter: (value: number, { seriesIndex }: { seriesIndex: number }) => {
        if (props.showValues && props.chartData.values) {
          return `${formatNumber(props.chartData.values[seriesIndex])} ${props.valueUnit} (${props.chartData.percentages[seriesIndex]}%)`
        }
        return `${props.chartData.percentages[seriesIndex]}%`
      }
    },
    theme: 'light',
    style: {
      fontSize: '12px'
    }
  },
  responsive: [{
    breakpoint: 768,
    options: {
      chart: {
        height: 200
      },
      plotOptions: {
        pie: {
          donut: {
            size: '60%'
          }
        }
      }
    }
  }]
}))

const formatNumber = (value: number): string => {
  if (!value) return '0'
  return value.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  })
}
</script>