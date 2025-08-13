<template>
  <div class="vesting-chart">
    <VueApexCharts
      v-if="chartOptions && series.length > 0"
      type="area"
      height="300"
      :options="chartOptions"
      :series="series"
    />
    <div v-else class="flex items-center justify-center h-64 border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-lg">
      <div class="text-center">
        <BarChart3Icon class="w-12 h-12 text-gray-400 mx-auto mb-3" />
        <p class="text-gray-500 dark:text-gray-400 font-medium">Token Unlock Schedule</p>
        <p class="text-sm text-gray-400 dark:text-gray-500 mt-1">No data available</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { BarChart3Icon } from 'lucide-vue-next'
import VueApexCharts from 'vue3-apexcharts'

interface VestingPoint {
  date: Date
  amount: number
  cumulative: number
  percentage: number
  type: 'buffer' | 'initial' | 'instant' | 'cliff' | 'vesting'
}

interface Props {
  vestingData: VestingPoint[]
  hasCliffPeriod: boolean
  hasInstantUnlock: boolean
  currentTimePosition?: number | null
  cliffEndPosition?: number | null
}

const props = defineProps<Props>()

// ApexCharts series data
const series = computed(() => {
  if (!props.vestingData || props.vestingData.length === 0) return []

  // Filter out buffer points for the main series
  const dataPoints = props.vestingData.filter(point => point.type !== 'buffer')
  console.log('props.vestingData', props.vestingData)
  return [
    {
      name: 'Token Unlock',
      type: 'area', // Changed to area type for fill support
      data: dataPoints.map((point, index) => ({
        x: point.date.getTime(),
        y: point.percentage,
        fillColor: getMarkerColor(point.type),
        strokeColor: getMarkerStroke(point.type),
        strokeWidth: getMarkerStrokeWidth(point.type),
        marker: {
          fillColor: getMarkerColor(point.type),
          strokeColor: getMarkerStroke(point.type),
          strokeWidth: getMarkerStrokeWidth(point.type),
          size: getMarkerSize(point.type),
          radius: getMarkerSize(point.type) / 2,
          shape: 'circle'
        },
        pointType: point.type
      }))
    }
  ]
})

