# Архитектурные решения: почему именно так

Это не просто список паттернов — это разбор каждого решения: что отвергли, что выбрали и чем за это заплатили. Читать вместе с `EF_Core_Advanced_Guide.md`.

---

## 1. Почему Rich Domain Model, а не Anemic

### Что такое Anemic Domain Model

Анемичная модель — это когда сущность выглядит так:

```csharp
// Анемичная модель — просто контейнер данных
public class Customer
{
    public int CustomerId { get; set; }
    public string LastName { get; set; } = null!;
    public bool Arch { get; set; }
    public bool IsDeleted { get; set; }
}

// Вся логика — в сервисе
public class CustomerService
{
    public void Archive(Customer customer)
    {
        if (customer.IsDeleted) throw new Exception("...");
        customer.Arch = true;  // Прямое изменение состояния снаружи
    }
}
```

Это антипаттерн, описанный Мартином Фаулером в 2003 году. Проблемы:

**Проблема 1 — логика размазана.** Валидация «нельзя архивировать удалённого пациента» может жить в `CustomerService`, `CustomerController`, `CustomerValidator`, `CustomerImportJob` — везде, где кто-то когда-то вызвал `customer.Arch = true`. Найти все места невозможно.

**Проблема 2 — объект всегда в невалидном состоянии.** После `new Customer()` поля пустые. Любой код может записать в них что угодно: `customer.Birthday = DateTime.MaxValue`. Нет ни одной точки, где гарантируется корректность объекта.

**Проблема 3 — тесты тестируют не то.** Тест `CustomerServiceTests.Archive_WhenDeleted_Throws()` тестирует сервис. Сервис завтра переименуют или уберут — тест упадёт. Правило «нельзя архивировать удалённого» — это правило домена, оно не должно быть привязано к конкретному сервису.

### Что мы выбрали и почему

```csharp
public sealed class Customer : AggregateRoot
{
    private Customer() { }  // EF Core использует это

    public void Archive()
    {
        if (IsDeleted) throw new DomainException("Невозможно архивировать удалённого пациента.");
        if (Arch) throw new DomainException("Пациент уже в архиве.");
        Arch = true;
    }
}
```

Правило «нельзя архивировать удалённого» живёт ровно в одном месте — в методе `Archive()` класса `Customer`. Любой код, который архивирует пациента, вызовет именно этот метод и получит проверку. Невозможно «забыть» валидацию.

**Что мы потеряли:** сложнее маппинг (EF Core должен уметь работать с `private set`). Больше кода на старте. Нельзя просто написать `customer.Arch = true` в тесте — нужно вызывать методы.

**Почему оно того стоит:** медицинская система живёт 10–15 лет. За это время через код пройдут десятки разработчиков. Анемичная модель гарантирует, что правила домена будут продублированы и рассинхронизированы. Rich Domain — гарантирует единственный источник истины для каждого правила.

---

## 2. Почему `private set`, а не `required` везде

### В чём разница

`required` означает: «свойство должно быть выставлено при создании объекта через object initializer». Это механизм C# 11 для compile-time проверки инициализации.

`private set` означает: «свойство можно менять только изнутри класса».

Они решают разные задачи:

```csharp
// required + public set — хорошо для DTO, плохо для доменной сущности
// Любой код снаружи может написать customer.LastName = ""
public class CustomerDto
{
    public required string LastName { get; set; }  // OK для DTO
}

// private set — правильно для сущности
// Изменить LastName можно только через UpdatePersonalInfo()
public sealed class Customer
{
    public string LastName { get; private set; }
}
```

### Где мы использовали `required`

Для справочников (lookup entities), которые создаются только через EF Core или через сид-данные и никогда не мутируют в рантайме:

```csharp
public sealed class Gender
{
    public required string Name { get; init; }  // init = только при создании
}
```

`required` + `init` даёт compile-time гарантию, что объект никогда не будет создан без `Name`. `= null!` — это способ сказать компилятору «я знаю, что тут null, но доверься мне». Это ложь компилятору. Если EF Core не заполнит поле при материализации — получите `NullReferenceException` в рантайме.

