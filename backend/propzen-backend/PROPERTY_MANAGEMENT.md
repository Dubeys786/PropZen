# PropZen Property Management & Search Engine (Phase 5)

## 1. Overview & Architecture

Phase 5 establishes a high-performance, production-ready Property Management, Discovery, Search, and Moderation engine directly integrated with PostgreSQL / Supabase table `public.posted_properties`.

### Key Guarantees
1. **100% Database-Level Filtering**: All filtering, searching, budget range checking, and sorting execute inside PostgreSQL. No fake frontend-only post-filtering.
2. **Strict Server-Side Ownership**: Dealer properties are bound to the authenticated user and approved dealer profile. Privileged fields (`owner_id`, `dealer_id`, `verification_status`) are server-assigned.
3. **Controlled Lifecycle States**: `DRAFT` ➔ `SUBMITTED` ➔ `UNDER_REVIEW` ➔ `APPROVED` ➔ `PUBLISHED` (or `REJECTED` / `ARCHIVED`).
4. **Data Isolation & Privacy**: Public discovery APIs never expose private owner phone numbers, internal admin notes, or sensitive metadata.

---

## 2. Exact Filter Specifications

### Location Filters
* `city`: Case-insensitive exact database match (`LOWER(p.city) = LOWER(:city)`).
* `sector`: Case-insensitive exact database match (`LOWER(p.sector) = LOWER(:sector)`).
* `locality`: Substring match (`LOWER(p.locality) LIKE %:locality%`).

### BHK Filter (Zero False Positives)
* Database stores values such as `"1 BHK"`, `"2 BHK"`, `"3 BHK"`, `"4 BHK"`.
* Filtering by `bhk=3` matches `'3'`, `'3 BHK'`, `'3-BHK'`, `'3BHK'`.
* **Zero Collision**: `bhk=3` will **never** match `13 BHK` or `23 BHK`.
* Supports comma-separated multiple values (e.g. `bhk=2,3`).

### Budget / Price Normalization
* The canonical database column is `price_cr` (DECIMAL in Crores).
* Automatic unit normalization ensures seamless frontend compatibility:
  * Raw INR values (e.g. `minPrice=8000000` = ₹80 Lakhs) ➔ divided by 10,000,000 ➔ `0.80 Cr`.
  * Lakhs values (e.g. `minPrice=80` to `maxPrice=150`) ➔ divided by 100 ➔ `0.80 Cr` to `1.50 Cr`.
  * Crores values (e.g. `minPriceCr=0.8` or `minPrice=1.5`) ➔ treated as Crores.

### Area / Sqft Range
* `minSqft` and `maxSqft`: SQL `>=` and `<=` on `sqft`.

### Predefined Whitelisted Sorting
* `price_low`: Ascending by `price_cr`.
* `price_high`: Descending by `price_cr`.
* `newest`: Descending by `created_at`.
* `oldest`: Ascending by `created_at`.
* `area_low`: Ascending by `sqft`.
* `area_high`: Descending by `sqft`.
* **SQL Injection Proof**: Arbitrary sort parameters are safely rejected or defaulted.

---

## 3. REST API Reference

### Public Endpoints

#### `GET /api/v1/properties`
* **Access**: Public
* **Query Parameters**:
  * `q` (Keyword search in title, city, sector, locality, property type)
  * `city`, `sector`, `locality`, `propertyType`, `bhk`
  * `minPrice`, `maxPrice`, `minPriceCr`, `maxPriceCr`
  * `minSqft`, `maxSqft`
  * `amenities` (comma-separated list)
  * `sort` (`newest`, `oldest`, `price_low`, `price_high`, `area_low`, `area_high`)
  * `page` (default 0), `size` (default 20, bounded to 100)
* **Response**: `ApiResponse<Page<PropertyListDto>>`

#### `GET /api/v1/properties/{id}`
* **Access**: Public (Published properties) / Authenticated (Owner or Admin for non-published)
* **Response**: `ApiResponse<PropertyDetailsDto>`

---

### Dealer Endpoints

#### `POST /api/v1/properties`
* **Access**: `ROLE_DEALER` or `ROLE_ADMIN`
* **Request Body**:
  ```json
  {
    "title": "ATS Kingston Heath Luxury 3BHK",
    "description": "Facing golf greens with ultra-modern amenities",
    "city": "Noida",
    "sector": "Sector 150",
    "locality": "Sports City",
    "propertyType": "Apartment",
    "bhk": "3 BHK",
    "priceCr": 1.45,
    "sqft": 1750,
    "amenities": "Gym, Swimming Pool, Parking",
    "imageUrl": "https://storage.propzen.ai/properties/ats-150-main.jpg",
    "submitForReview": true
  }
  ```
* **Response**: `ApiResponse<PropertyDetailsDto>`

#### `PATCH /api/v1/properties/{id}`
* **Access**: Property Owner (`ROLE_DEALER`) or `ROLE_ADMIN`
* **Description**: Updates permitted fields. Protected fields (`owner_id`, `dealer_id`, `verification_status`) cannot be modified.

#### `GET /api/v1/dealers/me/properties`
* **Access**: Authenticated Dealer (`ROLE_DEALER`)
* **Description**: Returns all properties owned by the authenticated dealer with full inventory filtering support.

---

### Admin Endpoints

#### `GET /api/v1/admin/properties`
* **Access**: `ROLE_ADMIN`
* **Description**: Search properties across all lifecycle states and dealers.

#### `GET /api/v1/admin/properties/{id}`
* **Access**: `ROLE_ADMIN`
* **Description**: Retrieves full property details including owner phone, dealer ID, and internal review notes.

#### `PATCH /api/v1/admin/properties/{id}/status`
* **Access**: `ROLE_ADMIN`
* **Request Body**:
  ```json
  {
    "status": "PUBLISHED",
    "adminNote": "Verified documents against RERA registry."
  }
  ```
* **Response**: `ApiResponse<PropertyAdminDto>`

---

## 4. Database Schema & Flyway V3

Applied via `V3__enhance_posted_properties.sql`:
```sql
ALTER TABLE public.posted_properties
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS locality VARCHAR(255),
    ADD COLUMN IF NOT EXISTS dealer_id UUID,
    ADD COLUMN IF NOT EXISTS owner_id UUID,
    ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'PENDING',
    ADD COLUMN IF NOT EXISTS amenities TEXT,
    ADD COLUMN IF NOT EXISTS image_url TEXT,
    ADD COLUMN IF NOT EXISTS images TEXT,
    ADD COLUMN IF NOT EXISTS admin_note TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_posted_properties_city ON public.posted_properties(city);
CREATE INDEX IF NOT EXISTS idx_posted_properties_sector ON public.posted_properties(sector);
CREATE INDEX IF NOT EXISTS idx_posted_properties_prop_type ON public.posted_properties(property_type);
CREATE INDEX IF NOT EXISTS idx_posted_properties_bhk ON public.posted_properties(bhk);
CREATE INDEX IF NOT EXISTS idx_posted_properties_price_cr ON public.posted_properties(price_cr);
CREATE INDEX IF NOT EXISTS idx_posted_properties_sqft ON public.posted_properties(sqft);
CREATE INDEX IF NOT EXISTS idx_posted_properties_status ON public.posted_properties(status);
CREATE INDEX IF NOT EXISTS idx_posted_properties_dealer_id ON public.posted_properties(dealer_id);
CREATE INDEX IF NOT EXISTS idx_posted_properties_owner_id ON public.posted_properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_posted_properties_status_city ON public.posted_properties(status, city);
```
