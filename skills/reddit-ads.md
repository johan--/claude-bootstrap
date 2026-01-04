# Reddit Ads API Skill

*Load with: base.md*

**Purpose:** Automate Reddit advertising campaigns using the Reddit Ads API. Create, manage, and optimize campaigns, ad groups, and ads programmatically.

---

## API Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  REDDIT ADS API HIERARCHY                                        │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Account                                                        │
│    └── Campaign (objective, budget, schedule)                   │
│         └── Ad Group (targeting, bidding, placement)            │
│              └── Ad (creative, headline, CTA)                   │
│                                                                 │
│  + Custom Audiences (customer lists, lookalikes)                │
│  + Conversions API (track events server-side)                   │
├─────────────────────────────────────────────────────────────────┤
│  BASE URL: https://ads-api.reddit.com/api/v2.0                  │
│  DOCS: https://ads-api.reddit.com/docs/                         │
│  RATE LIMIT: 1 request per second                               │
│  AUTH: OAuth 2.0 with Bearer token                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Authentication

### Step 1: Create Reddit Developer App

1. Go to https://www.reddit.com/prefs/apps/
2. Click "Create App" or "Create Another App"
3. Fill in:
   - **Name:** Your app name
   - **Type:** Select `script` for server-side automation
   - **Redirect URI:** Your callback URL (e.g., `https://yourapp.com/callback`)
4. Note your **Client ID** (under app name) and **Client Secret**

### Step 2: Authorization Flow

```javascript
// Node.js OAuth2 flow
const REDDIT_CLIENT_ID = process.env.REDDIT_ADS_CLIENT_ID;
const REDDIT_CLIENT_SECRET = process.env.REDDIT_ADS_CLIENT_SECRET;
const REDIRECT_URI = 'https://yourapp.com/callback';

// Step 1: Generate authorization URL
function getAuthorizationUrl(state) {
  const scopes = 'adsread,adsedit,history';
  return `https://www.reddit.com/api/v1/authorize?` +
    `client_id=${REDDIT_CLIENT_ID}` +
    `&response_type=code` +
    `&state=${state}` +
    `&redirect_uri=${encodeURIComponent(REDIRECT_URI)}` +
    `&duration=permanent` +
    `&scope=${scopes}`;
}

// Step 2: Exchange code for tokens
async function getAccessToken(authorizationCode) {
  const credentials = Buffer.from(
    `${REDDIT_CLIENT_ID}:${REDDIT_CLIENT_SECRET}`
  ).toString('base64');

  const response = await fetch('https://www.reddit.com/api/v1/access_token', {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'YourApp/1.0.0'
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code: authorizationCode,
      redirect_uri: REDIRECT_URI
    })
  });

  return response.json();
  // Returns: { access_token, refresh_token, expires_in, scope }
}

// Step 3: Refresh token when expired
async function refreshAccessToken(refreshToken) {
  const credentials = Buffer.from(
    `${REDDIT_CLIENT_ID}:${REDDIT_CLIENT_SECRET}`
  ).toString('base64');

  const response = await fetch('https://www.reddit.com/api/v1/access_token', {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'YourApp/1.0.0'
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken
    })
  });

  return response.json();
}
```

### Python OAuth2 Flow

```python
import requests
import base64
import os

REDDIT_CLIENT_ID = os.environ['REDDIT_ADS_CLIENT_ID']
REDDIT_CLIENT_SECRET = os.environ['REDDIT_ADS_CLIENT_SECRET']
REDIRECT_URI = 'https://yourapp.com/callback'
USER_AGENT = 'YourApp/1.0.0'

def get_authorization_url(state: str) -> str:
    """Generate OAuth authorization URL."""
    scopes = 'adsread,adsedit,history'
    return (
        f"https://www.reddit.com/api/v1/authorize?"
        f"client_id={REDDIT_CLIENT_ID}"
        f"&response_type=code"
        f"&state={state}"
        f"&redirect_uri={REDIRECT_URI}"
        f"&duration=permanent"
        f"&scope={scopes}"
    )

def get_access_token(authorization_code: str) -> dict:
    """Exchange authorization code for access token."""
    credentials = base64.b64encode(
        f"{REDDIT_CLIENT_ID}:{REDDIT_CLIENT_SECRET}".encode()
    ).decode()

    response = requests.post(
        'https://www.reddit.com/api/v1/access_token',
        headers={
            'Authorization': f'Basic {credentials}',
            'User-Agent': USER_AGENT
        },
        data={
            'grant_type': 'authorization_code',
            'code': authorization_code,
            'redirect_uri': REDIRECT_URI
        }
    )
    return response.json()

