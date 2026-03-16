# Полное руководство по Entity Framework Core для базы данных Диспансера

## Оглавление

1. [Создание проекта и установка пакетов](#1-создание-проекта-и-установка-пакетов)
2. [Классы сущностей (Entities)](#2-классы-сущностей-entities)
3. [DbContext и конфигурация Fluent API](#3-dbcontext-и-конфигурация-fluent-api)
4. [Строка подключения и регистрация сервиса](#4-строка-подключения-и-регистрация-сервиса)
5. [Миграции](#5-миграции)
6. [Работа с представлениями (Views)](#6-работа-с-представлениями-views)
7. [Вызов хранимых процедур](#7-вызов-хранимых-процедур)
8. [Мягкое удаление (Soft Delete)](#8-мягкое-удаление-soft-delete)
9. [Репозиторий — примеры запросов](#9-репозиторий--примеры-запросов)
10. [Советы и рекомендации](#10-советы-и-рекомендации)

---

## 1. Создание проекта и установка пакетов

### 1.1 Создание нового проекта

```bash
dotnet new webapi -n Dispancer.Api
cd Dispancer.Api

# Если нужен отдельный слой данных
dotnet new classlib -n Dispancer.Data
dotnet add Dispancer.Api/Dispancer.Api.csproj reference Dispancer.Data/Dispancer.Data.csproj
```

### 1.2 Установка необходимых NuGet-пакетов

```bash
# Основной пакет EF Core для SQL Server
dotnet add package Microsoft.EntityFrameworkCore.SqlServer

# Инструменты для миграций (в проект данных)
dotnet add package Microsoft.EntityFrameworkCore.Tools

# Design-пакет для dotnet ef CLI
dotnet add package Microsoft.EntityFrameworkCore.Design

# Расширения для DI
dotnet add package Microsoft.Extensions.DependencyInjection
```

Либо в `Dispancer.Data.csproj`:

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
  <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.0">
    <PrivateAssets>all</PrivateAssets>
    <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
  </PackageReference>
  <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.0">
    <PrivateAssets>all</PrivateAssets>
    <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
  </PackageReference>
</ItemGroup>
```

---

## 2. Классы сущностей (Entities)

Создайте папку `Entities/` в проекте данных.

### 2.1 Gender

```csharp
// Entities/Gender.cs
namespace Dispancer.Data.Entities;

public class Gender
{
    public int GenderId { get; set; }
    public string Name { get; set; } = null!;

    // Навигационное свойство
    public ICollection<Customer> Customers { get; set; } = new List<Customer>();
}
```

### 2.2 APPPTPR

```csharp
// Entities/Appptpr.cs
namespace Dispancer.Data.Entities;

public class Appptpr
{
    public int AppptprId { get; set; }
    public string Name { get; set; } = null!;

    public ICollection<Customer> Customers { get; set; } = new List<Customer>();
}
```

### 2.3 Customer (главная таблица)

```csharp
// Entities/Customer.cs
namespace Dispancer.Data.Entities;

public class Customer
{
    public int CustomerId { get; set; }
    public int? MedCard { get; set; }
    public int? CodeCustomer { get; set; }
    public string LastName { get; set; } = null!;
    public string FirstName { get; set; } = null!;
    public string? MiddleName { get; set; }
    public DateTime? Birthday { get; set; }
    public bool Arch { get; set; }
    public int? CustomerTempId { get; set; }
    public int? AppptprId { get; set; }
    public int? GenderId { get; set; }

    // Мягкое удаление (Soft Delete)
    public bool Delete { get; set; }
    public DateTime ModifyDate { get; set; }

    // Навигационные свойства
    public Appptpr? Appptpr { get; set; }
    public Gender? Gender { get; set; }
    public CustomerNotaBene? NotaBene { get; set; }
    public ICollection<Address> Addresses { get; set; } = new List<Address>();
    public ICollection<Register> Registers { get; set; } = new List<Register>();
    public ICollection<Invalid> Invalids { get; set; } = new List<Invalid>();
}
```

### 2.4 AdminDivision

```csharp
// Entities/AdminDivision.cs
namespace Dispancer.Data.Entities;

public class AdminDivision
{
    public int AdminDivisionId { get; set; }
    public int Level { get; set; }
    public string Name { get; set; } = null!;
    public string SocrName { get; set; } = null!;
    public int CodeType { get; set; }

    public ICollection<Address> Addresses { get; set; } = new List<Address>();
}
```

### 2.5 TypeStreet

```csharp
// Entities/TypeStreet.cs
namespace Dispancer.Data.Entities;

public class TypeStreet
{
    public int TypeStreetId { get; set; }
    public int Level { get; set; }
    public string Name { get; set; } = null!;
    public string SocrName { get; set; } = null!;
    public int CodeType { get; set; }

    public ICollection<Address> Addresses { get; set; } = new List<Address>();
}
```

### 2.6 Address

```csharp
// Entities/Address.cs
namespace Dispancer.Data.Entities;

public class Address
{
    public int AddressId { get; set; }
    public int CustomerId { get; set; }
    public string? Region { get; set; }
    public string? Country { get; set; }
    public string City { get; set; } = "---";
    public int AdminDivisionId { get; set; }
    public int? TypeStreetId { get; set; }
    public string? NameStreet { get; set; }
    public string? NumberHouse { get; set; }
    public string? NumberApartment { get; set; }
    public DateTime ModifiedDate { get; set; }

    // Навигационные свойства
    public Customer Customer { get; set; } = null!;
    public AdminDivision AdminDivision { get; set; } = null!;
    public TypeStreet? TypeStreet { get; set; }
}
```

### 2.7 RegisterType

```csharp
// Entities/RegisterType.cs
namespace Dispancer.Data.Entities;

public class RegisterType
{
    public int RegisterTypeId { get; set; }
    public string Name { get; set; } = null!;
    public string? NotaBene { get; set; }

    public ICollection<Register> FirstRegisters { get; set; } = new List<Register>();
    public ICollection<Register> SecondRegisters { get; set; } = new List<Register>();
}
```

### 2.8 WhyDeRegister

```csharp
// Entities/WhyDeRegister.cs
namespace Dispancer.Data.Entities;

public class WhyDeRegister
{
    public int WhyDeRegisterId { get; set; }
    public string Name { get; set; } = null!;
    public string? NotaBene { get; set; }

    public ICollection<Register> FirstDeRegisters { get; set; } = new List<Register>();
    public ICollection<Register> SecondDeRegisters { get; set; } = new List<Register>();
}
```

### 2.9 Land

```csharp
// Entities/Land.cs
namespace Dispancer.Data.Entities;

public class Land
{
    public int LandId { get; set; }
    public string NumberLand { get; set; } = null!;
    public string? NotaBene { get; set; }

    public ICollection<Register> Registers { get; set; } = new List<Register>();
}
```

### 2.10 Register

```csharp
// Entities/Register.cs
namespace Dispancer.Data.Entities;

public class Register
{
    public int RegisterId { get; set; }
    public DateTime? FirstRegister { get; set; }
    public DateTime? FirstDeregister { get; set; }
    public DateTime? SecondRegister { get; set; }
    public DateTime? SecondDeRegister { get; set; }
    public string? Diagnosis { get; set; }
    public DateTime? DataDiagnosis { get; set; }
    public int? RegisterTypeId { get; set; }
    public int? SecondRegisterTypeId { get; set; }
    public int CustomerId { get; set; }
    public int? WhyDeRegisterId { get; set; }
    public int? WhySecondDeRegisterId { get; set; }
    public int LandId { get; set; }
    public DateTime ModifiedDate { get; set; }

    // Навигационные свойства
    public Customer Customer { get; set; } = null!;
    public RegisterType? RegisterType { get; set; }
    public RegisterType? SecondRegisterType { get; set; }
    public WhyDeRegister? WhyDeRegister { get; set; }
    public WhyDeRegister? WhySecondDeRegister { get; set; }
    public Land Land { get; set; } = null!;
    public RegisterNotaBene? NotaBene { get; set; }
}
```

### 2.11 DisabilityGroup

```csharp
// Entities/DisabilityGroup.cs
namespace Dispancer.Data.Entities;

public class DisabilityGroup
{
    public int DisabilityGroupId { get; set; }
    public string Name { get; set; } = null!;
    public string? NotaBene { get; set; }

    public ICollection<Invalid> Invalids { get; set; } = new List<Invalid>();
}
```

### 2.12 ChiperRecept

```csharp
// Entities/ChiperRecept.cs
namespace Dispancer.Data.Entities;

public class ChiperRecept
{
    public int ChiperReceptId { get; set; }
    public string Name { get; set; } = null!;
    public string? NotaBene { get; set; }

    public ICollection<Invalid> Invalids { get; set; } = new List<Invalid>();
}
```

### 2.13 Invalid

```csharp
// Entities/Invalid.cs
namespace Dispancer.Data.Entities;

public class Invalid
{
    public int InvalidId { get; set; }
    public int? DisabilityGroupId { get; set; }
    public DateTime? DataInvalidity { get; set; }
    public DateTime? PeriodInvalidity { get; set; }
    public int? ChiperReceptId { get; set; }
    public bool Incapable { get; set; }
    public DateTime? DateIncapable { get; set; }
    public int CustomerId { get; set; }
    public DateTime ModifiedDate { get; set; }

    // Навигационные свойства
    public Customer Customer { get; set; } = null!;
    public DisabilityGroup? DisabilityGroup { get; set; }
    public ChiperRecept? ChiperRecept { get; set; }
    public ICollection<BenefitsCategory> BenefitsCategories { get; set; } = new List<BenefitsCategory>();
}
```

### 2.14 BenefitsCategory

```csharp
// Entities/BenefitsCategory.cs
namespace Dispancer.Data.Entities;

public class BenefitsCategory
{
    public int BenefitsCategoryId { get; set; }
    public string Name { get; set; } = null!;
    public string? NotaBene { get; set; }

    public ICollection<Invalid> Invalids { get; set; } = new List<Invalid>();
}
```

### 2.15 CustomerNotaBene

```csharp
// Entities/CustomerNotaBene.cs
namespace Dispancer.Data.Entities;

public class CustomerNotaBene
{
    public int CustomerId { get; set; }
    public string? NotaBene { get; set; }

    public Customer Customer { get; set; } = null!;
}
```

### 2.16 RegisterNotaBene

```csharp
// Entities/RegisterNotaBene.cs
namespace Dispancer.Data.Entities;

public class RegisterNotaBene
{
    public int RegisterId { get; set; }
    public string? NotaBene { get; set; }

    public Register Register { get; set; } = null!;
}
```

---

## 3. DbContext и конфигурация Fluent API

```csharp
// DispancerDbContext.cs
using Dispancer.Data.Entities;
using Dispancer.Data.Views;
using Microsoft.EntityFrameworkCore;

namespace Dispancer.Data;

public class DispancerDbContext : DbContext
{
    public DispancerDbContext(DbContextOptions<DispancerDbContext> options)
        : base(options) { }

    // Таблицы
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Gender> Genders => Set<Gender>();
    public DbSet<Appptpr> Appptprs => Set<Appptpr>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<AdminDivision> AdminDivisions => Set<AdminDivision>();
    public DbSet<TypeStreet> TypeStreets => Set<TypeStreet>();
    public DbSet<Register> Registers => Set<Register>();
    public DbSet<RegisterType> RegisterTypes => Set<RegisterType>();
    public DbSet<Land> Lands => Set<Land>();
    public DbSet<WhyDeRegister> WhyDeRegisters => Set<WhyDeRegister>();
    public DbSet<Invalid> Invalids => Set<Invalid>();
    public DbSet<DisabilityGroup> DisabilityGroups => Set<DisabilityGroup>();
    public DbSet<ChiperRecept> ChiperRecepts => Set<ChiperRecept>();
    public DbSet<BenefitsCategory> BenefitsCategories => Set<BenefitsCategory>();
    public DbSet<CustomerNotaBene> CustomerNotaBenes => Set<CustomerNotaBene>();
    public DbSet<RegisterNotaBene> RegisterNotaBenes => Set<RegisterNotaBene>();

    // Представления (Views — только для чтения)
    public DbSet<VGetCustomer> VGetCustomers => Set<VGetCustomer>();
    public DbSet<VGetCustomerFromArch> VGetCustomersFromArch => Set<VGetCustomerFromArch>();
    public DbSet<VGetAddress> VGetAddresses => Set<VGetAddress>();
    public DbSet<VGetRegister> VGetRegisters => Set<VGetRegister>();
    public DbSet<VGetInvalid> VGetInvalids => Set<VGetInvalid>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // ===================== GENDER =====================
        modelBuilder.Entity<Gender>(e =>
        {
            e.ToTable("Gender");
            e.HasKey(x => x.GenderId);
            e.Property(x => x.GenderId).HasColumnName("GenderID");
            e.Property(x => x.Name).HasColumnType("nchar(1)").IsRequired();
        });

        // ===================== APPPTPR =====================
        modelBuilder.Entity<Appptpr>(e =>
        {
            e.ToTable("APPPTPR");
            e.HasKey(x => x.AppptprId);
            e.Property(x => x.AppptprId).HasColumnName("APPPTPR");
            e.Property(x => x.Name).HasColumnType("nchar(5)").IsRequired();
        });

        // ===================== CUSTOMER =====================
        modelBuilder.Entity<Customer>(e =>
        {
            e.ToTable("Customer");
            e.HasKey(x => x.CustomerId);
            e.Property(x => x.CustomerId).HasColumnName("CustomerID");
            e.Property(x => x.LastName).HasMaxLength(100).IsRequired();
            e.Property(x => x.FirstName).HasMaxLength(100).IsRequired();
            e.Property(x => x.MiddleName).HasMaxLength(100);
            e.Property(x => x.Arch).IsRequired();
            e.Property(x => x.Delete).HasDefaultValue(false);
            e.Property(x => x.ModifyDate).HasDefaultValueSql("GETDATE()");
            e.Property(x => x.AppptprId).HasColumnName("APPPTPRID");
            e.Property(x => x.GenderId).HasColumnName("GenderID");

            // CHECK constraint: Birthday <= GETDATE()
            e.ToTable(t => t.HasCheckConstraint("CK_Customer_Birthday", "[Birthday] <= GETDATE()"));

            e.HasOne(x => x.Appptpr)
                .WithMany(x => x.Customers)
                .HasForeignKey(x => x.AppptprId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.Gender)
                .WithMany(x => x.Customers)
                .HasForeignKey(x => x.GenderId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.NotaBene)
                .WithOne(x => x.Customer)
                .HasForeignKey<CustomerNotaBene>(x => x.CustomerId);
        });

        // ===================== ADMIN DIVISION =====================
        modelBuilder.Entity<AdminDivision>(e =>
        {
            e.ToTable("AdminDivision");
            e.HasKey(x => x.AdminDivisionId);
            e.Property(x => x.AdminDivisionId).HasColumnName("AdminDivisionID");
            e.Property(x => x.Name).HasMaxLength(30).IsRequired();
            e.Property(x => x.SocrName).HasMaxLength(10).IsRequired();
        });

        // ===================== TYPE STREET =====================
        modelBuilder.Entity<TypeStreet>(e =>
        {
            e.ToTable("TypeStreet");
            e.HasKey(x => x.TypeStreetId);
            e.Property(x => x.TypeStreetId).HasColumnName("TypeStreetID");
            e.Property(x => x.Name).HasMaxLength(30).IsRequired();
            e.Property(x => x.SocrName).HasMaxLength(10).IsRequired();
        });

        // ===================== ADDRESS =====================
        modelBuilder.Entity<Address>(e =>
        {
            e.ToTable("Address");
            e.HasKey(x => x.AddressId);
            e.Property(x => x.AddressId).HasColumnName("AddressID");
            e.Property(x => x.CustomerId).HasColumnName("CustomerID").IsRequired();
            e.Property(x => x.Region).HasColumnType("nchar(50)");
            e.Property(x => x.Country).HasColumnType("nchar(50)");
            e.Property(x => x.City).HasMaxLength(100).HasDefaultValue("---").IsRequired();
            e.Property(x => x.AdminDivisionId).HasColumnName("AdminDivisionID").HasDefaultValue(5);
            e.Property(x => x.TypeStreetId).HasColumnName("TypeStreetID").HasDefaultValue(172);
            e.Property(x => x.NameStreet).HasMaxLength(100);
            e.Property(x => x.NumberHouse).HasMaxLength(10);
            e.Property(x => x.NumberApartment).HasMaxLength(10);
            e.Property(x => x.ModifiedDate).HasDefaultValueSql("GETDATE()");

            e.HasOne(x => x.Customer)
                .WithMany(x => x.Addresses)
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.AdminDivision)
                .WithMany(x => x.Addresses)
                .HasForeignKey(x => x.AdminDivisionId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.TypeStreet)
                .WithMany(x => x.Addresses)
                .HasForeignKey(x => x.TypeStreetId)
                .OnDelete(DeleteBehavior.ClientSetNull);
        });

        // ===================== REGISTER TYPE =====================
        modelBuilder.Entity<RegisterType>(e =>
        {
            e.ToTable("RegisterType");
            e.HasKey(x => x.RegisterTypeId);
            e.Property(x => x.RegisterTypeId).HasColumnName("RegisterTypeID");
            e.Property(x => x.Name).HasMaxLength(50).IsRequired();
            e.Property(x => x.NotaBene).HasMaxLength(150);
        });

        // ===================== WHY DE REGISTER =====================
        modelBuilder.Entity<WhyDeRegister>(e =>
        {
            e.ToTable("WhyDeRegister");
            e.HasKey(x => x.WhyDeRegisterId);
            e.Property(x => x.WhyDeRegisterId).HasColumnName("WhyDeRegisterID");
            e.Property(x => x.Name).HasMaxLength(100).IsRequired();
            e.Property(x => x.NotaBene).HasMaxLength(140);
        });

        // ===================== LAND =====================
        modelBuilder.Entity<Land>(e =>
        {
            e.ToTable("Land");
            e.HasKey(x => x.LandId);
            e.Property(x => x.LandId).HasColumnName("LandID");
            e.Property(x => x.NumberLand).HasMaxLength(50).IsRequired();
            e.Property(x => x.NotaBene).HasMaxLength(50);
        });

        // ===================== REGISTER =====================
        modelBuilder.Entity<Register>(e =>
        {
            e.ToTable("Register");
            e.HasKey(x => x.RegisterId);
            e.Property(x => x.RegisterId).HasColumnName("RegisterID");
            e.Property(x => x.CustomerId).HasColumnName("CustomerID").IsRequired();
            e.Property(x => x.LandId).HasColumnName("LandID").HasDefaultValue(1);
            e.Property(x => x.RegisterTypeId).HasColumnName("RegisterTypeID");
            e.Property(x => x.SecondRegisterTypeId).HasColumnName("SecondRegisterTypeID");
            e.Property(x => x.WhyDeRegisterId).HasColumnName("WhyDeRegisterID");
            e.Property(x => x.WhySecondDeRegisterId).HasColumnName("WhySecondDeRegisterID");
            e.Property(x => x.Diagnosis).HasMaxLength(10);
            e.Property(x => x.ModifiedDate).HasDefaultValueSql("GETDATE()");

            // CHECK constraints
            e.ToTable(t =>
            {
                t.HasCheckConstraint("CK_Register_DataDiagnosis", "[DataDiagnosis] <= GETDATE()");
                t.HasCheckConstraint("CK_Register_PeriodInvalidity", "[PeriodInvalidity] <= GETDATE()");
            });

            e.HasOne(x => x.Customer)
                .WithMany(x => x.Registers)
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.RegisterType)
                .WithMany(x => x.FirstRegisters)
                .HasForeignKey(x => x.RegisterTypeId)
                .OnDelete(DeleteBehavior.Cascade);

            // Второй тип регистрации — нет cascade (SQL ограничение нескольких каскадов)
            e.HasOne(x => x.SecondRegisterType)
                .WithMany(x => x.SecondRegisters)
                .HasForeignKey(x => x.SecondRegisterTypeId)
                .OnDelete(DeleteBehavior.NoAction);

            e.HasOne(x => x.WhyDeRegister)
                .WithMany(x => x.FirstDeRegisters)
                .HasForeignKey(x => x.WhyDeRegisterId)
                .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(x => x.WhySecondDeRegister)
                .WithMany(x => x.SecondDeRegisters)
                .HasForeignKey(x => x.WhySecondDeRegisterId)
                .OnDelete(DeleteBehavior.NoAction);

            e.HasOne(x => x.Land)
                .WithMany(x => x.Registers)
                .HasForeignKey(x => x.LandId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.NotaBene)
                .WithOne(x => x.Register)
                .HasForeignKey<RegisterNotaBene>(x => x.RegisterId);
        });

        // ===================== DISABILITY GROUP =====================
        modelBuilder.Entity<DisabilityGroup>(e =>
        {
            e.ToTable("DisabilityGroup");
            e.HasKey(x => x.DisabilityGroupId);
            e.Property(x => x.DisabilityGroupId).HasColumnName("DisabilityGroupID");
            e.Property(x => x.Name).HasMaxLength(100).IsRequired();
            e.Property(x => x.NotaBene).HasMaxLength(100);
        });

        // ===================== CHIPER RECEPT =====================
        modelBuilder.Entity<ChiperRecept>(e =>
        {
            e.ToTable("ChiperRecept");
            e.HasKey(x => x.ChiperReceptId);
            e.Property(x => x.ChiperReceptId).HasColumnName("ChiperReceptID");
            e.Property(x => x.Name).HasMaxLength(50).IsRequired();
            e.Property(x => x.NotaBene).HasMaxLength(150);
        });

        // ===================== INVALID =====================
        modelBuilder.Entity<Invalid>(e =>
        {
            e.ToTable("Invalid");
            e.HasKey(x => x.InvalidId);
            e.Property(x => x.InvalidId).HasColumnName("InvalidID");
            e.Property(x => x.CustomerId).HasColumnName("CustomerID").IsRequired();
            e.Property(x => x.DisabilityGroupId).HasColumnName("DisabilityGroupID");
            e.Property(x => x.ChiperReceptId).HasColumnName("ChiperReceptID");
            e.Property(x => x.Incapable).HasDefaultValue(false).IsRequired();
            e.Property(x => x.ModifiedDate).HasDefaultValueSql("GETDATE()");

            // CHECK constraints
            e.ToTable(t =>
            {
                t.HasCheckConstraint("CK_Invalid_DataInvalidity", "[DataInvalidity] <= GETDATE()");
                t.HasCheckConstraint("CK_Invalid_PeriodInvalidity", "[PeriodInvalidity] <= GETDATE()");
            });

            e.HasOne(x => x.Customer)
                .WithMany(x => x.Invalids)
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.DisabilityGroup)
                .WithMany(x => x.Invalids)
                .HasForeignKey(x => x.DisabilityGroupId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.ChiperRecept)
                .WithMany(x => x.Invalids)
                .HasForeignKey(x => x.ChiperReceptId)
                .OnDelete(DeleteBehavior.ClientSetNull);

            // Связь многие-ко-многим с BenefitsCategory через Invalid_BenefitsCategory
            e.HasMany(x => x.BenefitsCategories)
                .WithMany(x => x.Invalids)
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
        });

        // ===================== BENEFITS CATEGORY =====================
        modelBuilder.Entity<BenefitsCategory>(e =>
        {
            e.ToTable("BenefitsCategory");
            e.HasKey(x => x.BenefitsCategoryId);
            e.Property(x => x.BenefitsCategoryId).HasColumnName("BenefitsCategoryID");
            e.Property(x => x.Name).HasMaxLength(100).IsRequired();
            e.Property(x => x.NotaBene).HasMaxLength(100);
        });

        // ===================== CUSTOMER NOTA BENE =====================
        modelBuilder.Entity<CustomerNotaBene>(e =>
        {
            e.ToTable("CustomerNotaBene");
            e.HasKey(x => x.CustomerId);
            e.Property(x => x.CustomerId).HasColumnName("CustomerID");
            e.Property(x => x.NotaBene).HasColumnType("ntext");
        });

        // ===================== REGISTER NOTA BENE =====================
        modelBuilder.Entity<RegisterNotaBene>(e =>
        {
            e.ToTable("RegisterNotaBene");
            e.HasKey(x => x.RegisterId);
            e.Property(x => x.RegisterId).HasColumnName("RegisterID");
            e.Property(x => x.NotaBene).HasColumnType("ntext");
        });

        // ===================== VIEWS =====================
        modelBuilder.Entity<VGetCustomer>(e =>
        {
            e.ToView("vGetCustomers");
            e.HasNoKey();
        });

        modelBuilder.Entity<VGetCustomerFromArch>(e =>
        {
            e.ToView("vGetCustomersFromArch");
            e.HasNoKey();
        });

        modelBuilder.Entity<VGetAddress>(e =>
        {
            e.ToView("vGetAddress");
            e.HasNoKey();
        });

        modelBuilder.Entity<VGetRegister>(e =>
        {
            e.ToView("vGetRegister");
            e.HasNoKey();
        });

        modelBuilder.Entity<VGetInvalid>(e =>
        {
            e.ToView("vGetInvalid");
            e.HasNoKey();
        });
    }
}
```

---

## 4. Строка подключения и регистрация сервиса

### 4.1 appsettings.json

```json
{
  "ConnectionStrings": {
    "DispancerDb": "Server=YOUR_SERVER;Database=Dispancer;User Id=YOUR_USER;Password=YOUR_PASSWORD;TrustServerCertificate=True;"
  }
}
```

Или с Windows-аутентификацией:

```json
{
  "ConnectionStrings": {
    "DispancerDb": "Server=YOUR_SERVER;Database=Dispancer;Integrated Security=True;TrustServerCertificate=True;"
  }
}
```

### 4.2 Program.cs (ASP.NET Core)

```csharp
using Dispancer.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<DispancerDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DispancerDb"),
        sqlOptions =>
        {
            sqlOptions.CommandTimeout(60);
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        }));

builder.Services.AddControllers();
var app = builder.Build();
app.MapControllers();
app.Run();
```

---

## 5. Миграции

### 5.1 Первая миграция (если база создаётся с нуля)

```bash
# Добавить миграцию
dotnet ef migrations add InitialCreate --project Dispancer.Data --startup-project Dispancer.Api

# Применить миграцию к базе данных
dotnet ef database update --project Dispancer.Data --startup-project Dispancer.Api
```

### 5.2 Если база уже существует (работа с существующей БД)

Используйте **Scaffold** для генерации классов из существующей базы:

```bash
dotnet ef dbcontext scaffold \
  "Server=YOUR_SERVER;Database=Dispancer;Integrated Security=True;" \
  Microsoft.EntityFrameworkCore.SqlServer \
  --output-dir Entities \
  --context-dir . \
  --context DispancerDbContext \
  --data-annotations \
  --no-onconfiguring \
  --project Dispancer.Data \
  --startup-project Dispancer.Api
```

Или создайте пустую миграцию и пометьте текущее состояние как baseline:

```bash
# Создать пустую начальную миграцию
dotnet ef migrations add Baseline --project Dispancer.Data --startup-project Dispancer.Api

# Применить (без изменений, только зафиксировать снимок схемы)
dotnet ef database update --project Dispancer.Data --startup-project Dispancer.Api
```

### 5.3 Добавление последующих миграций

```bash
dotnet ef migrations add AddSomeFeature --project Dispancer.Data --startup-project Dispancer.Api
dotnet ef database update --project Dispancer.Data --startup-project Dispancer.Api
```

### 5.4 Откат миграции

```bash
# Откатить до конкретной миграции
dotnet ef database update PreviousMigrationName --project Dispancer.Data --startup-project Dispancer.Api

# Удалить последнюю миграцию (если ещё не применена)
dotnet ef migrations remove --project Dispancer.Data --startup-project Dispancer.Api
```

---

## 6. Работа с представлениями (Views)

### 6.1 Классы для представлений

```csharp
// Views/VGetCustomer.cs
namespace Dispancer.Data.Views;

public class VGetCustomer
{
    public int CustomerId { get; set; }
    public int? MedCard { get; set; }
    public string LastName { get; set; } = null!;
    public string FirstName { get; set; } = null!;
    public string? MiddleName { get; set; }
    public DateTime? Birthday { get; set; }
    public int? GenderId { get; set; }
    public int? AppptprId { get; set; }
    public string? NotaBene { get; set; }
}
```

```csharp
// Views/VGetAddress.cs
namespace Dispancer.Data.Views;

public class VGetAddress
{
    public int AddressId { get; set; }
    public int CustomerId { get; set; }
    public string City { get; set; } = null!;
    public string? NameStreet { get; set; }
    public string? NumberHouse { get; set; }
    public string? NumberApartment { get; set; }
    public int AdminDivisionId { get; set; }
}
```

```csharp
// Views/VGetRegister.cs
namespace Dispancer.Data.Views;

public class VGetRegister
{
    public int RegisterId { get; set; }
    public int CustomerId { get; set; }
    public DateTime? FirstRegister { get; set; }
    public DateTime? FirstDeregister { get; set; }
    public string? Diagnosis { get; set; }
    public int LandId { get; set; }
    public string? NotaBene { get; set; }
}
```

```csharp
// Views/VGetInvalid.cs
namespace Dispancer.Data.Views;

public class VGetInvalid
{
    public int InvalidId { get; set; }
    public int CustomerId { get; set; }
    public int? DisabilityGroupId { get; set; }
    public DateTime? DataInvalidity { get; set; }
    public DateTime? PeriodInvalidity { get; set; }
    public bool Incapable { get; set; }
}
```

```csharp
// Views/VGetCustomerFromArch.cs
namespace Dispancer.Data.Views;

public class VGetCustomerFromArch
{
    public int CustomerId { get; set; }
    public string LastName { get; set; } = null!;
    public string FirstName { get; set; } = null!;
    public string? MiddleName { get; set; }
    public DateTime? Birthday { get; set; }
    public string? NotaBene { get; set; }
}
```

### 6.2 Использование представлений

```csharp
// Получить всех активных пациентов
var customers = await context.VGetCustomers.ToListAsync();

// С фильтрацией
var byLastName = await context.VGetCustomers
    .Where(c => c.LastName.StartsWith("Иван"))
    .ToListAsync();

// Пациенты в архиве
var archived = await context.VGetCustomersFromArch.ToListAsync();
```

> **Важно:** Представления доступны только для чтения. Попытка добавить/изменить/удалить данные через них вызовет исключение.

---

## 7. Вызов хранимых процедур

### 7.1 Процедуры с результирующим набором данных

```csharp
// Получить адреса по CustomerID (uspGetAddressByCustomerID)
var addresses = await context.Addresses
    .FromSqlRaw("EXEC uspGetAddressByCustomerID @CustomerID = {0}", customerId)
    .ToListAsync();

// Поиск по фамилии (uspGetCustomerByLastName)
var customers = await context.Customers
    .FromSqlRaw("EXEC uspGetCustomerByLastName @LastName = {0}", lastName)
    .ToListAsync();

// Через SqlParameter (безопаснее для сложных запросов)
using Microsoft.Data.SqlClient;

var param = new SqlParameter("@LastName", lastName);
var result = await context.Customers
    .FromSqlRaw("EXEC uspGetCustomerByLastName @LastName", param)
    .ToListAsync();
```

### 7.2 Процедуры сохранения (Insert/Update)

```csharp
// uspSaveCustomer
await context.Database.ExecuteSqlRawAsync(
    "EXEC uspSaveCustomer @CustomerID, @LastName, @FirstName, @MiddleName, @Birthday, @GenderID, @APPPTPRID, @MedCard, @NotaBene",
    new SqlParameter("@CustomerID", customer.CustomerId),
    new SqlParameter("@LastName", customer.LastName),
    new SqlParameter("@FirstName", customer.FirstName),
    new SqlParameter("@MiddleName", (object?)customer.MiddleName ?? DBNull.Value),
    new SqlParameter("@Birthday", (object?)customer.Birthday ?? DBNull.Value),
    new SqlParameter("@GenderID", (object?)customer.GenderId ?? DBNull.Value),
    new SqlParameter("@APPPTPRID", (object?)customer.AppptprId ?? DBNull.Value),
    new SqlParameter("@MedCard", (object?)customer.MedCard ?? DBNull.Value),
    new SqlParameter("@NotaBene", DBNull.Value)
);
```

### 7.3 Процедуры удаления

```csharp
// uspDeleteCustomer
await context.Database.ExecuteSqlRawAsync(
    "EXEC uspDeleteCustomer @CustomerID = {0}",
    customerId
);
```

### 7.4 Процедуры фильтрации с TVP (табличные параметры)

```csharp
// uspFilterCustomerByLands — фильтр по списку участков
// Можно передать список через JOIN в приложении или использовать string_split

// Вариант 1: через строку с разделителями
var landIds = "1,2,3";
var filtered = await context.Customers
    .FromSqlRaw("EXEC uspFilterCustomerByLands @Lands = {0}", landIds)
    .ToListAsync();
```

---

## 8. Мягкое удаление (Soft Delete)

В базе данных у таблицы `Customer` есть триггер `CancelDeleteRow`, который перехватывает `DELETE` и вместо физического удаления выставляет `Delete = 1`. В EF Core это обрабатывается следующим образом:

### 8.1 Глобальный фильтр запросов

```csharp
// В OnModelCreating добавьте к конфигурации Customer:
modelBuilder.Entity<Customer>()
    .HasQueryFilter(c => !c.Delete);
```

Теперь все запросы к `Customer` автоматически добавляют `WHERE Delete = 0`.

### 8.2 Обход фильтра (для просмотра удалённых)

```csharp
// Получить в том числе "удалённых" пациентов
var allCustomers = await context.Customers
    .IgnoreQueryFilters()
    .ToListAsync();

// Только удалённые
var deletedCustomers = await context.Customers
    .IgnoreQueryFilters()
    .Where(c => c.Delete)
    .ToListAsync();
```

### 8.3 Восстановление пациента из "удалённых"

```csharp
var customer = await context.Customers
    .IgnoreQueryFilters()
    .FirstAsync(c => c.CustomerId == id);

customer.Delete = false;
await context.SaveChangesAsync();
```

### 8.4 Переопределение SaveChanges для автоматического Soft Delete

Если вы хотите, чтобы `context.Remove(customer)` автоматически выполнял мягкое удаление (а не полагаться на триггер):

```csharp
public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
{
    foreach (var entry in ChangeTracker.Entries<Customer>()
        .Where(e => e.State == EntityState.Deleted))
    {
        entry.State = EntityState.Modified;
        entry.Entity.Delete = true;
        entry.Entity.ModifyDate = DateTime.Now;
    }

    return base.SaveChangesAsync(cancellationToken);
}
```

---

## 9. Репозиторий — примеры запросов

### 9.1 Базовые CRUD операции

```csharp
// Получить пациента по ID
var customer = await context.Customers
    .Include(c => c.Gender)
    .Include(c => c.Appptpr)
    .Include(c => c.NotaBene)
    .FirstOrDefaultAsync(c => c.CustomerId == id);

// Получить пациента со всеми связанными данными
var fullCustomer = await context.Customers
    .Include(c => c.Addresses)
        .ThenInclude(a => a.AdminDivision)
    .Include(c => c.Addresses)
        .ThenInclude(a => a.TypeStreet)
    .Include(c => c.Registers)
        .ThenInclude(r => r.RegisterType)
    .Include(c => c.Registers)
        .ThenInclude(r => r.Land)
    .Include(c => c.Invalids)
        .ThenInclude(i => i.DisabilityGroup)
    .Include(c => c.Invalids)
        .ThenInclude(i => i.BenefitsCategories)
    .FirstOrDefaultAsync(c => c.CustomerId == id);

// Добавить нового пациента
var newCustomer = new Customer
{
    LastName = "Иванов",
    FirstName = "Иван",
    MiddleName = "Иванович",
    Birthday = new DateTime(1980, 5, 15),
    Arch = false,
    GenderId = 1,
    ModifyDate = DateTime.Now
};
context.Customers.Add(newCustomer);
await context.SaveChangesAsync();

// Обновить пациента
var customer = await context.Customers.FindAsync(id);
if (customer != null)
{
    customer.LastName = "Петров";
    customer.ModifyDate = DateTime.Now;
    await context.SaveChangesAsync();
}

// Удалить пациента (через триггер или переопределённый SaveChanges)
var customer = await context.Customers.FindAsync(id);
if (customer != null)
{
    context.Customers.Remove(customer);
    await context.SaveChangesAsync();
}
```

### 9.2 Работа с инвалидностью и льготами

```csharp
// Получить записи об инвалидности пациента
var invalids = await context.Invalids
    .Include(i => i.DisabilityGroup)
    .Include(i => i.ChiperRecept)
    .Include(i => i.BenefitsCategories)
    .Where(i => i.CustomerId == customerId)
    .ToListAsync();

// Добавить льготу к записи об инвалидности
var invalid = await context.Invalids
    .Include(i => i.BenefitsCategories)
    .FirstAsync(i => i.InvalidId == invalidId);

var benefitsCategory = await context.BenefitsCategories.FindAsync(categoryId);
if (benefitsCategory != null)
{
    invalid.BenefitsCategories.Add(benefitsCategory);
    await context.SaveChangesAsync();
}

// Удалить льготу из записи
invalid.BenefitsCategories.Remove(benefitsCategory!);
await context.SaveChangesAsync();
```

### 9.3 Поиск и фильтрация

```csharp
// Поиск по фамилии (аналог uspGetCustomerByLastName)
var results = await context.Customers
    .Where(c => c.LastName.Contains(searchText))
    .Include(c => c.Gender)
    .OrderBy(c => c.LastName)
    .ThenBy(c => c.FirstName)
    .ToListAsync();

// Пациенты по участку через регистрацию
var byLand = await context.Customers
    .Where(c => c.Registers.Any(r => r.LandId == landId))
    .ToListAsync();

// Пациенты по группе инвалидности
var byDisability = await context.Customers
    .Where(c => c.Invalids.Any(i => i.DisabilityGroupId == groupId))
    .Include(c => c.Invalids)
    .ToListAsync();

// Пациенты по льготной категории
var byBenefits = await context.Customers
    .Where(c => c.Invalids
        .Any(i => i.BenefitsCategories
            .Any(b => b.BenefitsCategoryId == categoryId)))
    .ToListAsync();
```

### 9.4 Работа с адресами

```csharp
// Найти пациентов по улице (аналог uspGetAddress)
var byStreet = await context.Addresses
    .Where(a => a.NameStreet != null && a.NameStreet.Contains(streetName))
    .Include(a => a.Customer)
    .Include(a => a.AdminDivision)
    .Include(a => a.TypeStreet)
    .ToListAsync();

// Добавить адрес пациенту
var address = new Address
{
    CustomerId = customerId,
    City = "Москва",
    AdminDivisionId = 5,
    NameStreet = "Ленина",
    NumberHouse = "10",
    NumberApartment = "5",
    ModifiedDate = DateTime.Now
};
context.Addresses.Add(address);
await context.SaveChangesAsync();
```

---

## 10. Советы и рекомендации

### 10.1 Настройка логирования SQL-запросов

```csharp
// В appsettings.Development.json
{
  "Logging": {
    "LogLevel": {
      "Microsoft.EntityFrameworkCore.Database.Command": "Information"
    }
  }
}
```

Или программно:

```csharp
builder.Services.AddDbContext<DispancerDbContext>(options =>
    options.UseSqlServer(connectionString)
           .LogTo(Console.WriteLine, LogLevel.Information)
           .EnableSensitiveDataLogging()); // Только для разработки!
```

### 10.2 Разделение конфигурации на отдельные классы

Вместо одного большого `OnModelCreating` используйте `IEntityTypeConfiguration<T>`:

```csharp
// Configurations/CustomerConfiguration.cs
public class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder)
    {
        builder.ToTable("Customer");
        builder.HasKey(x => x.CustomerId);
        // ... вся конфигурация Customer
    }
}

// В OnModelCreating:
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(DispancerDbContext).Assembly);
}
```

### 10.3 Асинхронность и управление временем жизни контекста

```csharp
// Всегда используйте async/await
var customers = await context.Customers.ToListAsync();

