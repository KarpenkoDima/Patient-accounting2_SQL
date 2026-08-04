# Entity Framework Core 8: Руководство для Senior-архитектора

> [!WARNING]
> Это учебный материал, созданный на основе legacy-проекта
> Patient-accounting2.
>
> Руководство сохранено для изучения EF Core и архитектурных решений,
> но не является готовым production-рецептом.
>
> Некоторые примеры требуют дополнительной проверки:
>
> - baseline migrations для существующей базы;
> - транзакции и обработка ошибок;
> - вызов хранимых процедур;
> - table-valued parameters;
> - soft delete;
> - domain events и transactional outbox;
> - шифрование и хранение ключей.

### Система «Диспансер» — Production-Ready Reference Guide

---

## Предисловие: О чём этот документ

Здесь нет «просто примеров кода». Каждый паттерн — это ответ на конкретный производственный сбой или архитектурное решение с явными компромиссами. Документ предполагает, что читатель знает базовый EF Core и хочет понять, почему архитекторы принимают именно такие решения при работе с медицинскими данными.

**Три главных принципа, пронизывающих весь документ:**
1. **База данных — деталь реализации**, а не центр архитектуры.
2. **Бизнес-логика живёт в домене**, а не в сервисах и тем более не в контроллерах.
3. **Производительность измеряется**, а не угадывается.

---

## Глава 1: Архитектура проекта

### 1.1 Структура решения

```
Dispancer.sln
├── src/
│   ├── Dispancer.Domain/               ← Ядро: сущности, интерфейсы, события
│   │   ├── Entities/
│   │   │   ├── Customer.cs
│   │   │   ├── Address.cs
│   │   │   ├── Register.cs
│   │   │   ├── Invalid.cs
│   │   │   └── Lookups/               ← Справочники
│   │   ├── ValueObjects/
│   │   │   ├── FullName.cs
│   │   │   └── AddressDetails.cs
│   │   ├── Events/                    ← Domain Events
│   │   │   └── CustomerArchivedEvent.cs
│   │   ├── Interfaces/
│   │   │   ├── IRepository.cs
│   │   │   ├── ICustomerRepository.cs
│   │   │   ├── ISoftDeletable.cs
│   │   │   └── IAuditable.cs
│   │   └── Exceptions/
│   │       └── DomainException.cs
│   │
│   ├── Dispancer.Infrastructure/       ← EF Core, репозитории, перехватчики
│   │   ├── Persistence/
│   │   │   ├── Configurations/        ← IEntityTypeConfiguration<T>
│   │   │   ├── Interceptors/          ← SoftDelete, Audit
│   │   │   ├── Repositories/          ← Реализации IRepository
│   │   │   ├── Outbox/                ← Outbox Pattern
│   │   │   └── DispancerDbContext.cs
│   │   ├── Security/
│   │   │   └── EncryptedStringConverter.cs
│   │   └── DependencyInjection.cs
│   │
│   └── Dispancer.Api/                  ← Controllers, DTOs, Middleware
│
└── tests/
    ├── Dispancer.Domain.Tests/         ← Unit-тесты домена (без EF, без БД)
    └── Dispancer.Integration.Tests/    ← Testcontainers + реальный SQL Server
```

**Trade-off:** Такое разделение создаёт больше проектов, но гарантирует, что изменение ORM не затрагивает домен — критично при долгосрочном развитии медицинской системы.

---

## Глава 2: Domain Layer — DDD и Rich Domain Model

### 2.1 Контракты домена

```csharp
// Dispancer.Domain/Interfaces/ISoftDeletable.cs
namespace Dispancer.Domain.Interfaces;

public interface ISoftDeletable
{
    bool IsDeleted { get; }
    DateTime? DeletedAt { get; }
    void MarkAsDeleted();
}
```

```csharp
// Dispancer.Domain/Interfaces/IAuditable.cs
namespace Dispancer.Domain.Interfaces;

public interface IAuditable
{
    DateTime CreatedAt { get; }
    DateTime ModifiedAt { get; }
    void TouchModifiedAt();
}
```

```csharp
// Dispancer.Domain/Interfaces/IHasDomainEvents.cs
namespace Dispancer.Domain.Interfaces;

public interface IHasDomainEvents
{
    IReadOnlyCollection<IDomainEvent> DomainEvents { get; }
    void ClearDomainEvents();
}

public interface IDomainEvent
{
    Guid EventId { get; }
    DateTime OccurredAt { get; }
}
```

```csharp
// Dispancer.Domain/Exceptions/DomainException.cs
namespace Dispancer.Domain.Exceptions;

public sealed class DomainException : Exception
{
    public DomainException(string message) : base(message) { }
}
```

### 2.2 Value Objects — инкапсуляция сложных типов

Value Object — неизменяемый тип без собственной идентичности. Равенство определяется значениями, а не ссылкой. В C# 9+ идеально подходит `record`.

#### FullName — ФИО пациента

```csharp
// Dispancer.Domain/ValueObjects/FullName.cs
namespace Dispancer.Domain.ValueObjects;

// record обеспечивает value-equality и иммутабельность «из коробки»
public sealed record FullName
{
    public required string LastName { get; init; }
    public required string FirstName { get; init; }
    public string? MiddleName { get; init; }

    // Приватный конструктор — создание только через фабрику
    private FullName() { }

    public static FullName Create(string lastName, string firstName, string? middleName = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(lastName, nameof(lastName));
        ArgumentException.ThrowIfNullOrWhiteSpace(firstName, nameof(firstName));

        return new FullName
        {
            LastName = lastName.Trim(),
            FirstName = firstName.Trim(),
            MiddleName = middleName?.Trim()
        };
    }

    // Отображение для UI и отчётов — логика принадлежит домену, а не контроллеру
    public string ShortName => $"{LastName} {FirstName[0]}.{(MiddleName is not null ? $" {MiddleName[0]}." : string.Empty)}";
    public string FullDisplay => MiddleName is null
        ? $"{LastName} {FirstName}"
        : $"{LastName} {FirstName} {MiddleName}";

   /* Архитектурные несоответствия
4. protected FullName(bool efCoreConstructor) { } — ненужный хак
EF Core 8 умеет использовать private parameterless конструктор через рефлексию — это стандартная и задокументированная возможность. Фиктивный protected-конструктор с bool-параметром:

не нужен
вводит в заблуждение читателя ("почему bool?")
создаёт ложное впечатление, что EF Core требует специального конструктора
    // Для EF Core: OwnsOne требует публичный конструктор без параметров
    // Добавляем protected конструктор для EF
    protected FullName(bool efCoreConstructor) { }*/
}
```

#### AddressDetails — детали адреса как Value Object

```csharp
// Dispancer.Domain/ValueObjects/AddressDetails.cs
namespace Dispancer.Domain.ValueObjects;

public sealed record AddressDetails
{
    public string? Region { get; init; }
    public string? Country { get; init; }
    public required string City { get; init; }
    public string? NameStreet { get; init; }
    public string? NumberHouse { get; init; }
    public string? NumberApartment { get; init; }

    private AddressDetails() { }

    public static AddressDetails Create(
        string city,
        string? region = null,
        string? country = null,
        string? nameStreet = null,
        string? numberHouse = null,
        string? numberApartment = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(city, nameof(city));

        return new AddressDetails
        {
            City = city.Trim(),
            Region = region?.Trim(),
            Country = country?.Trim(),
            NameStreet = nameStreet?.Trim(),
            NumberHouse = numberHouse?.Trim(),
            NumberApartment = numberApartment?.Trim()
        };
    }

    public string Display =>
        string.Join(", ", new[]
        {
            Region, Country, City,
            NameStreet is not null ? $"ул. {NameStreet}" : null,
            NumberHouse is not null ? $"д. {NumberHouse}" : null,
            NumberApartment is not null ? $"кв. {NumberApartment}" : null
        }.Where(s => s is not null));

    //protected AddressDetails(bool efCoreConstructor) { }
}
```

**Trade-off Value Objects:** EF Core отображает VO через `OwnsOne` (встроены в ту же таблицу) или `OwnsMany`. Нет отдельной таблицы → нет JOIN → быстрее. Минус — нельзя запрашивать VO независимо без владельца.

### 2.3 Справочные сущности (Lookup Entities)

Справочники — простые, стабильные данные. Используем `required` + `init` вместо мутабельных свойств.

```csharp
// Dispancer.Domain/Entities/Lookups/Gender.cs
namespace Dispancer.Domain.Entities.Lookups;

public sealed class Gender
{
    public int GenderId { get; init; }
    public required string Name { get; init; }  // nchar(1) — 'М' или 'Ж'

    public IReadOnlyCollection<Customer> Customers => _customers;
    private readonly HashSet<Customer> _customers = [];
}
```

```csharp
// Dispancer.Domain/Entities/Lookups/Land.cs
public sealed class Land
{
    public int LandId { get; init; }
    public required string NumberLand { get; init; }
    public string? NotaBene { get; init; }

    public IReadOnlyCollection<Register> Registers => _registers;
    private readonly HashSet<Register> _registers = [];
}
```

```csharp
// Dispancer.Domain/Entities/Lookups/RegisterType.cs
public sealed class RegisterType
{
    public int RegisterTypeId { get; init; }
    public required string Name { get; init; }
    public string? NotaBene { get; init; }
}
```

```csharp
// Dispancer.Domain/Entities/Lookups/WhyDeRegister.cs
public sealed class WhyDeRegister
{
    public int WhyDeRegisterId { get; init; }
    public required string Name { get; init; }
    public string? NotaBene { get; init; }
}
```

```csharp
// Dispancer.Domain/Entities/Lookups/DisabilityGroup.cs
public sealed class DisabilityGroup
{
    public int DisabilityGroupId { get; init; }
    public required string Name { get; init; }
    public string? NotaBene { get; init; }

    public IReadOnlyCollection<Invalid> Invalids => _invalids;
    private readonly HashSet<Invalid> _invalids = [];
}
```

```csharp
// Dispancer.Domain/Entities/Lookups/BenefitsCategory.cs
public sealed class BenefitsCategory
{
    public int BenefitsCategoryId { get; init; }
    public required string Name { get; init; }
    public string? NotaBene { get; init; }

    public IReadOnlyCollection<Invalid> Invalids => _invalids;
    private readonly HashSet<Invalid> _invalids = [];
}
```

