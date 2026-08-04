SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByDisabilityGroup] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetCustomerByDisabilityGroup]
(@ID INT)
AS

WITH CTE(CustomerID)
AS(
	SELECT
		vgi.CustomerID
	FROM
		vGetInvalid AS vgi
		INNER JOIN vGetDisabilityGroup AS vgdg
		ON vgi.DisabilityGroupID = vgdg.DisabilityGroupID
		WHERE vgdg.DisabilityGroupID = @ID
		
		
)
SELECT vgc.CustomerID, vgc.MedCard, vgc.CodeCustomer, vgc.LastName, vgc.FirstName,
       vgc.MiddleName, vgc.Birthday, vgc.Arch, vgc.APPPTPRID, vgc.GenderID,
       vgc.NotaBene
  FROM vGetCustomers AS vgc
  INNER JOIN CTE AS cte
  ON cte.CustomerID = vgc.CustomerID

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByDisabilityGroup] TO [Sensitive_low] AS [dbo]
GO
