SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByBenefitsCategory] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetCustomerByBenefitsCategory]
(@ID INT)
AS

WITH CTE_InvalidBenefits(CustomerID)
AS(
	SELECT
		vgi.CustomerID
	FROM
		vGetInvalid AS vgi
		INNER JOIN vGetInvalid_BenefitsCategory AS vgibc
		ON vgi.InvalidID = vgibc.invID
		INNER JOIN vGetBenefitsCategory AS vgbc
		ON vgbc.BenefitsCategoryID = vgibc.BenefitsID
WHERE vgbc.BenefitsCategoryID = @ID
		
		
)
SELECT vgc.CustomerID, vgc.MedCard, vgc.CodeCustomer, vgc.LastName, vgc.FirstName,
       vgc.MiddleName, vgc.Birthday, vgc.Arch, vgc.APPPTPRID, vgc.GenderID,
       vgc.NotaBene
  FROM vGetCustomers AS vgc
  INNER JOIN CTE_InvalidBenefits AS cte
  ON cte.CustomerID = vgc.CustomerID

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByBenefitsCategory] TO [Sensitive_low] AS [dbo]
GO
