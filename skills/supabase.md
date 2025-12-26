# Supabase Skill

*Load with: base.md + typescript.md*

For projects using Supabase as the backend (database, auth, storage, edge functions).

**Sources:** [Supabase Local Development](https://supabase.com/docs/guides/local-development/overview) | [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) | [Drizzle + Supabase](https://supabase.com/docs/guides/database/drizzle)

---

## Core Principle

**Local-first, migrations in version control, type-safe queries.**

Develop locally with the Supabase CLI, capture all changes as migrations, and use Drizzle ORM for type-safe database access. Never make direct changes to production.

---

## Recommended Stack

| Layer | Tool | Why |
|-------|------|-----|
| Local Dev | Supabase CLI | Full local stack, Studio dashboard |
| Schema | Drizzle ORM | Type-safe, SQL-like, good DX |
| Migrations | Drizzle Kit | Better control than `db diff` |
| Queries | Drizzle | Type-safe, composable |
| Auth | Supabase Auth | Native, RLS integration |
| Storage | Supabase Storage | Native, RLS integration |
| Realtime | Supabase Realtime | Native, simple API |
| Edge Functions | Supabase Functions | Deno, globally distributed |

---

## Project Structure

```
project/
├── supabase/
│   ├── config.toml           # Supabase local config
│   ├── seed.sql              # Seed data for local dev
│   ├── migrations/           # SQL migrations (Drizzle-generated)
│   │   └── 0001_initial.sql
│   └── functions/            # Edge Functions
│       └── hello/
│           └── index.ts
├── src/
│   ├── db/
│   │   ├── index.ts          # Drizzle client
│   │   ├── schema.ts         # Drizzle schema definitions
│   │   └── queries/          # Query functions
│   │       ├── users.ts
│   │       └── posts.ts
│   └── lib/
│       └── supabase.ts       # Supabase client (auth, storage)
├── drizzle.config.ts         # Drizzle Kit config
└── .env.local                # Local environment variables
```

---

## Initial Setup

### 1. Install CLI & Login
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login
supabase login

# Initialize in project
supabase init
```

### 2. Link to Remote Project
```bash
# Get project ref from Supabase dashboard
supabase link --project-ref <project-id>

# Pull existing schema (if any)
supabase db pull
```

### 3. Start Local Stack
```bash
# Start local Supabase (Postgres, Auth, Storage, etc.)
supabase start

# Output includes local URLs and keys:
# API URL: http://localhost:54321
# DB URL: postgresql://postgres:postgres@localhost:54322/postgres
# Studio: http://localhost:54323
# Anon Key: eyJ...
# Service Role Key: eyJ...
```

### 4. Install Drizzle
```bash
npm install drizzle-orm postgres
npm install -D drizzle-kit
```

---

## Drizzle Configuration

### drizzle.config.ts
```typescript
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './supabase/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  // Important: don't touch Supabase system schemas
  schemaFilter: ['public'],
  verbose: true,
  strict: true,
});
```

### src/db/index.ts (Drizzle Client)
```typescript
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

// Use connection pooling URL from Supabase
// For Transaction mode, disable prepare
const client = postgres(process.env.DATABASE_URL!, {
  prepare: false, // Required for Supabase connection pooling
});

export const db = drizzle(client, { schema });
```

### src/db/schema.ts
```typescript
import {
  pgTable,
  uuid,
  text,
  timestamp,
  boolean,
} from 'drizzle-orm/pg-core';