### Почему не `required` для Customer

У `Customer` есть `private set` — значит, снаружи нельзя выставить свойство в object initializer. `required` с `private set` — это противоречие: компилятор требует выставить при создании, но запрещает выставлять снаружи. Поэтому для богатых сущностей — конструктор или фабричный метод, а не `required`.

---

## 3. Почему Value Objects (FullName, AddressDetails)

### Альтернатива — примитивы прямо в сущности

```csharp
// Без Value Object
public class Customer
{
    public string LastName { get; private set; }
    public string FirstName { get; private set; }
    public string? MiddleName { get; private set; }

    // Форматирование — где оно живёт?
    // В контроллере? В сервисе? В хелпере? В каждом из них по-разному?
}
```

**Проблема 1 — примитивная одержимость (Primitive Obsession).** Три строки — это не три независимых данных. Это одно понятие «ФИО». Если их хранить раздельно, логика работы с ФИО (форматирование, валидация) будет размазана по всей кодовой базе.

**Проблема 2 — семантика теряется.** `string lastName` и `string firstName` одного типа. Компилятор не поймает `new Customer(firstName, lastName)` — перепутанный порядок аргументов. Если аргумент типа `FullName` — ошибка невозможна.

### Что мы получили с Value Objects

```csharp
public sealed record FullName
{
    public required string LastName { get; init; }
    public required string FirstName { get; init; }
    public string? MiddleName { get; init; }

    // Логика форматирования — ровно в одном месте
    public string ShortName => $"{LastName} {FirstName[0]}.";
    public string FullDisplay => MiddleName is null
        ? $"{LastName} {FirstName}"
        : $"{LastName} {FirstName} {MiddleName}";
}
```

`record` даёт структурное равенство бесплатно: `fullName1 == fullName2` сравнивает содержимое, а не ссылки. Это важно при сравнении ФИО в логике.

**Как EF Core хранит VO:** через `OwnsOne` — данные встраиваются в ту же таблицу. Никакого JOIN. `Customer` и его `FullName` — один SELECT. Производительность не хуже, чем без VO.

**Что мы потеряли:** нельзя запрашивать FullName отдельно от Customer. Но зачем нам ФИО без пациента?

---

## 4. Почему `SaveChangesInterceptor`, а не триггер БД

### Как работал исходный триггер

```sql
CREATE TRIGGER CancelDeleteRow ON Customer
INSTEAD OF DELETE
AS
BEGIN
    UPDATE Customer SET [Delete] = 1
    WHERE CustomerID IN (SELECT CustomerID FROM deleted)
END
```

Триггер перехватывает `DELETE` на уровне SQL Server и переписывает его в `UPDATE`. Это работает, но несёт серьёзные проблемы:

**Проблема 1 — невидимость.** Разработчик видит `context.Customers.Remove(customer)` и думает: «объект удалён». На самом деле выполняется `UPDATE`. Это нарушение принципа наименьшего удивления. Дебаггинг такого кода — боль.

**Проблема 2 — нетестируемость.** In-Memory провайдер и SQLite не поддерживают триггеры. При юнит-тестах триггер молча не срабатывает. Тест проходит, продакшен работает по-другому.

**Проблема 3 — зависимость от БД.** Логика «мягкое удаление» живёт в SQL Server. Миграция на другую СУБД — потеря логики. Или нужно дублировать триггер для каждой СУБД.

**Проблема 4 — права.** Создание триггеров требует прав `ALTER TABLE`. В корпоративных медицинских системах это часто недоступно.

### Почему Interceptor лучше

```csharp
public sealed class SoftDeleteInterceptor : SaveChangesInterceptor
{
    private static void ApplySoftDelete(DbContext? context)
    {
        foreach (var entry in context.ChangeTracker
            .Entries<ISoftDeletable>()
            .Where(e => e.State == EntityState.Deleted))
        {
            entry.State = EntityState.Modified;
            entry.Entity.MarkAsDeleted();
        }
    }
}
```

