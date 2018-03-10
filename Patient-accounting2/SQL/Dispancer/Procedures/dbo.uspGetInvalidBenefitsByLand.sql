SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [DispensaryMainTest].[dbo].[uspGetInvalidByAddress] */

CREATE PROCEDURE [dbo].[uspGetInvalidBenefitsByLand]
(@ID INT)
AS
  BEGIN
	WITH CTE_(CustomerID)
	AS(
		SELECT
			vgr.CustomerID
		FROM
			dbo.vGetRegister AS vgr	
			INNER JOIN dbo.vGetCustomers AS vgc
			ON vgc.CustomerID = vgr.CustomerID	
	WHERE vgr.LandID = @ID AND vgc.Arch =0
	)
    	
    	SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
	
		
END

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidBenefitsByLand] TO [Sensitive_low] AS [dbo]
GO
