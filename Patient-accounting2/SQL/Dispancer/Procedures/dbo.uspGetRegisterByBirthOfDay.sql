SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetRegisterByBirthOfDay] */

/* [Dispensary].[dbo].[uspGetCustomerByBirthOfDay] */

/* DispensaryTemp.[dbo].[uspGetCustomerByLastName] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[uspGetRegisterByBirthOfDay]
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
	SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ ON CTE_.CustomerID = vgr.CustomerID 
END

ELSE IF @predicate = '='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday = @BirthOfDay
	)

		SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ ON CTE_.CustomerID = vgr.CustomerID 
     END
     
 ELSE IF @predicate = '>='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday >= @BirthOfDay
	)

	SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ ON CTE_.CustomerID = vgr.CustomerID 
     END
     
 ELSE IF @predicate = '<='
     BEGIN
     	WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <= @BirthOfDay
	)
	SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ ON CTE_.CustomerID = vgr.CustomerID 
     END
     
  ELSE IF @predicate = '<'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc	 
	WHERE vgc.Birthday < @BirthOfDay
)

	SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ ON CTE_.CustomerID = vgr.CustomerID 
     END
   
   ELSE IF @predicate = '<>'
     BEGIN
WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <> @BirthOfDay
	)

	SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ ON CTE_.CustomerID = vgr.CustomerID 
     END
     
   ELSE IF @predicate = 'ÌÅÆÄÓ'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	 WHERE vgc.Birthday BETWEEN @BirthOfDay AND @BirthOfDayEnd
	 )

	SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID FROM dbo.vGetRegister AS vgr
	INNER JOIN CTE_ ON CTE_.CustomerID = vgr.CustomerID 
     END
END

GO
