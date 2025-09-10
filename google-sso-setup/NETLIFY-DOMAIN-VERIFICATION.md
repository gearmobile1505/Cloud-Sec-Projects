# 🔐 Netlify Domain Verification for Wix

## ✅ Current Status: Netlify Verification Required

Netlify has provided you with a verification TXT record to prove domain ownership:

```
Host: netlify-challenge
Value: 4a9b868840531923ad9d698a6c65bd4a
```

---

## 🚀 Step-by-Step Verification Process

### Step 1: Add TXT Record in Wix DNS
1. **Log into your Wix Dashboard**
2. **Navigate to:** Domains → Manage → DNS Records
3. **Click:** "Add Record" or "+" button
4. **Select:** TXT Record type
5. **Fill in:**
   - **Host/Name:** `netlify-challenge`
   - **Value:** `4a9b868840531923ad9d698a6c65bd4a`
   - **TTL:** 3600 (or leave default)
6. **Save the record**

### Step 2: Wait for DNS Propagation (5-30 minutes)
- TXT records usually propagate quickly
- Can take up to 24 hours in some cases

### Step 3: Verify in Netlify
1. **Return to Netlify dashboard**
2. **Click:** "Verify DNS configuration" or refresh
3. **Netlify will check** for the TXT record
4. **Once verified,** you can proceed with CNAME setup

---

## 📋 Complete DNS Records You'll Need

After verification, you'll have these DNS records in Wix:

### Record 1: Domain Verification (TXT)
```
Type: TXT
Host: netlify-challenge
Value: 4a9b868840531923ad9d698a6c65bd4a
```

### Record 2: Subdomain Routing (CNAME) - Add After Verification
```
Type: CNAME
Host: sso
Value: [your-netlify-site].netlify.app
```

---

## 🔍 Wix DNS Interface Guide

### Finding DNS Records in Wix:
1. **Main Dashboard** → Domains
2. **Select your domain:** inellasrestorationcenter.org
3. **Look for:** "DNS" or "Advanced DNS" or "DNS Records"
4. **Common locations:**
   - Domains → Manage → DNS
   - Domains → Advanced → DNS Records
   - Domain Settings → DNS Management

### Adding TXT Record:
- **Record Type:** Select "TXT" from dropdown
- **Host Field:** Enter `netlify-challenge` exactly
- **Value Field:** Enter `4a9b868840531923ad9d698a6c65bd4a` exactly
- **TTL:** Use default or 3600 seconds

---

## ⚠️ Common Issues & Solutions

### "Can't find DNS settings in Wix"
- **Solution:** Look under "Advanced Settings" or "Developer Tools"
- **Alternative:** Contact Wix support for DNS access
- **Fallback:** Consider Cloudflare DNS transfer

### "TXT record not saving"
- **Check:** Field formatting (no extra spaces)
- **Verify:** You have DNS editing permissions
- **Try:** Different browser or clear cache

### "Netlify still says not verified"
- **Wait longer:** DNS can take up to 24 hours
- **Check online:** Use DNS checker tools
- **Verify:** Record was saved correctly in Wix

---

## 🛠️ Verification Commands (Optional)

You can check if the TXT record is working using these commands:

### Mac/Linux Terminal:
```bash
dig TXT netlify-challenge.inellasrestorationcenter.org
```

### Online DNS Checker:
- https://toolbox.googleapps.com/apps/dig/
- Search for: `netlify-challenge.inellasrestorationcenter.org`
- Type: TXT

---

## 📧 Alternative: Contact Wix Support

If you can't find DNS settings, contact Wix with this message:

```
Subject: Need to Add TXT Record for Domain Verification

Hi Wix Support,

I need to add a TXT record to my domain inellasrestorationcenter.org for domain verification with a third-party service.

Record details:
- Type: TXT
- Host: netlify-challenge  
- Value: 4a9b868840531923ad9d698a6c65bd4a

Can you help me add this record or provide access to DNS management?

Thanks!
```

---

## 🎯 What Happens After Verification

Once Netlify verifies domain ownership:

1. ✅ **Domain verified** - Netlify confirms you own the domain
2. 🔄 **CNAME setup** - Add the subdomain routing record
3. 🌐 **SSL certificate** - Netlify automatically provisions HTTPS
4. 🚀 **Go live** - `sso.inellasrestorationcenter.org` works

---

## 📱 Quick Reference Card

**Copy this for easy reference:**

```
=== NETLIFY VERIFICATION ===
Host: netlify-challenge
Value: 4a9b868840531923ad9d698a6c65bd4a

=== WHERE TO ADD IN WIX ===
Domains → Manage → DNS Records → Add TXT Record

=== AFTER VERIFICATION ===
Add CNAME: sso → [your-netlify-site].netlify.app
```

---

## ⏱️ Expected Timeline

| Step | Time | Description |
|------|------|-------------|
| Add TXT record | 2 min | Copy/paste in Wix DNS |
| DNS propagation | 5-30 min | Record spreads globally |
| Netlify verification | 1 min | Netlify checks and confirms |
| Add CNAME record | 2 min | Route subdomain to Netlify |
| CNAME propagation | 15-60 min | Subdomain becomes active |
| SSL certificate | 10-30 min | HTTPS automatically enabled |
| **Total time** | **30-120 min** | **Fully working custom domain** |

Go ahead and add that TXT record in Wix, then come back to verify it worked! 🚀
