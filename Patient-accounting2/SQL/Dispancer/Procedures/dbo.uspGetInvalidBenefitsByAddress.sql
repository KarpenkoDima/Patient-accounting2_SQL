SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [DispensaryMainTest].[dbo].[uspGetInvalidByAddress] */

CREATE PROCEDURE [dbo].[uspGetInvalidBenefitsByAddress]
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
    		SELECT customerID FROM [dbo].vGetAddress  AS a
    		WHERE a.City LIKE '%%' AND a.NameStreet LIKE @NameStreet +'%'
    	)
    	
    	SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_GetCustomeIDByAddress AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
	END 
		
END

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidBenefitsByAddress] TO [Sensitive_low] AS [dbo]
GO
