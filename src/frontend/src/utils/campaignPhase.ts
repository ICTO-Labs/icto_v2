import type { CampaignTimeline, PhaseInfo, PhaseConfig } from '@/types/campaignPhase'
import { CampaignPhase } from '@/types/campaignPhase'

export const PHASE_CONFIGS: Record<CampaignPhase, PhaseConfig> = {
  [CampaignPhase.CREATED]: {
    phase: CampaignPhase.CREATED,
    label: 'Created',
    description: 'Campaign created, waiting to start',
    color: {
      bg: 'bg-gray-100 dark:bg-gray-800',
      text: 'text-gray-700 dark:text-gray-300',
      border: 'border-gray-300 dark:border-gray-600',
      dot: 'bg-gray-400'
    }
  },
  [CampaignPhase.REGISTRATION_OPEN]: {
    phase: CampaignPhase.REGISTRATION_OPEN,
    label: 'Registration Open',
    description: 'Users can register for the campaign',
    color: {
      bg: 'bg-blue-100 dark:bg-blue-900/30',
      text: 'text-blue-700 dark:text-blue-300',
      border: 'border-blue-300 dark:border-blue-700',
      dot: 'bg-blue-500'
    }
  },
  [CampaignPhase.REGISTRATION_CLOSED]: {
    phase: CampaignPhase.REGISTRATION_CLOSED,
    label: 'Registration Closed',
    description: 'Registration ended, waiting for distribution',
    color: {
      bg: 'bg-orange-100 dark:bg-orange-900/30',
      text: 'text-orange-700 dark:text-orange-300',
      border: 'border-orange-300 dark:border-orange-700',
      dot: 'bg-orange-500'
    }
  },
  [CampaignPhase.DISTRIBUTION_LIVE]: {
    phase: CampaignPhase.DISTRIBUTION_LIVE,
    label: 'Live',
    description: 'Distribution is active, users can claim tokens',
    color: {
      bg: 'bg-green-100 dark:bg-green-900/30',
      text: 'text-green-700 dark:text-green-300',
      border: 'border-green-300 dark:border-green-700',
      dot: 'bg-green-500'
    }
  },
  [CampaignPhase.DISTRIBUTION_ENDED]: {
    phase: CampaignPhase.DISTRIBUTION_ENDED,
    label: 'Ended',
    description: 'Campaign has finished',
    color: {
      bg: 'bg-gray-100 dark:bg-gray-800',
      text: 'text-gray-700 dark:text-gray-300',
      border: 'border-gray-300 dark:border-gray-600',
      dot: 'bg-gray-500'
    }
  }
}