- Логика видна в коде на C# — нет магии на уровне БД.
- Тестируется без БД: просто проверяем состояние `ChangeTracker`.
- Работает с любой СУБД.
- Не требует прав `ALTER TABLE`.
- Логика централизована: добавить новую сущность с soft delete — просто имплементировать `ISoftDeletable`.

**Что мы потеряли:** если кто-то выполнит `DELETE` напрямую через SQL Management Studio или другое приложение — триггера нет, данные удалятся физически. Решение: убрать права `DELETE` у рабочего пользователя БД.

---

## 5. Почему `HashSet<T>` вместо `List<T>` для коллекций

### Вопрос, который задают все

```csharp
// Почему не List?
private readonly HashSet<Address> _addresses = [];

// И почему IReadOnlyCollection, а не IEnumerable или List?
public IReadOnlyCollection<Address> Addresses => _addresses;
```

### Причина 1 — дубликаты при маппинге графов объектов

EF Core при `AsSplitQuery()` выполняет несколько SELECT и собирает граф объектов в памяти. При join-е нескольких коллекций один объект может встретиться несколько раз. `HashSet` гарантирует уникальность через `GetHashCode()` + `Equals()`. `List` — молча добавит дубликаты.

Пример: загружаем `Invalid` с его `BenefitsCategories`. Если у пациента 3 записи об инвалидности и 5 льготных категорий, join создаёт 15 строк. `HashSet` корректно схлопнет их до 3 + 5. `List` даст 15 объектов.

### Причина 2 — O(1) vs O(n) для Contains/Remove

В методе `Invalid.RemoveBenefitsCategory()`:

```csharp
public void RemoveBenefitsCategory(BenefitsCategory category)
{
    if (!_benefitsCategories.Remove(category)) // O(1) для HashSet
        throw new DomainException("...");
}
```

`List.Remove()` — O(n): перебирает все элементы. `HashSet.Remove()` — O(1): сразу находит по хэшу. При 100 категориях разница несущественна, при 100 000 (исторические данные) — принципиальна.

### Причина 3 — IReadOnlyCollection, не IEnumerable

`IEnumerable` даёт минимальный контракт — только итерацию. Но он допускает ленивую оценку: коллекция может быть запросом к БД. При множественном перечислении возможен повторный запрос.

`IReadOnlyCollection<T>` гарантирует: данные уже в памяти, есть `Count`. Это явный контракт — «я даю тебе готовую коллекцию в памяти, не запрос».

---

## 6. Почему `IEntityTypeConfiguration<T>`, а не `OnModelCreating`

### Проблема гигантского OnModelCreating

```csharp
// Через год это выглядит так:
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Конфигурация Customer — 40 строк
    // Конфигурация Address — 30 строк
    // Конфигурация Register — 50 строк
    // Конфигурация Invalid — 45 строк
    // ... 17 таблиц ...
    // Итого: 600+ строк в одном методе
}
```

Это стандартный путь к нечитаемому коду. Проблема не только в размере — проблема в связности. Конфигурация `Customer` и конфигурация `TypeStreet` живут в одном файле, хотя у них нет ничего общего.

### Что мы выбрали

```csharp
// Каждая таблица — отдельный файл, отдельный класс
internal sealed class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder) { ... }
}

// OnModelCreating — одна строка, не меняется никогда
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(DispancerDbContext).Assembly);
}
```

`ApplyConfigurationsFromAssembly` через рефлексию находит все классы, реализующие `IEntityTypeConfiguration<T>`, и применяет их. Добавление новой таблицы — новый файл конфигурации, `OnModelCreating` не трогаем.

**Дополнительный бонус:** конфигурацию конкретной таблицы можно легко найти через «Перейти к файлу» в IDE. `CustomerConfiguration.cs` найдётся за секунду. В 600-строчном `OnModelCreating` — надо листать.

---