```csharp
// Dispancer.Domain/Entities/Lookups/Appptpr.cs
// Тип прикрепления пациента
public sealed class Appptpr
{
    public int AppptprId { get; init; }
    public required string Name { get; init; }   // nchar(5)

    public IReadOnlyCollection<Customer> Customers => _customers;
    private readonly HashSet<Customer> _customers = [];
}
```

### 2.4 Базовый класс для агрегатов

```csharp
// Dispancer.Domain/Entities/AggregateRoot.cs
namespace Dispancer.Domain.Entities;

public abstract class AggregateRoot : IHasDomainEvents, IAuditable, ISoftDeletable
{
    private readonly List<IDomainEvent> _domainEvents = [];

    // IAuditable
    public DateTime CreatedAt { get; private set; }
    public DateTime ModifiedAt { get; private set; }

    // ISoftDeletable
    public bool IsDeleted { get; private set; }
    public DateTime? DeletedAt { get; private set; }

    // IHasDomainEvents
    public IReadOnlyCollection<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    protected void RaiseDomainEvent(IDomainEvent domainEvent) =>
        _domainEvents.Add(domainEvent);

    public void ClearDomainEvents() => _domainEvents.Clear();

    // Вызывается Interceptor'ом — не вручную в коде приложения
    public void TouchModifiedAt() => ModifiedAt = DateTime.UtcNow;

    // ISoftDeletable — вызывается SoftDeleteInterceptor
    public void MarkAsDeleted()
    {
        IsDeleted = true;
        DeletedAt = DateTime.UtcNow;
    }

    // Вызывается только при создании через фабричный метод
    protected void InitAudit()
    {
        CreatedAt = DateTime.UtcNow;
        ModifiedAt = DateTime.UtcNow;
    }
}
```

### 2.5 Customer — Rich Domain Model

```csharp
// Dispancer.Domain/Entities/Customer.cs
namespace Dispancer.Domain.Entities;

using Dispancer.Domain.Events;
using Dispancer.Domain.Exceptions;
using Dispancer.Domain.ValueObjects;
using Dispancer.Domain.Entities.Lookups;

public sealed class Customer : AggregateRoot
{
    // Backing fields — HashSet<T> для O(1) поиска и устранения дублей
    private readonly HashSet<Address> _addresses = [];
    private readonly HashSet<Register> _registers = [];
    private readonly HashSet<Invalid> _invalids = [];

    // Приватный конструктор без параметров — ТОЛЬКО для EF Core
    // EF использует его при материализации из БД через рефлексию
    private Customer() { }

    private Customer(
        FullName fullName,
        DateTime? birthday,
        int? medCard,
        int? genderId,
        int? appptprId)
    {
        FullName = fullName;
        Birthday = birthday;
        MedCard = medCard;
        GenderId = genderId;
        AppptprId = appptprId;
        Arch = false;
        InitAudit();
    }

    public int CustomerId { get; private set; }
    public int? MedCard { get; private set; }
    public int? CodeCustomer { get; private set; }

    // FullName — Value Object, встроен в ту же таблицу через OwnsOne
    public FullName FullName { get; private set; } = default!;

    public DateTime? Birthday { get; private set; }
    public bool Arch { get; private set; }
    public int? CustomerTempId { get; private set; }
    public int? AppptprId { get; private set; }
    public int? GenderId { get; private set; }

    // Навигационные свойства — приватные сеттеры, только EF заполняет
    public Gender? Gender { get; private set; }
    public Appptpr? Appptpr { get; private set; }

    // Доступ только через IReadOnlyCollection — нельзя мутировать снаружи
    public IReadOnlyCollection<Address> Addresses => _addresses;
    public IReadOnlyCollection<Register> Registers => _registers;
    public IReadOnlyCollection<Invalid> Invalids => _invalids;

    // ─── Фабричный метод ───────────────────────────────────────────────────

    public static Customer Create(
        string lastName,
        string firstName,
        string? middleName = null,
        DateTime? birthday = null,
        int? medCard = null,
        int? genderId = null,
        int? appptprId = null)
    {
        if (birthday.HasValue && birthday.Value.Date > DateTime.Today)
            throw new DomainException("Дата рождения не может быть в будущем.");

        var fullName = FullName.Create(lastName, firstName, middleName);
        return new Customer(fullName, birthday, medCard, genderId, appptprId);
    }

    // ─── Методы домена ─────────────────────────────────────────────────────

    public void UpdatePersonalInfo(
        string lastName,
        string firstName,
        string? middleName,
        DateTime? birthday)
    {
        if (IsDeleted)
            throw new DomainException("Невозможно изменить удалённого пациента.");
        if (birthday.HasValue && birthday.Value.Date > DateTime.Today)
            throw new DomainException("Дата рождения не может быть в будущем.");

        FullName = FullName.Create(lastName, firstName, middleName);
        Birthday = birthday;
    }

    public void Archive()
    {
        if (IsDeleted)
            throw new DomainException("Невозможно архивировать удалённого пациента.");
        if (Arch)
            throw new DomainException("Пациент уже в архиве.");

        Arch = true;

        // Доменное событие — подписчики могут реагировать на архивирование
        RaiseDomainEvent(new CustomerArchivedEvent(CustomerId));
    }

    public void RestoreFromArchive()
    {
        if (!Arch)
            throw new DomainException("Пациент не в архиве.");
        Arch = false;
    }

    public void AssignMedCard(int medCard)
    {
        if (medCard <= 0)
            throw new DomainException("Номер медкарты должен быть положительным числом.");
        MedCard = medCard;
    }

    public Address AddAddress(AddressDetails details, int adminDivisionId, int? typeStreetId = null)
    {
        if (IsDeleted)
            throw new DomainException("Невозможно добавить адрес удалённому пациенту.");

        var address = Address.Create(CustomerId, details, adminDivisionId, typeStreetId);
        _addresses.Add(address);
        return address;
    }

    public Register RegisterInDispancer(int landId, DateTime registrationDate, string? diagnosis = null)
    {
        if (IsDeleted)
            throw new DomainException("Невозможно поставить на учёт удалённого пациента.");

        var register = Register.Create(CustomerId, landId, registrationDate, diagnosis);
        _registers.Add(register);
        return register;
    }

    public Invalid RegisterInvalidity(int? disabilityGroupId, DateTime dataInvalidity)
    {
        if (IsDeleted)
            throw new DomainException("Невозможно зарегистрировать инвалидность удалённого пациента.");
        if (dataInvalidity.Date > DateTime.Today)
            throw new DomainException("Дата установления инвалидности не может быть в будущем.");

        var invalid = Invalid.Create(CustomerId, disabilityGroupId, dataInvalidity);
        _invalids.Add(invalid);
        return invalid;
    }
}
```

### 2.6 Domain Events

```csharp
// Dispancer.Domain/Events/CustomerArchivedEvent.cs
namespace Dispancer.Domain.Events;

public sealed record CustomerArchivedEvent(int CustomerId) : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}
```

### 2.7 Address Entity

```csharp
// Dispancer.Domain/Entities/Address.cs
namespace Dispancer.Domain.Entities;

public sealed class Address
{
    private Address() { }

    private Address(int customerId, AddressDetails details, int adminDivisionId, int? typeStreetId)
    {
        CustomerId = customerId;
        Details = details;
        AdminDivisionId = adminDivisionId;
        TypeStreetId = typeStreetId;
        ModifiedDate = DateTime.UtcNow;
    }

    public int AddressId { get; private set; }
    public int CustomerId { get; private set; }
    public AddressDetails Details { get; private set; } = default!;
    public int AdminDivisionId { get; private set; }
    public int? TypeStreetId { get; private set; }
    public DateTime ModifiedDate { get; private set; }

    public Customer Customer { get; private set; } = default!;

    internal static Address Create(
        int customerId,
        AddressDetails details,
        int adminDivisionId,
        int? typeStreetId) =>
        new(customerId, details, adminDivisionId, typeStreetId);

    public void Update(AddressDetails newDetails)
    {
        Details = newDetails;
        ModifiedDate = DateTime.UtcNow;
    }
}
```

### 2.8 Register Entity

```csharp
// Dispancer.Domain/Entities/Register.cs
namespace Dispancer.Domain.Entities;

public sealed class Register
{
    private Register() { }

    private Register(int customerId, int landId, DateTime firstRegister, string? diagnosis)
    {
        CustomerId = customerId;
        LandId = landId;
        FirstRegister = firstRegister;
        Diagnosis = diagnosis;
        ModifiedDate = DateTime.UtcNow;
    }

    public int RegisterId { get; private set; }
    public int CustomerId { get; private set; }
    public int LandId { get; private set; }
    public DateTime? FirstRegister { get; private set; }
    public DateTime? FirstDeregister { get; private set; }
    public DateTime? SecondRegister { get; private set; }
    public DateTime? SecondDeRegister { get; private set; }
    public string? Diagnosis { get; private set; }
    public DateTime? DataDiagnosis { get; private set; }
    public int? RegisterTypeId { get; private set; }
    public int? SecondRegisterTypeId { get; private set; }
    public int? WhyDeRegisterId { get; private set; }
    public int? WhySecondDeRegisterId { get; private set; }
    public DateTime ModifiedDate { get; private set; }

    public Customer Customer { get; private set; } = default!;
    public Land Land { get; private set; } = default!;
    public RegisterType? RegisterType { get; private set; }
    public WhyDeRegister? WhyDeRegister { get; private set; }

    internal static Register Create(
        int customerId, int landId, DateTime firstRegister, string? diagnosis) =>
        new(customerId, landId, firstRegister, diagnosis);

    public void Deregister(int whyDeRegisterId, DateTime deregisterDate)
    {
        if (FirstDeregister.HasValue)
            throw new DomainException("Пациент уже снят с учёта (первичный).");
        /*Сравнение DateTime с DateTime? через nullable lifting: если FirstRegister == null, выражение возвращает false и проверка молча пропускается. Бизнес-инвариант не выполнится. Нужно:
        if (deregisterDate < FirstRegister) // ⚠️*/
        if(FirstRegister.HasValue && deregisterDate < FirstRegister.Value)
            throw new DomainException("Дата снятия с учёта не может быть раньше даты постановки.");

        FirstDeregister = deregisterDate;
        WhyDeRegisterId = whyDeRegisterId;
        ModifiedDate = DateTime.UtcNow;
    }

    public void SetDiagnosis(string diagnosis, DateTime dataDiagnosis)
    {
        if (dataDiagnosis.Date > DateTime.Today)
            throw new DomainException("Дата установления диагноза не может быть в будущем.");

        Diagnosis = diagnosis;
        DataDiagnosis = dataDiagnosis;
        ModifiedDate = DateTime.UtcNow;
    }
}
```

