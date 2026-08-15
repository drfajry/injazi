export type ConnectorSource = 'MADRASATI' | 'GOOGLE_DRIVE';

export type DiscoveredItem = {
  externalId: string;
  itemType?: string;
  title?: string;
  url?: string;
  checksum?: string;
  metadata?: Record<string, unknown>;
};

export interface SourceConnector {
  readonly type: ConnectorSource;
  connect(userId: string, payload: unknown): Promise<void>;
  sync(userId: string, sourceId: string): Promise<DiscoveredItem[]>;
  disconnect(userId: string, sourceId: string): Promise<void>;
}
