export enum CampaignPhase {
  CREATED = 'created',
  REGISTRATION_OPEN = 'registration_open',
  REGISTRATION_CLOSED = 'registration_closed',
  DISTRIBUTION_LIVE = 'distribution_live',
  DISTRIBUTION_ENDED = 'distribution_ended'
}

export interface PhaseConfig {
  phase: CampaignPhase
  label: string
  description: string
  color: {
    bg: string
    text: string
    border: string
    dot: string
  }
  icon?: string
}

export interface CampaignTimeline {
  hasRegistration: boolean
  registrationStart?: Date
  registrationEnd?: Date
  distributionStart?: Date
  distributionEnd?: Date
}

export interface PhaseInfo {
  currentPhase: CampaignPhase
  nextPhase?: CampaignPhase
  timeToNextPhase: number
  progress: number // 0-100% progress through current phase
  phaseStartTime?: Date
  phaseEndTime?: Date
}