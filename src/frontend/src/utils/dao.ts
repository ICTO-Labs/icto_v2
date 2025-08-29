import { type  GovernanceLevel } from "@/types/dao";

export const convertGovernanceLevelToBackend = (level: GovernanceLevel) => {
    if(level === 'motion-only') return { MotionOnly: null }
    else if(level === 'semi-managed') return { SemiManaged: null }
    else if(level === 'fully-managed') return { FullyManaged: null }
}
export const convertGovernanceLevelFromBackend = (level: { MotionOnly: null } | { SemiManaged: null } | { FullyManaged: null }) => {
    if(level.hasOwnProperty('MotionOnly')) return 'motion-only'
    else if(level.hasOwnProperty('SemiManaged')) return 'semi-managed'
    else if(level.hasOwnProperty('FullyManaged')) return 'fully-managed'
    else return 'motion-only'
}