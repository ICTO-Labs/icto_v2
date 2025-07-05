<template>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
        <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                Token Distribution
            </h3>
            <div class="flex items-center space-x-2">
                <button 
                    v-for="period in ['1D', '1W', '1M', '1Y', 'ALL']"
                    :key="period"
                    @click="timeRange = period"
                    :class="[
                        'px-3 py-1 text-sm rounded-lg',
                        timeRange === period
                            ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                            : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300'
                    ]"
                >
                    {{ period }}
                </button>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Distribution Pie Chart -->
            <div>
                <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">
                    Token Standards Distribution
                </h4>
                <div class="relative" style="height: 300px;">
                    <canvas ref="pieChartRef"></canvas>
                </div>
                <div class="mt-4 space-y-2">
                    <div 
                        v-for="(item, index) in pieChartData.labels" 
                        :key="item"
                        class="flex items-center justify-between"
                    >
                        <div class="flex items-center">
                            <span 
                                class="w-3 h-3 rounded-full mr-2"
                                :style="{ backgroundColor: pieChartData.colors[index] }"
                            ></span>
                            <span class="text-sm text-gray-600 dark:text-gray-400">
                                {{ item }}
                            </span>
                        </div>
                        <span class="text-sm font-medium text-gray-900 dark:text-white">
                            {{ pieChartData.percentages[index] }}%
                        </span>
                    </div>
                </div>
            </div>

            <!-- Creation Trend Line Chart -->
            <div>
                <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-4">
                    Token Creation Trend
                </h4>
                <div class="relative" style="height: 300px;">
                    <canvas ref="lineChartRef"></canvas>
                </div>
                <div class="mt-4 grid grid-cols-3 gap-4">
                    <div class="text-center">
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Total Created
                        </p>
                        <p class="text-lg font-medium text-gray-900 dark:text-white">
                            {{ formatNumber(lineChartData.total) }}
                        </p>
                    </div>
                    <div class="text-center">
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Average/Day
                        </p>
                        <p class="text-lg font-medium text-gray-900 dark:text-white">
                            {{ formatNumber(lineChartData.average) }}
                        </p>
                    </div>
                    <div class="text-center">
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Growth
                        </p>
                        <p 
                            class="text-lg font-medium"
                            :class="lineChartData.growth >= 0 
                                ? 'text-green-600 dark:text-green-500'
                                : 'text-red-600 dark:text-red-500'"
                        >
                            {{ lineChartData.growth >= 0 ? '+' : '' }}{{ lineChartData.growth }}%
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { Chart, ChartConfiguration, ChartData } from 'chart.js/auto'
import { formatNumber } from '@/utils/numberFormat'

interface PieChartData {
    labels: string[];
    data: number[];
    colors: string[];
    percentages: number[];
}

interface LineChartData {
    labels: string[];
    data: number[];
    total: number;
    average: number;
    growth: number;
}

const timeRange = ref('1M')
const pieChartRef = ref<HTMLCanvasElement | null>(null)
const lineChartRef = ref<HTMLCanvasElement | null>(null)
let pieChart: Chart | null = null
let lineChart: Chart | null = null

// Mock data - replace with actual data from API
const pieChartData = ref<PieChartData>({
    labels: ['ICRC-1', 'ICRC-2', 'ICRC-3', 'Other'],
    data: [45, 30, 15, 10],
    colors: ['#3B82F6', '#10B981', '#F59E0B', '#6B7280'],
    percentages: [45, 30, 15, 10]
})

const lineChartData = ref<LineChartData>({
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    data: [10, 15, 25, 30, 45, 60],
    total: 185,
    average: 30.8,
    growth: 33.3
})

const createPieChart = () => {
    if (!pieChartRef.value) return

    const ctx = pieChartRef.value.getContext('2d')
    if (!ctx) return

    const config: ChartConfiguration = {
        type: 'doughnut',
        data: {
            labels: pieChartData.value.labels,
            datasets: [{
                data: pieChartData.value.data,
                backgroundColor: pieChartData.value.colors,
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            cutout: '70%'
        }
    }

    if (pieChart) {
        pieChart.destroy()
    }
    pieChart = new Chart(ctx, config)
}

const createLineChart = () => {
    if (!lineChartRef.value) return

    const ctx = lineChartRef.value.getContext('2d')
    if (!ctx) return

    const config: ChartConfiguration = {
        type: 'line',
        data: {
            labels: lineChartData.value.labels,
            datasets: [{
                label: 'Tokens Created',
                data: lineChartData.value.data,
                borderColor: '#3B82F6',
                backgroundColor: 'rgba(59, 130, 246, 0.1)',
                fill: true,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        display: true,
                        color: 'rgba(0, 0, 0, 0.1)'
                    }
                },
                x: {
                    grid: {
                        display: false
                    }
                }
            }
        }
    }

    if (lineChart) {
        lineChart.destroy()
    }
    lineChart = new Chart(ctx, config)
}

watch(timeRange, () => {
    // TODO: Fetch new data based on time range
    // For now, just update with mock data
    if (timeRange.value === '1D') {
        lineChartData.value.labels = ['9AM', '12PM', '3PM', '6PM', '9PM', 'Now']
        lineChartData.value.data = [5, 8, 12, 15, 18, 20]
    } else if (timeRange.value === '1W') {
        lineChartData.value.labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        lineChartData.value.data = [10, 15, 18, 22, 25, 28, 30]
    }
    createLineChart()
})

onMounted(() => {
    createPieChart()
    createLineChart()
})
</script> 