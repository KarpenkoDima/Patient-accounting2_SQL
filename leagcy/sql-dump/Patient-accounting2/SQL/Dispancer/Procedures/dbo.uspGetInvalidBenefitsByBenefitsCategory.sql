SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [DispensaryMainTest].[dbo].[uspGetInvalidByAddress] */

CREATE PROCEDURE [dbo].[uspGetInvalidBenefitsByBenefitsCategory]
(@ID INT)
AS
BEGIN
    	SET NOCOUNT ON;
    BEGIN
		  WITH CTE_ (CustomerID)
	AS(
		SELECT vgc.CustomerID FROM dbo.vGetCustomers AS vgc
		--WHERE vgc.APPPTPRID =@ID
	)
    	
    	SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID
    	WHERE ibc.BenefitsID=@ID;
	END 
		
END

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidBenefitsByBenefitsCategory] TO [Sensitive_low] AS [dbo]
GO