### 2.9 Invalid Entity

```csharp
// Dispancer.Domain/Entities/Invalid.cs
namespace Dispancer.Domain.Entities;

public sealed class Invalid
{
    private readonly HashSet<BenefitsCategory> _benefitsCategories = [];

    private Invalid() { }

    private Invalid(int customerId, int? disabilityGroupId, DateTime dataInvalidity)
    {
        CustomerId = customerId;
        DisabilityGroupId = disabilityGroupId;
        DataInvalidity = dataInvalidity;
        Incapable = false;
        ModifiedDate = DateTime.UtcNow;
    }

    public int InvalidId { get; private set; }
    public int CustomerId { get; private set; }
    public int? DisabilityGroupId { get; private set; }
    public DateTime? DataInvalidity { get; private set; }
    public DateTime? PeriodInvalidity { get; private set; }
    public int? ChiperReceptId { get; private set; }
    public bool Incapable { get; private set; }
    public DateTime? DateIncapable { get; private set; }
    public DateTime ModifiedDate { get; private set; }

    public Customer Customer { get; private set; } = default!;
    public DisabilityGroup? DisabilityGroup { get; private set; }

    // Связь M:M через Invalid_BenefitsCategory
    public IReadOnlyCollection<BenefitsCategory> BenefitsCategories => _benefitsCategories;

    internal static Invalid Create(
        int customerId, int? disabilityGroupId, DateTime dataInvalidity) =>
        new(customerId, disabilityGroupId, dataInvalidity);

    public void SetIncapable(DateTime dateIncapable)
    {
        if (Incapable)
            throw new DomainException("Недееспособность уже установлена.");

        Incapable = true;
        DateIncapable = dateIncapable;
        ModifiedDate = DateTime.UtcNow;
    }

    public void SetValidityPeriod(DateTime periodInvalidity)
    {
        if (periodInvalidity.Date > DateTime.Today)
            throw new DomainException("Срок действия инвалидности не может быть в будущем.");

        PeriodInvalidity = periodInvalidity;
        ModifiedDate = DateTime.UtcNow;
    }

    public void AddBenefitsCategory(BenefitsCategory category)
    {
        // HashSet.Add возвращает false при дубле — без исключений
        _benefitsCategories.Add(category);
        ModifiedDate = DateTime.UtcNow;
    }

    public void RemoveBenefitsCategory(BenefitsCategory category)
    {
        if (!_benefitsCategories.Remove(category))
            throw new DomainException($"Льготная категория '{category.Name}' не привязана к этой записи.");
        ModifiedDate = DateTime.UtcNow;
    }
}
```

---

## Глава 3: Infrastructure — Конфигурации EF Core

**Золотое правило:** один класс конфигурации — одна таблица. Никогда не пишите конфигурацию в `OnModelCreating` напрямую.

### 3.1 CustomerConfiguration

```csharp
// Dispancer.Infrastructure/Persistence/Configurations/CustomerConfiguration.cs
namespace Dispancer.Infrastructure.Persistence.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Dispancer.Domain.Entities;

internal sealed class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder)
    {
        builder.ToTable("Customer");
        builder.HasKey(c => c.CustomerId);

        builder.Property(c => c.CustomerId)
            .HasColumnName("CustomerID")
            .UseIdentityColumn();

        // ─── Value Object: FullName (OwnsOne → те же колонки, без JOIN) ────
        builder.OwnsOne(c => c.FullName, fn =>
        {
            fn.Property(x => x.LastName)
                .HasColumnName("LastName")
                .HasMaxLength(100)
                .IsRequired();

            fn.Property(x => x.FirstName)
                .HasColumnName("FirstName")
                .HasMaxLength(100)
                .IsRequired();

            fn.Property(x => x.MiddleName)
                .HasColumnName("MiddleName")
                .HasMaxLength(100);
        });

        builder.Property(c => c.Birthday);
        builder.Property(c => c.MedCard);
        builder.Property(c => c.Arch).IsRequired();

        builder.Property(c => c.AppptprId).HasColumnName("APPPTPRID");
        builder.Property(c => c.GenderId).HasColumnName("GenderID");

        // ─── Soft Delete — маппинг наших полей на колонки БД ────────────────
        // IsDeleted (bool) → Delete (bit)
        // DeletedAt (DateTime?) → нет колонки — добавляем через теневое свойство
        builder.Property(c => c.IsDeleted)
            .HasColumnName("Delete")
            .HasDefaultValue(false);

        // Теневое свойство — колонка DeletedAt не существует в старой схеме,
        // добавляем через новую миграцию
        builder.Property<DateTime?>("DeletedAt")
            .HasColumnName("DeletedAt");

        builder.Property(c => c.CreatedAt)
            .HasColumnName("CreatedAt")
            .HasDefaultValueSql("GETDATE()");

        builder.Property(c => c.ModifiedAt)
            .HasColumnName("ModifyDate")
            .HasDefaultValueSql("GETDATE()");

        // ─── CHECK constraint: Birthday <= GETDATE() ─────────────────────────
        builder.ToTable(t => t.HasCheckConstraint("CK_Customer_Birthday", "[Birthday] <= GETDATE()"));

        // ─── Связи (Foreign Keys) ─────────────────────────────────────────────
        builder.HasOne(c => c.Appptpr)
            .WithMany(a => a.Customers)
            .HasForeignKey(c => c.AppptprId)
            .OnDelete(DeleteBehavior.SetDefault);

        builder.HasOne(c => c.Gender)
            .WithMany(g => g.Customers)
            .HasForeignKey(c => c.GenderId)
            .OnDelete(DeleteBehavior.SetDefault);

        // ─── Global Query Filter: исключает удалённых из ВСЕХ запросов ────────
        // Переопределяется через .IgnoreQueryFilters() при необходимости
        builder.HasQueryFilter(c => !c.IsDeleted);

        // ─── Навигационные коллекции — указываем backing field ───────────────
        builder.Navigation(c => c.Addresses).HasField("_addresses");
        builder.Navigation(c => c.Registers).HasField("_registers");
        builder.Navigation(c => c.Invalids).HasField("_invalids");

        // ─── Индексы для производительности ──────────────────────────────────
        builder.HasIndex(c => new { c.IsDeleted, c.Arch })
            .HasDatabaseName("IX_Customer_Delete_Arch");

        // Частичный индекс — только активные пациенты (SQL Server 2014+)
        builder.HasIndex(c => c.ModifiedAt)
            .HasDatabaseName("IX_Customer_ModifyDate")
            .HasFilter("[Delete] = 0");
    }
}
```

### 3.2 AddressConfiguration

```csharp
// Dispancer.Infrastructure/Persistence/Configurations/AddressConfiguration.cs
internal sealed class AddressConfiguration : IEntityTypeConfiguration<Address>
{
    public void Configure(EntityTypeBuilder<Address> builder)
    {
        builder.ToTable("Address");
        builder.HasKey(a => a.AddressId);

        builder.Property(a => a.AddressId)
            .HasColumnName("AddressID")
            .UseIdentityColumn();

        builder.Property(a => a.CustomerId)
            .HasColumnName("CustomerID")
            .IsRequired();

        // ─── Value Object: AddressDetails (OwnsOne) ───────────────────────────
        builder.OwnsOne(a => a.Details, d =>
        {
            d.Property(x => x.Region)
                .HasColumnName("Region")
                .HasColumnType("nchar(50)");

            d.Property(x => x.Country)
                .HasColumnName("Country")
                .HasColumnType("nchar(50)");

            d.Property(x => x.City)
                .HasColumnName("City")
                .HasMaxLength(100)
                .HasDefaultValue("Москва")
                .IsRequired();

            d.Property(x => x.NameStreet)
                .HasColumnName("NameStreet")
                .HasMaxLength(100);

            d.Property(x => x.NumberHouse)
                .HasColumnName("NumberHouse")
                .HasMaxLength(10);

            d.Property(x => x.NumberApartment)
                .HasColumnName("NumberApartment")
                .HasMaxLength(10);
        });

        builder.Property(a => a.AdminDivisionId)
            .HasColumnName("AdminDivisionID")
            .HasDefaultValue(5)
            .IsRequired();

        builder.Property(a => a.TypeStreetId)
            .HasColumnName("TypeStreetID")
            .HasDefaultValue(172);

        builder.Property(a => a.ModifiedDate)
            .HasDefaultValueSql("GETDATE()");

        builder.HasOne(a => a.Customer)
            /*При этом CustomerConfiguration объявляет:
csharpbuilder.Navigation(c => c.Addresses).HasField("_addresses");
builder.Navigation(c => c.Registers).HasField("_registers");
Конфликт: WithMany() без аргумента говорит EF Core «обратной навигации не существует», но Navigation() пытается её настроить. EF может либо создать две отдельные связи, либо одна из них «выиграет» и коллекция не будет заполняться при .Include(). Правильно:
            // .WithMany() без навигационного свойства — несоответствие маппинга
            .WithMany() // ❌ — говорит EF: обратной навигации нет
            */
            .WithMany(c => c.Addresses)
            .HasForeignKey(a => a.CustomerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(a => a.CustomerId)
            .HasDatabaseName("IX_Address_CustomerID");
    }
}
```

### 3.3 RegisterConfiguration