// Reference Supabase auth.users
export const profiles = pgTable('profiles', {
  id: uuid('id').primaryKey().references(() => authUsers.id),
  username: text('username').notNull().unique(),
  avatarUrl: text('avatar_url'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const posts = pgTable('posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  authorId: uuid('author_id').references(() => profiles.id).notNull(),
  title: text('title').notNull(),
  content: text('content'),
  published: boolean('published').default(false),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// For referencing auth.users (read-only)
export const authUsers = pgTable('users', {
  id: uuid('id').primaryKey(),
}, (table) => ({
  // This is in the auth schema
}));
```

---

## Migration Workflow

### Creating Migrations
```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Review the generated SQL in supabase/migrations/
# IMPORTANT: Review before applying!

# Apply to local database
npx drizzle-kit push
# OR
supabase db reset  # Resets and applies all migrations + seed
```

### Migration Commands
```bash
# Generate new migration
npx drizzle-kit generate

# Push schema to local DB (no migration file)
npx drizzle-kit push

# Apply migrations to local
supabase migration up

# Reset local DB (applies all migrations + seed.sql)
supabase db reset

# Diff local vs remote (use sparingly)
supabase db diff --schema public

# Push migrations to remote
supabase db push
```

### Seed Data
```sql
-- supabase/seed.sql
-- Runs after migrations on `supabase db reset`

-- Insert test users (profiles)
INSERT INTO profiles (id, username, avatar_url)
VALUES
  ('d0e1f2a3-b4c5-6d7e-8f9a-0b1c2d3e4f5a', 'testuser', null),
  ('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'admin', null)
ON CONFLICT (id) DO NOTHING;

-- Insert test posts
INSERT INTO posts (author_id, title, content, published)
VALUES
  ('d0e1f2a3-b4c5-6d7e-8f9a-0b1c2d3e4f5a', 'First Post', 'Hello world', true)
ON CONFLICT DO NOTHING;
```

---

## Supabase Client (Auth & Storage)

### src/lib/supabase.ts
```typescript
import { createClient } from '@supabase/supabase-js';

// For client-side (browser)
export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// For server-side with service role (admin access)
export const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);
```

### Using Both Clients
```typescript
// Use Supabase for auth
const { data: { user } } = await supabase.auth.getUser();

// Use Drizzle for database queries (type-safe)
import { db } from '@/db';
import { profiles, posts } from '@/db/schema';
import { eq } from 'drizzle-orm';

const userPosts = await db
  .select()
  .from(posts)
  .where(eq(posts.authorId, user.id));
```

---

## Row Level Security (RLS)

### Enable RLS in Migration
```sql
-- In your migration file
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read all profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- Policy: Users can update own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Users can read published posts
CREATE POLICY "Published posts are viewable by everyone"
  ON posts FOR SELECT
  USING (published = true);

-- Policy: Authors can CRUD own posts
CREATE POLICY "Authors can manage own posts"
  ON posts FOR ALL
  USING (auth.uid() = author_id);
```

### RLS with Drizzle
```typescript
// Drizzle respects RLS when using the anon/authenticated role
// For admin operations, use service role client

// Client-side: RLS applies automatically
const posts = await db.select().from(postsTable);

// Server-side with service role: bypasses RLS
// Use supabaseAdmin for admin operations
```

---

## Environment Variables

### .env.local (Local Development)
```bash
# Supabase - Local (from `supabase start` output)
NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...local-anon-key

# Server-side only (NEVER expose these)
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_ROLE_KEY=eyJ...local-service-role-key

# Database - Direct connection for Drizzle
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
```

### .env.production (Production)
```bash
# Supabase - Production (from Supabase dashboard)
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Server-side only
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Database - Use connection pooling URL
DATABASE_URL=postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true
```

---

## Edge Functions

### Create Function
```bash
supabase functions new hello
```

### supabase/functions/hello/index.ts
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    // Create Supabase client with auth context
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    );

    // Get user from JWT
    const { data: { user } } = await supabase.auth.getUser();

    return new Response(
      JSON.stringify({ message: 'Hello', user: user?.email }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

### Deploy Function
```bash
# Serve locally
supabase functions serve hello --env-file .env.local

# Deploy to production
supabase functions deploy hello
```

---

## Type Generation

### From Database (Supabase CLI)
```bash
# Generate TypeScript types from database schema
supabase gen types typescript --local > src/types/database.ts

# Or from remote
supabase gen types typescript --project-id <ref> > src/types/database.ts
```

### From Drizzle Schema (Preferred)
```typescript
// Types are inferred from Drizzle schema
import { profiles, posts } from '@/db/schema';
import { InferSelectModel, InferInsertModel } from 'drizzle-orm';

export type Profile = InferSelectModel<typeof profiles>;
export type NewProfile = InferInsertModel<typeof profiles>;
export type Post = InferSelectModel<typeof posts>;
export type NewPost = InferInsertModel<typeof posts>;
```

---

## Common Patterns

### Query Functions
```typescript
// src/db/queries/posts.ts
import { db } from '@/db';
import { posts, profiles } from '@/db/schema';
import { eq, desc, and } from 'drizzle-orm';

export async function getPublishedPosts(limit = 10) {
  return db
    .select({
      id: posts.id,
      title: posts.title,
      content: posts.content,
      author: profiles.username,
      createdAt: posts.createdAt,
    })
    .from(posts)
    .innerJoin(profiles, eq(posts.authorId, profiles.id))
    .where(eq(posts.published, true))
    .orderBy(desc(posts.createdAt))
    .limit(limit);
}

export async function getUserPosts(userId: string) {
  return db
    .select()
    .from(posts)
    .where(eq(posts.authorId, userId))
    .orderBy(desc(posts.createdAt));
}

export async function createPost(data: NewPost) {
  const [post] = await db.insert(posts).values(data).returning();
  return post;
}
```

### Auth Helpers (Next.js)
```typescript
// src/lib/auth.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function getServerSupabase() {
  const cookieStore = cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options) {
          cookieStore.set({ name, value, ...options });
        },
        remove(name: string, options) {
          cookieStore.delete({ name, ...options });
        },
      },
    }
  );
}

