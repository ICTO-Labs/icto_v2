<template>
  <AdminLayout>
    <div
      class="rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03] overflow-hidden"
    >
      <!-- Hero Section -->
      <div class="relative flex flex-col items-center justify-center min-h-[460px] px-6 py-16 text-center">
        <!-- Ambient blobs -->
        <div
          class="absolute -top-32 -right-32 w-80 h-80 rounded-full pointer-events-none"
          style="background: radial-gradient(circle, #d8a73530 0%, transparent 70%)"
        />
        <div
          class="absolute -bottom-32 -left-32 w-80 h-80 rounded-full pointer-events-none"
          style="background: radial-gradient(circle, #b27c1030 0%, transparent 70%)"
        />

        <!-- Icon with pulse ring -->
        <div class="relative mb-8">
          <div
            class="w-24 h-24 mx-auto rounded-2xl flex items-center justify-center shadow-xl"
            style="background: linear-gradient(135deg, #b27c10, #d8a735, #eacf6f)"
          >
            <component :is="featureIcon" class="w-12 h-12 text-white" />
          </div>
          <span class="absolute -top-1 -right-1 flex h-4 w-4">
            <span
              class="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75"
              style="background-color: #d8a735"
            />
            <span
              class="relative inline-flex rounded-full h-4 w-4"
              style="background-color: #b27c10"
            />
          </span>
        </div>

        <!-- Badge -->
        <span
          class="inline-flex items-center gap-1.5 mb-4 px-3 py-1 text-xs font-semibold uppercase tracking-widest rounded-full border"
          style="
            background: rgba(234, 207, 111, 0.12);
            border-color: rgba(216, 167, 53, 0.3);
            color: #b27c10;
          "
        >
          <ZapIcon class="w-3 h-3" />
          In Development
        </span>

        <!-- Feature Name -->
        <h1 class="text-3xl sm:text-4xl font-bold text-gray-900 dark:text-white mb-3">
          {{ featureName }}
        </h1>
        <p class="text-gray-500 dark:text-gray-400 max-w-md leading-relaxed text-sm sm:text-base">
          We're actively building this feature on the Internet Computer. Stay tuned — it will be
          available soon.
        </p>

        <!-- Actions -->
        <div class="mt-8 flex flex-col sm:flex-row items-center gap-3">
          <router-link
            to="/"
            class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl text-white font-semibold text-sm transition-all shadow-lg"
            style="
              background: linear-gradient(135deg, #b27c10, #d8a735);
              box-shadow: 0 4px 14px rgba(178, 124, 16, 0.25);
            "
          >
            <HomeIcon class="w-4 h-4" />
            Dashboard
          </router-link>
          <button
            @click="$router.back()"
            class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 font-medium text-sm hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-all"
          >
            <ArrowLeftIcon class="w-4 h-4" />
            Go Back
          </button>
        </div>
      </div>

      <!-- Upcoming features grid -->
      <div class="border-t border-gray-100 dark:border-gray-800 px-6 py-10">
        <p
          class="text-center text-xs font-semibold uppercase tracking-widest text-gray-400 dark:text-gray-500 mb-6"
        >
          More features coming to Internet Computer
        </p>
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 max-w-4xl mx-auto">
          <router-link
            v-for="item in upcomingFeatures"
            :key="item.name"
            :to="`/coming-soon?feature=${encodeURIComponent(item.name)}`"
            class="group flex items-center gap-3 p-3.5 rounded-xl border border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-white/[0.03] transition-all duration-200"
            style="--hover-border: rgba(216, 167, 53, 0.35)"
          >
            <div
              class="w-8 h-8 flex-shrink-0 rounded-lg bg-gray-100 dark:bg-gray-800 flex items-center justify-center transition-all group-hover:bg-[#eacf6f]/15 dark:group-hover:bg-[#b27c10]/20"
            >
              <component
                :is="item.icon"
                class="w-4 h-4 text-gray-400 dark:text-gray-500 group-hover:text-[#b27c10] dark:group-hover:text-[#eacf6f] transition-colors"
              />
            </div>
            <span
              class="text-sm font-medium text-gray-600 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white transition-colors truncate"
            >
              {{ item.name }}
            </span>
          </router-link>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import AdminLayout from "@/components/layout/AdminLayout.vue";
import {
  RocketIcon,
  HomeIcon,
  ArrowLeftIcon,
  ZapIcon,
  NetworkIcon,
  ArrowLeftRightIcon,
  GlobeIcon,
  TerminalIcon,
  GemIcon,
  LinkIcon,
  VoteIcon,
  CpuIcon,
  ShieldCheckIcon,
} from "lucide-vue-next";

const route = useRoute();

const featureName = computed(() => {
  const f = route.query.feature as string;
  return f ? decodeURIComponent(f.replace(/\+/g, " ")) : "Coming Soon";
});

const iconMap: Record<string, object> = {
  "SNS Neurons": NetworkIcon,
  "SNS Proposals": VoteIcon,
  "SNS Swap": ArrowLeftRightIcon,
  "NNS Staking": GlobeIcon,
  "ICRC-7 NFTs": GemIcon,
  "Chain-Key Tokens": LinkIcon,
  "Cycles Manager": ZapIcon,
  "Chain Fusion": ShieldCheckIcon,
  "Canister Hub": TerminalIcon,
};

const featureIcon = computed(() => iconMap[featureName.value] ?? RocketIcon);

const upcomingFeatures = [
  { name: "SNS Neurons", icon: NetworkIcon },
  { name: "SNS Proposals", icon: VoteIcon },
  { name: "SNS Swap", icon: ArrowLeftRightIcon },
  { name: "NNS Staking", icon: GlobeIcon },
  { name: "ICRC-7 NFTs", icon: GemIcon },
  { name: "Chain-Key Tokens", icon: LinkIcon },
  { name: "Cycles Manager", icon: ZapIcon },
  { name: "Chain Fusion", icon: ShieldCheckIcon },
  { name: "Canister Hub", icon: TerminalIcon },
];
</script>
