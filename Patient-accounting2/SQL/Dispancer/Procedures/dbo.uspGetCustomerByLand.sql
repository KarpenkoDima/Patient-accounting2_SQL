SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByLand] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspGetCustomerByLand]
(@ID INT)
AS
  BEGIN
	WITH CTE(CustomerID)
	AS(
		SELECT
			vgr.CustomerID
		FROM
			dbo.vGetRegister AS vgr		
	WHERE vgr.LandID = @ID
	)

	SELECT vgc.CustomerID, vgc.MedCard, vgc.CodeCustomer, vgc.LastName, vgc.FirstName,
		   vgc.MiddleName, vgc.Birthday, vgc.Arch, vgc.APPPTPRID, vgc.GenderID,
		   vgc.NotaBene
	  FROM dbo.vGetCustomers AS vgc
	  INNER JOIN CTE AS c 
	  ON c.CustomerID = vgc.CustomerID

      
  END

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByLand] TO [Sensitive_low] AS [dbo]
GO
