<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
  <div v-if="proposalInfo" class="mx-auto space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-4">
        <button @click="$router.go(-1)" class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
          <ArrowLeftIcon class="h-5 w-5 text-gray-500" />
        </button>
        <div>
          <div class="flex items-center space-x-3 mb-1">
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
              Proposal #{{ proposalInfo.proposal.id }}
            </h1>
            <ProposalStatusBadge :status="(proposalInfo.proposal.state as string)" />
            <ProposalTypeBadge :type="getProposalType(proposalInfo.proposal.payload)" />
          </div>
          <p class="text-gray-600 dark:text-gray-400">
            {{ dao?.name || 'Loading...' }}
          </p>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Proposal Details -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Title and Description -->
        <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
          <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">
            {{ getProposalTitle(proposalInfo.proposal.payload) }}
          </h2>
          <p class="text-gray-700 dark:text-gray-300 whitespace-pre-wrap mb-4">
            {{ getProposalDescription(proposalInfo.proposal.payload) }}
          </p>
          
          <!-- Discussion Link -->
          <div v-if="getDiscussionUrl(proposalInfo.proposal.payload)" class="border-t border-gray-200 dark:border-gray-700 pt-4">
            <a 
              :href="getDiscussionUrl(proposalInfo.proposal.payload) || ''" 
              target="_blank"
              class="inline-flex items-center text-yellow-600 hover:text-yellow-700 dark:text-yellow-400 dark:hover:text-yellow-300 font-medium"
            >
              <ExternalLinkIcon class="h-4 w-4 mr-2" />
              Join Discussion
            </a>
          </div>
        </div>

        <!-- Proposal Details -->
        <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Proposal Details</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Proposer</span>
                <UserIcon class="h-4 w-4 text-gray-400" />
              </div>
              <p class="text-sm font-mono text-gray-900 dark:text-white break-all">
                {{ (proposalInfo.proposal.proposer) }}
              </p>
            </div>

            <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Created</span>
                <CalendarIcon class="h-4 w-4 text-gray-400" />
              </div>
              <p class="text-sm text-gray-900 dark:text-white">
                {{ formatDate(Number(proposalInfo.proposal.timestamp)) }}
              </p>
            </div>

            <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Quorum Required</span>
                <TargetIcon class="h-4 w-4 text-gray-400" />
              </div>
              <p class="text-sm text-gray-900 dark:text-white">
                {{ formatTokenAmount(parseTokenAmount(Number(proposalInfo.proposal.quorumRequired), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
              </p>
            </div>

            <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Approval Threshold</span>
                <CheckCircleIcon class="h-4 w-4 text-gray-400" />
              </div>
              <p class="text-sm text-gray-900 dark:text-white">
                {{ Number(proposalInfo.proposal.approvalThreshold) / 100 }}%
              </p>
            </div>
          </div>

          <!-- Execution Time -->
          <div v-if="proposalInfo.proposal.executionTime && proposalInfo.proposal.executionTime[0]" class="mt-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
            <div class="flex items-center">
              <ClockIcon class="h-5 w-5 text-yellow-500 mr-2" />
              <div>
                <p class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                  Scheduled for Execution
                </p>
                <p class="text-sm text-yellow-600 dark:text-yellow-300">
                  {{ formatDate(Number(proposalInfo.proposal.executionTime[0])) }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Voting Section -->
        <div v-if="getProposalStateKey(proposalInfo.proposal.state) === 'Open'" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Cast Your Vote</h3>
          
          <div v-if="!memberInfo" class="text-center py-6">
            <p class="text-gray-500 dark:text-gray-400 mb-4">
              You need to be a DAO member to vote on proposals.
            </p>
            <button 
              @click="$router.push(`/dao/${$route.params.id}`)"
              class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-yellow-600 to-amber-600 text-white rounded-lg hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
            >
              Join DAO
            </button>
          </div>

          <div v-else class="space-y-4">
            <!-- Voting Power Display -->
            <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <div class="flex justify-between items-center">
                <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Your Voting Power</span>
                <span class="text-lg font-bold text-gray-900 dark:text-white">
                  {{ formatTokenAmount(parseTokenAmount(Number(memberInfo.votingPower), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
                </span>
              </div>
            </div>
            <!-- Voting Reason -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Reason (Optional)
              </label>
              <textarea
                v-model="voteReason"
                rows="3"
                placeholder="Explain your vote..."
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              ></textarea>
            </div>
            <!-- Vote Options -->
            <div class="grid grid-cols-3 gap-3">
              <button 
                @click="castVote('Yes')"
                :disabled="isVoting || hasVoted"
                class="flex-1 flex items-center justify-center px-4 py-3 bg-green-100 text-green-700 rounded-lg hover:bg-green-200 dark:bg-green-900/20 dark:text-green-400 dark:hover:bg-green-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ThumbsUpIcon class="h-5 w-5 mr-2" />
                Vote Yes
              </button>
              <button 
                @click="castVote('No')"
                :disabled="isVoting || hasVoted"
                class="flex-1 flex items-center justify-center px-4 py-3 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ThumbsDownIcon class="h-5 w-5 mr-2" />
                Vote No
              </button>
              <button 
                @click="castVote('Abstain')"
                :disabled="isVoting || hasVoted"
                class="flex-1 flex items-center justify-center px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <MinusIcon class="h-5 w-5 mr-2" />
                Abstain
              </button>
            </div>

            

            <div v-if="hasVoted && userVote" class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
              <div class="flex items-start space-x-3">
                <div class="flex-shrink-0">
                  <CheckCircleIcon class="h-5 w-5 text-blue-600 dark:text-blue-400" />
                </div>
                <div class="flex-1">
                  <p class="text-sm font-medium text-blue-700 dark:text-blue-300 mb-1">
                    Your Vote: {{ userVote.vote === 'yes' ? 'Yes' : userVote.vote === 'no' ? 'No' : 'Abstain' }}
                  </p>
                  <p class="text-xs text-blue-600 dark:text-blue-400 mb-2">
                    Voting Power: {{ formatTokenAmount(parseTokenAmount(Number(userVote.votingPower), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
                  </p>
                  <p class="text-xs text-blue-600 dark:text-blue-400">
                    Cast on: {{ formatDate(Number(userVote.timestamp)) }}
                  </p>
                  <div v-if="userVote.reason" class="mt-2">
                    <p class="text-xs font-medium text-blue-700 dark:text-blue-300">Reason:</p>
                    <p class="text-xs text-blue-600 dark:text-blue-400 mt-1 italic">{{ userVote.reason }}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Vote Records -->
        <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Vote Records</h3>
            <span class="text-sm text-gray-500 dark:text-gray-400">
              {{ voteRecords.length }} vote{{ voteRecords.length !== 1 ? 's' : '' }}
            </span>
          </div>

          <div v-if="isLoadingVotes" class="flex items-center justify-center py-8">
            <RefreshCcwIcon class="h-6 w-6 text-gray-400 animate-spin" />
            <span class="ml-2 text-gray-500 dark:text-gray-400">Loading votes...</span>
          </div>

          <div v-else-if="voteRecords.length === 0" class="text-center py-8">
            <MessageCircleIcon class="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
            <p class="text-gray-500 dark:text-gray-400">No votes cast yet</p>
          </div>

          <div v-else class="space-y-3">
            <div 
              v-for="vote in voteRecords" 
              :key="`${vote.voter}-${vote.timestamp}`"
              class="border border-gray-200 dark:border-gray-700 rounded-lg p-4"
            >
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <div class="flex items-center space-x-2 mb-2">
                    <span class="font-mono text-sm text-gray-600 dark:text-gray-400">
                      {{ shortPrincipal(vote.voter) }}
                    </span>
                    <div 
                      :class="[
                        'px-2 py-1 rounded text-xs font-medium',
                        vote.vote === 'yes' ? 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400' :
                        vote.vote === 'no' ? 'bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400' :
                        'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
                      ]"
                    >
                      {{ vote.vote === 'yes' ? 'Yes' : vote.vote === 'no' ? 'No' : 'Abstain' }}
                    </div>
                  </div>
                  
                  <div class="flex items-center text-xs text-gray-500 dark:text-gray-400 space-x-4 mb-2">
                    <span>
                      {{ formatTokenAmount(parseTokenAmount(Number(vote.votingPower), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
                    </span>
                    <span>
                      {{ formatDate(Number(vote.timestamp)) }}
                    </span>
                  </div>

                  <div v-if="vote.reason" class="text-sm text-gray-700 dark:text-gray-300 italic">
                    "{{ vote.reason }}"
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Voting Stats Sidebar -->
      <div class="space-y-6">
        <!-- Voting Results -->
        <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Voting Results</h3>
          
          <div class="space-y-4">
            <!-- Yes Votes -->
            <div>
              <div class="flex justify-between items-center mb-2">
                <span class="flex items-center text-sm font-medium text-green-600 dark:text-green-400">
                  <ThumbsUpIcon class="h-4 w-4 mr-1" />
                  Yes
                </span>
                <span class="text-sm font-medium text-gray-900 dark:text-white">
                  {{ formatTokenAmount(parseTokenAmount(Number(proposalInfo.votesDetails.yesVotes), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
                </span>
              </div>
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div 
                  class="bg-green-500 h-2 rounded-full transition-all duration-300"
                  :style="{ width: `${yesPercentage}%` }"
                ></div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ yesPercentage.toFixed(1) }}%</p>
            </div>

            <!-- No Votes -->
            <div>
              <div class="flex justify-between items-center mb-2">
                <span class="flex items-center text-sm font-medium text-red-600 dark:text-red-400">
                  <ThumbsDownIcon class="h-4 w-4 mr-1" />
                  No
                </span>
                <span class="text-sm font-medium text-gray-900 dark:text-white">
                  {{ formatTokenAmount(parseTokenAmount(Number(proposalInfo.votesDetails.noVotes), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
                </span>
              </div>
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div 
                  class="bg-red-500 h-2 rounded-full transition-all duration-300"
                  :style="{ width: `${noPercentage}%` }"
                ></div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ noPercentage.toFixed(1) }}%</p>
            </div>

            <!-- Abstain Votes -->
            <div>
              <div class="flex justify-between items-center mb-2">
                <span class="flex items-center text-sm font-medium text-gray-600 dark:text-gray-400">
                  <MinusIcon class="h-4 w-4 mr-1" />
                  Abstain
                </span>
                <span class="text-sm font-medium text-gray-900 dark:text-white">
                  {{ formatTokenAmount(parseTokenAmount(Number(proposalInfo.votesDetails.abstainVotes), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
                </span>
              </div>
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div 
                  class="bg-gray-500 h-2 rounded-full transition-all duration-300"
                  :style="{ width: `${abstainPercentage}%` }"
                ></div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ abstainPercentage.toFixed(1) }}%</p>
            </div>
          </div>

          <!-- Summary Stats -->
          <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700 space-y-3">
            <div class="flex justify-between">
              <span class="text-sm text-gray-600 dark:text-gray-400">Total Votes</span>
              <span class="text-sm font-medium text-gray-900 dark:text-white">
                {{ formatTokenAmount(parseTokenAmount(Number(proposalInfo.votesDetails.totalVotes), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm text-gray-600 dark:text-gray-400">Quorum Met</span>
              <span :class="[
                'text-sm font-medium',
                proposalInfo.votesDetails.quorumMet 
                  ? 'text-green-600 dark:text-green-400' 
                  : 'text-red-600 dark:text-red-400'
              ]">
                {{ proposalInfo.votesDetails.quorumMet ? 'Yes' : 'No' }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm text-gray-600 dark:text-gray-400">Threshold Met</span>
              <span :class="[
                'text-sm font-medium',
                proposalInfo.votesDetails.thresholdMet 
                  ? 'text-green-600 dark:text-green-400' 
                  : 'text-red-600 dark:text-red-400'
              ]">
                {{ proposalInfo.votesDetails.thresholdMet ? 'Yes' : 'No' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Time Information -->
        <div v-if="timeInfo" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Timeline</h3>
          <div class="flex items-center">
            <ClockIcon class="h-5 w-5 text-gray-400 mr-3" />
            <div>
              <p class="text-sm font-medium text-gray-900 dark:text-white">{{ timeInfo.label }}</p>
              <p v-if="timeInfo.duration" class="text-sm text-gray-500 dark:text-gray-400">{{ timeInfo.duration }}</p>
            </div>
          </div>
        </div>

        <!-- Comments Section -->
        <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
            <MessageCircleIcon class="h-5 w-5 mr-2" />
            Discussion ({{ comments.length }})
          </h3>
          
          <!-- Add Comment Form -->
          <div class="mb-6 space-y-4">
            <div>
              <textarea
                v-model="newComment"
                placeholder="Share your thoughts on this proposal..."
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 resize-none"
              ></textarea>
              <div class="flex items-center justify-between mt-2">
                <p class="text-xs text-gray-500 dark:text-gray-400">
                  Anyone can comment. Stakers will have voting power displayed.
                </p>
                <span class="text-xs text-gray-400">{{ newComment.length }}/500</span>
              </div>
            </div>
            <div class="flex justify-end">
              <button
                @click="showCommentConfirmation"
                :disabled="!newComment.trim() || newComment.length > 500"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-lg text-white bg-gradient-to-r from-yellow-600 to-amber-600 hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <MessageCircleIcon class="h-4 w-4 mr-2" />
                Post Comment
              </button>
            </div>
          </div>

          <!-- Comments List -->
          <div class="space-y-4">
            <div v-if="comments.length === 0" class="text-center py-8">
              <MessageCircleIcon class="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
              <p class="text-gray-500 dark:text-gray-400">No comments yet. Be the first to share your thoughts!</p>
            </div>
            
            <div v-for="comment in comments" :key="comment.id" class="border border-gray-200 dark:border-gray-700 rounded-lg p-4">
              <div class="flex items-start justify-between mb-3">
                <div class="flex items-center space-x-3">
                  <div class="w-8 h-8 bg-gradient-to-br from-yellow-400 to-amber-500 rounded-full flex items-center justify-center">
                    <span class="text-white text-sm font-medium">
                      {{ (comment.author).substring(0, 2).toUpperCase() }}
                    </span>
                  </div>
                  <div>
                    <div class="flex items-center space-x-2">
                      <span class="text-sm font-medium text-gray-900 dark:text-white font-mono">
                        {{ shortPrincipal(comment.author as string) }}
                      </span>
                      <div v-if="comment.isStaker" class="flex items-center space-x-1">
                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                          <CheckCircleIcon class="h-3 w-3 mr-1" />
                          Staker
                        </span>
                        <span v-if="comment.votingPower" class="text-xs text-gray-500 dark:text-gray-400">
                          {{ formatTokenAmount(parseTokenAmount(Number(comment.votingPower), dao?.tokenConfig.decimals).toNumber(), 'VP') }}
                        </span>
                      </div>
                    </div>
                    <p class="text-xs text-gray-500 dark:text-gray-400">
                      {{ formatDate(Number(comment.createdAt)) }}
                      <span v-if="comment.isEdited" class="ml-1">(edited)</span>
                    </p>
                  </div>
                </div>
                
                <!-- Comment Actions -->
                <div v-if="comment.author === currentUserPrincipal" class="flex items-center space-x-2">
                  <button
                    @click="startEditComment(comment)"
                    class="text-gray-400 hover:text-yellow-600 dark:hover:text-yellow-400 transition-colors"
                    title="Edit comment"
                  >
                    <EditIcon class="h-4 w-4" />
                  </button>
                  <button
                    @click="showDeleteConfirmation(comment)"
                    class="text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
                    title="Delete comment"
                  >
                    <Trash2Icon class="h-4 w-4" />
                  </button>
                </div>
              </div>
              
              <!-- Comment Content -->
              <div v-if="editingCommentId !== comment.id">
                <p class="text-gray-700 dark:text-gray-300 whitespace-pre-wrap">{{ comment.content }}</p>
              </div>
              
              <!-- Edit Comment Form -->
              <div v-else class="space-y-3">
                <textarea
                  v-model="editingCommentContent"
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white resize-none"
                  maxlength="500"
                ></textarea>
                <div class="flex items-center justify-between">
                  <span class="text-xs text-gray-400">{{ editingCommentContent.length }}/500</span>
                  <div class="flex space-x-2">
                    <button
                      @click="cancelEditComment"
                      class="px-3 py-1 text-sm text-gray-600 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      @click="showUpdateConfirmation(comment.id)"
                      :disabled="!editingCommentContent.trim() || editingCommentContent.length > 500"
                      class="inline-flex items-center px-3 py-1 text-sm font-medium text-white bg-yellow-600 hover:bg-yellow-700 rounded-lg disabled:opacity-50 transition-colors"
                    >
                      Update Comment
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Loading State -->
  <div v-else-if="isLoading" class="text-center py-12">
    <div class="inline-flex items-center px-6 py-3 border border-transparent rounded-full shadow-sm text-sm font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600">
      <div class="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-white mr-3"></div>
      Loading proposal...
    </div>
  </div>

  <!-- Error State -->
  <div v-else class="text-center py-12">
    <div class="text-red-500 mb-4">
      <AlertCircleIcon class="h-12 w-12 mx-auto" />
    </div>
    <p class="text-red-600 dark:text-red-400 text-lg font-medium mb-4">{{ error }}</p>
    <button 
      @click="fetchData"
      class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
    >
      <RefreshCcwIcon class="h-4 w-4 mr-2" />
      Try Again
    </button>
  </div>

  <!-- Confirmation Dialogs -->
  <ConfirmationDialog
    :show="showCommentConfirm"
    title="Post Comment"
    message="Are you sure you want to post this comment?"
    type="info"
    :isProcessing="isSubmittingComment"
    processingText="Posting comment..."
    confirmText="Post Comment"
    @confirm="submitComment"
    @cancel="showCommentConfirm = false"
  />

  <ConfirmationDialog
    :show="showDeleteConfirm"
    title="Delete Comment"
    message="Are you sure you want to delete this comment? This action cannot be undone."
    type="danger"
    confirmVariant="danger"
    confirmText="Delete Comment"
    @confirm="deleteComment"
    @cancel="showDeleteConfirm = false"
  />

  <ConfirmationDialog
    :show="showUpdateConfirm"
    title="Update Comment"
    message="Are you sure you want to update this comment?"
    type="info"
    :isProcessing="isUpdatingComment"
    processingText="Updating comment..."
    confirmText="Update Comment"
    @confirm="updateComment(editingCommentId!)"
    @cancel="showUpdateConfirm = false"
  />

  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { DAOService } from '@/api/services/dao'
import {
  ArrowLeftIcon,
  UserIcon,
  CalendarIcon,
  TargetIcon,
  CheckCircleIcon,
  ClockIcon,
  ExternalLinkIcon,
  ThumbsUpIcon,
  ThumbsDownIcon,
  MinusIcon,
  AlertCircleIcon,
  RefreshCcwIcon,
  MessageCircleIcon,
  EditIcon,
  Trash2Icon
} from 'lucide-vue-next'
import ProposalStatusBadge from '@/components/dao/ProposalStatusBadge.vue'
import ProposalTypeBadge from '@/components/dao/ProposalTypeBadge.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import ConfirmationDialog from '@/components/common/ConfirmationDialog.vue'
import type { DAO, ProposalInfo, MemberInfo, ProposalComment, VoteRecord } from '@/types/dao'
import { getProposalStateKey } from '@/types/dao'
import { useAuthStore } from '@/stores/auth'
import { parseTokenAmount } from '@/utils/token'
import { shortPrincipal } from '@/utils/common'
import { toast } from 'vue-sonner'
const route = useRoute()
const router = useRouter()
const daoService = DAOService.getInstance()
const authStore = useAuthStore()

// State
const dao = ref<DAO | null>(null)
const proposalInfo = ref<any | null>(null)
const memberInfo = ref<any | null>(null)
const isLoading = ref(true)
const error = ref<string | null>(null)
const isVoting = ref(false)
const voteReason = ref('')

// Vote state
const userVote = ref<any | null>(null)
const voteRecords = ref<any[]>([])
const isLoadingVotes = ref(false)

// Comment system state
const comments = ref<ProposalComment[]>([])
const newComment = ref('')
const isSubmittingComment = ref(false)
const editingCommentId = ref<string | null>(null)
const editingCommentContent = ref('')
const isUpdatingComment = ref(false)

// Confirmation dialog state
const showCommentConfirm = ref(false)
const showDeleteConfirm = ref(false)
const showUpdateConfirm = ref(false)
const commentToDelete = ref<ProposalComment | null>(null)

// Computed
const currentUserPrincipal = computed(() => {
  return authStore.principal || ''
})

const breadcrumbItems = computed(() => [
  { label: 'DAOs', to: '/dao' },
  { label: dao.value?.name || 'DAO', to: `/dao/${route.params.id}` },
  { label: 'Proposals', to: `/dao/${route.params.id}/proposals` },
  { label: `Proposal #${route.params.proposalId}` }
])

const hasVoted = computed(() => {
  return userVote.value !== null
})

const totalVotes = computed(() => {
  if (!proposalInfo.value) return 0
  return Number(proposalInfo.value.votesDetails.totalVotes)
})

const yesPercentage = computed(() => {
  if (totalVotes.value === 0) return 0
  return (Number(proposalInfo.value!.votesDetails.yesVotes) / totalVotes.value) * 100
})

const noPercentage = computed(() => {
  if (totalVotes.value === 0) return 0
  return (Number(proposalInfo.value!.votesDetails.noVotes) / totalVotes.value) * 100
})

const abstainPercentage = computed(() => {
  if (totalVotes.value === 0) return 0
  return (Number(proposalInfo.value!.votesDetails.abstainVotes) / totalVotes.value) * 100
})

const timeInfo = computed(() => {
  if (!proposalInfo.value) return null
  
  const now = Date.now()
  
  if (proposalInfo.value.timeRemaining && proposalInfo.value.timeRemaining[0]) {
    const timeLeft = Number(proposalInfo.value.timeRemaining[0])
    return {
      label: 'Voting ends in',
      duration: formatDuration(timeLeft)
    }
  }
  
  if (proposalInfo.value.timeToExecution && proposalInfo.value.timeToExecution[0]) {
    const timeToExec = Number(proposalInfo.value.timeToExecution[0])
    return {
      label: 'Executes in',
      duration: formatDuration(timeToExec)
    }
  }
  
  return null
})

// Methods
const fetchData = async () => {
  isLoading.value = true
  error.value = null

  try {
    const daoId = route.params.id as string
    const proposalId = parseInt(route.params.proposalId as string)
    
    // Fetch DAO details
    const daoData = await daoService.getDAO(daoId)
    if (!daoData) {
      error.value = 'DAO not found'
      return
    }
    dao.value = daoData

    // Fetch proposal details
    const proposalData = await daoService.getProposal(daoId, proposalId)
    if (!proposalData) {
      error.value = 'Proposal not found'
      return
    }
    proposalInfo.value = proposalData

    // Fetch vote data
    await Promise.all([
      fetchUserVote(),
      fetchVoteRecords()
    ])

    // Fetch member info (if user is connected)
    try {
      const memberData = await daoService.getMyMemberInfo(daoId)
      memberInfo.value = memberData
    } catch (err) {
      memberInfo.value = null
    }

  } catch (err) {
    console.error('Error fetching proposal:', err)
    error.value = 'Failed to load proposal details'
  } finally {
    isLoading.value = false
  }
}

const fetchUserVote = async () => {
  if (!authStore.principal || !dao.value || !proposalInfo.value) {
    userVote.value = null
    return
  }

  try {
    const result = await daoService.getUserVote(
      dao.value.canisterId, 
      proposalInfo.value.proposal.id, 
      authStore.principal
    )
    
    if (result.success) {
      userVote.value = result.data
    } else {
      userVote.value = null
    }
  } catch (err) {
    console.error('Error fetching user vote:', err)
    userVote.value = null
  }
}

const fetchVoteRecords = async () => {
  if (!dao.value || !proposalInfo.value) {
    voteRecords.value = []
    return
  }

  isLoadingVotes.value = true
  try {
    const result = await daoService.getProposalVotes(
      dao.value.canisterId, 
      proposalInfo.value.proposal.id
    )
    
    if (result.success && result.data) {
      voteRecords.value = result.data
    } else {
      voteRecords.value = []
    }
  } catch (err) {
    console.error('Error fetching vote records:', err)
    voteRecords.value = []
  } finally {
    isLoadingVotes.value = false
  }
}

const castVote = async (vote: 'Yes' | 'No' | 'Abstain') => {
  if (!proposalInfo.value || !dao.value || isVoting.value) return

  isVoting.value = true

  try {
    const result = await daoService.vote(dao.value.canisterId, {
      proposalId: proposalInfo.value.proposal.id,
      vote: vote,
      reason: voteReason.value || undefined
    })

    if (result.success) {
      // Refresh vote data
      toast.success('Vote cast successfully')
      await Promise.all([
        fetchUserVote(),
        fetchVoteRecords()
      ])
      voteReason.value = ''
    } else {
      error.value = result.error || 'Failed to cast vote'
      toast.error(error.value)  
    }
  } catch (err) {
    console.error('Error casting vote:', err)
    error.value = 'An unexpected error occurred while voting'
    toast.error(error.value)
  } finally {
    isVoting.value = false
  }
}

const getProposalType = (payload: any): 'motion' | 'callExternal' | 'tokenManage' | 'systemUpdate' => {
  if ('Motion' in payload) return 'motion'
  if ('CallExternal' in payload) return 'callExternal'
  if ('TokenManage' in payload) return 'tokenManage'
  if ('SystemUpdate' in payload) return 'systemUpdate'
  return 'motion'
}

const getProposalTitle = (payload: any): string => {
  if ('Motion' in payload) return payload.Motion.title
  if ('CallExternal' in payload) return 'External Contract Call'
  if ('TokenManage' in payload) return 'Token Management'
  if ('SystemUpdate' in payload) return 'System Update'
  return 'Proposal'
}

const getProposalDescription = (payload: any): string => {
  if ('Motion' in payload) return payload.Motion.description
  if ('CallExternal' in payload) return payload.CallExternal.description
  if ('TokenManage' in payload) return 'Token management operation'
  if ('SystemUpdate' in payload) return 'System parameter update'
  return 'No description available'
}

const getDiscussionUrl = (payload: any): string | null => {
  if ('Motion' in payload && payload.Motion.discussionUrl && payload.Motion.discussionUrl[0]) {
    return payload.Motion.discussionUrl[0]
  }
  return null
}

const formatDate = (timestamp: number): string => {
  const date = new Date(timestamp / 1000000) // Convert nanoseconds to milliseconds
  return date.toLocaleString('en-US', { 
    year: 'numeric',
    month: 'long', 
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''} ${hours} hour${hours > 1 ? 's' : ''}`
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''} ${minutes} minute${minutes > 1 ? 's' : ''}`
  } else {
    return `${minutes} minute${minutes > 1 ? 's' : ''}`
  }
}

const formatPrincipal = (principal: string): string => {
  if (principal.length <= 20) return principal
  return principal.substring(0, 8) + '...' + principal.substring(principal.length - 8)
}

const formatTokenAmount = (amount: number, symbol: string): string => {
  if (isNaN(amount)) return '0 ' + symbol
  
  if (amount >= 1000000) {
    return (amount / 1000000).toFixed(1) + 'M ' + symbol
  } else if (amount >= 1000) {
    return (amount / 1000).toFixed(1) + 'K ' + symbol
  }
  return Math.floor(amount).toString() + ' ' + symbol
}

// Comment system methods
const fetchComments = async () => {
  try {
    const proposalId = parseInt(route.params.proposalId as string)
    const daoId = route.params.id as string
    
    const fetchedComments = await daoService.getProposalComments(daoId, proposalId)
    comments.value = fetchedComments
  } catch (err) {
    console.error('Error fetching comments:', err)
  }
}

const submitComment = async () => {
  if (!newComment.value.trim() || !proposalInfo.value || isSubmittingComment.value) return

  isSubmittingComment.value = true

  try {
    const proposalId = route.params.proposalId as string
    const daoId = route.params.id as string
    
    const result = await daoService.createComment(daoId, {
      proposalId,
      content: newComment.value.trim()
    })
    
    if (result.success) {
      newComment.value = ''
      // Refresh comments to get the new one with accurate staker info
      await fetchComments()
    } else {
      error.value = result.error || 'Failed to submit comment'
    }
    
  } catch (err) {
    console.error('Error submitting comment:', err)
    error.value = 'Failed to submit comment'
  } finally {
    isSubmittingComment.value = false
  }
}

const startEditComment = (comment: ProposalComment) => {
  editingCommentId.value = comment.id
  editingCommentContent.value = comment.content
}

const cancelEditComment = () => {
  editingCommentId.value = null
  editingCommentContent.value = ''
}

const updateComment = async (commentId: string) => {
  if (!editingCommentContent.value.trim() || isUpdatingComment.value) return

  isUpdatingComment.value = true

  try {
    const daoId = route.params.id as string
    
    const result = await daoService.updateComment(daoId, {
      commentId,
      content: editingCommentContent.value.trim()
    })
    
    if (result.success) {
      cancelEditComment()
      // Refresh comments to get the updated one
      await fetchComments()
    } else {
      error.value = result.error || 'Failed to update comment'
    }
    
  } catch (err) {
    console.error('Error updating comment:', err)
    error.value = 'Failed to update comment'
  } finally {
    isUpdatingComment.value = false
  }
}

const deleteComment = async () => {
  if (!commentToDelete.value) return

  try {
    const daoId = route.params.id as string
    
    const result = await daoService.deleteComment(daoId, commentToDelete.value.id)
    
    if (result.success) {
      showDeleteConfirm.value = false
      commentToDelete.value = null
      // Refresh comments to remove the deleted one
      await fetchComments()
    } else {
      error.value = result.error || 'Failed to delete comment'
    }
    
  } catch (err) {
    console.error('Error deleting comment:', err)
    error.value = 'Failed to delete comment'
  }
}

// Confirmation dialog methods
const showCommentConfirmation = () => {
  if (!newComment.value.trim() || newComment.value.length > 500) return
  showCommentConfirm.value = true
}

const showDeleteConfirmation = (comment: ProposalComment) => {
  commentToDelete.value = comment
  showDeleteConfirm.value = true
}

const showUpdateConfirmation = (commentId: string) => {
  if (!editingCommentContent.value.trim() || editingCommentContent.value.length > 500) return
  showUpdateConfirm.value = true
}

onMounted(() => {
  fetchData()
  fetchComments()
})
</script>