export async function getUser() {
  const supabase = await getServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

export async function requireAuth() {
  const user = await getUser();
  if (!user) {
    throw new Error('Unauthorized');
  }
  return user;
}
```

---

## CI/CD Workflow

### GitHub Actions
```yaml
# .github/workflows/supabase.yml
name: Supabase CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
  SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_DB_PASSWORD }}
  SUPABASE_PROJECT_ID: ${{ secrets.SUPABASE_PROJECT_ID }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Start Supabase
        run: supabase start

      - name: Run migrations
        run: supabase db reset

      - name: Run tests
        run: npm test

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Link project
        run: supabase link --project-ref $SUPABASE_PROJECT_ID

      - name: Push migrations
        run: supabase db push

      - name: Deploy functions
        run: supabase functions deploy
```

---

## CLI Quick Reference

```bash
# Project
supabase init                    # Initialize project
supabase start                   # Start local stack
supabase stop                    # Stop local stack
supabase status                  # Show local stack status

# Database
supabase db reset                # Reset local DB + apply migrations + seed
supabase db push                 # Push migrations to remote
supabase db pull                 # Pull remote schema
supabase db diff                 # Diff local vs remote
supabase db lint                 # Lint for schema errors

# Migrations
supabase migration new <name>    # Create empty migration
supabase migration list          # List migrations
supabase migration up            # Apply pending migrations

# Types
supabase gen types typescript --local  # Generate types from local

# Functions
supabase functions new <name>    # Create new function
supabase functions serve         # Serve functions locally
supabase functions deploy        # Deploy all functions

# Link & Auth
supabase login                   # Login to Supabase
supabase link --project-ref <id> # Link to remote project
```

---

## Anti-Patterns

- **Making changes directly in production** - Always use migrations
- **Using `db diff` as primary migration tool** - Use Drizzle Kit instead
- **Storing service role key client-side** - Never expose in browser
- **Ignoring RLS** - Enable on all tables with user data
- **Connection without pooling** - Use pooled connection string
- **Committing .env files** - Add to .gitignore
- **Mixing Supabase client and Drizzle for queries** - Pick one (Drizzle recommended)
- **Not seeding local data** - Use seed.sql for consistent dev experience
- **Deploying untested migrations** - Always test locally first
- **Not reviewing generated migrations** - Review SQL before applying