def refresh_access_token(refresh_token: str) -> dict:
    """Refresh expired access token."""
    credentials = base64.b64encode(
        f"{REDDIT_CLIENT_ID}:{REDDIT_CLIENT_SECRET}".encode()
    ).decode()

    response = requests.post(
        'https://www.reddit.com/api/v1/access_token',
        headers={
            'Authorization': f'Basic {credentials}',
            'User-Agent': USER_AGENT
        },
        data={
            'grant_type': 'refresh_token',
            'refresh_token': refresh_token
        }
    )
    return response.json()
```

### Required Scopes

| Scope | Access Level |
|-------|--------------|
| `adsread` | Read campaigns, ad groups, ads, reports |
| `adsedit` | Create/update campaigns, ad groups, ads |
| `history` | Access account history |

---

## Reddit Ads Client

### Node.js Client

```typescript
// lib/reddit-ads-client.ts
interface RedditAdsConfig {
  accessToken: string;
  accountId: string;
}

class RedditAdsClient {
  private baseUrl = 'https://ads-api.reddit.com/api/v2.0';
  private accessToken: string;
  private accountId: string;

  constructor(config: RedditAdsConfig) {
    this.accessToken = config.accessToken;
    this.accountId = config.accountId;
  }

  private async request<T>(
    method: string,
    endpoint: string,
    body?: object
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;

    const response = await fetch(url, {
      method,
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json',
        'User-Agent': 'YourApp/1.0.0'
      },
      body: body ? JSON.stringify(body) : undefined
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Reddit Ads API Error: ${JSON.stringify(error)}`);
    }

    return response.json();
  }

  // Account
  async getAccount() {
    return this.request('GET', `/accounts/${this.accountId}`);
  }

  // Campaigns
  async getCampaigns() {
    return this.request('GET', `/accounts/${this.accountId}/campaigns`);
  }

  async getCampaign(campaignId: string) {
    return this.request('GET', `/accounts/${this.accountId}/campaigns/${campaignId}`);
  }

  async createCampaign(campaign: CampaignCreate) {
    return this.request('POST', `/accounts/${this.accountId}/campaigns`, campaign);
  }

  async updateCampaign(campaignId: string, updates: Partial<CampaignCreate>) {
    return this.request('PUT', `/accounts/${this.accountId}/campaigns/${campaignId}`, updates);
  }

  // Ad Groups
  async getAdGroups(campaignId?: string) {
    const endpoint = campaignId
      ? `/accounts/${this.accountId}/campaigns/${campaignId}/ad_groups`
      : `/accounts/${this.accountId}/ad_groups`;
    return this.request('GET', endpoint);
  }

  async getAdGroup(adGroupId: string) {
    return this.request('GET', `/accounts/${this.accountId}/ad_groups/${adGroupId}`);
  }

  async createAdGroup(adGroup: AdGroupCreate) {
    return this.request('POST', `/accounts/${this.accountId}/ad_groups`, adGroup);
  }

  async updateAdGroup(adGroupId: string, updates: Partial<AdGroupCreate>) {
    return this.request('PUT', `/accounts/${this.accountId}/ad_groups/${adGroupId}`, updates);
  }

  // Ads
  async getAds(adGroupId?: string) {
    const endpoint = adGroupId
      ? `/accounts/${this.accountId}/ad_groups/${adGroupId}/ads`
      : `/accounts/${this.accountId}/ads`;
    return this.request('GET', endpoint);
  }

  async createAd(ad: AdCreate) {
    return this.request('POST', `/accounts/${this.accountId}/ads`, ad);
  }

  async updateAd(adId: string, updates: Partial<AdCreate>) {
    return this.request('PUT', `/accounts/${this.accountId}/ads/${adId}`, updates);
  }

  // Reports
  async getReport(reportRequest: ReportRequest) {
    return this.request('POST', `/accounts/${this.accountId}/reports`, reportRequest);
  }

  // Custom Audiences
  async getCustomAudiences() {
    return this.request('GET', `/accounts/${this.accountId}/custom_audiences`);
  }

  async createCustomAudience(audience: CustomAudienceCreate) {
    return this.request('POST', `/accounts/${this.accountId}/custom_audiences`, audience);
  }
}

export default RedditAdsClient;
```

### Python Client

```python
# lib/reddit_ads_client.py
import requests
from typing import Optional, Dict, Any, List
from dataclasses import dataclass

@dataclass
class RedditAdsConfig:
    access_token: str
    account_id: str

class RedditAdsClient:
    BASE_URL = 'https://ads-api.reddit.com/api/v2.0'

    def __init__(self, config: RedditAdsConfig):
        self.access_token = config.access_token
        self.account_id = config.account_id
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json',
            'User-Agent': 'YourApp/1.0.0'
        })

    def _request(
        self,
        method: str,
        endpoint: str,
        json: Optional[Dict] = None
    ) -> Dict[str, Any]:
        url = f"{self.BASE_URL}{endpoint}"
        response = self.session.request(method, url, json=json)
        response.raise_for_status()
        return response.json()

    # Account
    def get_account(self) -> Dict:
        return self._request('GET', f'/accounts/{self.account_id}')

    # Campaigns
    def get_campaigns(self) -> List[Dict]:
        return self._request('GET', f'/accounts/{self.account_id}/campaigns')

    def get_campaign(self, campaign_id: str) -> Dict:
        return self._request('GET', f'/accounts/{self.account_id}/campaigns/{campaign_id}')

    def create_campaign(self, campaign: Dict) -> Dict:
        return self._request('POST', f'/accounts/{self.account_id}/campaigns', json=campaign)

    def update_campaign(self, campaign_id: str, updates: Dict) -> Dict:
        return self._request('PUT', f'/accounts/{self.account_id}/campaigns/{campaign_id}', json=updates)

    # Ad Groups
    def get_ad_groups(self, campaign_id: Optional[str] = None) -> List[Dict]:
        endpoint = (
            f'/accounts/{self.account_id}/campaigns/{campaign_id}/ad_groups'
            if campaign_id
            else f'/accounts/{self.account_id}/ad_groups'
        )
        return self._request('GET', endpoint)

    def create_ad_group(self, ad_group: Dict) -> Dict:
        return self._request('POST', f'/accounts/{self.account_id}/ad_groups', json=ad_group)

    def update_ad_group(self, ad_group_id: str, updates: Dict) -> Dict:
        return self._request('PUT', f'/accounts/{self.account_id}/ad_groups/{ad_group_id}', json=updates)

    # Ads
    def get_ads(self, ad_group_id: Optional[str] = None) -> List[Dict]:
        endpoint = (
            f'/accounts/{self.account_id}/ad_groups/{ad_group_id}/ads'
            if ad_group_id
            else f'/accounts/{self.account_id}/ads'
        )
        return self._request('GET', endpoint)

    def create_ad(self, ad: Dict) -> Dict:
        return self._request('POST', f'/accounts/{self.account_id}/ads', json=ad)

    # Reports
    def get_report(self, report_request: Dict) -> Dict:
        return self._request('POST', f'/accounts/{self.account_id}/reports', json=report_request)

    # Custom Audiences
    def get_custom_audiences(self) -> List[Dict]:
        return self._request('GET', f'/accounts/{self.account_id}/custom_audiences')

    def create_custom_audience(self, audience: Dict) -> Dict:
        return self._request('POST', f'/accounts/{self.account_id}/custom_audiences', json=audience)
```

---

## API Endpoints Reference

### Account Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/accounts/{account_id}` | Get account details |
| GET | `/accounts/{account_id}/funding` | Get funding information |

### Campaign Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/accounts/{account_id}/campaigns` | List all campaigns |
| GET | `/accounts/{account_id}/campaigns/{campaign_id}` | Get campaign by ID |
| POST | `/accounts/{account_id}/campaigns` | Create campaign |
| PUT | `/accounts/{account_id}/campaigns/{campaign_id}` | Update campaign |
| DELETE | `/accounts/{account_id}/campaigns/{campaign_id}` | Delete campaign |

### Ad Group Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/accounts/{account_id}/ad_groups` | List all ad groups |
| GET | `/accounts/{account_id}/ad_groups/{ad_group_id}` | Get ad group by ID |
| POST | `/accounts/{account_id}/ad_groups` | Create ad group |
| PUT | `/accounts/{account_id}/ad_groups/{ad_group_id}` | Update ad group |
| DELETE | `/accounts/{account_id}/ad_groups/{ad_group_id}` | Delete ad group |

### Ad Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/accounts/{account_id}/ads` | List all ads |
| GET | `/accounts/{account_id}/ads/{ad_id}` | Get ad by ID |
| POST | `/accounts/{account_id}/ads` | Create ad |
| PUT | `/accounts/{account_id}/ads/{ad_id}` | Update ad |
| DELETE | `/accounts/{account_id}/ads/{ad_id}` | Delete ad |

### Custom Audience Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/accounts/{account_id}/custom_audiences` | List custom audiences |
| POST | `/accounts/{account_id}/custom_audiences` | Create custom audience |
| PUT | `/accounts/{account_id}/custom_audiences/{audience_id}` | Update audience |
| DELETE | `/accounts/{account_id}/custom_audiences/{audience_id}` | Delete audience |

### Report Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/accounts/{account_id}/reports` | Generate report |

---

## Campaign Creation

### Campaign Objectives

| Objective | Use Case |
|-----------|----------|
| `BRAND_AWARENESS` | Build brand recognition and reach |
| `TRAFFIC` | Drive clicks to website/landing page |
| `CONVERSIONS` | Track and optimize for conversions |
| `VIDEO_VIEWS` | Maximize video view engagement |
| `APP_INSTALLS` | Drive mobile app installations |
| `CATALOG_SALES` | Promote product catalog items |

### Budget Types

| Type | Description |
|------|-------------|
| `DAILY` | Average daily spend (may vary slightly) |
| `LIFETIME` | Total spend over campaign duration |

### Campaign Create Example

```typescript
interface CampaignCreate {
  name: string;
  objective: 'BRAND_AWARENESS' | 'TRAFFIC' | 'CONVERSIONS' | 'VIDEO_VIEWS' | 'APP_INSTALLS';
  is_enabled: boolean;
  budget_type: 'DAILY' | 'LIFETIME';
  budget_total_amount_micros: number; // Amount in micros (1 USD = 1,000,000 micros)
  start_time: string; // ISO 8601 format
  end_time?: string; // ISO 8601 format (optional)
}

// Create a traffic campaign with $50/day budget
const campaign: CampaignCreate = {
  name: 'Q1 2025 Traffic Campaign',
  objective: 'TRAFFIC',
  is_enabled: true,
  budget_type: 'DAILY',
  budget_total_amount_micros: 50_000_000, // $50
  start_time: '2025-01-15T00:00:00Z',
  end_time: '2025-03-31T23:59:59Z'
};

const result = await client.createCampaign(campaign);
```

```python
# Python example
campaign = {
    'name': 'Q1 2025 Traffic Campaign',
    'objective': 'TRAFFIC',
    'is_enabled': True,
    'budget_type': 'DAILY',
    'budget_total_amount_micros': 50_000_000,  # $50
    'start_time': '2025-01-15T00:00:00Z',
    'end_time': '2025-03-31T23:59:59Z'
}

result = client.create_campaign(campaign)
```

---

## Ad Group Creation

### Bidding Strategies

| Strategy | Description | Use Case |
|----------|-------------|----------|
| `LOWEST_COST` | Maximize conversions within budget | Best for most campaigns |
| `COST_CAP` | Set average CPC cap | Control cost per result |
| `MANUAL` | Set strict CPC/CPM bid | Maximum control |

### Targeting Options

| Targeting Type | Description |
|----------------|-------------|
| `communities` | Target specific subreddits |
| `interests` | Target by interest categories |
| `keywords` | Target by keyword engagement |
| `devices` | Target by device type |
| `locations` | Target by geography |
| `custom_audiences` | Target uploaded customer lists |

### Ad Group Create Example

```typescript
interface AdGroupCreate {
  name: string;
  campaign_id: string;
  is_enabled: boolean;
  bid_strategy: 'LOWEST_COST' | 'COST_CAP' | 'MANUAL';
  bid_amount_micros?: number; // For COST_CAP or MANUAL
  goal_type: 'CLICKS' | 'IMPRESSIONS' | 'CONVERSIONS';
  goal_value_micros?: number;
  targeting: {
    communities?: string[]; // Subreddit names without r/
    interests?: string[];
    keywords?: string[];
    geo_locations?: {
      countries?: string[];
      regions?: string[];
      cities?: string[];
    };
    devices?: ('DESKTOP' | 'MOBILE' | 'TABLET')[];
    custom_audience_ids?: string[];
  };
  start_time?: string;
  end_time?: string;
}

// Create ad group targeting specific subreddits
const adGroup: AdGroupCreate = {
  name: 'Tech Enthusiasts - Subreddit Targeting',
  campaign_id: 'campaign_123',
  is_enabled: true,
  bid_strategy: 'LOWEST_COST',
  goal_type: 'CLICKS',
  targeting: {
    communities: [
      'technology',
      'gadgets',
      'programming',
      'webdev',
      'startups'
    ],
    geo_locations: {
      countries: ['US', 'CA', 'GB']
    },
    devices: ['DESKTOP', 'MOBILE']
  },
  start_time: '2025-01-15T00:00:00Z'
};

const result = await client.createAdGroup(adGroup);
```

```python
# Python example
ad_group = {
    'name': 'Tech Enthusiasts - Subreddit Targeting',
    'campaign_id': 'campaign_123',
    'is_enabled': True,
    'bid_strategy': 'LOWEST_COST',
    'goal_type': 'CLICKS',
    'targeting': {
        'communities': [
            'technology',
            'gadgets',
            'programming',
            'webdev',
            'startups'
        ],
        'geo_locations': {
            'countries': ['US', 'CA', 'GB']
        },
        'devices': ['DESKTOP', 'MOBILE']
    },
    'start_time': '2025-01-15T00:00:00Z'
}

result = client.create_ad_group(ad_group)
```

---

## Ad Creation

### Ad Types

| Type | Description |
|------|-------------|
| `LINK` | Link ad with image/video |
| `TEXT` | Text-only promoted post |
| `VIDEO` | Video ad |
| `CAROUSEL` | Multiple images/cards |
| `PRODUCT` | Product catalog ad |

### Call-to-Action Options

| CTA | Use Case |
|-----|----------|
| `SHOP_NOW` | E-commerce |
| `SIGN_UP` | Lead generation |
| `LEARN_MORE` | Information |
| `DOWNLOAD` | App/content download |
| `INSTALL` | App install |
| `GET_QUOTE` | Services |
| `CONTACT_US` | B2B/Services |
| `APPLY_NOW` | Jobs/Finance |
| `BOOK_NOW` | Travel/Services |
| `WATCH_NOW` | Video content |
| `SUBSCRIBE` | Newsletters/SaaS |
| `GET_OFFER` | Promotions |
| `SEE_MENU` | Restaurants |

### Ad Create Example

```typescript
interface AdCreate {
  name: string;
  ad_group_id: string;
  is_enabled: boolean;
  type: 'LINK' | 'TEXT' | 'VIDEO' | 'CAROUSEL';
  headline: string; // Max 300 characters
  body?: string;
  url: string;
  display_url?: string;
  call_to_action: string;
  thumbnail_url?: string; // For image/video ads
  video_url?: string; // For video ads
}

// Create a link ad
const ad: AdCreate = {
  name: 'Product Launch Ad - v1',
  ad_group_id: 'ad_group_456',
  is_enabled: true,
  type: 'LINK',
  headline: 'Introducing Our Revolutionary New Product',
  body: 'Discover how our latest innovation can transform your workflow. Join 10,000+ satisfied customers.',
  url: 'https://yoursite.com/product?utm_source=reddit&utm_medium=paid',
  display_url: 'yoursite.com/product',
  call_to_action: 'LEARN_MORE',
  thumbnail_url: 'https://yoursite.com/images/ad-creative.jpg'
};

const result = await client.createAd(ad);
```

```python
# Python example
ad = {
    'name': 'Product Launch Ad - v1',
    'ad_group_id': 'ad_group_456',
    'is_enabled': True,
    'type': 'LINK',
    'headline': 'Introducing Our Revolutionary New Product',
    'body': 'Discover how our latest innovation can transform your workflow. Join 10,000+ satisfied customers.',
    'url': 'https://yoursite.com/product?utm_source=reddit&utm_medium=paid',
    'display_url': 'yoursite.com/product',
    'call_to_action': 'LEARN_MORE',
    'thumbnail_url': 'https://yoursite.com/images/ad-creative.jpg'
}

result = client.create_ad(ad)
```

---

## Conversions API

### Event Types

| Event Type | Description |
|------------|-------------|
| `PAGE_VISIT` | Page view |
| `VIEW_CONTENT` | Product/content view |
| `SEARCH` | Search action |
| `ADD_TO_CART` | Add to cart |
| `ADD_TO_WISHLIST` | Add to wishlist |
| `PURCHASE` | Completed purchase |
| `LEAD` | Lead submission |
| `SIGN_UP` | Account creation |
| `CUSTOM` | Custom event |

### Conversion Event Structure

```typescript
interface ConversionEvent {
  event_at: number; // Unix timestamp in milliseconds
  event_type: {
    tracking_type: string;
    custom_event_name?: string; // For CUSTOM type
  };
  user: {
    email?: string; // SHA256 hashed, lowercase
    phone_number?: string; // SHA256 hashed, E.164 format
    external_id?: string;
    ip_address?: string;
    user_agent?: string;
    aaid?: string; // Android Advertising ID
    idfa?: string; // iOS IDFA
  };
  event_metadata?: {
    item_count?: number;
    value_decimal?: number;
    currency?: string;
    conversion_id: string; // Unique event ID
    products?: Array<{
      id: string;
      name?: string;
      category?: string;
    }>;
  };
  click_id?: string; // Reddit click ID for attribution
}
```

### Send Conversion Events

```typescript
import crypto from 'crypto';

function hashPII(value: string): string {
  return crypto
    .createHash('sha256')
    .update(value.toLowerCase().trim())
    .digest('hex');
}

async function sendConversionEvent(
  accessToken: string,
  pixelId: string,
  event: ConversionEvent
) {
  const response = await fetch(
    `https://ads-api.reddit.com/api/v2.0/conversions/events/${pixelId}`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        events: [event],
        test_mode: false // Set true for testing
      })
    }
  );

  return response.json();
}