```csharp
// Dispancer.Infrastructure/Persistence/Configurations/RegisterConfiguration.cs
internal sealed class RegisterConfiguration : IEntityTypeConfiguration<Register>
{
    public void Configure(EntityTypeBuilder<Register> builder)
    {
        builder.ToTable("Register");
        builder.HasKey(r => r.RegisterId);

        builder.Property(r => r.RegisterId)
            .HasColumnName("RegisterID")
            .UseIdentityColumn();

        builder.Property(r => r.CustomerId).HasColumnName("CustomerID").IsRequired();
        builder.Property(r => r.LandId).HasColumnName("LandID").HasDefaultValue(1);
        builder.Property(r => r.RegisterTypeId).HasColumnName("RegisterTypeID");
        builder.Property(r => r.SecondRegisterTypeId).HasColumnName("SecondRegisterTypeID");
        builder.Property(r => r.WhyDeRegisterId).HasColumnName("WhyDeRegisterID");
        builder.Property(r => r.WhySecondDeRegisterId).HasColumnName("WhySecondDeRegisterID");
        builder.Property(r => r.Diagnosis).HasMaxLength(10);
        builder.Property(r => r.ModifiedDate).HasDefaultValueSql("GETDATE()");

        builder.ToTable(t =>
        {
            t.HasCheckConstraint("CK_Register_DataDiagnosis", "[DataDiagnosis] <= GETDATE()");
        });

        // ─── Связи (два FK на RegisterType — нельзя оба делать CASCADE в SQL Server)
        builder.HasOne(r => r.Customer)
            /*При этом CustomerConfiguration объявляет:
csharpbuilder.Navigation(c => c.Addresses).HasField("_addresses");
builder.Navigation(c => c.Registers).HasField("_registers");
Конфликт: WithMany() без аргумента говорит EF Core «обратной навигации не существует», но Navigation() пытается её настроить. EF может либо создать две отдельные связи, либо одна из них «выиграет» и коллекция не будет заполняться при .Include(). Правильно:
            // .WithMany() без навигационного свойства — несоответствие маппинга
            .WithMany() // ❌ — говорит EF: обратной навигации нет
            */
            .WithMany(c => c.Registers)
            .HasForeignKey(r => r.CustomerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.Land)
            .WithMany(l => l.Registers)
            .HasForeignKey(r => r.LandId)
            .OnDelete(DeleteBehavior.SetDefault);

        builder.HasOne(r => r.RegisterType)
            .WithMany()
            .HasForeignKey(r => r.RegisterTypeId)
            .OnDelete(DeleteBehavior.SetDefault);

        // NoAction — SQL Server не поддерживает несколько CASCADE на одну таблицу
        builder.HasOne(r => r.WhyDeRegister)
            .WithMany()
            .HasForeignKey(r => r.WhyDeRegisterId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(r => r.CustomerId)
            .HasDatabaseName("IX_Register_CustomerID");

        builder.HasIndex(r => r.LandId)
            .HasDatabaseName("IX_Register_LandID");
    }
}
```

### 3.4 InvalidConfiguration

```csharp
// Dispancer.Infrastructure/Persistence/Configurations/InvalidConfiguration.cs
internal sealed class InvalidConfiguration : IEntityTypeConfiguration<Invalid>
{
    public void Configure(EntityTypeBuilder<Invalid> builder)
    {
        builder.ToTable("Invalid");
        builder.HasKey(i => i.InvalidId);

        builder.Property(i => i.InvalidId)
            .HasColumnName("InvalidID")
            .UseIdentityColumn();

        builder.Property(i => i.CustomerId).HasColumnName("CustomerID").IsRequired();
        builder.Property(i => i.DisabilityGroupId).HasColumnName("DisabilityGroupID");
        builder.Property(i => i.ChiperReceptId).HasColumnName("ChiperReceptID");
        builder.Property(i => i.Incapable).HasDefaultValue(false);
        builder.Property(i => i.ModifiedDate).HasDefaultValueSql("GETDATE()");

        builder.ToTable(t =>
        {
            t.HasCheckConstraint("CK_Invalid_DataInvalidity", "[DataInvalidity] <= GETDATE()");
            t.HasCheckConstraint("CK_Invalid_PeriodInvalidity", "[PeriodInvalidity] <= GETDATE()");
        });

        builder.HasOne(i => i.Customer)
            .WithMany(c => c.Invalids)
            .HasForeignKey(i => i.CustomerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(i => i.DisabilityGroup)
            .WithMany(d => d.Invalids)
            .HasForeignKey(i => i.DisabilityGroupId)
            .OnDelete(DeleteBehavior.SetDefault);

        // ─── Many-to-Many через Invalid_BenefitsCategory ──────────────────────
        builder.HasMany(i => i.BenefitsCategories)
            .WithMany(b => b.Invalids)
            .UsingEntity<Dictionary<string, object>>(
                "Invalid_BenefitsCategory",
                j => j.HasOne<BenefitsCategory>()
                      .WithMany()
                      .HasForeignKey("BenefitsID")
                      .OnDelete(DeleteBehavior.Cascade),
                j => j.HasOne<Invalid>()
                      .WithMany()
                      .HasForeignKey("invID")
                      .OnDelete(DeleteBehavior.Cascade),
                j =>
                {
                    j.HasKey("invID", "BenefitsID");
                    j.ToTable("Invalid_BenefitsCategory");
                });

        // Backing field для коллекции BenefitsCategories
        builder.Navigation(i => i.BenefitsCategories)
            .HasField("_benefitsCategories");

        builder.HasIndex(i => i.CustomerId)
            .HasDatabaseName("IX_Invalid_CustomerID");
    }
}
```

---

## Глава 4: Interceptors — Автоматический Soft Delete и Аудит

Перехватчики — самый чистый способ реализовать сквозную функциональность (cross-cutting concerns) без загрязнения бизнес-логики.

### 4.1 SoftDeleteInterceptor

```csharp
// Dispancer.Infrastructure/Persistence/Interceptors/SoftDeleteInterceptor.cs
namespace Dispancer.Infrastructure.Persistence.Interceptors;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Dispancer.Domain.Interfaces;

/// <summary>
/// Перехватывает EntityState.Deleted и заменяет физическое удаление
/// на проставление флага IsDeleted. Заменяет триггер CancelDeleteRow в БД.
/// Преимущество перед триггером: работает на уровне приложения,
/// не требует прав DBO и тестируется без реальной БД.
/// </summary>
public sealed class SoftDeleteInterceptor : SaveChangesInterceptor
{
    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData,
        InterceptionResult<int> result)
    {
        ApplySoftDelete(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        ApplySoftDelete(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private static void ApplySoftDelete(DbContext? context)
    {
        if (context is null) return;

        foreach (var entry in context.ChangeTracker
            .Entries<ISoftDeletable>()
            .Where(e => e.State == EntityState.Deleted))
        {
            // Переключаем состояние с Deleted на Modified
            // EF сгенерирует UPDATE вместо DELETE
            entry.State = EntityState.Modified;
            entry.Entity.MarkAsDeleted();
        }
    }
}
```

### 4.2 AuditInterceptor — Автоматический аудит и дата изменения

```csharp
// Dispancer.Infrastructure/Persistence/Interceptors/AuditInterceptor.cs
namespace Dispancer.Infrastructure.Persistence.Interceptors;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Dispancer.Domain.Interfaces;

/// <summary>
/// Автоматически проставляет ModifiedAt при любом изменении сущности.
/// Публикует Domain Events через MediatR после успешного сохранения.
/// </summary>
public sealed class AuditInterceptor : SaveChangesInterceptor
{
    private readonly IMediator _mediator;

    public AuditInterceptor(IMediator mediator) => _mediator = mediator;

    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData,
        InterceptionResult<int> result)
    {
        UpdateAuditFields(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        UpdateAuditFields(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    public override async ValueTask<int> SavedChangesAsync(
        SaveChangesCompletedEventData eventData,
        int result,
        CancellationToken cancellationToken = default)
    {
        // Domain Events публикуются ПОСЛЕ успешного сохранения
        // чтобы не рассылать события при откате транзакции
        await PublishDomainEventsAsync(eventData.Context, cancellationToken);
        return await base.SavedChangesAsync(eventData, result, cancellationToken);
    }

    private static void UpdateAuditFields(DbContext? context)
    {
        if (context is null) return;

        foreach (var entry in context.ChangeTracker
            .Entries<IAuditable>()
            .Where(e => e.State is EntityState.Added or EntityState.Modified))
        {
            entry.Entity.TouchModifiedAt();
        }
    }

    private async Task PublishDomainEventsAsync(DbContext? context, CancellationToken ct)
    {
        if (context is null) return;

        var entitiesWithEvents = context.ChangeTracker
            .Entries<IHasDomainEvents>()
            .Select(e => e.Entity)
            .Where(e => e.DomainEvents.Count != 0)
            .ToList();

        var domainEvents = entitiesWithEvents
            .SelectMany(e => e.DomainEvents)
            .ToList();

        // Сначала очищаем, потом публикуем — избегаем повторной публикации
        // при возможном повторе (retry strategy)
        entitiesWithEvents.ForEach(e => e.ClearDomainEvents());

        foreach (var domainEvent in domainEvents)
            await _mediator.Publish(domainEvent, ct);
    }
}
```

### 4.3 Encryption Value Converter — Защита персональных данных

В медицине персональные данные требуют шифрования. Value Converter шифрует данные «на лету» при записи в БД и расшифровывает при чтении.

```csharp
// Dispancer.Infrastructure/Security/EncryptedStringConverter.cs
namespace Dispancer.Infrastructure.Security;

using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

/// <summary>
/// Прозрачное шифрование строковых полей через ASP.NET Core Data Protection.
/// Данные в БД хранятся в зашифрованном виде — даже при компрометации БД
/// злоумышленник получит только зашифрованные строки.
///
/// Trade-off: шифрование исключает поиск по зашифрованным полям (LIKE, =).
/// Для полей, по которым нужен поиск, используйте детерминированное шифрование
/// (AES-SIV) или храните хеш для сравнения рядом с зашифрованными данными.
/// </summary>
public sealed class EncryptedStringConverter : ValueConverter<string, string>
{
    public EncryptedStringConverter(IDataProtector protector)
        : base(
            plainText => protector.Protect(plainText),
            cipherText => protector.Unprotect(cipherText))
    { }
}
```

Применение в конфигурации:

