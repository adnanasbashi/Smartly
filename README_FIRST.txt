SMARTLY - COMPLETE BUILD PACKAGE

FILES
1. index.html - customer website. Existing design preserved; additions/fixes included.
2. admin.html - secure admin panel with login + admin role + CRUD + CSV export.
3. config.js - Supabase URL, public/anon key, WhatsApp number.
4. supabase_schema.sql - database, RLS, admin role, customer profiles, storage, payment methods and initial products.
5. manifest.json - valid PWA manifest.
6. service-worker.js - PWA service worker.
7. icon-192.svg / icon-512.svg - app icons.
8. hero.jpg - master hero image used by the website.

IMPORTANT SECURITY
- Only use the Supabase publishable/anon key in website files.
- NEVER put a Supabase service_role/secret key in index.html, admin.html, GitHub, Vercel, or Netlify.
- The admin page is protected by Supabase Auth + admin_users + RLS. Hiding /admin.html alone is NOT security.

WHAT IS INCLUDED
- Smartly branding and existing navy/teal/red design kept.
- Lebanon + Syria and additional country support.
- Categories editable from Admin.
- Initial product catalogue: LED/red-light face mask, gua sha, mini/travel massage gun, posture corrector, magnetic phone accessories, natural food & herbs.
- Natural products section.
- Bundles & offers.
- Out-of-stock reservation with quantity.
- Pickup or Delivery.
- Payment methods: Whish Money, OMT, Cash on Delivery, Pickup.
- Exact location, street, building, floor, city/area and GPS share.
- Delivery date is confirmed by the team on WhatsApp; customer is not forced to choose a date. Minimum requested delivery is 3 days.
- Damaged/incorrect stocked-item return notice within 2 days.
- Special request with picture upload and 2-4 week lead time.
- Customer accounts: Login / Create New Account.
- Customer fields: full name, age, email, country, country code, phone, alternative phone, street, building, floor, city/area, location and GPS.
- Gmail and Outlook OAuth buttons (Google provider is labelled Gmail; Azure/Microsoft provider is labelled Outlook).
- Hello, Name + My Account + My Orders + Logout.
- Admin CRUD for products, categories, countries, bundles, payments, orders, reservations, reviews, special requests, customers, admins and settings.
- CSV export that opens in Excel.
- PWA manifest/service worker fixed.

DEPLOYMENT ORDER
A. Supabase: run supabase_schema.sql once.
B. Supabase: create an Auth user for your admin.
C. Supabase: insert that user's UUID into admin_users.
D. GitHub: upload all files from this package to the Smartly repository root.
E. Vercel: import the Smartly GitHub repository and deploy.
F. Test the Vercel URL before relying on Netlify.
G. Netlify: if production deploys are paused because of account credits, do not wait for Netlify; Vercel can be used as the live site while the Netlify account issue is resolved.

ADMIN CREATION SQL
After creating the admin user in Supabase Authentication > Users, copy its User UID and run:

insert into public.admin_users(user_id,email,active)
values('PASTE-USER-UUID-HERE','YOUR-ADMIN-EMAIL-HERE',true)
on conflict (user_id) do update set email=excluded.email,active=true;

OAUTH
Gmail and Outlook require provider setup in Supabase Authentication > Providers. The site code is ready for the providers; provider credentials/redirect settings must be configured in Supabase before those buttons can work.

FINAL TEST
1. Open homepage.
2. Confirm hero.jpg appears.
3. Confirm no manifest 404/401.
4. Create account.
5. Login.
6. Confirm Hello, Name and Logout.
7. Add product to cart.
8. Test Delivery and Pickup.
9. Test Whish Money, OMT and Cash on Delivery.
10. Enter exact location and test Share My Location.
11. Test an out-of-stock reservation.
12. Test special request picture upload.
13. Open /admin.html and login with the authorized admin account.
14. Add/edit/delete a product.
15. Add/edit/delete a category.
16. Add/edit/delete a payment method.
17. Review an order/reservation/customer.
18. Export a table to CSV and open it in Excel.
