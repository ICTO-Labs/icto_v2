import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { LaunchpadProject } from '@/types/launchpad';

export const useLaunchpadStore = defineStore('launchpad', () => {
  const projects = ref<LaunchpadProject[]>([
    {
      id: 'project1',
      name: 'Example Project',
      description: 'A revolutionary DeFi protocol that will change the world. Built on the Internet Computer for maximum security and scalability.',
      tokenSymbol: 'EXT',
      tokenAddress: 'rrkah-fqaaa-aaaaa-aaaaq-cai',
      status: 'active',
      startTime: Date.now() - 86400000,
      endTime: Date.now() + 86400000 * 6,
      hardCap: 1000000n,
      softCap: 500000n,
      price: 1.0,
      raised: 750000n,
      owner: 'aaaaa-aa',
      website: 'https://example.com',
      whitepaper: 'https://example.com/whitepaper.pdf',
      logo: '/images/product/product-01.png'
    },
    {
      id: 'project2',
      name: 'Super DApp',
      description: 'The next generation of social media, decentralized and user-owned. Your data, your rules.',
      tokenSymbol: 'SDA',
      tokenAddress: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
      status: 'upcoming',
      startTime: Date.now() + 86400000 * 2,
      endTime: Date.now() + 86400000 * 9,
      hardCap: 2500000n,
      softCap: 1000000n,
      price: 0.5,
      raised: 0n,
      owner: 'bbbbb-bb',
      website: 'https://superdapp.com',
      whitepaper: 'https://superdapp.com/whitepaper.pdf',
      logo: '/images/product/product-02.png'
    },
    {
      id: 'project3',
      name: 'Old Project',
      description: 'This project has already ended. It was a great success.',
      tokenSymbol: 'OLD',
      tokenAddress: 'rs7vi-wmaaa-aaaaa-qab5a-cai',
      status: 'ended',
      startTime: Date.now() - 86400000 * 30,
      endTime: Date.now() - 86400000 * 20,
      hardCap: 50000n,
      softCap: 20000n,
      price: 2.5,
      raised: 55000n,
      owner: 'ccccc-cc',
      logo: '/images/product/product-03.png'
    },
  ]);

  const getProjectsByStatus = computed(() => (status: LaunchpadProject['status']) => {
    return projects.value.filter(p => p.status === status)
  });

  // TODO: Add actions to create/fetch launchpad projects from the backend.

  return {
    projects,
    getProjectsByStatus,
  };
}); 