SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByLand] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspFilterCustomerByLands]
(@landid NVARCHAR(100))
AS
  BEGIN

DECLARE @sqlQuery NVARCHAR(200)
SET @sqlQuery =  N'SELECT
			vgr.CustomerID
		FROM
			dbo.vGetRegister AS vgr		
	WHERE vgr.LandID  IN (' + @landid +N')';


CREATE TABLE #CustomerTempTotals
(
  CustomerID int
  
)
INSERT #CustomerTempTotals
(
    CustomerID
)
EXEC sp_executesql @sqlQuery

SELECT vgc.CustomerID, vgc.MedCard, vgc.CodeCustomer, vgc.LastName, vgc.FirstName,
		   vgc.MiddleName, vgc.Birthday, vgc.Arch, vgc.APPPTPRID, vgc.GenderID,
		   vgc.NotaBene
	  FROM dbo.vGetCustomers AS vgc
	  INNER JOIN #CustomerTempTotals AS c 
	  ON c.CustomerID = vgc.CustomerID

DELETE #CustomerTempTotals      
  END
GO
