/**
 * API Service Layer
 * Handles all HTTP requests to backend API
 */

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class APIError extends Error {
  constructor(message, status, data) {
    super(message);
    this.name = 'APIError';
    this.status = status;
    this.data = data;
  }
}

async function request(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;

  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  };

  // Add auth token if available
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(url, config);
    const data = await response.json();

    if (!response.ok) {
      throw new APIError(
        data.error || 'Request failed',
        response.status,
        data
      );
    }

    return data;
  } catch (error) {
    if (error instanceof APIError) {
      throw error;
    }
    throw new APIError('Network error', 0, { originalError: error.message });
  }
}

// ============================================================================
// USER API
// ============================================================================

export const userAPI = {
  // Get user by ID
  async getUser(id) {
    return request(`/users/${id}`);
  },

  // Get user by World ID
  async getUserByWorldId(worldId) {
    return request(`/users/world/${worldId}`);
  },

  // Get user by username
  async getUserByUsername(username) {
    return request(`/users/username/${username}`);
  },

  // Update user profile
  async updateUser(id, updates) {
    return request(`/users/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(updates),
    });
  },

  // Get user stats
  async getUserStats(id) {
    return request(`/users/${id}/stats`);
  },

  // Get user's ACF children
  async getUserChildren(id) {
    return request(`/users/${id}/children`);
  },

  // Get user's upline path
  async getUserUpline(id) {
    return request(`/users/${id}/upline`);
  },
};

// ============================================================================
// FINPOINT API
// ============================================================================

export const finpointAPI = {
  // Get FP balance
  async getBalance(userId) {
    return request(`/finpoint/${userId}/balance`);
  },

  // Get FP transactions
  async getTransactions(userId, params = {}) {
    const query = new URLSearchParams(params).toString();
    return request(`/finpoint/${userId}/transactions?${query}`);
  },

  // Get recent ledger entries
  async getLedger(userId, params = {}) {
    const query = new URLSearchParams(params).toString();
    return request(`/finpoint/${userId}/ledger?${query}`);
  },

  // Get today's earnings
  async getTodayEarnings(userId) {
    return request(`/finpoint/${userId}/today`);
  },
};

// ============================================================================
// NETWORK API
// ============================================================================

export const networkAPI = {
  // Get network tree
  async getTree(userId) {
    return request(`/network/${userId}/tree`);
  },

  // Get network summary
  async getSummary(userId) {
    return request(`/network/${userId}/summary`);
  },

  // Get ACF network table
  async getACFTable(userId) {
    return request(`/network/${userId}/acf`);
  },
};

// ============================================================================
// INSURANCE API
// ============================================================================

export const insuranceAPI = {
  // Get level progress
  async getLevelProgress(userId) {
    return request(`/insurance/${userId}/levels`);
  },

  // Purchase insurance
  async purchase(userId, levelCode) {
    return request(`/insurance/${userId}/purchase`, {
      method: 'POST',
      body: JSON.stringify({ levelCode }),
    });
  },

  // Use rights
  async useRights(userId, levelCode) {
    return request(`/insurance/${userId}/use-rights`, {
      method: 'POST',
      body: JSON.stringify({ levelCode }),
    });
  },
};

// ============================================================================
// AUTH API
// ============================================================================

export const authAPI = {
  // Login
  async login(username, password) {
    const data = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    });

    if (data.token) {
      localStorage.setItem('authToken', data.token);
      localStorage.setItem('userId', data.user.id);
    }

    return data;
  },

  // Logout
  async logout() {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userId');
  },

  // Check if logged in
  isLoggedIn() {
    return !!localStorage.getItem('authToken');
  },

  // Get current user ID
  getCurrentUserId() {
    return localStorage.getItem('userId');
  },
};

export { APIError };
