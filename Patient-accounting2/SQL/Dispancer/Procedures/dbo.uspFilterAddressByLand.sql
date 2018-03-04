SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary].[dbo].[uspGetCustomerByLand] */

/****** Script for SelectTopNRows command from SSMS  
* 09.08.2016 Procedure for selecting Gender table
* ******/
CREATE PROCEDURE [dbo].[uspFilterAddressByLand]
(@landid NVARCHAR(100))
AS
  BEGIN

DECLARE @sqlQuery NVARCHAR(200)
SET @sqlQuery =  N'SELECT
			vgr.CustomerID			
		FROM
			dbo.vGetRegister AS vgr	
			INNER JOIN dbo.vGetCustomers AS vgc
			ON vgc.CustomerID = vgr.CustomerID	
	WHERE vgr.LandID IN (' + @landid + N')AND vgc.Arch =0'	

CREATE TABLE #CustomerTempTotals
(
  CustomerID int
  
)
INSERT #CustomerTempTotals
(
    CustomerID
)
EXEC sp_executesql @sqlQuery

	SELECT vga.AddressID,
           vga.AdminDivisionID,
           vga.City,
           vga.Contry,
           vga.CustomerID,
           vga.ModifiedDate,
           vga.NameStreet,
           vga.NumberApartment,
           vga.NumberHouse,
           vga.Region,
           vga.TypeStreetID FROM dbo.vGetAddress AS vga
	  INNER JOIN #CustomerTempTotals AS c 
	  ON c.CustomerID = vga.CustomerID

 DELETE #CustomerTempTotals           
  END
GO
