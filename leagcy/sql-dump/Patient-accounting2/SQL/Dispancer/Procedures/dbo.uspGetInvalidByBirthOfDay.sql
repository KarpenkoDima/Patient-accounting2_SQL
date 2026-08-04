SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetInvalidByBirthOfDay] */

/* [Dispensary].[dbo].[uspGetCustomerByBirthOfDay] */

/* DispensaryTemp.[dbo].[uspGetCustomerByLastName] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[uspGetInvalidByBirthOfDay]
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
	SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ ON CTE_.CustomerID = vgi.CustomerID 
END

ELSE IF @predicate = '='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday = @BirthOfDay
	)

	SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ ON CTE_.CustomerID = vgi.CustomerID 
     END
     
 ELSE IF @predicate = '>='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday >= @BirthOfDay
	)

SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ ON CTE_.CustomerID = vgi.CustomerID 
     END
     
 ELSE IF @predicate = '<='
     BEGIN
     	WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <= @BirthOfDay
	)
SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ ON CTE_.CustomerID = vgi.CustomerID 
     END
     
  ELSE IF @predicate = '<'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc	 
	WHERE vgc.Birthday < @BirthOfDay
)

SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ ON CTE_.CustomerID = vgi.CustomerID 
     END
   
   ELSE IF @predicate = '<>'
     BEGIN
WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <> @BirthOfDay
	)

SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ ON CTE_.CustomerID = vgi.CustomerID 
     END
     
   ELSE IF @predicate = 'ÌÅÆÄÓ'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	 WHERE vgc.Birthday BETWEEN @BirthOfDay AND @BirthOfDayEnd
	 )

SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	INNER JOIN CTE_ ON CTE_.CustomerID = vgi.CustomerID 
     END
END

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidByBirthOfDay] TO [Sensitive_low] AS [dbo]
GO