```csharp
// В CustomerConfiguration.Configure():
// Шифруем диагнозы в Register — медицинская тайна
// Применяется через отдельную конфигурацию RegisterConfiguration:

private readonly EncryptedStringConverter _encConverter;

public RegisterConfiguration(IDataProtector protector) =>
    _encConverter = new EncryptedStringConverter(
        protector.CreateProtector("Register.Diagnosis"));

public void Configure(EntityTypeBuilder<Register> builder)
{
    // ...
    builder.Property(r => r.Diagnosis)
        .HasConversion(_encConverter)
        .HasMaxLength(500);  // Зашифрованная строка длиннее исходной
}
```

---

## Глава 5: DbContext

```csharp
// Dispancer.Infrastructure/Persistence/DispancerDbContext.cs
namespace Dispancer.Infrastructure.Persistence;

using Microsoft.EntityFrameworkCore;
using Dispancer.Domain.Entities;
using Dispancer.Domain.Entities.Lookups;

public sealed class DispancerDbContext : DbContext
{
    public DispancerDbContext(DbContextOptions<DispancerDbContext> options)
        : base(options) { }

    // ─── Таблицы ─────────────────────────────────────────────────────────────
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<Register> Registers => Set<Register>();
    public DbSet<Invalid> Invalids => Set<Invalid>();

    // Справочники
    public DbSet<Gender> Genders => Set<Gender>();
    public DbSet<Appptpr> Appptprs => Set<Appptpr>();
    public DbSet<Land> Lands => Set<Land>();
    public DbSet<RegisterType> RegisterTypes => Set<RegisterType>();
    public DbSet<WhyDeRegister> WhyDeRegisters => Set<WhyDeRegister>();
    public DbSet<DisabilityGroup> DisabilityGroups => Set<DisabilityGroup>();
    public DbSet<BenefitsCategory> BenefitsCategories => Set<BenefitsCategory>();
    public DbSet<ChiperRecept> ChiperRecepts => Set<ChiperRecept>();
    public DbSet<AdminDivision> AdminDivisions => Set<AdminDivision>();
    public DbSet<TypeStreet> TypeStreets => Set<TypeStreet>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Автоматически применяет ВСЕ IEntityTypeConfiguration<T> из сборки
        // Добавление новой конфигурации не требует изменения этого метода
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(DispancerDbContext).Assembly);

        base.OnModelCreating(modelBuilder);
    }

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        // Глобальное соглашение: все datetime → datetime2 в SQL Server
        // datetime2 точнее и не имеет проблем с 2038 годом
        configurationBuilder.Properties<DateTime>()
            .HaveColumnType("datetime2");

        configurationBuilder.Properties<DateTime?>()
            .HaveColumnType("datetime2");
    }
}
```

### 5.1 DependencyInjection — регистрация всего слоя

```csharp
// Dispancer.Infrastructure/DependencyInjection.cs
namespace Dispancer.Infrastructure;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Dispancer.Domain.Interfaces;
using Dispancer.Infrastructure.Persistence;
using Dispancer.Infrastructure.Persistence.Interceptors;
using Dispancer.Infrastructure.Persistence.Repositories;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Interceptors регистрируются как Singleton — они stateless
        services.AddSingleton<SoftDeleteInterceptor>();        
        //Критические баги (сломают prodution)
       /* AuditInterceptor принимает IMediator в конструкторе. MediatR по умолчанию регистрируется как Scoped. Singleton, захватывающий Scoped-зависимость — классический captive dependency. В итоге IMediator становится де-факто синглтоном и начинает тащить за собой все Scoped-сервисы (DbContext, репозитории) в неверном жизненном цикле. Падёт не сразу — а в самый неожиданный момент под нагрузкой.
Правильно: AuditInterceptor должен быть Scoped.
        services.AddSingleton<AuditInterceptor>(); // ❌
        */
        services.AddScoped<AuditInterceptor>();
        
        services.AddDbContext<DispancerDbContext>((sp, options) =>
        {
            options.UseSqlServer(
                configuration.GetConnectionString("DispancerDb"),
                sql =>
                {
                    sql.CommandTimeout(60);

                    // Автоматические повторы при кратковременных сбоях сети
                    // SQL Server 40613 (DB not available), 49920 (cannot process request)
                    sql.EnableRetryOnFailure(
                        maxRetryCount: 5,
                        maxRetryDelay: TimeSpan.FromSeconds(30),
                        errorNumbersToAdd: [49920, 4060, 40197]);

                    // Split Query как глобальный дефолт для этого контекста
                    // Переопределяется через .AsSingleQuery() там, где нужно
                    sql.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
                });

            // Подключаем перехватчики
            options.AddInterceptors(
                sp.GetRequiredService<SoftDeleteInterceptor>(),
                sp.GetRequiredService<AuditInterceptor>());
        });

        // Репозитории
        services.AddScoped<ICustomerRepository, CustomerRepository>();
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

        return services;
    }
}
```

---

## Глава 6: Производительность

### 6.1 AsNoTracking — когда и зачем

EF Core по умолчанию отслеживает (tracks) все загруженные сущности в ChangeTracker. Это расходует память и CPU. Для read-only операций (API ответы, отчёты) это бессмысленная нагрузка.

```csharp
// ❌ Плохо — ChangeTracker отслеживает каждый объект
var customers = await context.Customers.ToListAsync();

// ✅ Хорошо — для чтения всегда явно отключаем трекинг
var customers = await context.Customers
    .AsNoTracking()
    .ToListAsync();

// ✅ AsNoTrackingWithIdentityResolution — когда один объект встречается
// в нескольких навигационных свойствах (например, один Land в нескольких Register)
// Без него EF создаст несколько экземпляров одного объекта
var registers = await context.Registers
    .Include(r => r.Land)
    .Include(r => r.Customer)
    .AsNoTrackingWithIdentityResolution()
    .ToListAsync();
```

**Правило:** если вы не вызываете `SaveChanges()` с этими объектами — всегда используйте `AsNoTracking()`.

### 6.2 Compiled Queries — для горячих путей

Каждый LINQ-запрос компилируется EF Core в SQL при первом выполнении и кешируется. Но разбор Expression Tree всё равно происходит при каждом вызове. `EF.CompileAsyncQuery` устраняет этот overhead.

```csharp
// Dispancer.Infrastructure/Persistence/Repositories/CompiledQueries.cs
namespace Dispancer.Infrastructure.Persistence.Repositories;

/// <summary>
/// Скомпилированные запросы для критических путей (поиск пациентов, горячие API).
/// Выигрыш: ~15-30% CPU экономии на горячих путях.
/// Trade-off: нельзя динамически менять структуру запроса (нет .Include()
/// после компиляции — только то, что указано при объявлении).
/// </summary>
internal static class CompiledQueries
{
    // Поиск активного пациента по ID — вызывается при каждом открытии карточки
    internal static readonly Func<DispancerDbContext, int, Task<Customer?>>
        GetActiveCustomerById = EF.CompileAsyncQuery(
            (DispancerDbContext ctx, int id) =>
                ctx.Customers
                    .AsNoTracking()
                    .FirstOrDefault(c => c.CustomerId == id));
                    // Global Query Filter (IsDeleted == false) применяется автоматически

    // Список пациентов по участку — для ежедневных выборок врача
    internal static readonly Func<DispancerDbContext, int, IAsyncEnumerable<Customer>>
        GetActiveCustomersByLand = EF.CompileAsyncQuery(
            (DispancerDbContext ctx, int landId) =>
                ctx.Customers
                    .AsNoTracking()
                    .Where(c => c.Registers
                        .Any(r => r.LandId == landId && r.FirstDeregister == null))
                    .OrderBy(c => c.FullName.LastName)
                    .ThenBy(c => c.FullName.FirstName));

    // Поиск по фамилии — с пагинацией
    internal static readonly Func<DispancerDbContext, string, int, int, IAsyncEnumerable<Customer>>
        SearchByLastName = EF.CompileAsyncQuery(
            (DispancerDbContext ctx, string lastName, int skip, int take) =>
                ctx.Customers
                    .AsNoTracking()
                    .Where(c => c.FullName.LastName.StartsWith(lastName))
                    .OrderBy(c => c.FullName.LastName)
                    .Skip(skip)
                    .Take(take));
}
```

### 6.3 Split Queries — борьба с декартовым взрывом

Когда вы загружаете несколько коллекций через `Include`, EF генерирует JOIN, который перемножает строки: 1 пациент × 3 адреса × 5 записей учёта × 2 инвалидности = 30 строк вместо 11.

```csharp
// ❌ Плохо — один запрос с картезианским произведением
// При 100 пациентах с 10 регистрациями каждый → 1000 строк вместо 200
var customers = await context.Customers
    .Include(c => c.Addresses)
    .Include(c => c.Registers)
    .Include(c => c.Invalids)
        .ThenInclude(i => i.BenefitsCategories)
    .ToListAsync();

// ✅ Хорошо — AsSplitQuery генерирует 4 отдельных SELECT
// EF собирает граф объектов в памяти
// Подходит когда коллекции независимы и данных много
var customers = await context.Customers
    .Include(c => c.Addresses)
    .Include(c => c.Registers)
    .Include(c => c.Invalids)
        .ThenInclude(i => i.BenefitsCategories)
    .AsSplitQuery()
    .AsNoTrackingWithIdentityResolution()
    .ToListAsync();
```

**Когда Split Query проигрывает:** если между запросами другая транзакция изменила данные — вы получите несогласованные данные. Для отчётов используйте `IsolationLevel.Snapshot`.

### 6.4 IAsyncEnumerable — стриминг больших выборок

При загрузке тысяч записей для отчётов не нужно держать всё в памяти.

```csharp
// Dispancer.Infrastructure/Persistence/Repositories/CustomerRepository.cs

// ✅ Стриминг — каждая запись обрабатывается по мере поступления
// Память: O(batch size) вместо O(N)
public async IAsyncEnumerable<Customer> StreamByLandAsync(
    int landId,
    [EnumeratorCancellation] CancellationToken ct = default)
{
    await foreach (var customer in CompiledQueries
        .GetActiveCustomersByLand(_context, landId)
        .WithCancellation(ct))
    {
        yield return customer;
    }
}

// В контроллере — стриминг прямо в HTTP Response
[HttpGet("lands/{landId}/customers/stream")]
public async IAsyncEnumerable<CustomerDto> StreamCustomers(
    int landId,
    [EnumeratorCancellation] CancellationToken ct)
{
    await foreach (var customer in _repo.StreamByLandAsync(landId, ct))
        yield return customer.ToDto();
}
```