export function detectCampaignPhase(timeline: CampaignTimeline): PhaseInfo {
  const now = Date.now()
  
  // Helper function to get milliseconds from date
  const getTime = (date?: Date) => date ? date.getTime() : 0
  
  const regStart = getTime(timeline.registrationStart)
  const regEnd = getTime(timeline.registrationEnd)
  const distStart = getTime(timeline.distributionStart)
  const distEnd = getTime(timeline.distributionEnd)
  
  // Phase detection logic
  let currentPhase: CampaignPhase
  let nextPhase: CampaignPhase | undefined
  let timeToNextPhase = 0
  let progress = 0
  let phaseStartTime: Date | undefined
  let phaseEndTime: Date | undefined
  
  if (timeline.hasRegistration) {
    if (now < regStart) {
      // Before registration starts
      currentPhase = CampaignPhase.CREATED
      nextPhase = CampaignPhase.REGISTRATION_OPEN
      timeToNextPhase = regStart - now
      progress = 0
      phaseEndTime = timeline.registrationStart
    } else if (now >= regStart && now < regEnd) {
      // During registration period
      currentPhase = CampaignPhase.REGISTRATION_OPEN
      nextPhase = CampaignPhase.REGISTRATION_CLOSED
      timeToNextPhase = regEnd - now
      progress = ((now - regStart) / (regEnd - regStart)) * 100
      phaseStartTime = timeline.registrationStart
      phaseEndTime = timeline.registrationEnd
    } else if (now >= regEnd && now < distStart) {
      // Registration closed, waiting for distribution
      currentPhase = CampaignPhase.REGISTRATION_CLOSED
      nextPhase = CampaignPhase.DISTRIBUTION_LIVE
      timeToNextPhase = distStart - now
      progress = ((now - regEnd) / (distStart - regEnd)) * 100
      phaseStartTime = timeline.registrationEnd
      phaseEndTime = timeline.distributionStart
    } else if (now >= distStart && (distEnd === 0 || now < distEnd)) {
      // Distribution active (or no end date - permanently live)
      currentPhase = CampaignPhase.DISTRIBUTION_LIVE
      if (distEnd > 0) {
        nextPhase = CampaignPhase.DISTRIBUTION_ENDED
        timeToNextPhase = distEnd - now
        progress = ((now - distStart) / (distEnd - distStart)) * 100
        phaseEndTime = timeline.distributionEnd
      } else {
        // No end date - permanently live
        nextPhase = undefined
        timeToNextPhase = 0
        progress = 100 // Always fully active
        phaseEndTime = undefined
      }
      phaseStartTime = timeline.distributionStart
    } else {
      // Distribution ended (only when distEnd > 0)
      currentPhase = CampaignPhase.DISTRIBUTION_ENDED
      progress = 100
      phaseStartTime = timeline.distributionEnd
    }
  } else {
    // No registration period
    if (now < distStart) {
      currentPhase = CampaignPhase.CREATED
      nextPhase = CampaignPhase.DISTRIBUTION_LIVE
      timeToNextPhase = distStart - now
      progress = 0
      phaseEndTime = timeline.distributionStart
    } else if (now >= distStart && (distEnd === 0 || now < distEnd)) {
      // Distribution active (or no end date - permanently live) 
      currentPhase = CampaignPhase.DISTRIBUTION_LIVE
      if (distEnd > 0) {
        nextPhase = CampaignPhase.DISTRIBUTION_ENDED
        timeToNextPhase = distEnd - now
        progress = ((now - distStart) / (distEnd - distStart)) * 100
        phaseEndTime = timeline.distributionEnd
      } else {
        // No end date - permanently live
        nextPhase = undefined
        timeToNextPhase = 0
        progress = 100 // Always fully active
        phaseEndTime = undefined
      }
      phaseStartTime = timeline.distributionStart
    } else {
      // Distribution ended (only when distEnd > 0)
      currentPhase = CampaignPhase.DISTRIBUTION_ENDED
      progress = 100
      phaseStartTime = timeline.distributionEnd
    }
  }
  
  return {
    currentPhase,
    nextPhase,
    timeToNextPhase: Math.max(0, timeToNextPhase),
    progress: Math.max(0, Math.min(100, progress)),
    phaseStartTime,
    phaseEndTime
  }
}

export function getPhaseConfig(phase: CampaignPhase): PhaseConfig {
  return PHASE_CONFIGS[phase]
}

export function getAllPhases(hasRegistration: boolean, hasEndDate: boolean = true): CampaignPhase[] {
  if (hasRegistration) {
    const phases = [
      CampaignPhase.CREATED,
      CampaignPhase.REGISTRATION_OPEN,
      CampaignPhase.REGISTRATION_CLOSED,
      CampaignPhase.DISTRIBUTION_LIVE
    ]
    if (hasEndDate) {
      phases.push(CampaignPhase.DISTRIBUTION_ENDED)
    }
    return phases
  } else {
    const phases = [
      CampaignPhase.CREATED,
      CampaignPhase.DISTRIBUTION_LIVE
    ]
    if (hasEndDate) {
      phases.push(CampaignPhase.DISTRIBUTION_ENDED)
    }
    return phases
  }
}