## 7. Почему `AsNoTracking()` обязателен для чтения

### Что делает ChangeTracker

Каждый объект, загруженный через EF Core без `AsNoTracking`, добавляется в `ChangeTracker`. EF хранит снимок его состояния на момент загрузки. При `SaveChanges()` сравнивает текущее состояние со снимком и генерирует SQL только для изменённых полей.

Это удобно для write-операций. Для read-операций — чистый overhead.

### Цена отслеживания

```csharp
// Загружаем 1000 пациентов для отчёта
var customers = await context.Customers.ToListAsync();
// ChangeTracker теперь хранит 1000 исходных снимков объектов
// + 1000 текущих объектов = 2000 объектов в памяти
// При SaveChanges() — сравнение всех 1000 пар

// Правильно:
var customers = await context.Customers.AsNoTracking().ToListAsync();
// 1000 объектов, нет снимков, нет сравнения при SaveChanges()
```

Типичный выигрыш для read-heavy операций: 15–30% CPU, 40–50% памяти.

### Когда AsNoTracking нельзя использовать

Только одна ситуация: когда вы загружаете объект, меняете его и вызываете `SaveChanges()` в той же области видимости:

```csharp
// Нужен трекинг — мы будем сохранять изменения
var customer = await context.Customers
    .FirstAsync(c => c.CustomerId == id);  // Без AsNoTracking!

customer.Archive();
await context.SaveChangesAsync();  // EF знает, что изменилось
```

### AsNoTracking vs AsNoTrackingWithIdentityResolution

`AsNoTracking` — самый быстрый, но при загрузке графов объектов один и тот же объект может материализоваться несколько раз:

```csharp
// Land с ID=1 встречается в 10 Register — будет создано 10 РАЗНЫХ объектов Land
var registers = await context.Registers
    .Include(r => r.Land)
    .AsNoTracking()
    .ToListAsync();
// registers[0].Land != registers[1].Land (разные ссылки, хотя один Land)
```

`AsNoTrackingWithIdentityResolution` — чуть медленнее, но гарантирует один объект = одна ссылка:

```csharp
var registers = await context.Registers
    .Include(r => r.Land)
    .AsNoTrackingWithIdentityResolution()
    .ToListAsync();
// registers[0].Land == registers[1].Land (одна ссылка)
```

**Правило выбора:**
- Проекция в DTO (`.Select(r => new Dto(...))`) — `AsNoTracking`, объектный граф не строится.
- Загрузка графа с навигационными свойствами — `AsNoTrackingWithIdentityResolution`.

---

## 8. Почему Compiled Queries и когда они нужны

### Что происходит при обычном запросе

Каждый LINQ-запрос в EF Core проходит три шага:
1. **Разбор Expression Tree** — EF анализирует ваше лямбда-выражение.
2. **Трансляция в SQL** — Expression Tree превращается в SQL AST.
3. **Кеширование результата** — SQL сохраняется по хэшу запроса.

При повторном вызове шаг 3 позволяет пропустить шаг 2. Но шаг 1 (разбор Expression Tree) выполняется **при каждом вызове**, даже если запрос идентичен. Это занимает 1–5 мс на запрос.

### Что делает EF.CompileAsyncQuery

```csharp
private static readonly Func<DispancerDbContext, int, Task<Customer?>>
    GetActiveCustomerById = EF.CompileAsyncQuery(
        (DispancerDbContext ctx, int id) =>
            ctx.Customers.FirstOrDefault(c => c.CustomerId == id));
```

Запрос компилируется один раз при старте приложения. При каждом последующем вызове — только выполнение готового плана. Шаг 1 пропускается полностью.

### Когда применять

| Ситуация | Применять? |
|---|---|
| Поиск пациента по ID (100+ вызовов/сек) | Да |
| Генерация отчёта раз в сутки | Нет |
| Запрос меняется в зависимости от параметров | Нет |
| Динамическая фильтрация (разные условия WHERE) | Нет |

