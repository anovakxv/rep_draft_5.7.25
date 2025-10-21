// src/pages/utils/api.ts
// API utility using native fetch instead of axios

const BASE_URL = import.meta.env.VITE_API_BASE_URL;
const TIMEOUT = 30000; // 30 seconds

interface RequestConfig {
  headers?: Record<string, string>;
  timeout?: number;
}

interface ApiResponse<T = any> {
  data: T;
  status: number;
  statusText: string;
}

class ApiError extends Error {
  response?: {
    status: number;
    statusText: string;
    data: any;
  };

  constructor(message: string, response?: { status: number; statusText: string; data: any }) {
    super(message);
    this.response = response;
    this.name = 'ApiError';
  }
}

async function fetchWithTimeout(url: string, options: RequestInit, timeout: number): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    return response;
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

async function request<T = any>(
  method: string,
  path: string,
  data?: any,
  config?: RequestConfig
): Promise<ApiResponse<T>> {
  const url = `${BASE_URL}${path}`;
  const token = localStorage.getItem('jwtToken');

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(config?.headers || {})
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const options: RequestInit = {
    method,
    headers,
  };

  if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
    options.body = JSON.stringify(data);
  }

  try {
    const response = await fetchWithTimeout(url, options, config?.timeout || TIMEOUT);

    let responseData: any;
    const contentType = response.headers.get('content-type');

    if (contentType && contentType.includes('application/json')) {
      responseData = await response.json();
    } else {
      responseData = await response.text();
    }

    // Handle unauthorized errors globally
    if (response.status === 401 || response.status === 403) {
      console.error('Unauthorized - clearing session and redirecting to login');

      localStorage.removeItem('jwtToken');
      localStorage.removeItem('userId');
      localStorage.removeItem('isRegistered');
      localStorage.removeItem('onboardingComplete');

      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }

    if (!response.ok) {
      throw new ApiError(
        responseData?.error || responseData?.message || `HTTP ${response.status}: ${response.statusText}`,
        {
          status: response.status,
          statusText: response.statusText,
          data: responseData
        }
      );
    }

    return {
      data: responseData,
      status: response.status,
      statusText: response.statusText
    };
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }

    // Handle network errors
    console.error('Network error:', error);
    throw new ApiError(
      error instanceof Error ? error.message : 'Network error occurred'
    );
  }
}

const api = {
  get: <T = any>(path: string, config?: RequestConfig) =>
    request<T>('GET', path, undefined, config),

  post: <T = any>(path: string, data?: any, config?: RequestConfig) =>
    request<T>('POST', path, data, config),

  put: <T = any>(path: string, data?: any, config?: RequestConfig) =>
    request<T>('PUT', path, data, config),

  patch: <T = any>(path: string, data?: any, config?: RequestConfig) =>
    request<T>('PATCH', path, data, config),

  delete: <T = any>(path: string, config?: RequestConfig) =>
    request<T>('DELETE', path, undefined, config),
};

export default api;
