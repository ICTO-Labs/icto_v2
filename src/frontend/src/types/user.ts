export interface UserProfile {
  principal: string;
  name?: string;
  email?: string;
  avatar?: string;
  joinedAt?: number;
  lastActive?: number;
  deployments?: number;
  tokens?: number;
  wallet?: string;
  status?: 'active' | 'locked';
  role?: 'user' | 'admin';
}

export interface UserDeployment {
  id: string;
  projectName: string;
  type: string;
  status: string;
  deployedAt?: number;
  canisterId: string;
}

export interface UserPayment {
  id: string;
  type: 'payment' | 'refund';
  amount: string;
  status: 'success' | 'pending' | 'failed';
  createdAt?: number;
  txId: string;
} 