**Ограничение:** скомпилированный запрос нельзя модифицировать после компиляции. Нельзя добавить `.Include()` в рантайме. Структура запроса фиксируется навсегда.

**Реальный выигрыш:** 10–30% на горячих путях. Для большинства запросов — незначительно. Применяйте только после профилирования, не заранее.

---

## 9. Почему `AsSplitQuery()` и в чём опасность

### Проблема декартового произведения

```csharp
// Этот запрос выглядит невинно:
var customer = await context.Customers
    .Include(c => c.Addresses)      // У пациента 2 адреса
    .Include(c => c.Registers)      // 10 записей на учёте
    .Include(c => c.Invalids)       // 3 инвалидности
    .FirstOrDefaultAsync(c => c.CustomerId == id);
```

EF Core без `AsSplitQuery` генерирует один JOIN-запрос. Результат: 2 × 10 × 3 = **60 строк** вместо 15. Каждая строка дублирует данные пациента. При 100 адресах, 200 регистрациях, 50 инвалидностях — 1 000 000 строк для одного пациента. Это реальная проблема в старых медицинских системах с историческими данными.

### Что делает AsSplitQuery

```csharp
var customer = await context.Customers
    .Include(c => c.Addresses)
    .Include(c => c.Registers)
    .Include(c => c.Invalids)
    .AsSplitQuery()
    .FirstOrDefaultAsync(c => c.CustomerId == id);
```

Генерируются 4 отдельных SELECT: один для Customer, один для Addresses, один для Registers, один для Invalids. EF собирает граф в памяти. Строк в каждом запросе — ровно столько, сколько реальных данных.

### Главная опасность AsSplitQuery

Между четырьмя запросами нет единой транзакции. Если между первым и вторым SELECT другая транзакция добавила запись на учёт — вы получите несогласованный граф: Address из состояния T1, Registers из состояния T2.

**Когда это приемлемо:** для отображения карточки пациента — вполне. Пользователь не заметит, что Address загрузился на 50 мс раньше Registers.

**Когда неприемлемо:** для отчётов и финансовых расчётов. Там нужен `IsolationLevel.Snapshot` + `AsSingleQuery`.

---

## 10. Почему `IExecutionStrategy.ExecuteAsync` для транзакций

### Что ломается без ExecuteAsync

```csharp
// Кажется правильным, но это ловушка:
options.EnableRetryOnFailure(maxRetryCount: 5);  // Настроили retry

// В коде:
await using var transaction = await context.Database.BeginTransactionAsync();
// Транзакция открыта

await context.SaveChangesAsync();
// Если здесь обрыв сети — EF попытается повторить
// НО: была ли транзакция закоммичена до обрыва?
// EF НЕ ЗНАЕТ. И всё равно повторит SaveChanges.
// Результат: дублирование данных
```

Когда `EnableRetryOnFailure` активна, EF Core выбрасывает исключение при попытке начать вручную управляемую транзакцию без `ExecutionStrategy`. Это защита от описанной ловушки.

### Правильный способ

```csharp
var strategy = context.Database.CreateExecutionStrategy();

await strategy.ExecuteAsync(async () =>
{
    // Каждая попытка retry начинает НОВУЮ транзакцию с чистого листа
    await using var transaction = await context.Database.BeginTransactionAsync();

    try
    {
        await context.SaveChangesAsync();
        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;  // strategy решит — повторять или нет
    }
});
```

`ExecuteAsync` оборачивает весь блок, включая создание транзакции. При retry — новая транзакция, новая попытка с нуля. Никакого дублирования.

**Почему это важно для медицинских систем:** потеря данных о регистрации пациента на учёт или о льготной категории — юридически значимое событие. Дублирование записей — тоже. Правильная стратегия retry обязательна.

---

## 11. Почему Outbox Pattern, а не прямая публикация Domain Events

### Проблема с прямой публикацией

```csharp
// В AuditInterceptor.SavedChangesAsync():
await mediator.Publish(new CustomerArchivedEvent(customerId));
```