// ApexCharts configuration
const chartOptions = computed(() => {
  if (!props.vestingData || props.vestingData.length === 0) return null

  const minDate = props.vestingData[0]?.date.getTime()
  const maxDate = props.vestingData[props.vestingData.length - 1]?.date.getTime()
  
  // Filter out buffer points and create discrete markers
  const dataPoints = props.vestingData.filter(point => point.type !== 'buffer')
  const discreteMarkers = dataPoints.map((point, index) => ({
    seriesIndex: 0,
    dataPointIndex: index,
    fillColor: getMarkerColor(point.type),
    strokeColor: getMarkerStroke(point.type),
    strokeWidth: getMarkerStrokeWidth(point.type),
    size: getMarkerSize(point.type),
    shape: 'circle'
  }))

  return {
    chart: {
      type: 'area',
      height: 300,
      background: 'transparent',
      toolbar: {
        show: false
      },
      zoom: {
        enabled: false
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
    stroke: {
      curve: 'stepline' as const,
      width: 3,
      colors: ['#DAA520'], // Darker ICTO gold for stroke
      lineCap: 'round'
    },
    fill: {
      type: 'gradient',
      gradient: {
        shade: 'light',
        type: 'vertical',
        shadeIntensity: 0.4,
        gradientToColors: ['#FFD700'], // ICTO Gold
        inverseColors: false,
        opacityFrom: 0.4,
        opacityTo: 0.05,
        stops: [0, 50, 100],
        colorStops: [
          {
            offset: 0,
            color: '#FFD700', // ICTO Gold at top
            opacity: 0.4
          },
          {
            offset: 50,
            color: '#FFED4E', // Lighter gold in middle
            opacity: 0.2
          },
          {
            offset: 100,
            color: '#FFF8DC', // Very light gold at bottom
            opacity: 0.05
          }
        ]
      }
    },
    dataLabels: {
      enabled: false
    },
    markers: {
      size: 8, // Increased size for better visibility
      strokeWidth: 3,
      strokeOpacity: 0.9,
      fillOpacity: 1,
      discrete: discreteMarkers,
      hover: {
        size: 8,
        sizeOffset: 2
      },
      // Show marker labels with data
      labels: {
        show: true,
        showForNullSeries: false,
        formatter: function(val: any, opts: any) {
          const point = props.vestingData.filter(p => p.type !== 'buffer')[opts.dataPointIndex]
          if (!point) return ''
          return `${point.percentage.toFixed(1)}%`
        },
        style: {
          colors: '#374151',
          fontSize: '11px',
          fontWeight: '600',
          fontFamily: 'Inter, sans-serif'
        },
        offsetY: -8
      }
    },
    xaxis: {
      type: 'datetime',
      min: minDate,
      max: maxDate,
      labels: {
        style: {
          colors: '#6B7280',
          fontSize: '12px',
          fontWeight: 400
        },
        datetimeFormatter: {
          year: 'yyyy',
          month: 'MMM \'yy',
          day: 'dd MMM',
          hour: 'HH:mm'
        }
      },
      axisBorder: {
        show: true,
        color: '#E5E7EB'
      },
      axisTicks: {
        show: true,
        color: '#E5E7EB'
      }
    },
    yaxis: {
      min: 0,
      max: 100,
      labels: {
        formatter: (value: number) => `${value.toFixed(0)}%`,
        style: {
          colors: '#6B7280',
          fontSize: '12px',
          fontWeight: 400
        }
      },
      axisBorder: {
        show: true,
        color: '#E5E7EB'
      }
    },
    grid: {
      show: true,
      borderColor: '#F3F4F6',
      strokeDashArray: 0,
      position: 'back',
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
    tooltip: {
      enabled: true,
      theme: 'light',
      custom: function({ series, seriesIndex, dataPointIndex, w }: any) {
        const point = props.vestingData.filter(p => p.type !== 'buffer')[dataPointIndex]
        if (!point) return ''

        return `
          <div class="px-3 py-2">
            <div class="font-medium text-gray-900 mb-1">
              ${formatDate(point.date)}
            </div>
            <div class="text-gray-600 space-y-1">
              <div>Amount: ${formatNumber(point.amount)} Token</div>
              <div>Cumulative: ${point.percentage.toFixed(1)}%</div>
              <div class="font-medium ${getTooltipColor(point.type)}">
                ${getTypeLabel(point.type)}
              </div>
            </div>
          </div>
        `
      }
    },
    legend: {
      show: false
    },
    annotations: {
      ...getAnnotations(),
      texts: [{
        x: '50%',
        y: '50%',
        text: '',
        textAnchor: 'middle',
        style: {
          color: document.documentElement.classList.contains('dark') ? '#B8860B' : '#FFD700',
          fontSize: '360px',
          fontWeight: '800',
          fontFamily: 'Inter, system-ui, sans-serif',
          opacity: 0.1,
          letterSpacing: '1em'
        }
      }]
    },
    theme: {
      mode: 'light'
    }
  }
})

// Helper functions
function getMarkerColor(type: string): string {
  switch (type) {
    case 'initial': return '#00C851' // Success Blue
    case 'instant': return '#FFA500' // Orange Gold
    case 'cliff': return '#DAA520'   // Goldenrod
    case 'vesting': return '#F4E4BC' // Light Gold
    default: return 'transparent'
  }
}

function getMarkerStroke(type: string): string {
  switch (type) {
    case 'initial': return '#00C851' // Success Blue
    case 'instant': return '#B8860B' // Dark Orange Gold
    case 'cliff': return '#CD853F'   // Peru
    case 'vesting': return '#DEB887' // Burlywood
    default: return 'transparent'
  }
}

function getMarkerStrokeWidth(type: string): number {
  switch (type) {
    case 'instant': return 3
    case 'cliff': return 2
    case 'initial': return 2
    case 'vesting': return 1
    default: return 0
  }
}

function getMarkerSize(type: string): number {
  switch (type) {
    case 'instant': return 8
    case 'cliff': return 5
    case 'initial': return 5
    case 'vesting': return 4
    default: return 2
  }
}

function getTooltipColor(type: string): string {
  switch (type) {
    case 'initial': return 'text-green-600'
    case 'instant': return 'text-orange-600'
    case 'cliff': return 'text-yellow-700'
    case 'vesting': return 'text-yellow-500'
    default: return 'text-gray-600'
  }
}

function getTypeLabel(type: string): string {
  switch (type) {
    case 'initial': return 'Initial Unlock'
    case 'instant': return 'Instant Unlock (100%)'
    case 'cliff': return 'Cliff Unlock'
    case 'vesting': return 'Linear Vesting'
    default: return ''
  }
}

function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }).format(date)
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat().format(value)
}

