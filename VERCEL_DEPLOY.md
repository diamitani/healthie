# Vercel Cloud Deployment from GitHub

**Direct GitHub Integration - No CLI Required**

## Quick Deploy (5 minutes)

### Step 1: Go to Vercel

Visit: **https://vercel.com/new**

### Step 2: Import GitHub Repository

1. Click **"Add New Project"**
2. Select **"Import Git Repository"**
3. Authorize Vercel to access your GitHub account (if first time)
4. Find and select: **`diamitani/healthie`**
5. Click **"Import"**

### Step 3: Configure Project

**Project Settings:**
- **Framework Preset**: Other (we're using static HTML)
- **Root Directory**: `./` (leave as default)
- **Build Command**: Leave empty or `echo "Static site"`
- **Output Directory**: `web`
- **Install Command**: Leave empty

**Environment Variables** (Optional - add later after AWS deployment):
```
NEXT_PUBLIC_API_URL = https://your-api-gateway-url
NEXT_PUBLIC_COGNITO_USER_POOL_ID = your-pool-id
NEXT_PUBLIC_COGNITO_CLIENT_ID = your-client-id
NEXT_PUBLIC_AWS_REGION = us-east-1
```

### Step 4: Deploy

1. Click **"Deploy"**
2. Wait 30-60 seconds
3. Done! ✅

Your site will be live at: **`https://healthie.vercel.app`**

---

## Automatic Deployments

Every time you push to GitHub:
- **`main` branch** → Production deployment (`healthie.vercel.app`)
- **Other branches** → Preview deployments (unique URLs)

No manual deployment needed!

---

## Add Custom Domain (Optional)

### In Vercel Dashboard:

1. Go to your project: https://vercel.com/dashboard
2. Select **healthie** project
3. Go to **Settings** → **Domains**
4. Click **"Add Domain"**
5. Enter: `healthie.diamitani.com`
6. Click **"Add"**

### Configure DNS:

Vercel will show you DNS records to add. Go to your domain registrar (e.g., Namecheap, Cloudflare, Route53):

**Option A - CNAME (Recommended):**
```
CNAME   healthie   cname.vercel-dns.com
```

**Option B - A Record:**
```
A       healthie   76.76.21.21
```

Wait 5-10 minutes for DNS propagation.

---

## Environment Variables (After AWS Deployment)

### Step 1: Deploy AWS Infrastructure First

```bash
cd /Users/patmini/healthie
./infrastructure/scripts/setup-infrastructure.sh
```

### Step 2: Get AWS Outputs

```bash
cd infrastructure/terraform

# Get API Gateway URL
terraform output -raw api_gateway_url

# Get Cognito details
terraform output -raw cognito_user_pool_id
terraform output -raw cognito_user_pool_client_id
```

### Step 3: Add to Vercel

1. Go to Vercel Dashboard
2. Select **healthie** project
3. Go to **Settings** → **Environment Variables**
4. Add each variable:

| Variable | Value | Environment |
|----------|-------|-------------|
| `NEXT_PUBLIC_API_URL` | (from terraform output) | Production |
| `NEXT_PUBLIC_COGNITO_USER_POOL_ID` | (from terraform output) | Production |
| `NEXT_PUBLIC_COGNITO_CLIENT_ID` | (from terraform output) | Production |
| `NEXT_PUBLIC_AWS_REGION` | `us-east-1` | Production |

5. Click **"Redeploy"** to apply new environment variables

---

## Deployment Architecture

```
GitHub (diamitani/healthie)
    ↓ (push to main)
Vercel (automatic build)
    ↓
Production Site (healthie.vercel.app)
    ↓ (API calls)
AWS API Gateway
    ↓
Lambda Functions
    ↓
RDS + S3
```

---

## Monitoring Deployments

### Vercel Dashboard:
- **Live**: https://vercel.com/dashboard
- **Deployments**: See all builds and preview URLs
- **Analytics**: Traffic and performance metrics
- **Logs**: Real-time deployment logs

### Git Integration:
- ✅ Every commit shows deployment status
- ✅ PR comments show preview URLs
- ✅ Build errors appear in GitHub checks

---

## Troubleshooting

### Build Fails
- Check **Deployments** tab in Vercel
- Click on failed deployment → View logs
- Usually: missing files or incorrect paths

### Site Loads but API Calls Fail
- Check environment variables are set
- Verify API Gateway URL is correct
- Check CORS settings in AWS

### Custom Domain Not Working
- Wait 10 minutes for DNS propagation
- Use `dig healthie.diamitani.com` to verify DNS
- Check SSL certificate status in Vercel

---

## Quick Links

- **Vercel Dashboard**: https://vercel.com/dashboard
- **GitHub Repo**: https://github.com/diamitani/healthie
- **Deployment URL**: https://healthie.vercel.app (after deploy)
- **Docs**: https://vercel.com/docs

---

## One-Click Deploy Button (Optional)

Add this to your README for easy deploys:

```markdown
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fdiamitani%2Fhealthie)
```

---

**That's it!** Your Healthie landing page will be live on Vercel with automatic deployments from GitHub. 🚀

**Next**: Deploy AWS backend infrastructure and connect the two systems.
