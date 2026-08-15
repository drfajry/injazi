import type { DiscoveredItem, SourceConnector } from './types.js';

/**
 * The Madrasati connector is intentionally isolated.
 * The implementation must follow the approved access flow and the platform's
 * terms/permissions. The core product does not depend on its implementation details.
 */
export class MadrasatiConnector implements SourceConnector {
  readonly type = 'MADRASATI' as const;

  async connect(_userId: string, _payload: unknown): Promise<void> {
    // Add the approved browser/session connector here.
  }

  async sync(_userId: string, _sourceId: string): Promise<DiscoveredItem[]> {
    // Adapter placeholder: map Madrasati items into the common DiscoveredItem shape.
    return [];
  }

  async disconnect(_userId: string, _sourceId: string): Promise<void> {}
}