Допустим, `CustomerArchivedEvent` должен отправить уведомление врачу. MediatR вызывает обработчик. Обработчик обращается к SMTP-серверу. SMTP недоступен — исключение.

Что произошло: запись в БД сохранена (`SaveChanges` уже выполнен), но уведомление не отправлено. Событие потеряно навсегда. Это называется «потеря сообщения» (message loss).

### Outbox гарантирует доставку

Idея проста: событие сохраняется в ту же таблицу БД, что и основные данные, в той же транзакции. Отдельный фоновый процесс читает непрочитанные сообщения и доставляет их.

```
Транзакция {
    UPDATE Customer SET Arch = 1 WHERE CustomerID = 42
    INSERT INTO OutboxMessages (Type, Payload) VALUES ('CustomerArchivedEvent', '{"CustomerId":42}')
}
// Либо оба действия выполнены, либо ни одно
```

Если SMTP недоступен — OutboxProcessor повторит через 10 секунд. И через 20. И через 40. До победы.

**Что мы потеряли:** задержка. Событие доставляется не мгновенно, а через N секунд после сохранения. Для уведомления врача — это нормально. Для финансовой транзакции «в реальном времени» — нужно другое решение.

**Альтернатива:** если нужна мгновенная обработка события В ТОЙ ЖЕ транзакции — это уже не событие, а часть бизнес-логики. Переместите в доменный метод.

---

## 12. Почему Testcontainers, а не In-Memory или SQLite

### Что не умеет In-Memory провайдер

EF Core In-Memory Database — это не база данных. Это словарь в памяти, который понимает LINQ. Он не поддерживает:

- Хранимые процедуры (все 65 процедур нашей системы)
- Триггеры (наш `CancelDeleteRow`, хотя мы его заменили)
- CHECK constraints (проверки дат `Birthday <= GETDATE()`)
- Транзакционную изоляцию
- SQL-специфичные функции (`GETDATE()`, `NEWID()`, `DATEDIFF`)
- Правильную обработку `NULL` в JOIN-ах
- `hierarchyid` тип данных
- JSON-функции

Тест на In-Memory проходит, потому что In-Memory игнорирует всё, что не понимает. На реальной БД тот же код может упасть из-за CHECK constraint или неожиданного поведения `NULL` в LEFT JOIN.

### Почему не SQLite

SQLite поддерживает больше, чем In-Memory, но у него другая семантика:

- `DATETIME` хранится как TEXT или REAL — проблемы с точностью
- Нет `NVARCHAR` — все строки UTF-8, другая сортировка
- Нет `hierarchyid`, нет JSON-функций SQL Server
- Поведение `NULL` в некоторых случаях отличается

SQLite-тест может проходить, а SQL Server-продакшен — падать. Это хуже, чем отсутствие теста: вы уверены в корректности кода, а уверенность ложная.

### Что даёт Testcontainers

Настоящий SQL Server 2022 в Docker-контейнере. Те же версия, та же конфигурация, то же поведение. Тест, прошедший на Testcontainers, с вероятностью 99% пройдёт на продакшене.

```csharp
private readonly MsSqlContainer _container = new MsSqlBuilder()
    .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
    .Build();
```

**Цена:** тест запускается 15–30 секунд вместо миллисекунд. Для unit-тестов — неприемлемо. Для integration-тестов слоя данных — это правильная цена за реальную уверенность.

**Правило:** unit-тесты домена (валидация в методах Customer, Register) — без БД, мгновенно. Integration-тесты репозитория — Testcontainers, медленно, но честно.

---

## 13. Почему `AggregateRoot` как базовый класс

### Альтернатива — интерфейсы

```csharp
// Можно было сделать так:
public class Customer : ISoftDeletable, IAuditable, IHasDomainEvents { ... }
// И реализовывать каждый интерфейс в каждом классе
```

Проблема: `IsDeleted`, `DeletedAt`, `CreatedAt`, `ModifiedAt`, список `_domainEvents` — это одинаковый код в каждой сущности. Дублирование.