// В ASP.NET Core DbContext регистрируется как Scoped (один экземпляр на запрос)
// Не используйте DbContext как Singleton!
```

### 10.4 Избегайте N+1 проблем

```csharp
// Плохо — N+1
var customers = await context.Customers.ToListAsync();
foreach (var c in customers)
{
    var addresses = await context.Addresses // Отдельный запрос для каждого!
        .Where(a => a.CustomerId == c.CustomerId)
        .ToListAsync();
}

// Хорошо — один запрос с JOIN
var customers = await context.Customers
    .Include(c => c.Addresses)
    .ToListAsync();
```

### 10.5 Использование транзакций

```csharp
using var transaction = await context.Database.BeginTransactionAsync();
try
{
    var customer = new Customer { LastName = "Новый", FirstName = "Пациент", Arch = false };
    context.Customers.Add(customer);
    await context.SaveChangesAsync();

    var address = new Address { CustomerId = customer.CustomerId, City = "Москва", AdminDivisionId = 5 };
    context.Addresses.Add(address);
    await context.SaveChangesAsync();

    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

### 10.6 Подключение к существующей базе без миграций

Если вы подключаетесь к уже существующей базе и не хотите управлять схемой через EF:

```csharp
// В Program.cs — только убедитесь, что соединение работает
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<DispancerDbContext>();
    await db.Database.CanConnectAsync(); // Проверка соединения
    // НЕ вызывайте db.Database.MigrateAsync() если схема управляется вручную
}
```

### 10.7 Структура проекта (рекомендуемая)

```
Dispancer.sln
├── Dispancer.Api/                  # ASP.NET Core Web API
│   ├── Controllers/
│   ├── Program.cs
│   └── appsettings.json
└── Dispancer.Data/                 # Слой данных
    ├── Entities/                   # Классы сущностей
    │   ├── Customer.cs
    │   ├── Address.cs
    │   └── ...
    ├── Views/                      # Классы для представлений
    │   ├── VGetCustomer.cs
    │   └── ...
    ├── Configurations/             # IEntityTypeConfiguration
    │   ├── CustomerConfiguration.cs
    │   └── ...
    ├── Migrations/                 # Автогенерируемые миграции
    └── DispancerDbContext.cs
```

---

## Краткая шпаргалка по командам EF Core

| Действие | Команда |
|---|---|
| Добавить миграцию | `dotnet ef migrations add <Name>` |
| Применить миграции | `dotnet ef database update` |
| Откатить миграцию | `dotnet ef database update <PrevMigration>` |
| Удалить последнюю миграцию | `dotnet ef migrations remove` |
| Scaffold из БД | `dotnet ef dbcontext scaffold "..." Microsoft.EntityFrameworkCore.SqlServer` |
| Список миграций | `dotnet ef migrations list` |
| Сгенерировать SQL скрипт | `dotnet ef migrations script` |
| Проверить соединение | `dotnet ef dbcontext info` |