// Example: Track a purchase
const purchaseEvent: ConversionEvent = {
  event_at: Date.now(),
  event_type: {
    tracking_type: 'PURCHASE'
  },
  user: {
    email: hashPII('customer@example.com'),
    ip_address: '192.168.1.1',
    user_agent: 'Mozilla/5.0...'
  },
  event_metadata: {
    conversion_id: 'order_12345',
    value_decimal: 99.99,
    currency: 'USD',
    item_count: 2,
    products: [
      { id: 'SKU001', name: 'Product A', category: 'Electronics' },
      { id: 'SKU002', name: 'Product B', category: 'Electronics' }
    ]
  },
  click_id: 'reddit_click_id_from_url' // From rdt_cid parameter
};

await sendConversionEvent(accessToken, 'pixel_123', purchaseEvent);
```

```python
import hashlib
import time
import requests

def hash_pii(value: str) -> str:
    """SHA256 hash PII data."""
    return hashlib.sha256(value.lower().strip().encode()).hexdigest()

def send_conversion_event(
    access_token: str,
    pixel_id: str,
    events: list[dict],
    test_mode: bool = False
) -> dict:
    """Send conversion events to Reddit."""
    response = requests.post(
        f'https://ads-api.reddit.com/api/v2.0/conversions/events/{pixel_id}',
        headers={
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        },
        json={
            'events': events,
            'test_mode': test_mode
        }
    )
    response.raise_for_status()
    return response.json()

