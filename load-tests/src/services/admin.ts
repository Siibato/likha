import { ApiClient } from '../core/api-client';

export class AdminService {
  constructor(private client: ApiClient) {}

  listAccounts() {
    return this.client.get('/auth/accounts', { tags: { name: 'Admin:AccountList' } });
  }

  getAccount(userId: string) {
    return this.client.get(`/auth/accounts/${userId}`, { tags: { name: 'Admin:AccountDetail' } });
  }

  getActivityLogs(userId: string) {
    return this.client.get(`/auth/accounts/${userId}/logs`, { tags: { name: 'Admin:ActivityLogs' } });
  }

  getQrCode() {
    return this.client.get('/admin/setup/qr', { tags: { name: 'Admin:SetupQr' } });
  }

  getSchoolCode() {
    return this.client.get('/admin/setup/code', { tags: { name: 'Admin:SetupCode' } });
  }

  getSchoolSettings() {
    return this.client.get('/admin/setup/school-settings', { tags: { name: 'Admin:SchoolSettings' } });
  }

  searchStudents(query: string) {
    return this.client.get(`/students/search?q=${encodeURIComponent(query)}`, {
      tags: { name: 'Admin:StudentSearch' },
    });
  }
}
