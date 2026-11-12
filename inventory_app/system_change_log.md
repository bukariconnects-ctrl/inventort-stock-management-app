# سجل تغييرات وتحديثات النظام (System Change Log)
## نظام إدارة مخازن مياه رواء (Rawaa WMS)

---

### الحالة الحالية للنظام (Current Status)
* **المرحلة المكتملة:** المرحلة 2 - تصميم وبناء طبقة قاعدة البيانات المحلية SQLite والعمليات الذرية (Phase 2: SQLite Database Layer & Atomic Models).
* **حالة النظام:** مكتمل وجاهز 100% بدون أي أخطاء أو تحذيرات برمجية (`No issues found`).
* **الاختبارات الآلية:** اجتياز جميع اختبارات الوحدة والاختبارات التوافقية بنجاح (`9 of 9 passed`).
* **البيئة المعتمدة:** Flutter (Dart SDK ^3.8.0) مع محرك `sqflite` ونمط العمل المستقل بدون إنترنت (Offline-First).

---

### 1. ملخص إنجازات المرحلة 2 (Phase 2 Highlights)

#### أ. نماذج البيانات المعيارية (Domain Data Models)
تم إنشاء كلاسات النماذج التالية داخل مجلدات الميزات المناسبة مع دوال `toMap()`, `fromMap()`, و `copyWith()`:
1. **`WarehouseModel`** ([lib/features/warehouses/models/warehouse_model.dart](file:///d:/inventory_management_app/inventory_app/lib/features/warehouses/models/warehouse_model.dart)):
   - الحقول: `id`, `name`, `location`, `code` (فريد), `minAlertThreshold` (الافتراضي 100 كرتون), `createdAt`.
2. **`ItemModel`** ([lib/features/inventory/models/item_model.dart](file:///d:/inventory_management_app/inventory_app/lib/features/inventory/models/item_model.dart)):
   - الحقول: `id`, `name`, `unit` (كرتون), `bottlesPerPackage` (20 قنينة), `bottleVolume` (75 مل), `createdAt`.
3. **`WarehouseStockModel`** ([lib/features/inventory/models/warehouse_stock_model.dart](file:///d:/inventory_management_app/inventory_app/lib/features/inventory/models/warehouse_stock_model.dart)):
   - يمثل رصيد كراتين المياه في كل مخزن على حدة مع حقول الربط المساعدة (JOIN) وخاصية `isLowStock` لتنبيه انخفاض الرصيد.
4. **`StockTransactionModel`** ([lib/features/transactions/models/stock_transaction_model.dart](file:///d:/inventory_management_app/inventory_app/lib/features/transactions/models/stock_transaction_model.dart)):
   - يمثل سندات الحركات الثلاث المعتمدة (استلام `receipt`، صرف `issue`، إتلاف `damage`).
   - الحقول: `voucherNumber`, `type`, `warehouseId`, `itemId`, `quantity`, `relatedPerson`, `referenceNumber`, `notes`, `damageReason`, `createdAt`.
5. **`StocktakeModel`** ([lib/features/stocktake/models/stocktake_model.dart](file:///d:/inventory_management_app/inventory_app/lib/features/stocktake/models/stocktake_model.dart)):
   - يمثل جلسة الجرد والتسوية ومقارنة الرصيد الدفتري بالفعلي واحتساب الفارق `difference` وخصائص `hasDeficit` و `hasSurplus`.

---

#### ب. مخطط قاعدة البيانات المحلية SQLite (Database Schema)
تم بناء الجداول والعلاقات داخل [lib/core/database/database_helper.dart](file:///d:/inventory_management_app/inventory_app/lib/core/database/database_helper.dart) مع تفعيل القيود المرجعية `PRAGMA foreign_keys = ON;`:
1. **`warehouses`**: جدول المستودعات وأكوادها وحدود التنبيه.
2. **`items`**: جدول الأصناف ومواصفات العبوات.
3. **`warehouse_stocks`**: جدول أرصدة المستودعات مع قيد فريد مركب `UNIQUE(warehouse_id, item_id)`.
4. **`transactions`**: جدول السندات والأرشيف مع فهارس سريعة على `warehouse_id`, `type`, و `created_at`.
5. **`stocktakes`**: جدول جلسات الجرد والتسويات الدورية.

---

#### ج. حقن البيانات الافتراضية (Seed Data)
عند إنشاء قاعدة البيانات لأول مرة، يتم تلقائياً:
1. إدراج الصنف الافتراضي: **"كرتون مياه رواء - 20 علبة × 75 مل"** (20 قنينة، سعة 75 مل).
2. إدراج المخزنين الافتراضيين:
   - **المخزن الرئيسي (المصنع):** الكود `WH-01`، حد التنبيه: 500 كرتون.
   - **مخزن التوزيع الخارجي:** الكود `WH-02`، حد التنبيه: 200 كرتون.
3. تهيئة سجلات الأرصدة للمخزنين في `warehouse_stocks` برصيد ابتدائي (0).

---

#### د. العمليات الحسابية الذرية (Atomic Business Transactions)
تم تنفيذ المعاملات باستخدام `db.transaction()` لضمان الاتساق الذري الكامل ومنع تضارب البيانات:
1. **`insertReceiptTransaction`**: حفظ سند الاستلام وزيادة رصيد كراتين المياه في المخزن ذرياً.
2. **`insertIssueTransaction`**: فحص الرصيد المتوفر، ومنع الصرف في حال عدم الكفاية عبر استثناء `InsufficientStockException`، ثم خصم الرصيد وحفظ السند ذرياً لمنع الأرصدة السالبة تماماً.
3. **`insertDamageTransaction`**: فحص وتوثيق حالات الإتلاف والهدر وخصم الكمية من المخزن مع توثيق السبب المباشر.
4. **`executeStocktakeReconciliation`**: حفظ نتيجة الجرد، وضبط رصيد المخزن في `warehouse_stocks` ليصبح مساوياً تماماً للكمية الفعلية المحصورة.

---

#### هـ. دوال الاستعلام والفلترة وتوليد السندات
* **`getAllWarehousesWithStock`**: جلب كافة المخازن مع أرصدتها وحالة تنبيه انخفاض المخزون `isLowStock`.
* **`getTransactions`**: استعلام أرشيف الحركات مع دعم الفلترة بواسطة: المخزن، نوع السند، وتاريخ البداية والنهاية.
* **`generateNextVoucherNumber`**: توليد تسلسلي تلقائي شهري لأرقام السندات (مثل: `REC-202611-0001`، `ISS-202611-0001`، `DAM-202611-0001`، `STK-202611-0001`).

---

### 2. الاختبارات والتحقق البرمجي (Verification & Tests)
* تم إنشاء ملف اختبارات شامل في [test/database_test.dart](file:///d:/inventory_management_app/inventory_app/test/database_test.dart) للتحقق من:
  1. سلامة التهيئة وحقن البيانات المبدئية.
  2. صحة زيادة الرصيد في سند الاستلام.
  3. صحة خصم الرصيد في سند الصرف.
  4. التحقق الصارم من منع الأرصدة السالبة ورمي `InsufficientStockException`.
  5. صحة سند الإتلاف وخصم التالف.
  6. صحة تسوية الجرد الفعلي ومطابقة الرصيد.
  7. دقة توليد أرقام السندات التسلسلية.
  8. اختبار استعلام مؤشرات وتنبيهات انخفاض المخزون.
* نتيجة الفحص البرمجي:
  ```text
  flutter analyze -> No issues found!
  flutter test -> 00:02 +9: All tests passed!
  ```

---

### 3. الجاهزية للمرحلة التالية (Next Stage Readiness)
* **المرحلة 3 القادمة:** **واجهات وإدارة المخازن ورصيد المخزون (Warehouse & Inventory Management UI)**.
* **الخطوات القادمة:**
  1. بناء مزودي الحالة `WarehousesProvider` و `InventoryProvider` باستخدام مكتبة `provider`.
  2. تصميم وتطوير واجهة الشاشة الرئيسية (Dashboard / Home View) لعرض ملخص المخازن، الأرصدة الإجمالية، والشارات التنبيهية بالألوان.
  3. شاشة إدارة وتفاصيل المخازن وإضافة مخزن جديد مع تحديد حد التنبيه.
  4. بطاقات كروت المخازن السريعة وتنبيهات نفاد المخزون.
