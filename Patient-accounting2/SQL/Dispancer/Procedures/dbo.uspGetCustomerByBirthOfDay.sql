SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByBirthOfDay] */

/* DispensaryTemp.[dbo].[uspGetCustomerByLastName] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[uspGetCustomerByBirthOfDay]
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
	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.Birthday > @BirthOfDay	
END

ELSE IF @predicate = '='
     BEGIN
     	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.Birthday = @BirthOfDay
     END
     
 ELSE IF @predicate = '>='
     BEGIN
     	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.Birthday >= @BirthOfDay
     END
     
 ELSE IF @predicate = '<='
     BEGIN
     	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.Birthday <= @BirthOfDay
     END
     
  ELSE IF @predicate = '<'
     BEGIN
     	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.Birthday < @BirthOfDay
     END
   
   ELSE IF @predicate = '<>'
     BEGIN
     	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.Birthday <> @BirthOfDay
     END
     
   ELSE IF @predicate = 'ÌÅÆÄÓ'
     BEGIN
     	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.Birthday BETWEEN @BirthOfDay AND @BirthOfDayEnd
     END
END

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByBirthOfDay] TO [Sensitive_low] AS [dbo]
GO