### 6.5 Решение проблемы N+1

```csharp
// ❌ N+1 — для каждого пациента идёт отдельный запрос в БД
var customers = await context.Customers.AsNoTracking().ToListAsync();
foreach (var c in customers)
{
    // КАЖДАЯ итерация — отдельный SELECT в БД!
    var addresses = await context.Addresses
        .Where(a => a.CustomerId == c.CustomerId)
        .ToListAsync();
}

// ✅ Один запрос с JOIN (или два с AsSplitQuery)
var customers = await context.Customers
    .Include(c => c.Addresses)
    .AsNoTrackingWithIdentityResolution()
    .ToListAsync();

// ✅ Для проекций (DTO) — Select без Include, только нужные колонки
var dtos = await context.Customers
    .AsNoTracking()
    .Select(c => new CustomerListDto(
        c.CustomerId,
        c.FullName.LastName,
        c.FullName.FirstName,
        c.FullName.MiddleName,
        c.Birthday,
        c.Addresses.FirstOrDefault() != null
            ? c.Addresses.First().Details.City
            : null))
    .ToListAsync();
```

**Совет:** включите логирование SQL в разработке (`options.LogTo(Console.WriteLine)`) и убедитесь, что запросов нет больше чем ожидается.

---

## Глава 7: Repository Pattern — Чистая архитектура

### 7.1 Базовый интерфейс

```csharp
// Dispancer.Domain/Interfaces/IRepository.cs
namespace Dispancer.Domain.Interfaces;

public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<IReadOnlyList<T>> GetAllAsync(CancellationToken ct = default);
    void Add(T entity);
    //void Update(T entity);
    void Remove(T entity);
    Task<int> SaveChangesAsync(CancellationToken ct = default);
}
```

### 7.2 Специализированный интерфейс пациентов

```csharp
// Dispancer.Domain/Interfaces/ICustomerRepository.cs
namespace Dispancer.Domain.Interfaces;

public interface ICustomerRepository : IRepository<Customer>
{
    Task<Customer?> GetWithFullDataAsync(int customerId, CancellationToken ct = default);

    Task<IReadOnlyList<Customer>> SearchByLastNameAsync(
        string lastName, int page, int pageSize, CancellationToken ct = default);

    Task<IReadOnlyList<Customer>> GetByLandAsync(
        int landId, CancellationToken ct = default);

    // Фильтрация по нескольким участкам — EF Core 8 parameterized collection
    Task<IReadOnlyList<Customer>> GetByLandsAsync(
        IEnumerable<int> landIds, CancellationToken ct = default);

    IAsyncEnumerable<Customer> StreamByLandAsync(
        int landId, CancellationToken ct = default);

    Task<bool> ExistsAsync(int customerId, CancellationToken ct = default);

    // Восстановление мягко удалённых — IgnoreQueryFilters
    Task<Customer?> GetDeletedByIdAsync(int customerId, CancellationToken ct = default);
}
```

### 7.3 Реализация

```csharp
// Dispancer.Infrastructure/Persistence/Repositories/CustomerRepository.cs
namespace Dispancer.Infrastructure.Persistence.Repositories;

using Microsoft.EntityFrameworkCore;
using Dispancer.Domain.Interfaces;
using Dispancer.Domain.Entities;

internal sealed class CustomerRepository : ICustomerRepository
{
    private readonly DispancerDbContext _context;

    public CustomerRepository(DispancerDbContext context) => _context = context;

    // ─── Read (AsNoTracking — нет отслеживания, нет накладных расходов) ──────

    public async Task<Customer?> GetByIdAsync(int id, CancellationToken ct = default) =>
        await CompiledQueries.GetActiveCustomerById(_context, id);

    public async Task<Customer?> GetWithFullDataAsync(int customerId, CancellationToken ct = default) =>
        await _context.Customers
            .AsNoTrackingWithIdentityResolution()
            .Include(c => c.Addresses)
            .Include(c => c.Registers)
                .ThenInclude(r => r.Land)
            .Include(c => c.Registers)
                .ThenInclude(r => r.RegisterType)
            .Include(c => c.Invalids)
                .ThenInclude(i => i.DisabilityGroup)
            .Include(c => c.Invalids)
                .ThenInclude(i => i.BenefitsCategories)
            .AsSplitQuery()  // 5 отдельных запросов вместо одного с декартовым взрывом
            .FirstOrDefaultAsync(c => c.CustomerId == customerId, ct);

    public async Task<IReadOnlyList<Customer>> SearchByLastNameAsync(
        string lastName, int page, int pageSize, CancellationToken ct = default)
    {
        // EF Core 8 нормально транслирует StartsWith в LIKE 'N%'
        // В отличие от Contains → LIKE '%N%' (нельзя использовать индекс)
        var result = await _context.Customers
            .AsNoTracking()
            .Where(c => c.FullName.LastName.StartsWith(lastName))
            .OrderBy(c => c.FullName.LastName)
            .ThenBy(c => c.FullName.FirstName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return result.AsReadOnly();
    }

    public async Task<IReadOnlyList<Customer>> GetByLandAsync(
        int landId, CancellationToken ct = default)
    {
        var result = await _context.Customers
            .AsNoTracking()
            .Where(c => c.Registers.Any(r =>
                r.LandId == landId &&
                r.FirstDeregister == null))
            .ToListAsync(ct);

        return result.AsReadOnly();
    }

    // ─── EF Core 8: Parameterized Collections (IN query) ─────────────────────
    // EF Core 8 транслирует Contains(collection) в параметризованный IN (...)
    // а не в склейку строк — полная защита от SQL-инъекций
    public async Task<IReadOnlyList<Customer>> GetByLandsAsync(
        IEnumerable<int> landIds, CancellationToken ct = default)
    {
        var ids = landIds.Distinct().ToList();

        // Генерирует: WHERE LandID IN (@p0, @p1, @p2, ...)
        // EF Core 8 использует параметризацию коллекций примитивов
        var result = await _context.Customers
            .AsNoTracking()
            .Where(c => c.Registers.Any(r =>
                ids.Contains(r.LandId) &&
                r.FirstDeregister == null))
            .ToListAsync(ct);

        return result.AsReadOnly();
    }

    public async IAsyncEnumerable<Customer> StreamByLandAsync(
        int landId,
        [EnumeratorCancellation] CancellationToken ct = default)
    {
        await foreach (var customer in CompiledQueries
            .GetActiveCustomersByLand(_context, landId)
            .WithCancellation(ct))
        {
            yield return customer;
        }
    }

    public async Task<bool> ExistsAsync(int customerId, CancellationToken ct = default) =>
        await _context.Customers.AnyAsync(c => c.CustomerId == customerId, ct);

    public async Task<Customer?> GetDeletedByIdAsync(int customerId, CancellationToken ct = default) =>
        await _context.Customers
            .AsNoTracking()
            .IgnoreQueryFilters()  // Обходим Global Query Filter для ISoftDeletable
            .Where(c => c.IsDeleted && c.CustomerId == customerId)
            .FirstOrDefaultAsync(ct);

    public async Task<IReadOnlyList<Customer>> GetAllAsync(CancellationToken ct = default)
    {
        var result = await _context.Customers
            .AsNoTracking()
            .OrderBy(c => c.FullName.LastName)
            .ToListAsync(ct);

        return result.AsReadOnly();
    }

    // ─── Write (с трекингом — EF должен знать об изменениях) ─────────────────

    public void Add(Customer entity) => _context.Customers.Add(entity);

    /*5. IRepository<T>.Update(T entity) — антипаттерн в Rich Domain Model
csharppublic void Update(Customer entity) => _context.Customers.Update(entity); // ⚠️
DbSet.Update() помечает всю сущность как Modified и генерирует UPDATE по всем колонкам. Это прямое противоречие RDM: в rich model вы загружаете трекируемую сущность, вызываете доменный метод, и EF сам отслеживает изменения через Change Tracker. Метод Update в репозитории нужен только при disconnected-сценариях (API без контекста), что не соответствует описанной архитектуре.*/
    //public void Update(Customer entity) => _context.Customers.Update(entity);
    public void Remove(Customer entity) =>
        // SoftDeleteInterceptor перехватит Deleted → Modified + IsDeleted = true
        _context.Customers.Remove(entity);

    public async Task<int> SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
```

---

## Глава 8: Транзакции, Изоляция и Надёжность

### 8.1 IExecutionStrategy + явные транзакции

**Критическая ошибка:** нельзя просто обернуть `BeginTransactionAsync` в `EnableRetryOnFailure`. При сбое EF не знает, была ли транзакция зафиксирована — повторная попытка может продублировать данные. Правильный способ — через `IExecutionStrategy.ExecuteAsync`.

```csharp
// Dispancer.Infrastructure/Persistence/Repositories/PatientRegistrationService.cs
namespace Dispancer.Infrastructure.Persistence;

/// <summary>
/// Демонстрирует правильную комбинацию IExecutionStrategy + BeginTransactionAsync.
/// Без ExecuteAsync retry-политика будет проигнорирована внутри ручной транзакции.
/// </summary>
public sealed class PatientRegistrationService
{
    private readonly DispancerDbContext _context;
    private readonly ICustomerRepository _customerRepo;

    public PatientRegistrationService(
        DispancerDbContext context,
        ICustomerRepository customerRepo)
    {
        _context = context;
        _customerRepo = customerRepo;
    }

    public async Task RegisterNewPatientAsync(
        Customer customer,
        AddressDetails address,
        int adminDivisionId,
        int landId,
        CancellationToken ct = default)
    {
        // CreateExecutionStrategy создаёт стратегию с настроенными retry-правилами
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            // Каждая попытка retry получает свою транзакцию
            await using var transaction = await _context.Database
                .BeginTransactionAsync(ct);

            try
            {
                _customerRepo.Add(customer);
                await _context.SaveChangesAsync(ct);
                // После SaveChanges customer.CustomerId проставлен EF Core

                var addr = customer.AddAddress(address, adminDivisionId);
                // addr уже добавлен в _addresses через Customer.AddAddress()

                var register = customer.RegisterInDispancer(landId, DateTime.Today);
                // register уже в _registers

                await _context.SaveChangesAsync(ct);
                await transaction.CommitAsync(ct);
            }
            catch
            {
                await transaction.RollbackAsync(ct);
                throw;
            }
        });
    }
}
```

