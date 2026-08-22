import { google } from 'googleapis';
import { createAccessToken, verifyAccessToken } from '../auth/auth-utils.js';
import { env } from '../../config/env.js';

const DRIVE_SCOPE = 'https://www.googleapis.com/auth/drive.readonly';

export function isGoogleDriveConfigured(): boolean {
  return Boolean(env.GOOGLE_CLIENT_ID && env.GOOGLE_CLIENT_SECRET && env.GOOGLE_REDIRECT_URI);
}

function getOAuthClient() {
  if (!isGoogleDriveConfigured()) {
    throw new Error('Google Drive is not configured on this server yet.');
  }

  return new google.auth.OAuth2(
    env.GOOGLE_CLIENT_ID,
    env.GOOGLE_CLIENT_SECRET,
    env.GOOGLE_REDIRECT_URI,
  );
}

/**
 * The OAuth redirect from Google carries no Authorization header, so we
 * encode the userId into a short-lived signed `state` token instead. This
 * both identifies the user on callback and prevents CSRF (an attacker can't
 * forge a valid state without the JWT secret). Reuses the same signed-token
 * scheme already used for access tokens, just with a 10-minute expiry.
 */
export function buildAuthUrl(userId: string): string {
  const client = getOAuthClient();

  const state = createAccessToken(userId, 'oauth-state', env.JWT_SECRET, 600);

  return client.generateAuthUrl({
    access_type: 'offline', // required to receive a refresh_token
    prompt: 'consent', // forces refresh_token on repeat connections too
    scope: [DRIVE_SCOPE],
    state,
  });
}

export function verifyState(state: string): string {
  const payload = verifyAccessToken(state, env.JWT_SECRET);
  return payload.sub;
}

export type GoogleTokens = {
  access_token: string;
  refresh_token?: string;
  expiry_date?: number;
};

export async function exchangeCodeForTokens(code: string): Promise<GoogleTokens> {
  const client = getOAuthClient();
  const { tokens } = await client.getToken(code);

  if (!tokens.access_token) {
    throw new Error('Google did not return an access token.');
  }

  return {
    access_token: tokens.access_token,
    refresh_token: tokens.refresh_token ?? undefined,
    expiry_date: tokens.expiry_date ?? undefined,
  };
}

export async function getGoogleAccountEmail(tokens: GoogleTokens): Promise<string | undefined> {
  const client = getOAuthClient();
  client.setCredentials(tokens);

  try {
    const oauth2 = google.oauth2({ version: 'v2', auth: client });
    const { data } = await oauth2.userinfo.get();
    return data.email ?? undefined;
  } catch {
    return undefined;
  }
}

export type DriveFile = {
  id: string;
  name: string;
  mimeType: string;
  webViewLink?: string;
  modifiedTime?: string;
};

/**
 * Lists recent files from the user's Drive using stored tokens. The
 * googleapis client auto-refreshes the access token using the stored
 * refresh_token when it has expired.
 */
export async function listDriveFiles(tokens: GoogleTokens): Promise<DriveFile[]> {
  const client = getOAuthClient();
  client.setCredentials(tokens);

  const drive = google.drive({ version: 'v3', auth: client });

  const { data } = await drive.files.list({
    pageSize: 25,
    orderBy: 'modifiedTime desc',
    fields: 'files(id, name, mimeType, webViewLink, modifiedTime)',
    q: "trashed = false",
  });

  return (data.files ?? []).map((file) => ({
    id: file.id!,
    name: file.name ?? 'ملف بدون اسم',
    mimeType: file.mimeType ?? 'application/octet-stream',
    webViewLink: file.webViewLink ?? undefined,
    modifiedTime: file.modifiedTime ?? undefined,
  }));
}
