import type { DiscoveredItem, SourceConnector } from './types.js';

export class GoogleDriveConnector implements SourceConnector {
  readonly type = 'GOOGLE_DRIVE' as const;

  async connect(_userId: string, _payload: unknown): Promise<void> {
    // OAuth implementation belongs here. No Google token is stored by this starter.
  }

  async sync(_userId: string, _sourceId: string): Promise<DiscoveredItem[]> {
    // Replace with Drive API calls after OAuth is configured.
    return [];
  }

  async disconnect(_userId: string, _sourceId: string): Promise<void> {}
}