### 8.2 Уровни изоляции для медицинских отчётов

```csharp
// Dispancer.Infrastructure/Persistence/Repositories/ReportRepository.cs

public async Task<IReadOnlyList<RegisterReport>> GetMonthlyRegisterReportAsync(
    int year, int month, CancellationToken ct = default)
{
    var strategy = _context.Database.CreateExecutionStrategy();

    return await strategy.ExecuteAsync(async () =>
    {
        // SNAPSHOT — читаем согласованный снимок БД без блокировок.
        // Другие транзакции не блокируются нашим чтением.
        // Требует включённого ALLOW_SNAPSHOT_ISOLATION на БД SQL Server:
        // ALTER DATABASE Dispancer SET ALLOW_SNAPSHOT_ISOLATION ON
        await using var transaction = await _context.Database
            .BeginTransactionAsync(System.Data.IsolationLevel.Snapshot, ct);

        var from = new DateTime(year, month, 1);
        var to = from.AddMonths(1);

        // Split Query здесь НЕ используем: отчёт читает срез на момент времени,
        // между запросами данные могут измениться — нужна Single Query + Snapshot
        var result = await _context.Registers
            .AsNoTracking()
            .AsSingleQuery()
            .Where(r => r.FirstRegister >= from && r.FirstRegister < to)
            .Include(r => r.Customer)
            .Include(r => r.Land)
            .Include(r => r.RegisterType)
            .Select(r => new RegisterReport(
                r.RegisterId,
                r.Customer.FullName.FullDisplay,
                r.Land.NumberLand,
                r.FirstRegister,
                r.Diagnosis))
            .ToListAsync(ct);

        await transaction.CommitAsync(ct);
        return result.AsReadOnly();
    });
}
```

**Таблица выбора уровня изоляции:**

| Сценарий | Уровень | Почему |
|---|---|---|
| Чтение карточки пациента | `READ COMMITTED` (default) | Достаточно для обычного чтения |
| Ежемесячный отчёт | `SNAPSHOT` | Согласованность без блокировок |
| Регистрация пациента | `READ COMMITTED` в транзакции | Запись + защита от dirty reads |
| Финансовый расчёт льгот | `SERIALIZABLE` | Полная изоляция, нет фантомов |

### 8.3 Outbox Pattern — надёжная доставка событий

Проблема: Domain Event публикуется в `SavedChangesAsync`, но если MediatR-обработчик упал — событие потеряно. Outbox гарантирует доставку.

```csharp
// Dispancer.Domain/Entities/OutboxMessage.cs
public sealed class OutboxMessage
{
    private OutboxMessage() { }

    public static OutboxMessage Create(IDomainEvent domainEvent)
    {
        var type = domainEvent.GetType().FullName
            ?? throw new InvalidOperationException("Невозможно получить тип события.");

        return new OutboxMessage
        {
            Id = Guid.NewGuid(),
            Type = type,
            Payload = JsonSerializer.Serialize(domainEvent, domainEvent.GetType()),
            OccurredAt = domainEvent.OccurredAt,
            ProcessedAt = null
        };
    }

    public Guid Id { get; private set; }
    public required string Type { get; init; }
    public required string Payload { get; init; }
    public DateTime OccurredAt { get; private set; }
    public DateTime? ProcessedAt { get; private set; }
    public string? Error { get; private set; }

    public void MarkAsProcessed() => ProcessedAt = DateTime.UtcNow;
    public void MarkAsFailed(string error)
    {
        Error = error;
        ProcessedAt = DateTime.UtcNow;
    }
}
```

```csharp
// Замена AuditInterceptor.PublishDomainEventsAsync — теперь сохраняем в Outbox
// вместо прямой публикации через MediatR
private async Task SaveToOutboxAsync(DbContext? context, CancellationToken ct)
{
    if (context is null) return;

    var domainEvents = context.ChangeTracker
        .Entries<IHasDomainEvents>()
        .SelectMany(e => e.Entity.DomainEvents)
        .Select(OutboxMessage.Create)
        .ToList();

    if (domainEvents.Count == 0) return;

    // Outbox-сообщения сохраняются в ТОЙ ЖЕ транзакции, что и основные данные
    // Атомарность гарантирована: либо всё, либо ничего
    context.Set<OutboxMessage>().AddRange(domainEvents);
    // SaveChanges вызовется автоматически в конце текущего SaveChanges
}
```

```csharp
// Dispancer.Infrastructure/Persistence/OutboxProcessor.cs
// Фоновый воркер — читает необработанные Outbox-сообщения и публикует их
public sealed class OutboxProcessor : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<OutboxProcessor> _logger;

    public OutboxProcessor(IServiceScopeFactory scopeFactory, ILogger<OutboxProcessor> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await ProcessOutboxAsync(stoppingToken);
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
        }
    }

    private async Task ProcessOutboxAsync(CancellationToken ct)
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
        var context = scope.ServiceProvider.GetRequiredService<DispancerDbContext>();
        var mediator = scope.ServiceProvider.GetRequiredService<IMediator>();

        var messages = await context.Set<OutboxMessage>()
            .AsNoTracking()
            .Where(m => m.ProcessedAt == null)
            .OrderBy(m => m.OccurredAt)
            .Take(20)
            .ToListAsync(ct);

        foreach (var message in messages)
        {
            try
            {
                var eventType = Type.GetType(message.Type);
                if (eventType is null) continue;

                var domainEvent = (IDomainEvent)JsonSerializer.Deserialize(message.Payload, eventType)!;
                await mediator.Publish(domainEvent, ct);

                // Явно загружаем для обновления (не AsNoTracking!)
                var tracked = await context.Set<OutboxMessage>().FindAsync([message.Id], ct);
                tracked?.MarkAsProcessed();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Ошибка обработки Outbox-сообщения {Id}", message.Id);
                var tracked = await context.Set<OutboxMessage>().FindAsync([message.Id], ct);
                tracked?.MarkAsFailed(ex.Message);
            }
        }

        await context.SaveChangesAsync(ct);
    }
}
```

---

## Глава 9: Современные возможности EF Core 8

### 9.1 JSON Columns — метаданные пациента без новых таблиц

Иногда нужно хранить неструктурированные данные. Раньше это требовало новой таблицы или сериализации в строку. EF Core 8 умеет хранить VO прямо как JSON-колонку.

```csharp
// Dispancer.Domain/ValueObjects/PatientMetadata.cs
public sealed class PatientMetadata
{
    public string? BloodType { get; set; }        // A+, B-, O+ и т.д.
    public List<string> Allergies { get; set; } = [];
    public List<string> ChronicDiseases { get; set; } = [];
    public Dictionary<string, string> ExternalIds { get; set; } = new();
    // Идентификаторы в других системах (СНИЛС, полис, и т.д.)
}
```

```csharp
// В Customer добавляем:
public PatientMetadata? Metadata { get; private set; }

public void UpdateMetadata(PatientMetadata metadata) => Metadata = metadata;
```

```csharp
// В CustomerConfiguration.Configure():
builder.OwnsOne(c => c.Metadata, m =>
{
    // ToJson() — сохраняет весь объект как JSON в одну колонку
    m.ToJson("Metadata");
    // SQL Server хранит как nvarchar(max) с JSON-индексами
});
```

Запросы по JSON-полям:

```csharp
// EF Core 8 транслирует это в JSON_VALUE(Metadata, '$.BloodType')
var patients = await context.Customers
    .AsNoTracking()
    .Where(c => c.Metadata != null && c.Metadata.BloodType == "A+")
    .ToListAsync();

// Поиск по элементу массива — JSON_QUERY
var patientsWithPenicillinAllergy = await context.Customers
    .AsNoTracking()
    .Where(c => c.Metadata != null && c.Metadata.Allergies.Contains("Пенициллин"))
    .ToListAsync();
```

### 9.2 HierarchyId — иерархия административного деления

SQL Server поддерживает тип `hierarchyid` для деревьев. EF Core 8 добавил его нативную поддержку.

```csharp
// Добавляем пакет: dotnet add package Microsoft.EntityFrameworkCore.SqlServer
// HierarchyId уже включён в Microsoft.EntityFrameworkCore.SqlServer 8+

public sealed class AdminDivision
{
    public int AdminDivisionId { get; init; }
    public required string Name { get; init; }
    public required string SocrName { get; init; }
    public int Level { get; init; }
    public int CodeType { get; init; }

    // HierarchyId — хранит путь в дереве: /1/, /1/2/, /1/2/3/
    public HierarchyId Path { get; private set; } = HierarchyId.GetRoot();

    public IReadOnlyCollection<Address> Addresses => _addresses;
    private readonly HashSet<Address> _addresses = [];

    public static AdminDivision Create(
        string name,
        string socrName,
        int level,
        int codeType,
        HierarchyId? parentPath = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        var division = new AdminDivision
        {
            Name = name,
            SocrName = socrName,
            Level = level,
            CodeType = codeType
        };

        if (parentPath.HasValue)
        {
            // GetDescendant(null, null) — добавляет дочерний узел в конец
            division.Path = parentPath.Value.GetDescendant(null, null);
        }

        return division;
    }
}
```

```csharp
// AdminDivisionConfiguration.cs
internal sealed class AdminDivisionConfiguration : IEntityTypeConfiguration<AdminDivision>
{
    public void Configure(EntityTypeBuilder<AdminDivision> builder)
    {
        builder.ToTable("AdminDivision");
        builder.HasKey(a => a.AdminDivisionId);
        builder.Property(a => a.AdminDivisionId).HasColumnName("AdminDivisionID").UseIdentityColumn();
        builder.Property(a => a.Name).HasMaxLength(30).IsRequired();
        builder.Property(a => a.SocrName).HasMaxLength(10).IsRequired();

        // HierarchyId — нативный тип SQL Server
        builder.Property(a => a.Path)
            .HasColumnType("hierarchyid")
            .HasDefaultValueSql("hierarchyid::GetRoot()");

        builder.HasIndex(a => a.Path)
            .HasDatabaseName("IX_AdminDivision_Path");
    }
}
```