# Example: Track a purchase
purchase_event = {
    'event_at': int(time.time() * 1000),
    'event_type': {
        'tracking_type': 'PURCHASE'
    },
    'user': {
        'email': hash_pii('customer@example.com'),
        'ip_address': '192.168.1.1',
        'user_agent': 'Mozilla/5.0...'
    },
    'event_metadata': {
        'conversion_id': 'order_12345',
        'value_decimal': 99.99,
        'currency': 'USD',
        'item_count': 2,
        'products': [
            {'id': 'SKU001', 'name': 'Product A', 'category': 'Electronics'},
            {'id': 'SKU002', 'name': 'Product B', 'category': 'Electronics'}
        ]
    },
    'click_id': 'reddit_click_id_from_url'
}

result = send_conversion_event(access_token, 'pixel_123', [purchase_event])
```

### Important Notes

- Events must occur within **last 7 days** to be processed
- Maximum **500 events per batch** request
- Include `click_id` when available for better attribution
- Use `test_mode: true` for testing without affecting campaigns

---

## Custom Audiences

### Audience Types

| Type | Description |
|------|-------------|
| `CUSTOMER_LIST` | Upload hashed emails/phone/MAIDs |
| `WEBSITE_VISITORS` | Pixel-based retargeting |
| `LOOKALIKE` | Similar to source audience |

### Create Customer List Audience

```typescript
interface CustomAudienceCreate {
  name: string;
  type: 'CUSTOMER_LIST';
  description?: string;
  users: Array<{
    email_sha256?: string;
    maid_sha256?: string; // Mobile Advertising ID
  }>;
}

