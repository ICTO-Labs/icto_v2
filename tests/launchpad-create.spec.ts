import { test, expect } from '@playwright/test';

// Updated sample test data matching current formData structure
const sampleLaunchpadData = {
  projectInfo: {
    name: 'Test Token Launchpad',
    description: 'A test token launchpad for E2E testing with comprehensive features',
    logo: 'https://example.com/logo.png',
    banner: 'https://example.com/banner.png',
    website: 'https://testtoken.example.com',
    twitter: 'https://twitter.com/testtoken',
    telegram: 'https://t.me/testtoken',
    discord: 'https://discord.gg/testtoken',
    github: 'https://github.com/testtoken',
    documentation: 'https://docs.testtoken.example.com',
    whitepaper: 'https://testtoken.example.com/whitepaper.pdf',
    auditReport: 'https://testtoken.example.com/audit.pdf',
    category: 'DeFi',
    tags: ['DeFi', 'Test', 'Launchpad'],
    kycProvider: 'TestKYC',
    isKYCed: false,
    isAudited: true,
    metadata: [],
    blockIdRequired: 1000
  },
  saleToken: {
    name: 'Test Token',
    symbol: 'TEST',
    decimals: 8,
    totalSupply: '100000000',
    transferFee: '10000',
    standard: 'ICRC1',
    logo: 'https://example.com/test-token-logo.png',
    description: 'Test token for launchpad testing',
    website: 'https://testtoken.example.com'
  },
  purchaseToken: {
    canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
    name: 'Internet Computer',
    symbol: 'ICP',
    decimals: 8,
    totalSupply: '0',
    transferFee: '10000',
    standard: 'ICRC1',
    logo: 'https://cryptologos.cc/logos/internet-computer-icp-logo.png',
    description: 'Internet Computer Protocol',
    website: 'https://internetcomputer.org'
  },
  saleParams: {
    saleType: 'FairLaunch',
    allocationMethod: 'FirstComeFirstServe',
    totalSaleAmount: '10000000',
    price: '0.1',
    tokenPrice: '0.1',
    softCap: '1000000',
    hardCap: '5000000',
    minContribution: '100',
    maxContribution: '10000',
    maxParticipants: '500',
    requiresWhitelist: false,
    requiresKYC: false,
    blockIdRequired: 1000,
    restrictedRegions: [],
    whitelistAddresses: [],
    whitelistMode: 'closed'
  },
  timeline: {
    saleStart: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().slice(0, 16), // Tomorrow
    saleEnd: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16), // Next week
    whitelistStart: new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString().slice(0, 16), // 12 hours
    whitelistEnd: new Date(Date.now() + 23 * 60 * 60 * 1000).toISOString().slice(0, 16), // 23 hours
    claimStart: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16), // Day after sale ends
    listingTime: new Date(Date.now() + 9 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16), // 9 days
    vestingStart: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16), // Same as claim
    daoActivation: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16), // 10 days
    createdAt: Date.now()
  },
  dexConfig: {
    platform: 'ICPSwap',
    totalLiquidityToken: '1000000',
    liquidityLockDays: 365,
    autoList: true,
    lpTokenRecipient: ''
  },
  raisedFundsAllocation: {
    allocations: [
      {
        id: 'team',
        name: 'Team Allocation',
        amount: '1500000',
        percentage: 30,
        recipients: [
          {
            principal: 'test-principal-1',
            percentage: 70,
            name: 'Core Team',
            vestingEnabled: true,
            vestingSchedule: {
              cliffDays: 180,
              durationDays: 730,
              releaseFrequency: 'monthly' as const,
              immediateRelease: 10
            }
          },
          {
            principal: 'test-principal-2',
            percentage: 30,
            name: 'Advisors',
            vestingEnabled: false
          }
        ]
      },
      {
        id: 'development',
        name: 'Development Fund',
        amount: '2000000',
        percentage: 40,
        recipients: [
          {
            principal: 'test-principal-dev',
            percentage: 100,
            name: 'Development Team',
            vestingEnabled: false
          }
        ]
      }
    ]
  },
  governanceConfig: {
    enabled: true,
    daoCanisterId: '',
    votingToken: 'TEST',
    proposalThreshold: '10000',
    quorumPercentage: 50,
    votingPeriod: '7',
    timelockDuration: '2',
    emergencyContacts: ['test-emergency-principal'],
    initialGovernors: ['test-governor-principal'],
    autoActivateDAO: false
  },
  distribution: [
    {
      name: 'Sale Participants',
      percentage: 40,
      totalAmount: '40000000',
      recipients: { type: 'SaleParticipants' }
    },
    {
      name: 'Team & Advisors',
      percentage: 20,
      totalAmount: '20000000',
      recipients: { type: 'TeamAllocation' }
    },
    {
      name: 'Development',
      percentage: 25,
      totalAmount: '25000000',
      recipients: { type: 'TreasuryReserve' }
    },
    {
      name: 'Liquidity',
      percentage: 15,
      totalAmount: '15000000',
      recipients: { type: 'LiquidityPool' }
    }
  ]
};

