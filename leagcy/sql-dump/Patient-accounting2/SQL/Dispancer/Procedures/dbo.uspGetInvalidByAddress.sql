SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [DispensaryMainTest].[dbo].[uspGetInvalidByAddress] */

CREATE PROCEDURE [dbo].[uspGetInvalidByAddress]
(
	@City NVARCHAR(100) NULL,
	@NameStreet NVARCHAR(100)	
)
AS
BEGIN
    	SET NOCOUNT ON;
    	
    	SET @City = ISNULL(nullif(@City,''), '%%');
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
		  SELECT vgi.ChiperReceptID,
                 vgi.CustomerID,
                 vgi.DataInvalidity,
                 vgi.DateIncapable,
                 vgi.DisabilityGroupID,
                 vgi.Incapable,
                 vgi.InvalidID,
                 vgi.ModifiedDate,
                 vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
				  INNER	JOIN CTE_GetCustomeIDByAddress AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
	END 
		
END

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidByAddress] TO [Sensitive_low] AS [dbo]
GO