// Create audience from customer emails
const audience: CustomAudienceCreate = {
  name: 'High Value Customers Q4 2024',
  type: 'CUSTOMER_LIST',
  description: 'Customers with LTV > $500',
  users: customerEmails.map(email => ({
    email_sha256: hashPII(email)
  }))
};

const result = await client.createCustomAudience(audience);
```

### Minimum Audience Size

- **1,000 matched users** minimum to be usable for targeting
- Match rates displayed as ranges for privacy

---

## Reporting

### Report Request

```typescript
interface ReportRequest {
  start_date: string; // YYYY-MM-DD
  end_date: string; // YYYY-MM-DD
  level: 'ACCOUNT' | 'CAMPAIGN' | 'AD_GROUP' | 'AD';
  metrics: string[];
  dimensions?: string[];
  filters?: {
    campaign_ids?: string[];
    ad_group_ids?: string[];
  };
}

// Get campaign performance report
const report = await client.getReport({
  start_date: '2025-01-01',
  end_date: '2025-01-31',
  level: 'CAMPAIGN',
  metrics: [
    'impressions',
    'clicks',
    'spend',
    'ctr',
    'cpc',
    'conversions',
    'conversion_rate',
    'cpa'
  ],
  dimensions: ['date']
});
```

### Available Metrics

| Metric | Description |
|--------|-------------|
| `impressions` | Total impressions |
| `clicks` | Total clicks |
| `spend` | Total spend (in account currency) |
| `ctr` | Click-through rate |
| `cpc` | Cost per click |
| `cpm` | Cost per 1,000 impressions |
| `conversions` | Total conversions |
| `conversion_rate` | Conversions / Clicks |
| `cpa` | Cost per acquisition |
| `video_views` | Video view count |
| `video_completions` | Videos watched to completion |

---

## Environment Variables

```bash
# .env
REDDIT_ADS_CLIENT_ID=your_client_id
REDDIT_ADS_CLIENT_SECRET=your_client_secret
REDDIT_ADS_ACCOUNT_ID=t2_xxxxx
REDDIT_ADS_ACCESS_TOKEN=your_access_token
REDDIT_ADS_REFRESH_TOKEN=your_refresh_token
REDDIT_ADS_PIXEL_ID=your_pixel_id
```

---

## Best Practices

### Campaign Structure

```
┌─────────────────────────────────────────────────────────────────┐
│  RECOMMENDED STRUCTURE                                          │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Campaign (by objective/product line)                           │
│  ├── Ad Group: Subreddit Targeting - Tech                      │
│  │   ├── Ad: Headline A + Image 1                              │
│  │   └── Ad: Headline B + Image 1                              │
│  ├── Ad Group: Subreddit Targeting - Business                  │
│  │   ├── Ad: Headline A + Image 1                              │
│  │   └── Ad: Headline B + Image 1                              │
│  └── Ad Group: Interest Targeting - Entrepreneurs              │
│      ├── Ad: Headline A + Image 2                              │
│      └── Ad: Headline B + Image 2                              │
│                                                                 │
│  • Separate ad groups by targeting type                         │
│  • Test 2-3 ad variations per ad group                          │
│  • Use clear naming conventions                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Naming Conventions

