SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary13102017].[dbo].[uspGetCustomerByAddress] */

/* DispensaryTemp.[dbo].[uspGetAddressByCustomerID] */

 CREATE PROCEDURE [dbo].[uspGetCustomerByAddress]
(
	@City NVARCHAR(100) NULL,
	@NameStreet NVARCHAR(100)	
)
AS
BEGIN
    	SET NOCOUNT ON;
    	
    	SET @City = ISNULL(nullif(@City, ''), '%%');
    	IF @city IS NOT NULL AND @nameStreet IS NOT NULL
    	BEGIN   
    
    	--IF @city IS NOT NULL AND @nameStreet IS NOT NULL
    	--BEGIN
    	--SET @City = ISNULL(@City, '%%');
    	--SET @NameStreet = ISNULL(@NameStreet, '%%');
    
    	--IF @City = N'' 
    	--BEGIN
    	--	SET @City ='%%';
    	--END 
    	--IF @NameStreet = N'' 
    	--BEGIN
    	--	SET @NameStreet ='%%';
    	--END ;
    	WITH CTE_GetCustomeIDByAddress(CustomerID)
    	AS(
    		SELECT customerID FROM [dbo].[Address] AS a
    		WHERE a.City LIKE @City AND a.NameStreet LIKE @NameStreet+'%'
    	)
    
    	SELECT c.[CustomerID]
    	  ,c.[MedCard]
    	  ,c.[CodeCustomer]
    	  ,c.[LastName]
    	  ,c.[FirstName]
    	  ,c.[MiddleName]
    	  ,c.[Birthday]
    	  ,c.[ModifyDate]
    	  ,c.[Arch]
    	  ,c.CustomerTempID
    	  ,c.[APPPTPRID]
    	  ,c.[GenderID]
    	  FROM [dbo].[Customer] AS c
    	  INNER JOIN CTE_GetCustomeIDByAddress AS cgcia
    	  ON  cgcia.CustomerID = c.CustomerID
		  END 
END

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByAddress] TO [Sensitive_medium] AS [dbo]
GO