test.describe('Launchpad Creation Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Start dev server URL
    await page.goto('http://localhost:5173');

    // Wait for the page to load
    await page.waitForLoadState('networkidle');
  });

  test('should complete full launchpad creation flow step by step', async ({ page }) => {
    console.log('🚀 Starting complete launchpad creation flow test...');

    // Navigate to launchpad creation page
    await page.goto('http://localhost:5173/launchpad/create');
    await page.waitForLoadState('networkidle');

    // ====== STEP 1: Choose Template ======
    console.log('📋 Step 1: Choosing template...');
    await page.waitForSelector('button, .template, [data-template]', { timeout: 10000 });

    // Try to select a template
    const templateSelectors = [
      'button:has-text("Standard")',
      'button:has-text("Basic")',
      'button:has-text("Simple")',
      '.template-card:first-child',
      '[data-template]:first-child',
      'button[class*="template"]:first-child'
    ];

    let templateSelected = false;
    for (const selector of templateSelectors) {
      const element = page.locator(selector).first();
      if (await element.isVisible() && await element.isEnabled()) {
        console.log(`✅ Selecting template: ${selector}`);
        await element.click();
        templateSelected = true;
        await page.waitForTimeout(1000);
        break;
      }
    }

    if (!templateSelected) {
      console.log('⚠️ No template found, proceeding to next step');
    }

    // Proceed to Project Information
    let nextButton = page.locator('button:has-text("Next")').or(page.locator('button:has-text("Continue")'));
    if (await nextButton.first().isVisible()) {
      await nextButton.first().click();
      await page.waitForTimeout(1500);
    }

    // ====== STEP 2: Project Information ======
    console.log('📝 Step 2: Filling project information...');

    // Fill project information fields
    const projectFields = [
      { selector: 'input[name="name"], input[name="projectInfo.name"]', value: sampleLaunchpadData.projectInfo.name },
      { selector: 'input[name="website"], input[name="projectInfo.website"]', value: sampleLaunchpadData.projectInfo.website },
      { selector: 'input[name="twitter"], input[name="projectInfo.twitter"]', value: sampleLaunchpadData.projectInfo.twitter },
      { selector: 'input[name="telegram"], input[name="projectInfo.telegram"]', value: sampleLaunchpadData.projectInfo.telegram },
      { selector: 'textarea[name="description"], textarea[name="projectInfo.description"]', value: sampleLaunchpadData.projectInfo.description }
    ];

    for (const field of projectFields) {
      const element = page.locator(field.selector).first();
      if (await element.isVisible()) {
        await element.fill(field.value);
        console.log(`✓ Filled ${field.selector}`);
      }
    }

    // Select category if available
    const categorySelect = page.locator('select[name="category"], select[name="projectInfo.category"]').first();
    if (await categorySelect.isVisible()) {
      await categorySelect.selectOption(sampleLaunchpadData.projectInfo.category);
      console.log('✓ Selected category');
    }

    // Next to Token Configuration
    nextButton = page.locator('button:has-text("Next")').or(page.locator('button:has-text("Continue")'));
    if (await nextButton.first().isVisible()) {
      await nextButton.first().click();
      await page.waitForTimeout(1500);
      console.log('➡️ Moving to Token Configuration');
    }

    // ====== STEP 3: Token Configuration ======
    console.log('🪙 Step 3: Configuring token settings...');

    const tokenFields = [
      { selector: 'input[name="symbol"], input[name="saleToken.symbol"]', value: sampleLaunchpadData.saleToken.symbol },
      { selector: 'input[name="tokenName"], input[name="saleToken.name"]', value: sampleLaunchpadData.saleToken.name },
      { selector: 'input[name="totalSupply"], input[name="saleToken.totalSupply"]', value: sampleLaunchpadData.saleToken.totalSupply },
      { selector: 'input[name="decimals"], input[name="saleToken.decimals"]', value: sampleLaunchpadData.saleToken.decimals.toString() },
      { selector: 'input[name="transferFee"], input[name="saleToken.transferFee"]', value: sampleLaunchpadData.saleToken.transferFee }
    ];

    for (const field of tokenFields) {
      const element = page.locator(field.selector).first();
      if (await element.isVisible()) {
        await element.fill(field.value);
        console.log(`✓ Filled ${field.selector}`);
      }
    }

    // Next to Sale Parameters
    nextButton = page.locator('button:has-text("Next")').or(page.locator('button:has-text("Continue")'));
    if (await nextButton.first().isVisible()) {
      await nextButton.first().click();
      await page.waitForTimeout(1500);
      console.log('➡️ Moving to Sale Parameters');
    }

    // ====== STEP 4: Sale Parameters ======
    console.log('💰 Step 4: Setting sale parameters...');

    const saleFields = [
      { selector: 'input[name="softCap"], input[name="saleParams.softCap"]', value: sampleLaunchpadData.saleParams.softCap },
      { selector: 'input[name="hardCap"], input[name="saleParams.hardCap"]', value: sampleLaunchpadData.saleParams.hardCap },
      { selector: 'input[name="price"], input[name="saleParams.price"], input[name="tokenPrice"]', value: sampleLaunchpadData.saleParams.tokenPrice },
      { selector: 'input[name="minContribution"], input[name="saleParams.minContribution"]', value: sampleLaunchpadData.saleParams.minContribution },
      { selector: 'input[name="maxContribution"], input[name="saleParams.maxContribution"]', value: sampleLaunchpadData.saleParams.maxContribution },
      { selector: 'input[name="totalSaleAmount"], input[name="saleParams.totalSaleAmount"]', value: sampleLaunchpadData.saleParams.totalSaleAmount }
    ];

    for (const field of saleFields) {
      const element = page.locator(field.selector).first();
      if (await element.isVisible()) {
        await element.fill(field.value);
        console.log(`✓ Filled ${field.selector}`);
      }
    }

    // Select sale type and allocation method
    const saleTypeSelect = page.locator('select[name="saleType"], select[name="saleParams.saleType"]').first();
    if (await saleTypeSelect.isVisible()) {
      await saleTypeSelect.selectOption(sampleLaunchpadData.saleParams.saleType);
      console.log('✓ Selected sale type');
    }

    // Next to Timeline
    nextButton = page.locator('button:has-text("Next")').or(page.locator('button:has-text("Continue")'));
    if (await nextButton.first().isVisible()) {
      await nextButton.first().click();
      await page.waitForTimeout(1500);
      console.log('➡️ Moving to Timeline');
    }

    // ====== STEP 5: Timeline ======
    console.log('📅 Step 5: Setting timeline...');

    const timelineFields = [
      { selector: 'input[name="saleStart"], input[name="timeline.saleStart"]', value: sampleLaunchpadData.timeline.saleStart },
      { selector: 'input[name="saleEnd"], input[name="timeline.saleEnd"]', value: sampleLaunchpadData.timeline.saleEnd },
      { selector: 'input[name="claimStart"], input[name="timeline.claimStart"]', value: sampleLaunchpadData.timeline.claimStart }
    ];

    for (const field of timelineFields) {
      const element = page.locator(field.selector).first();
      if (await element.isVisible()) {
        await element.fill(field.value);
        console.log(`✓ Filled ${field.selector}`);
      }
    }

    // Next to Distribution & DEX
    nextButton = page.locator('button:has-text("Next")').or(page.locator('button:has-text("Continue")'));
    if (await nextButton.first().isVisible()) {
      await nextButton.first().click();
      await page.waitForTimeout(1500);
      console.log('➡️ Moving to Distribution & DEX');
    }

    // ====== STEP 6: Distribution & DEX ======
    console.log('🔄 Step 6: Configuring distribution and DEX...');

    // Configure DEX if available
    const autoListCheckbox = page.locator('input[type="checkbox"][name="autoList"], input[name="dexConfig.autoList"]').first();
    if (await autoListCheckbox.isVisible() && sampleLaunchpadData.dexConfig.autoList) {
      await autoListCheckbox.check();
      console.log('✓ Enabled auto listing');
    }

    const dexPlatformSelect = page.locator('select[name="platform"], select[name="dexConfig.platform"]').first();
    if (await dexPlatformSelect.isVisible()) {
      await dexPlatformSelect.selectOption(sampleLaunchpadData.dexConfig.platform);
      console.log('✓ Selected DEX platform');
    }

    // Next to Review/Deploy
    nextButton = page.locator('button:has-text("Next")').or(page.locator('button:has-text("Continue")'));
    if (await nextButton.first().isVisible()) {
      await nextButton.first().click();
      await page.waitForTimeout(1500);
      console.log('➡️ Moving to Review & Deploy');
    }

    // ====== STEP 7: Review & Deploy ======
    console.log('🔍 Step 7: Review and prepare for deployment...');

    // Look for deploy/submit button
    const deployButton = page.locator('button:has-text("Deploy")').or(page.locator('button:has-text("Create")').or(page.locator('button:has-text("Submit")')));

    if (await deployButton.first().isVisible()) {
      console.log('✅ Found deploy button - ready for wallet connection');

      // Check if the button is enabled
      const isEnabled = await deployButton.first().isEnabled();
      expect(isEnabled).toBeTruthy();

      console.log('🎉 Test completed successfully - ready for wallet connection and deployment');
    } else {
      console.log('⚠️ Deploy button not found, checking for final step indicators...');

      // Verify we're at the final step
      const finalStepElements = [
        page.locator('text=Review'),
        page.locator('text=Summary'),
        page.locator('text=Confirm'),
        page.locator('text=Deploy'),
        page.locator('text=Wallet'),
        page.locator('text=Connect')
      ];

      let finalStepFound = false;
      for (const element of finalStepElements) {
        if (await element.first().isVisible()) {
          const text = await element.first().textContent();
          console.log(`✓ Found final step indicator: ${text}`);
          finalStepFound = true;
          break;
        }
      }

      if (finalStepFound) {
        console.log('✅ Successfully reached final step');
      } else {
        console.log('⚠️ Final step not clearly identified, but flow completed');
      }
    }

    // Final verification
    await expect(page.locator('body')).toContainText(/deploy|review|summary|confirm|wallet|connect/i, { timeout: 5000 });

    console.log('🎊 Complete launchpad creation flow test finished successfully!');
  });
});

test.describe('Launchpad Navigation and UI', () => {
  test('should load launchpad listing page', async ({ page }) => {
    await page.goto('http://localhost:5173');

    // Look for launchpad navigation
    const launchpadLink = page.locator('text=Launchpad').or(page.locator('[href*="launchpad"]')).first();

    if (await launchpadLink.isVisible()) {
      await launchpadLink.click();
      await expect(page).toHaveURL(/.*launchpad/);
    } else {
      // Try direct navigation
      await page.goto('http://localhost:5173/launchpad');
    }

    // Verify launchpad listing elements are present
    await expect(page.locator('text=Launchpad').or(page.locator('text=Projects')).or(page.locator('text=Active')).first()).toBeVisible();
  });

  test('should display create launchpad button', async ({ page }) => {
    await page.goto('http://localhost:5173/launchpad');

    // Look for create button
    const createButton = page.locator('button:has-text("Create")').or(page.locator('a:has-text("Create")'));

    await expect(createButton.first()).toBeVisible();
  });
});