import {
createHmac,
randomBytes,
scryptSync,
timingSafeEqual,
} from 'node:crypto';

type JwtPayload = {
sub: string;
email: string;
iat: number;
exp: number;
};

function base64Url(value: string | Buffer): string {
const buffer = Buffer.isBuffer(value)
? value
: Buffer.from(value, 'utf8');

return buffer.toString('base64url');
}

function base64UrlDecode(value: string): Buffer {
return Buffer.from(value, 'base64url');
}

export function hashPassword(password: string): string {
const salt = randomBytes(16).toString('hex');
const derivedKey = scryptSync(password, salt, 64).toString('hex');

return salt + ':' + derivedKey;
}

export function verifyPassword(
password: string,
storedHash: string,
): boolean {
const parts = storedHash.split(':');

if (parts.length !== 2) {
return false;
}

const salt = parts[0];
const storedKey = parts[1];

const derivedKey = scryptSync(password, salt, 64);
const expectedKey = Buffer.from(storedKey, 'hex');

if (derivedKey.length !== expectedKey.length) {
return false;
}

return timingSafeEqual(derivedKey, expectedKey);
}

export function createAccessToken(
userId: string,
email: string,
secret: string,
expiresInSeconds: number,
): string {
const header = JSON.stringify({
alg: 'HS256',
typ: 'JWT',
});

const now = Math.floor(Date.now() / 1000);

const payload: JwtPayload = {
sub: userId,
email,
iat: now,
exp: now + expiresInSeconds,
};

const encodedHeader = base64Url(header);
const encodedPayload = base64Url(JSON.stringify(payload));
const unsignedToken = encodedHeader + '.' + encodedPayload;

const signature = createHmac('sha256', secret)
.update(unsignedToken)
.digest();

return unsignedToken + '.' + base64Url(signature);
}

export function verifyAccessToken(
token: string,
secret: string,
): JwtPayload {
const parts = token.split('.');

if (parts.length !== 3) {
throw new Error('Invalid access token');
}

const encodedHeader = parts[0];
const encodedPayload = parts[1];
const encodedSignature = parts[2];

const unsignedToken = encodedHeader + '.' + encodedPayload;

const expectedSignature = createHmac('sha256', secret)
.update(unsignedToken)
.digest();

const receivedSignature = base64UrlDecode(encodedSignature);

if (receivedSignature.length !== expectedSignature.length) {
throw new Error('Invalid access token');
}

if (!timingSafeEqual(receivedSignature, expectedSignature)) {
throw new Error('Invalid access token');
}

let payload: JwtPayload;

try {
payload = JSON.parse(
base64UrlDecode(encodedPayload).toString('utf8'),
) as JwtPayload;
} catch {
throw new Error('Invalid access token payload');
}

if (!payload.sub || !payload.email || !payload.iat || !payload.exp) {
throw new Error('Invalid access token payload');
}

if (payload.exp <= Math.floor(Date.now() / 1000)) {
throw new Error('Access token expired');
}

return payload;
}
