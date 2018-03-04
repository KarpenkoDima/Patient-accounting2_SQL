SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetInvalidByBenefitsCategory] */

/* [Dispensary].[dbo].[uspGetCustomerByBenefitsCategory] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetInvalidByBenefitsCategory]
(@ID INT)
AS
 BEGIN
WITH CTE_InvalidBenefits(CustomerID)
AS(
	SELECT
		vgi.CustomerID
	FROM
		dbo.vGetInvalid AS vgi
		INNER JOIN dbo.vGetInvalid_BenefitsCategory AS vgibc
		ON vgi.InvalidID = vgibc.invID
		INNER JOIN dbo.vGetBenefitsCategory AS vgbc
		ON vgbc.BenefitsCategoryID = vgibc.BenefitsID
		INNER JOIN dbo.vGetCustomers AS vgc
		ON vgc.CustomerID = vgi.CustomerID
WHERE vgbc.BenefitsCategoryID = @ID AND vgc.Arch =0
		
		
)
SELECT vgi.ChiperReceptID,
       vgi.CustomerID,
       vgi.DataInvalidity,
       vgi.DateIncapable,
       vgi.DisabilityGroupID,
       vgi.Incapable,
       vgi.InvalidID,
       vgi.ModifiedDate,
       vgi.PeriodInvalidity  FROM dbo.vGetInvalid AS vgi
  INNER JOIN CTE_InvalidBenefits AS cte
  ON cte.CustomerID = vgi.CustomerID

      
  END

GO
