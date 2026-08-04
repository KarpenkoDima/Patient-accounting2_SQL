SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetAddressByBirthOfDay] */

/* [Dispensary].[dbo].[uspGetCustomerByBirthOfDay] */

/* DispensaryTemp.[dbo].[uspGetCustomerByLastName] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[uspGetAddressByBirthOfDay]
	-- Add the parameters for the stored procedure here
	@BirthOfDay DATETIME NULL,
	@BirthOfDayEnd DATETIME NULL,
	@predicate NVARCHAR(10)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	    -- Insert statements for procedure here
	SET @predicate = RTRIM(LTRIM(@predicate));

IF @predicate = '>' 
BEGIN
	WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday > @BirthOfDay	
	)
	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ ON CTE_.CustomerID = vga.CustomerID 
END

ELSE IF @predicate = '='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday = @BirthOfDay
	)

	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID  FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ ON CTE_.CustomerID = vga.CustomerID 
     END
     
 ELSE IF @predicate = '>='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday >= @BirthOfDay
	)

	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID  FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ ON CTE_.CustomerID = vga.CustomerID 
     END
     
 ELSE IF @predicate = '<='
     BEGIN
     	WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <= @BirthOfDay
	)
	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID  FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ ON CTE_.CustomerID = vga.CustomerID 
     END
     
  ELSE IF @predicate = '<'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc	 
	WHERE vgc.Birthday < @BirthOfDay
)

	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID  FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ ON CTE_.CustomerID = vga.CustomerID 
     END
   
   ELSE IF @predicate = '<>'
     BEGIN
WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <> @BirthOfDay
	)

	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID  FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ ON CTE_.CustomerID = vga.CustomerID 
     END
     
   ELSE IF @predicate = 'ÌÅÆÄÓ'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	 WHERE vgc.Birthday BETWEEN @BirthOfDay AND @BirthOfDayEnd
	 )

	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Country,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID  FROM dbo.vGetAddress AS vga
	INNER JOIN CTE_ ON CTE_.CustomerID = vga.CustomerID 
     END
END

GO

GRANT EXECUTE ON [dbo].[uspGetAddressByBirthOfDay] TO [Sensitive_low] AS [dbo]
GO