```
Campaign:  [Objective] - [Product/Brand] - [Date Range]
           Example: TRAFFIC - ProductX - Q1-2025

Ad Group:  [Targeting Type] - [Audience Description]
           Example: Subreddits - Tech Enthusiasts

Ad:        [Headline Type] - [Creative Version]
           Example: Problem-Solution - Image-A
```

### Rate Limiting

- **1 request per second** limit
- Implement exponential backoff for retries
- Batch operations where possible

```typescript
async function rateLimitedRequest<T>(
  fn: () => Promise<T>,
  retries = 3
): Promise<T> {
  for (let i = 0; i < retries; i++) {
    try {
      await new Promise(resolve => setTimeout(resolve, 1000)); // 1 second delay
      return await fn();
    } catch (error: any) {
      if (error.status === 429 && i < retries - 1) {
        const delay = Math.pow(2, i) * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw error;
    }
  }
  throw new Error('Max retries exceeded');
}
```

---

## Complete Workflow Example

```typescript
// Full campaign creation workflow
async function createRedditAdCampaign(
  client: RedditAdsClient,
  config: {
    campaignName: string;
    dailyBudget: number;
    targetSubreddits: string[];
    headline: string;
    body: string;
    landingUrl: string;
    imageUrl: string;
  }
) {
  // 1. Create Campaign
  const campaign = await client.createCampaign({
    name: config.campaignName,
    objective: 'TRAFFIC',
    is_enabled: false, // Start paused for review
    budget_type: 'DAILY',
    budget_total_amount_micros: config.dailyBudget * 1_000_000,
    start_time: new Date().toISOString()
  });

  console.log(`Created campaign: ${campaign.id}`);

  // 2. Create Ad Group with targeting
  const adGroup = await client.createAdGroup({
    name: `${config.campaignName} - Subreddit Targeting`,
    campaign_id: campaign.id,
    is_enabled: true,
    bid_strategy: 'LOWEST_COST',
    goal_type: 'CLICKS',
    targeting: {
      communities: config.targetSubreddits,
      geo_locations: { countries: ['US'] },
      devices: ['DESKTOP', 'MOBILE']
    }
  });

  console.log(`Created ad group: ${adGroup.id}`);

  // 3. Create Ad
  const ad = await client.createAd({
    name: `${config.campaignName} - Ad v1`,
    ad_group_id: adGroup.id,
    is_enabled: true,
    type: 'LINK',
    headline: config.headline,
    body: config.body,
    url: config.landingUrl,
    call_to_action: 'LEARN_MORE',
    thumbnail_url: config.imageUrl
  });

  console.log(`Created ad: ${ad.id}`);

  return { campaign, adGroup, ad };
}

// Usage
const result = await createRedditAdCampaign(client, {
  campaignName: 'Product Launch - Jan 2025',
  dailyBudget: 50, // $50/day
  targetSubreddits: ['technology', 'gadgets', 'programming'],
  headline: 'Introducing the Future of Development',
  body: 'Join 50,000+ developers using our tool to ship faster.',
  landingUrl: 'https://yoursite.com?utm_source=reddit',
  imageUrl: 'https://yoursite.com/ad-image.jpg'
});
```