### Почему базовый класс, а не мixin через default interface implementation

C# 8+ позволяет реализовывать логику прямо в интерфейсе через default implementation. Но у этого подхода ограничение: default implementation не может добавить поле (backing field для хранения состояния). А нам нужны поля `_isDeleted`, `_deletedAt`, `_domainEvents`.

Базовый класс `AggregateRoot` — единственный способ вынести эти поля и общую логику в одно место без дублирования.

**Что мы потеряли:** нельзя наследоваться от другого класса (C# не поддерживает множественное наследование). Если у вас уже есть иерархия наследования — базовый класс не подойдёт. В нашем случае это не проблема.

---

## 14. Почему JSON Columns, а не новая таблица для метаданных

### Сценарий: нужно хранить разные метаданные для разных пациентов

Один пациент имеет аллергии. Другой — хронические заболевания. Третий — внешние идентификаторы из других систем.

**Вариант 1 — EAV (Entity-Attribute-Value):**

```sql
CREATE TABLE PatientMetadata (
    PatientId INT,
    Key NVARCHAR(100),
    Value NVARCHAR(MAX)
);
```

Гибко, но невозможно типизировать. Запрос «пациенты с аллергией на пенициллин» — строковый поиск без индексов. Нет никаких гарантий типов.

**Вариант 2 — отдельные таблицы для каждого типа метаданных:**

Добавить `PatientAllergies`, `PatientChronicDiseases`, `PatientExternalIds`. Строго типизировано, но схема раздувается. Каждый новый тип метаданных — новая миграция, новая таблица, новый репозиторий.

**Вариант 3 — JSON Column:**

```csharp
builder.OwnsOne(c => c.Metadata, m => m.ToJson());
```

Один столбец хранит структурированный JSON. EF Core умеет запрашивать по полям JSON: `WHERE JSON_VALUE(Metadata, '$.BloodType') = 'A+'`. Схема не меняется при добавлении нового поля в метаданные — только код C#.

**Когда JSON Column неприемлем:**
- По этим данным нужны сложные JOIN-ы с другими таблицами.
- Объём данных велик (тысячи элементов в массиве) — JSON-индексы не спасут.
- Нужна строгая нормализация и ссылочная целостность.

В нашем случае метаданные — дополнительная информация, не критичная для бизнес-логики. JSON Column — правильный выбор.

---

## 15. Почему `HierarchyId`, а не self-referencing FK

### Стандартная реализация иерархии

```sql
-- Классическая «таблица с родителем»
CREATE TABLE AdminDivision (
    AdminDivisionID INT PRIMARY KEY,
    ParentID INT NULL REFERENCES AdminDivision(AdminDivisionID),
    Name NVARCHAR(30)
);
```

Запрос «все потомки района X» через Recursive CTE:

```sql
WITH Hierarchy AS (
    SELECT AdminDivisionID, Name, ParentID
    FROM AdminDivision WHERE AdminDivisionID = @Root

    UNION ALL

    SELECT d.AdminDivisionID, d.Name, d.ParentID
    FROM AdminDivision d
    INNER JOIN Hierarchy h ON d.ParentID = h.AdminDivisionID
)
SELECT * FROM Hierarchy;
```

Это работает, но:
- CTE — рекурсивный запрос, дорогой при глубоком дереве.
- Нет встроенного порядка обхода: «потомки X» — это множество, порядок произвольный.
- Индексирование иерархии неэффективно.

### Что даёт HierarchyId

`HierarchyId` — специальный тип SQL Server. Хранит путь в дереве как `/1/3/7/`. Операции:

```csharp
// Все потомки — один сканирующий индекс, без рекурсии
.Where(d => d.Path.IsDescendantOf(parentPath))

// Непосредственные дети
.Where(d => d.Path.GetAncestor(1) == parentPath)

// Порядок обхода дерева (DFS) — просто ORDER BY Path
.OrderBy(d => d.Path)
```

Нет рекурсии. Иерархия хранится в индексируемом поле. Запрос всех потомков — один range scan по индексу.

**Ограничение:** `HierarchyId` — специфика SQL Server. Если когда-нибудь решите мигрировать на PostgreSQL — нужна замена (ltree extension в PG решает ту же задачу, но другим синтаксисом).

---

## 16. Почему `EncryptedStringConverter`, а не TDE (Transparent Data Encryption)

### TDE — шифрование на уровне файлов

SQL Server TDE шифрует файлы данных и журналов транзакций. Защищает от кражи физического диска.

**Не защищает от:** запросов через SQL Server Management Studio. Администратор БД видит данные в открытом виде. В медицинской системе это часто нарушает требования законодательства о защите ПД.

### Always Encrypted — шифрование на уровне столбцов в SQL Server

Данные шифруются до отправки в SQL Server. Даже DBA видит только зашифрованные строки.

**Проблема:** не поддерживает `LIKE`, `ORDER BY`, `GROUP BY` по зашифрованным столбцам. Для медицинской системы, где нужен поиск по фамилии — неприемлемо для основных полей.

### Value Converter — шифрование на уровне приложения

```csharp
builder.Property(r => r.Diagnosis)
    .HasConversion(_encConverter);
```

EF Core шифрует перед записью, расшифровывает после чтения. Приложение работает с открытыми данными, БД хранит зашифрованные.

**Для каких полей:** для медицинских данных, по которым не нужен поиск (диагнозы в историческом хранении, СНИЛС для хранения без поиска).

**Для каких не подходит:** `LastName` — по нему нужен поиск `StartsWith`. Для таких полей либо храним хеш рядом с зашифрованным значением (для точного совпадения), либо используем поиск на уровне приложения (выгрузить и отфильтровать — дорого), либо принимаем, что DBA видит фамилии.

**Компромисс реального проекта:** шифруем то, что не нужно для поиска (диагнозы, медицинские заключения, паспортные данные). Фамилию и дату рождения — через права доступа на уровне SQL Server (Row-Level Security).

---

## Итоговая карта решений

| Решение | Альтернатива | Почему выбрали |
|---|---|---|
| Rich Domain Model | Anemic + Service | Логика домена в одном месте, невозможно нарушить бизнес-правило |
| `required` + `init` для справочников | `= null!` | Compile-time гарантия, нет лжи компилятору |
| `private set` для сущностей | `public set` | Инвариант только через методы домена |
| Value Objects (`FullName`) | Примитивные поля | Семантика, единое место форматирования, структурное равенство |
| `SaveChangesInterceptor` | Триггер БД | Тестируемость, видимость, независимость от СУБД |
| `IEntityTypeConfiguration<T>` | `OnModelCreating` | Один файл — одна ответственность, масштабируемость |
| `HashSet<T>` для коллекций | `List<T>` | Нет дублей при маппинге, O(1) поиск |
| `AsNoTracking` для чтения | По умолчанию (с трекингом) | -30% CPU, -50% памяти на read-heavy путях |
| `EF.CompileAsyncQuery` | Обычный LINQ | Устраняет разбор Expression Tree на горячих путях |
| `AsSplitQuery` | Один JOIN | Устраняет декартово произведение коллекций |
| `IExecutionStrategy.ExecuteAsync` | `BeginTransactionAsync` напрямую | Корректная работа retry без дублирования данных |
| Outbox Pattern | Прямой `mediator.Publish` | Гарантия доставки события при сбоях |
| `IsolationLevel.Snapshot` для отчётов | `READ COMMITTED` | Согласованные данные без блокировок |
| Testcontainers | In-Memory / SQLite | Реальная СУБД = реальные гарантии теста |
| JSON Columns для метаданных | Отдельная таблица / EAV | Нет миграций при изменении структуры метаданных |
| `HierarchyId` | Self-referencing FK + CTE | Эффективные запросы иерархии без рекурсии |
| `EncryptedStringConverter` | TDE / без шифрования | Защита ПД даже от администратора БД |