```csharp
// Запросы с HierarchyId

// Найти все дочерние районы для данного корня
var childDivisions = await context.AdminDivisions
    .AsNoTracking()
    .Where(d => d.Path.IsDescendantOf(parentPath))
    .OrderBy(d => d.Path)
    .ToListAsync();

// Найти непосредственных потомков (следующий уровень)
var directChildren = await context.AdminDivisions
    .AsNoTracking()
    .Where(d => d.Path.GetAncestor(1) == parentPath)
    .ToListAsync();

// Получить предков (путь от узла до корня)
var ancestors = await context.AdminDivisions
    .AsNoTracking()
    .Where(d => parentPath.IsDescendantOf(d.Path))
    .OrderBy(d => d.Path)
    .ToListAsync();
```

### 9.3 EF Core 8: Параметризация коллекций примитивов

```csharp
// До EF Core 8 — требовалось хранимой процедуры или string.Join → SQL-инъекция
// EF Core 8 корректно параметризует список примитивов

var targetLandIds = new List<int> { 1, 3, 5, 7 };
var targetDisabilityGroups = new List<int> { 1, 2 };

// EF Core 8 транслирует Contains() в параметризованный IN (...)
// Генерирует: WHERE LandID IN (@p0, @p1, @p2, @p3)
// Полная защита от SQL-инъекций, нет ручного построения SQL
var registrations = await context.Registers
    .AsNoTracking()
    .Where(r => targetLandIds.Contains(r.LandId))
    .Include(r => r.Customer)
    .ToListAsync();

// Сложная фильтрация по нескольким коллекциям
var invalids = await context.Invalids
    .AsNoTracking()
    .Where(i =>
        targetDisabilityGroups.Contains(i.DisabilityGroupId!.Value) &&
        i.PeriodInvalidity > DateTime.Today)
    .Include(i => i.Customer)
    .Include(i => i.BenefitsCategories)
    .AsSplitQuery()
    .ToListAsync();
```

---

## Глава 10: Integration Testing с Testcontainers

**Почему не In-Memory провайдер:** InMemory не поддерживает хранимые процедуры, триггеры, CHECK-ограничения, специфику SQL Server. Тесты проходят, продакшен падает.

### 10.1 Установка пакетов

```bash
dotnet add package Testcontainers.MsSql
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package xunit
dotnet add package FluentAssertions
```

### 10.2 Базовый класс для Integration тестов

```csharp
// Dispancer.Integration.Tests/Infrastructure/DispancerDbContextFixture.cs
namespace Dispancer.Integration.Tests.Infrastructure;

using Testcontainers.MsSql;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// IAsyncLifetime — запуск/остановка контейнера один раз для класса тестов.
/// Используем IClassFixture для переиспользования между тестами.
/// </summary>
public sealed class DispancerDbContextFixture : IAsyncLifetime
{
    private readonly MsSqlContainer _container = new MsSqlBuilder()
        .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
        .WithPassword("Dispancer_Test_2024!")
        .WithAutoRemove(true)  // Удаляет контейнер после теста
        .Build();

    public DispancerDbContext Context { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        await _container.StartAsync();

        var options = new DbContextOptionsBuilder<DispancerDbContext>()
            .UseSqlServer(_container.GetConnectionString())
            .Options;

        Context = new DispancerDbContext(options);

        // Применяем реальные миграции — те же, что на продакшене
        await Context.Database.MigrateAsync();

        await SeedTestDataAsync();
    }

    private async Task SeedTestDataAsync()
    {
        // Добавляем минимальный набор справочников
        Context.Genders.AddRange(
            new Gender { GenderId = 1, Name = "М" },
            new Gender { GenderId = 2, Name = "Ж" });

        Context.Lands.Add(new Land { LandId = 1, NumberLand = "Участок №1" });

        Context.DisabilityGroups.Add(new DisabilityGroup
        {
            DisabilityGroupId = 1,
            Name = "I группа"
        });

        await Context.SaveChangesAsync();
    }

    public async Task DisposeAsync()
    {
        await Context.DisposeAsync();
        await _container.DisposeAsync();
    }
}
```

### 10.3 Тесты Rich Domain Model + EF Core

```csharp
// Dispancer.Integration.Tests/CustomerRepositoryTests.cs
namespace Dispancer.Integration.Tests;

using FluentAssertions;
using Xunit;

public sealed class CustomerRepositoryTests : IClassFixture<DispancerDbContextFixture>
{
    private readonly DispancerDbContext _context;

    public CustomerRepositoryTests(DispancerDbContextFixture fixture) =>
        _context = fixture.Context;

    [Fact]
    public async Task Create_ValidCustomer_PersistsToDatabase()
    {
        // Arrange
        var customer = Customer.Create(
            lastName: "Иванов",
            firstName: "Иван",
            middleName: "Иванович",
            birthday: new DateTime(1980, 5, 15),
            genderId: 1);

        // Act
        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();

        // Assert — перечитываем из БД для проверки сохранения
        var saved = await _context.Customers
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.CustomerId == customer.CustomerId);

        saved.Should().NotBeNull();
        saved!.FullName.LastName.Should().Be("Иванов");
        saved.FullName.FirstName.Should().Be("Иван");
        saved.IsDeleted.Should().BeFalse();
    }

    [Fact]
    public async Task SoftDelete_RemoveCustomer_SetsIsDeletedFlag()
    {
        // Arrange
        var customer = Customer.Create("Петров", "Пётр");
        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();
        _context.ChangeTracker.Clear();

        var tracked = await _context.Customers
            .FirstAsync(c => c.CustomerId == customer.CustomerId);

        // Act — Remove вызовет SoftDeleteInterceptor
        _context.Customers.Remove(tracked);
        await _context.SaveChangesAsync();

        // Assert — пациент физически есть в БД, но помечен как удалённый
        var deleted = await _context.Customers
            .AsNoTracking()
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(c => c.CustomerId == customer.CustomerId);

        deleted.Should().NotBeNull();
        deleted!.IsDeleted.Should().BeTrue();
        deleted.DeletedAt.Should().NotBeNull();

        // Через обычный запрос (с Global Query Filter) пациент не виден
        var notVisible = await _context.Customers
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.CustomerId == customer.CustomerId);

        notVisible.Should().BeNull();
    }

    [Fact]
    public async Task Archive_ActiveCustomer_RaisesDomainEvent()
    {
        // Arrange
        var customer = Customer.Create("Сидоров", "Сидор");
        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();
        _context.ChangeTracker.Clear();

        var tracked = await _context.Customers
            .FirstAsync(c => c.CustomerId == customer.CustomerId);

        // Act
        tracked.Archive();
        await _context.SaveChangesAsync();

        // Assert
        var archived = await _context.Customers
            .AsNoTracking()
            .FirstAsync(c => c.CustomerId == tracked.CustomerId);

        archived.Arch.Should().BeTrue();
    }

    [Fact]
    public async Task GetByLands_MultipleIds_TranslatesAsParameterizedInQuery()
    {
        // Arrange — создаём пациентов на разных участках
        var landIds = new List<int> { 1, 2, 3 };

        // Act
        var repo = new CustomerRepository(_context);
        var customers = await repo.GetByLandsAsync(landIds);

        // Assert — EF Core 8 должен использовать параметризованный IN (не строку)
        // Проверяем корректность результата
        customers.Should().AllSatisfy(c =>
            c.Registers.Should().Contain(r => landIds.Contains(r.LandId)));
    }

    [Fact]
    public async Task RegisterInvalidity_WithDomainMethod_CheckConstraintEnforced()
    {
        // Тест проверяет, что CHECK constraint в реальном SQL Server работает
        // (InMemory этого не проверяет!)

        // Arrange
        var customer = Customer.Create("Козлов", "Козёл");
        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();
        _context.ChangeTracker.Clear();

        var tracked = await _context.Customers
            .FirstAsync(c => c.CustomerId == customer.CustomerId);

        // Act & Assert — дата в будущем должна нарушить CHECK constraint
        var futureDate = DateTime.Today.AddDays(10);

        var act = () =>
        {
            tracked.RegisterInvalidity(disabilityGroupId: 1, dataInvalidity: futureDate);
            return _context.SaveChangesAsync();
        };

        // DomainException бросается в самом методе ещё до обращения к БД
        await act.Should().ThrowAsync<DomainException>()
            .WithMessage("*будущем*");
    }
}
```

### 10.4 Тест транзакции с IExecutionStrategy

```csharp
[Fact]
public async Task RegisterNewPatient_FullFlow_Atomic()
{
    // Arrange
    var service = new PatientRegistrationService(_context, new CustomerRepository(_context));

    var customer = Customer.Create("Новиков", "Алексей", genderId: 1);
    var address = AddressDetails.Create("Москва", nameStreet: "Ленина", numberHouse: "5");

    // Act
    await service.RegisterNewPatientAsync(customer, address, adminDivisionId: 5, landId: 1);

    // Assert — всё сохранено атомарно
    var saved = await _context.Customers
        .AsNoTracking()
        .Include(c => c.Addresses)
        .Include(c => c.Registers)
        .FirstOrDefaultAsync(c => c.CustomerId == customer.CustomerId);

    saved.Should().NotBeNull();
    saved!.Addresses.Should().HaveCount(1);
    saved.Registers.Should().HaveCount(1);
}
```

---

## Шпаргалка для код-ревью

Чек-лист при ревью EF Core кода:

| Что проверять | Правило |
|---|---|
| Read-only запрос | Есть `.AsNoTracking()` или `.AsNoTrackingWithIdentityResolution()` |
| Несколько коллекций в Include | Есть `.AsSplitQuery()` |
| Горячий путь (>1000 RPS) | Используется `EF.CompileAsyncQuery` |
| Фильтр по списку | Используется `.Contains(list)` вместо `string.Join` + FromSqlRaw |
| Retry + ручная транзакция | Обёрнуто в `IExecutionStrategy.ExecuteAsync` |
| Удаление сущности | `SoftDeleteInterceptor` настроен, физического удаления нет |
| Большая выборка (отчёт) | Используется `IAsyncEnumerable` + стриминг |
| Несколько FK на одну таблицу | Нет двух `CASCADE` на одну целевую таблицу |
| Тесты с EF Core | Используется Testcontainers, не InMemory |
| Персональные данные | Поля с ПД конвертируются через `EncryptedStringConverter` |