function getAnnotations() {
  const annotations: any = {
    xaxis: [],
    yaxis: []
  }

  // Current time line
  if (props.currentTimePosition !== null && props.vestingData.length > 0) {
    const startTime = props.vestingData[0].date.getTime()
    const endTime = props.vestingData[props.vestingData.length - 1].date.getTime()
    const currentTime = startTime + ((props.currentTimePosition ?? 0) / 100) * (endTime - startTime)
    
    //Change to blue color
    annotations.xaxis.push({
      x: currentTime,
      strokeDashArray: 0,
      borderColor: '#3B82F6',
      borderWidth: 2,
      label: {
        borderColor: '#3B82F6',
        style: {
          color: '#fff',
          background: '#3B82F6',
          fontSize: '10px'
        },
        text: 'NOW'
      }
    })
  }

  // Cliff horizon line
  if (props.hasCliffPeriod && props.cliffEndPosition !== null && props.vestingData.length > 0) {
    const startTime = props.vestingData[0].date.getTime()
    const endTime = props.vestingData[props.vestingData.length - 1].date.getTime()
    const cliffTime = startTime + ((props.cliffEndPosition ?? 0) / 100) * (endTime - startTime)
    
    annotations.xaxis.push({
      x: cliffTime,
      strokeDashArray: 4,
      borderColor: '#F59E0B',
      borderWidth: 1,
      opacity: 0.8,
      label: {
        borderColor: '#F59E0B',
        style: {
          color: '#fff',
          background: '#F59E0B',
          fontSize: '10px'
        },
        text: 'Cliff End'
      }
    })
  }

  return annotations
}
</script>

<style scoped>
.vesting-chart {
  @apply w-full h-full;
}
/* ApexCharts theme customization */
:deep(.apexcharts-canvas) {
  @apply rounded-lg;
}

:deep(.apexcharts-tooltip) {
  @apply shadow-lg border border-gray-200 rounded-lg !important;
  background: white !important;
  border-color: #E5E7EB !important;
}

:deep(.apexcharts-tooltip-title) {
  @apply bg-gray-50 border-b border-gray-200 font-medium !important;
}

:deep(.apexcharts-grid-borders line) {
  stroke: #F3F4F6 !important;
}

:deep(.apexcharts-xaxis-tick) {
  stroke: #E5E7EB !important;
}

:deep(.apexcharts-yaxis-tick) {
  stroke: #E5E7EB !important;
}

/* Dark mode styles */
.dark :deep(.apexcharts-tooltip) {
  background: #1F2937 !important;
  border-color: #374151 !important;
}

.dark :deep(.apexcharts-tooltip-title) {
  background: #111827 !important;
  border-color: #374151 !important;
  color: #F9FAFB !important;
}

.dark :deep(.apexcharts-grid-borders line) {
  stroke: #374151 !important;
}

.dark :deep(.apexcharts-xaxis-tick) {
  stroke: #4B5563 !important;
}

.dark :deep(.apexcharts-yaxis-tick) {
  stroke: #4B5563 !important;
}

.dark :deep(.apexcharts-xaxis .apexcharts-xaxis-label) {
  color: #9CA3AF !important;
}

.dark :deep(.apexcharts-yaxis .apexcharts-yaxis-label) {
  color: #9CA3AF !important;
}

/* Watermark styling improvements */
:deep(.apexcharts-text) {
  pointer-events: none;
  user-select: none;
}

/* Responsive watermark for smaller charts */
@media (max-width: 640px) {
  :deep(.apexcharts-text) {
    font-size: 24px !important;
  }
}

@media (max-width: 480px) {
  :deep(.apexcharts-text) {
    font-size: 18px !important;
    opacity: 0.08 !important;
  }
}
</style>