---

## Testing

### Test Checklist

- [ ] OAuth flow completes successfully
- [ ] Token refresh works before expiry
- [ ] Campaign creates with correct budget
- [ ] Ad group targeting is applied correctly
- [ ] Ad creative displays properly
- [ ] Conversion events tracked (use test_mode)
- [ ] Reports return expected metrics
- [ ] Rate limiting handled gracefully
- [ ] Error responses handled properly

### Mock API for Development

```typescript
// test/mocks/reddit-ads-mock.ts
import { rest } from 'msw';

export const redditAdsMocks = [
  rest.post('https://www.reddit.com/api/v1/access_token', (req, res, ctx) => {
    return res(ctx.json({
      access_token: 'mock_access_token',
      refresh_token: 'mock_refresh_token',
      expires_in: 3600,
      scope: 'adsread adsedit history'
    }));
  }),

  rest.get('https://ads-api.reddit.com/api/v2.0/accounts/:accountId', (req, res, ctx) => {
    return res(ctx.json({
      id: req.params.accountId,
      name: 'Test Account',
      currency: 'USD'
    }));
  }),

  rest.post('https://ads-api.reddit.com/api/v2.0/accounts/:accountId/campaigns', (req, res, ctx) => {
    return res(ctx.json({
      id: 'campaign_mock_123',
      ...req.body
    }));
  })
];
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `401 Unauthorized` | Invalid/expired token | Refresh access token |
| `403 Forbidden` | Account not whitelisted | Contact Reddit Ads support |
| `429 Too Many Requests` | Rate limit exceeded | Implement backoff, slow down |
| `400 Bad Request` | Invalid payload | Check required fields, data types |
| `Audience too small` | < 1,000 matched users | Add more users to audience |

---

## Resources

- [Reddit Ads API Docs](https://ads-api.reddit.com/docs/)
- [Reddit Developer Portal](https://www.reddit.com/prefs/apps/)
- [Reddit Ads Help Center](https://business.reddithelp.com/s/article/Reddit-Ads-API)
- [OAuth2 Documentation](https://www.reddit.com/dev/api/oauth/)
