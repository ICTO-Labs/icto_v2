export const formatTimeAgo = (timestamp: number): string => {
    const now = Date.now()
    const secondsAgo = Math.floor((now - timestamp) / 1000)

    if (secondsAgo < 60) {
        return 'just now'
    }

    const minutesAgo = Math.floor(secondsAgo / 60)
    if (minutesAgo < 60) {
        return `${minutesAgo}m ago`
    }

    const hoursAgo = Math.floor(minutesAgo / 60)
    if (hoursAgo < 24) {
        return `${hoursAgo}h ago`
    }

    const daysAgo = Math.floor(hoursAgo / 24)
    if (daysAgo < 7) {
        return `${daysAgo}d ago`
    }

    const weeksAgo = Math.floor(daysAgo / 7)
    if (weeksAgo < 4) {
        return `${weeksAgo}w ago`
    }

    const monthsAgo = Math.floor(daysAgo / 30)
    if (monthsAgo < 12) {
        return `${monthsAgo}mo ago`
    }

    const yearsAgo = Math.floor(daysAgo / 365)
    return `${yearsAgo}y ago`
}

export const formatDate = (date: Date | number | string, options: Intl.DateTimeFormatOptions = {}): string => {
    const dateObj = typeof date === 'string' ? new Date(date) : new Date(date)
    return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        ...options
    }).format(dateObj)
}

export const formatDateTime = (date: Date | number | string): string => {
    return formatDate(date, {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
    })
}

export const formatDateRange = (start: Date | number | string, end: Date | number | string): string => {
    const startDate = new Date(start)
    const endDate = new Date(end)

    if (startDate.getFullYear() === endDate.getFullYear()) {
        if (startDate.getMonth() === endDate.getMonth()) {
            return `${formatDate(startDate, { day: 'numeric' })} - ${formatDate(endDate)}`
        }
        return `${formatDate(startDate, { month: 'short', day: 'numeric' })} - ${formatDate(endDate)}`
    }
    return `${formatDate(startDate)} - ${formatDate(endDate)}`
} 